import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'avisos.dart';
import 'desenho_nucleo.dart';

/// Valor guardado numa celula do mapa para um asset desenhado: [baseAsset] + id.
const int baseAsset = 100000;

class AssetSalvo {
  AssetSalvo({required this.id, required this.nome, required this.l, required this.a, required this.criadoMs});
  final int id;
  String nome;
  final int l, a;
  final int criadoMs;

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'l': l, 'a': a, 'criado': criadoMs};
  static AssetSalvo deJson(Map<String, dynamic> j) => AssetSalvo(id: j['id'] as int, nome: j['nome'] as String, l: j['l'] as int, a: j['a'] as int, criadoMs: j['criado'] as int);
}

/// Biblioteca de desenhos do usuario (arquivos na pasta do app): um .json (camadas) e um .png (resultado) por desenho.
/// Os desenhos sao feitos dentro do app, entao o usuario e dono de tudo (nada importado).
class Biblioteca extends ChangeNotifier {
  Biblioteca._();
  static final Biblioteca i = Biblioteca._();

  final List<AssetSalvo> itens = [];
  final Map<int, ui.Image> _imagens = {};
  final Set<int> _carregando = {};
  /// Sobe a cada gravacao: chave para recarregar miniaturas.
  final Map<int, int> versoes = {};
  int _proximo = 1;
  bool _pronta = false;
  Directory? _dir;

  Future<Directory> _pasta() async {
    final d = _dir ??= Directory('${(await getApplicationDocumentsDirectory()).path}/assets');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<void> carregar() async {
    if (_pronta) return;
    try {
      final f = File('${(await _pasta()).path}/indice.json');
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _proximo = (j['proximo'] as num?)?.toInt() ?? 1;
        itens
          ..clear()
          ..addAll([for (final e in (j['itens'] as List)) AssetSalvo.deJson(Map<String, dynamic>.from(e as Map))]);
      }
      _pronta = true;
      notifyListeners();
    } catch (e) {
      Avisos.add(Nivel.erro, 'Biblioteca: $e');
    }
  }

  AssetSalvo? porId(int id) {
    for (final a in itens) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<void> _gravarIndice() async {
    final f = File('${(await _pasta()).path}/indice.json');
    await f.writeAsString(jsonEncode({'proximo': _proximo, 'itens': [for (final a in itens) a.toJson()]}));
  }

  /// Registra um desenho novo e devolve o item (ainda sem arquivos: use [salvar]).
  Future<AssetSalvo> criar(Documento d) async {
    await carregar();
    final a = AssetSalvo(id: _proximo++, nome: d.config.nome, l: d.l, a: d.a, criadoMs: DateTime.now().millisecondsSinceEpoch);
    itens.insert(0, a);
    await salvar(a, d);
    return a;
  }

  Future<void> salvar(AssetSalvo a, Documento d) async {
    final dir = await _pasta();
    a.nome = d.config.nome;
    await File('${dir.path}/${a.id}.json').writeAsString(jsonEncode(d.toJson()));
    final png = await d.png();
    await File('${dir.path}/${a.id}.png').writeAsBytes(png);
    await _gravarIndice();
    _imagens.remove(a.id)?.dispose();
    versoes[a.id] = (versoes[a.id] ?? 0) + 1;
    notifyListeners();
  }

  Future<Documento?> abrir(AssetSalvo a) async {
    try {
      final f = File('${(await _pasta()).path}/${a.id}.json');
      return Documento.deJson(jsonDecode(await f.readAsString()) as Map<String, dynamic>);
    } catch (e) {
      Avisos.add(Nivel.erro, 'Abrir desenho ${a.nome}: $e');
      return null;
    }
  }

  Future<void> apagar(AssetSalvo a) async {
    final dir = await _pasta();
    for (final ext in const ['json', 'png']) {
      final f = File('${dir.path}/${a.id}.$ext');
      if (await f.exists()) await f.delete();
    }
    itens.removeWhere((x) => x.id == a.id);
    _imagens.remove(a.id)?.dispose();
    await _gravarIndice();
    notifyListeners();
  }

  Future<Uint8List?> pngBytes(int id) async {
    final f = File('${(await _pasta()).path}/$id.png');
    return await f.exists() ? f.readAsBytes() : null;
  }

  /// Imagem pronta para desenhar (null enquanto carrega; avisa os ouvintes quando chegar).
  ui.Image? imagem(int id) {
    final i = _imagens[id];
    if (i != null) return i;
    if (_carregando.add(id)) {
      pngBytes(id).then((b) async {
        if (b != null) {
          final codec = await ui.instantiateImageCodec(b);
          final fr = await codec.getNextFrame();
          _imagens[id] = fr.image;
          notifyListeners();
        }
      }).catchError((Object e) {
        Avisos.add(Nivel.erro, 'Imagem do asset $id: $e');
      }).whenComplete(() => _carregando.remove(id));
    }
    return null;
  }
}
