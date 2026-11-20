import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'dados.dart';

/// Limites do editor de celular (mapas grandes demais pesam no aparelho).
const int mapaMin = 4;
const int mapaMax = 64;

enum Fisica { plataforma, rpg }

String rotuloFisica(Fisica f) => f == Fisica.plataforma ? 'Plataforma' : 'RPG';

class Cena {
  Cena({required this.nome, this.fisica = Fisica.plataforma, this.largura = 16, this.altura = 12, this.corFundo = 0xFF4DD0FF, Map<String, int>? celulas, this.inicial = false, this.px = -1, this.py = -1}) : celulas = celulas ?? {};
  String nome;
  Fisica fisica;
  int largura;
  int altura;
  int corFundo; // ARGB
  bool inicial;
  /// Posicao do cartao no tabuleiro de cenas (negativo = ainda nao posicionado).
  double px;
  double py;
  /// "x,y" -> indice do item da paleta (origem embaixo-esquerda, como no editor de PC).
  Map<String, int> celulas;

  Map<String, dynamic> toJson() => {'nome': nome, 'fisica': fisica.name, 'l': largura, 'a': altura, 'cor': corFundo, 'ini': inicial, 'px': px, 'py': py, 'cel': celulas};

  static Cena fromJson(Map<String, dynamic> j) => Cena(
        nome: (j['nome'] as String?) ?? 'Cena',
        fisica: (j['fisica'] == 'rpg') ? Fisica.rpg : Fisica.plataforma,
        largura: ((j['l'] as num?) ?? 16).toInt().clamp(mapaMin, mapaMax),
        altura: ((j['a'] as num?) ?? 12).toInt().clamp(mapaMin, mapaMax),
        corFundo: ((j['cor'] as num?) ?? 0xFF4DD0FF).toInt(),
        inicial: (j['ini'] as bool?) ?? false,
        px: ((j['px'] as num?) ?? -1).toDouble(),
        py: ((j['py'] as num?) ?? -1).toDouble(),
        celulas: {for (final e in ((j['cel'] as Map?) ?? {}).entries) e.key as String: (e.value as num).toInt()},
      );

  Cena copia() => Cena(nome: '$nome (cópia)', fisica: fisica, largura: largura, altura: altura, corFundo: corFundo, celulas: Map.of(celulas), px: px + 30, py: py + 30);
}

class Projeto {
  Projeto({required this.id, required this.nome, this.orientacao = Orientacao.paisagem, List<Cena>? cenas}) : cenas = cenas ?? [];
  final String id;
  String nome;
  Orientacao orientacao; // paisagem | retrato (qualquer tambem aceito)
  final List<Cena> cenas;

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'ori': orientacao.name, 'cenas': [for (final c in cenas) c.toJson()]};

  static Projeto fromJson(Map<String, dynamic> j) => Projeto(
        id: j['id'] as String,
        nome: (j['nome'] as String?) ?? 'Jogo',
        orientacao: Orientacao.values.firstWhere((o) => o.name == j['ori'], orElse: () => Orientacao.paisagem),
        cenas: [for (final c in ((j['cenas'] as List?) ?? [])) Cena.fromJson(c as Map<String, dynamic>)],
      );
}

/// Lista de projetos do usuario, salva em JSON na pasta do app (sem nuvem por enquanto).
class RepositorioProjetos extends ChangeNotifier {
  RepositorioProjetos._();
  static final RepositorioProjetos instancia = RepositorioProjetos._();

  final List<Projeto> projetos = [];
  bool _carregado = false;

  Future<File> _arquivo() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/projetos.json');
  }

  Future<void> carregar() async {
    if (_carregado) return;
    _carregado = true;
    try {
      final f = await _arquivo();
      if (await f.exists()) {
        final lista = jsonDecode(await f.readAsString()) as List;
        projetos
          ..clear()
          ..addAll([for (final p in lista) Projeto.fromJson(p as Map<String, dynamic>)]);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('projetos: falha ao carregar: $e');
    }
  }

  Future<void> salvar() async {
    notifyListeners();
    try {
      final f = await _arquivo();
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(jsonEncode([for (final p in projetos) p.toJson()]));
      await tmp.rename(f.path); // escrita atomica: nao corrompe se o app fechar no meio
    } catch (e) {
      debugPrint('projetos: falha ao salvar: $e');
    }
  }

  /// Projeto novo so com o inicial: uma cena de plataforma vazia (mapa inicial).
  Projeto criar(String nome) {
    final p = Projeto(id: DateTime.now().microsecondsSinceEpoch.toString(), nome: nome.trim(), cenas: [Cena(nome: 'Nível 1', inicial: true)]);
    projetos.insert(0, p);
    salvar();
    return p;
  }

  void apagar(Projeto p) {
    projetos.remove(p);
    salvar();
  }
}
