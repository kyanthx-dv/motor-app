import 'package:flutter/material.dart';

import 'avisos.dart';
import 'dados.dart';
import 'icones.dart';
import 'nuvem.dart';
import 'widgets.dart';

/// Capas de post (enquanto imagens/videos proprios nao existem): 6 degrades e 6 icones, escolhidos por quem posta.
const capasCores = <(Color, Color)>[
  (Color(0xFF1D9BF0), Color(0xFF1D9BF0)),
  (Color(0xFFF97316), Color(0xFFF97316)),
  (Color(0xFF23A55A), Color(0xFF23A55A)),
  (Color(0xFFF23F43), Color(0xFFF23F43)),
  (Color(0xFFF59E0B), Color(0xFFF59E0B)),
  (Color(0xFF8E9297), Color(0xFF8E9297)),
];
const capasIcones = <IconData>[Ic.brilho, Ic.controle, Ic.foguete, Ic.flor, Ic.musica, Ic.camera];

/// Posts reais (Supabase): feed, curtir/favoritar com atualizacao imediata, contagens e quem eu sigo.
class RepoPosts extends ChangeNotifier {
  RepoPosts._();
  static final i = RepoPosts._();

  List<Post> posts = [];
  bool carregando = false;
  String? erro;
  Set<String> seguindoIds = {};
  final Set<String> _curtidos = {};
  final Set<String> _favoritos = {};
  final Map<String, int> _curt = {};
  final Map<String, int> _fav = {};
  final Map<String, int> _com = {};

  bool curtiu(Post p) => _curtidos.contains(p.id);
  bool favoritou(Post p) => _favoritos.contains(p.id);
  int curtidas(Post p) => _curt[p.id] ?? p.curtidas;
  int favoritos(Post p) => _fav[p.id] ?? 0;
  int comentarios(Post p) => _com[p.id] ?? p.numComentarios;

  Post _dePost(Map<String, dynamic> r) {
    final ex = (r['extras'] as Map?) ?? const {};
    final id = r['id'] as String;
    final h = id.codeUnits.fold<int>(0, (a, b) => a + b);
    final pi = ((ex['p'] as num?)?.toInt() ?? h) % capasCores.length;
    final ii = ((ex['i'] as num?)?.toInt() ?? h ~/ 3) % capasIcones.length;
    return Post(
      id: id,
      autorId: r['autor'] as String,
      titulo: r['titulo'] as String,
      descricao: (r['descricao'] as String?) ?? '',
      autor: r['autor_usuario'] as String,
      cor1: capasCores[pi].$1,
      cor2: capasCores[pi].$2,
      icone: capasIcones[ii],
      video: r['video'] == true,
      curtidas: (r['curtidas'] as num?)?.toInt() ?? 0,
      totalComentarios: (r['comentarios'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> carregar() async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      final linhas = await Nuvem.i.feed('post');
      final novos = [for (final r in linhas) _dePost(r)];
      final marcas = await Nuvem.i.minhasMarcas('post', [for (final p in novos) p.id]);
      final sigo = await Nuvem.i.quemSigo();
      posts = novos;
      _curtidos
        ..clear()
        ..addAll(marcas['curtida'] ?? {});
      _favoritos
        ..clear()
        ..addAll(marcas['favorito'] ?? {});
      _curt.clear();
      _fav.clear();
      _com.clear();
      for (final r in linhas) {
        _fav[r['id'] as String] = (r['favoritos'] as num?)?.toInt() ?? 0;
      }
      seguindoIds = sigo;
    } on ErroNuvem catch (e) {
      erro = e.msg;
      Avisos.add(Nivel.aviso, 'Feed: ${e.msg}');
    }
    carregando = false;
    notifyListeners();
  }

  Future<void> publicar({required String titulo, required String descricao, required int paleta, required int icone}) async {
    await Nuvem.i.publicar(tipo: 'post', titulo: titulo, descricao: descricao, extras: {'p': paleta, 'i': icone});
    await carregar();
  }

  /// Liga/desliga curtida ou favorito: muda na hora e desfaz se o servidor recusar.
  Future<void> alternar(Post p, String marca) async {
    if (!Nuvem.i.logado) throw ErroNuvem('Entre na sua conta para curtir e favoritar.');
    final conj = marca == 'curtida' ? _curtidos : _favoritos;
    final cont = marca == 'curtida' ? _curt : _fav;
    final base = marca == 'curtida' ? curtidas(p) : favoritos(p);
    final ligar = !conj.contains(p.id);
    if (ligar) {
      conj.add(p.id);
    } else {
      conj.remove(p.id);
    }
    cont[p.id] = (base + (ligar ? 1 : -1)).clamp(0, 1 << 30);
    notifyListeners();
    try {
      await Nuvem.i.marcar('post', p.id, marca, ligar);
    } on ErroNuvem {
      if (ligar) {
        conj.remove(p.id);
      } else {
        conj.add(p.id);
      }
      cont[p.id] = base;
      notifyListeners();
      rethrow;
    }
  }

  void comentou(String id) {
    final p = posts.where((x) => x.id == id);
    if (p.isEmpty) return;
    _com[id] = comentarios(p.first) + 1;
    notifyListeners();
  }
}

/// Executa uma acao da nuvem e mostra o erro (em portugues) num aviso, sem travar a tela.
Future<void> tentar(BuildContext context, Future<void> Function() acao) async {
  try {
    await acao();
  } on ErroNuvem catch (e) {
    Avisos.add(Nivel.aviso, e.msg);
    if (context.mounted) aviso(context, e.msg);
  }
}
