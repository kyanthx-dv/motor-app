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

/// Um objeto colocado no mapa. Varios podem ocupar a mesma celula (exceto Tile sobre Tile).
class ObjetoCena {
  ObjetoCena({required this.id, required this.v, required this.x, required this.y, this.w = 1, this.h = 1, Map<String, dynamic>? props}) : props = props ?? {};
  final int id;
  int v; // indice da paleta ou baseAsset + id do desenho
  int x, y; // celula do canto inferior esquerdo (origem embaixo-esquerda)
  int w, h; // tamanho em celulas
  /// camada, solido, visivel, scripts, nome, textura (ausente = padrao do tipo).
  Map<String, dynamic> props;

  Map<String, dynamic> toJson() => {'id': id, 'v': v, 'x': x, 'y': y, 'w': w, 'h': h, 'p': props};

  static ObjetoCena fromJson(Map<String, dynamic> j) => ObjetoCena(
        id: (j['id'] as num).toInt(),
        v: (j['v'] as num).toInt(),
        x: (j['x'] as num).toInt(),
        y: (j['y'] as num).toInt(),
        w: ((j['w'] as num?) ?? 1).toInt().clamp(1, mapaMax),
        h: ((j['h'] as num?) ?? 1).toInt().clamp(1, mapaMax),
        props: Map<String, dynamic>.from((j['p'] as Map?) ?? {}),
      );

  ObjetoCena copia(int novoId) => ObjetoCena(id: novoId, v: v, x: x, y: y, w: w, h: h, props: Map<String, dynamic>.from(props));
}

class Cena {
  Cena({required this.nome, this.fisica = Fisica.plataforma, this.largura = 16, this.altura = 12, this.corFundo = 0xFF4DD0FF, List<ObjetoCena>? objetos, this.inicial = false, this.px = -1, this.py = -1}) : objetos = objetos ?? [];
  String nome;
  Fisica fisica;
  int largura;
  int altura;
  int corFundo; // ARGB
  bool inicial;
  /// Posicao do cartao no tabuleiro de cenas (negativo = ainda nao posicionado).
  double px;
  double py;
  /// Objetos do mapa (origem embaixo-esquerda, como no editor de PC).
  final List<ObjetoCena> objetos;
  int _proxId = 1;
  int novoId() => _proxId++;

  Map<String, dynamic> toJson() => {'nome': nome, 'fisica': fisica.name, 'l': largura, 'a': altura, 'cor': corFundo, 'ini': inicial, 'px': px, 'py': py, 'objs': [for (final o in objetos) o.toJson()]};

  static Cena fromJson(Map<String, dynamic> j) {
    final c = Cena(
      nome: (j['nome'] as String?) ?? 'Cena',
      fisica: (j['fisica'] == 'rpg') ? Fisica.rpg : Fisica.plataforma,
      largura: ((j['l'] as num?) ?? 16).toInt().clamp(mapaMin, mapaMax),
      altura: ((j['a'] as num?) ?? 12).toInt().clamp(mapaMin, mapaMax),
      corFundo: ((j['cor'] as num?) ?? 0xFF4DD0FF).toInt(),
      inicial: (j['ini'] as bool?) ?? false,
      px: ((j['px'] as num?) ?? -1).toDouble(),
      py: ((j['py'] as num?) ?? -1).toDouble(),
    );
    for (final o in ((j['objs'] as List?) ?? const [])) {
      final ob = ObjetoCena.fromJson(Map<String, dynamic>.from(o as Map));
      c.objetos.add(ob);
      if (ob.id >= c._proxId) c._proxId = ob.id + 1;
    }
    // formato antigo: uma celula = um objeto ("x,y" -> valor, props por celula)
    final cel = (j['cel'] as Map?) ?? const {};
    final pr = (j['props'] as Map?) ?? const {};
    for (final e in cel.entries) {
      final p = (e.key as String).split(',');
      final extra = pr[e.key];
      c.objetos.add(ObjetoCena(id: c.novoId(), v: (e.value as num).toInt(), x: int.parse(p[0]), y: int.parse(p[1]), props: extra is Map ? Map<String, dynamic>.from(extra) : null));
    }
    return c;
  }

  Cena copia() {
    final c = Cena(nome: '$nome (cópia)', fisica: fisica, largura: largura, altura: altura, corFundo: corFundo, px: px + 30, py: py + 30);
    for (final o in objetos) {
      c.objetos.add(o.copia(c.novoId()));
    }
    return c;
  }
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
