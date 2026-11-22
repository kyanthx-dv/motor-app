import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';

/// Nucleo do editor de desenho (sem interface): camadas, pixels, formas, selecao e exportacao.
/// Cada camada guarda pixels ARGB (nao pre-multiplicados) em um Uint32List de largura x altura.

class ConfigDesenho {
  const ConfigDesenho({required this.nome, required this.largura, required this.altura, this.fundo});
  final String nome;
  final int largura;
  final int altura;
  final int? fundo; // ARGB; null = transparente
}

class Camada {
  Camada(this.nome, int n)
      : px = Uint32List(n),
        visivel = true,
        bloqueada = false,
        opac = 1;
  Camada._(this.nome, this.px, this.visivel, this.bloqueada, this.opac);

  String nome;
  Uint32List px;
  bool visivel;
  bool bloqueada;
  double opac;

  Camada copia() => Camada._(nome, Uint32List.fromList(px), visivel, bloqueada, opac);
}

class Foto {
  Foto(this.camadas, this.atual);
  final List<Camada> camadas;
  final int atual;
}

/// Pixels copiados (area selecionada), relativos ao canto superior esquerdo.
class AreaCopiada {
  AreaCopiada(this.largura, this.altura, this.pontos);
  final int largura;
  final int altura;
  final List<(int, int, int)> pontos; // dx, dy, cor
}

/// Todas as camadas + historico (desfazer/refazer) + selecao.
class Documento {
  Documento(this.config) : l = config.largura, a = config.altura {
    final fundo = Camada('Fundo', l * a);
    if (config.fundo != null) fundo.px.fillRange(0, fundo.px.length, config.fundo!);
    camadas = [fundo, Camada('Camada 1', l * a)];
    atual = 1;
  }

  static const int maxHistorico = 40;

  final ConfigDesenho config;
  final int l;
  final int a;
  late List<Camada> camadas;
  int atual = 0;
  Uint8List? sel; // mascara 0/1 (null = sem selecao)
  AreaCopiada? area;
  final List<Foto> _desfazer = [];
  final List<Foto> _refazer = [];

  Camada get cam => camadas[atual];
  bool get podeDesfazer => _desfazer.isNotEmpty;
  bool get podeRefazer => _refazer.isNotEmpty;

  Foto _foto() => Foto([for (final c in camadas) c.copia()], atual);

  /// Guarda o estado ANTES de uma mudanca.
  void guardar() {
    _desfazer.add(_foto());
    if (_desfazer.length > maxHistorico) _desfazer.removeAt(0);
    _refazer.clear();
  }

  /// Cancela o ultimo [guardar] sem mudar nada (traco abortado).
  void descartarUltimo() {
    if (_desfazer.isNotEmpty) _desfazer.removeLast();
  }

  void desfazer() {
    if (_desfazer.isEmpty) return;
    _refazer.add(_foto());
    final f = _desfazer.removeLast();
    camadas = f.camadas;
    atual = f.atual.clamp(0, camadas.length - 1);
  }

  void refazer() {
    if (_refazer.isEmpty) return;
    _desfazer.add(_foto());
    final f = _refazer.removeLast();
    camadas = f.camadas;
    atual = f.atual.clamp(0, camadas.length - 1);
  }

  // ------------------------------------------------------------ camadas
  void novaCamada() {
    guardar();
    camadas.insert(atual + 1, Camada('Camada ${_proximoNumero()}', l * a));
    atual++;
  }

  int _proximoNumero() {
    var n = camadas.length;
    while (camadas.any((c) => c.nome == 'Camada $n')) {
      n++;
    }
    return n;
  }

  void duplicar() {
    guardar();
    final c = cam.copia()..nome = '${cam.nome} (cópia)';
    camadas.insert(atual + 1, c);
    atual++;
  }

  bool apagarCamada() {
    if (camadas.length <= 1) return false;
    guardar();
    camadas.removeAt(atual);
    atual = atual.clamp(0, camadas.length - 1);
    return true;
  }

  void mover(int delta) {
    final n = atual + delta;
    if (n < 0 || n >= camadas.length) return;
    guardar();
    final c = camadas.removeAt(atual);
    camadas.insert(n, c);
    atual = n;
  }

  /// Junta a camada atual com a de baixo.
  bool juntarAbaixo() {
    if (atual == 0) return false;
    guardar();
    final topo = camadas[atual], base = camadas[atual - 1];
    for (var i = 0; i < base.px.length; i++) {
      base.px[i] = _sobre(base.px[i], topo.px[i], topo.visivel ? topo.opac : 0);
    }
    camadas.removeAt(atual);
    atual--;
    return true;
  }

  void limparCamada() {
    guardar();
    final m = sel;
    if (m == null) {
      cam.px.fillRange(0, cam.px.length, 0);
    } else {
      for (var i = 0; i < m.length; i++) {
        if (m[i] != 0) cam.px[i] = 0;
      }
    }
  }

  static int _sobre(int base, int topo, double opac) {
    final ta = (((topo >>> 24) & 255) * opac) / 255.0;
    if (ta <= 0) return base;
    final ba = ((base >>> 24) & 255) / 255.0;
    final oa = ta + ba * (1 - ta);
    if (oa <= 0) return 0;
    int canal(int s) {
      final t = (topo >>> s) & 255, b = (base >>> s) & 255;
      return ((t * ta + b * ba * (1 - ta)) / oa).round().clamp(0, 255);
    }

    return ((oa * 255).round().clamp(0, 255) << 24) | (canal(16) << 16) | (canal(8) << 8) | canal(0);
  }

  // ------------------------------------------------------------ pixels
  bool dentro(int x, int y) => x >= 0 && y >= 0 && x < l && y < a;

  bool podeEditar() => !cam.bloqueada && cam.visivel;

  /// Escreve um pixel (respeita selecao). [espelhoX]/[espelhoY] repetem o pixel simetricamente.
  void ponto(int x, int y, int cor, {bool espelhoX = false, bool espelhoY = false}) {
    void um(int px, int py) {
      if (!dentro(px, py)) return;
      final i = py * l + px;
      final m = sel;
      if (m != null && m[i] == 0) return;
      cam.px[i] = cor;
    }

    um(x, y);
    if (espelhoX) um(l - 1 - x, y);
    if (espelhoY) um(x, a - 1 - y);
    if (espelhoX && espelhoY) um(l - 1 - x, a - 1 - y);
  }

  /// Cor visivel no ponto (de cima para baixo), para o conta-gotas.
  int corVisivel(int x, int y) {
    if (!dentro(x, y)) return 0;
    var r = 0;
    for (final c in camadas) {
      if (c.visivel) r = _sobre(r, c.px[y * l + x], c.opac);
    }
    return r;
  }

  /// Pontos de uma linha (Bresenham).
  static List<(int, int)> linha(int x0, int y0, int x1, int y1) {
    final r = <(int, int)>[];
    var x = x0, y = y0;
    final dx = (x1 - x0).abs(), dy = -(y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1;
    var err = dx + dy;
    while (true) {
      r.add((x, y));
      if (x == x1 && y == y1) break;
      final e2 = 2 * err;
      if (e2 >= dy) {
        err += dy;
        x += sx;
      }
      if (e2 <= dx) {
        err += dx;
        y += sy;
      }
    }
    return r;
  }

  static List<(int, int)> contornoRetangulo(int x0, int y0, int x1, int y1) {
    final xa = math.min(x0, x1), xb = math.max(x0, x1), ya = math.min(y0, y1), yb = math.max(y0, y1);
    final r = <(int, int)>[];
    for (var x = xa; x <= xb; x++) {
      r.add((x, ya));
      if (yb != ya) r.add((x, yb));
    }
    for (var y = ya + 1; y < yb; y++) {
      r.add((xa, y));
      if (xb != xa) r.add((xb, y));
    }
    return r;
  }

  static List<(int, int)> preenchimentoRetangulo(int x0, int y0, int x1, int y1) {
    final r = <(int, int)>[];
    for (var y = math.min(y0, y1); y <= math.max(y0, y1); y++) {
      for (var x = math.min(x0, x1); x <= math.max(x0, x1); x++) {
        r.add((x, y));
      }
    }
    return r;
  }

  /// Elipse inscrita no retangulo (x0,y0)-(x1,y1). [cheia] false = so o contorno.
  static List<(int, int)> elipse(int x0, int y0, int x1, int y1, bool cheia) {
    final xa = math.min(x0, x1), xb = math.max(x0, x1), ya = math.min(y0, y1), yb = math.max(y0, y1);
    final cx = (xa + xb) / 2, cy = (ya + yb) / 2;
    final rx = (xb - xa + 1) / 2, ry = (yb - ya + 1) / 2;
    bool em(double x, double y, double rxx, double ryy) {
      if (rxx <= 0 || ryy <= 0) return false;
      final u = (x - cx) / rxx, v = (y - cy) / ryy;
      return u * u + v * v <= 1;
    }

    final r = <(int, int)>[];
    for (var y = ya; y <= yb; y++) {
      for (var x = xa; x <= xb; x++) {
        if (!em(x.toDouble(), y.toDouble(), rx, ry)) continue;
        if (cheia || !em(x.toDouble(), y.toDouble(), rx - 1, ry - 1)) r.add((x, y));
      }
    }
    return r;
  }

  /// Balde de tinta: preenche a regiao contigua da mesma cor na camada atual.
  void balde(int x, int y, int cor) {
    if (!dentro(x, y)) return;
    final px = cam.px, alvo = px[y * l + x];
    if (alvo == cor) return;
    final m = sel;
    if (m != null && m[y * l + x] == 0) return;
    final pilha = <int>[y * l + x];
    while (pilha.isNotEmpty) {
      final i = pilha.removeLast();
      if (px[i] != alvo) continue;
      if (m != null && m[i] == 0) continue;
      px[i] = cor;
      final cx = i % l, cy = i ~/ l;
      if (cx > 0) pilha.add(i - 1);
      if (cx < l - 1) pilha.add(i + 1);
      if (cy > 0) pilha.add(i - l);
      if (cy < a - 1) pilha.add(i + l);
    }
  }

  // ------------------------------------------------------------ selecao
  void selecionarRetangulo(int x0, int y0, int x1, int y1) {
    final m = Uint8List(l * a);
    for (var y = math.max(0, math.min(y0, y1)); y <= math.min(a - 1, math.max(y0, y1)); y++) {
      for (var x = math.max(0, math.min(x0, x1)); x <= math.min(l - 1, math.max(x0, x1)); x++) {
        m[y * l + x] = 1;
      }
    }
    sel = m;
  }

  /// Varinha magica: seleciona a regiao contigua de mesma cor.
  void varinha(int x, int y) {
    if (!dentro(x, y)) return;
    final px = cam.px, alvo = px[y * l + x], m = Uint8List(l * a);
    final pilha = <int>[y * l + x];
    while (pilha.isNotEmpty) {
      final i = pilha.removeLast();
      if (m[i] != 0 || px[i] != alvo) continue;
      m[i] = 1;
      final cx = i % l, cy = i ~/ l;
      if (cx > 0) pilha.add(i - 1);
      if (cx < l - 1) pilha.add(i + 1);
      if (cy > 0) pilha.add(i - l);
      if (cy < a - 1) pilha.add(i + l);
    }
    sel = m;
  }

  void selecionarTudo() => sel = Uint8List(l * a)..fillRange(0, l * a, 1);

  void inverterSelecao() {
    final m = sel;
    if (m == null) return selecionarTudo();
    final n = Uint8List(l * a);
    for (var i = 0; i < n.length; i++) {
      n[i] = m[i] == 0 ? 1 : 0;
    }
    sel = n;
  }

  void desmarcar() => sel = null;

  bool get temSelecao => sel != null && sel!.any((v) => v != 0);

  void apagarSelecao() {
    final m = sel;
    if (m == null) return;
    guardar();
    for (var i = 0; i < m.length; i++) {
      if (m[i] != 0) cam.px[i] = 0;
    }
  }

  void copiar() {
    final m = sel;
    if (m == null) return;
    var x0 = l, y0 = a, x1 = -1, y1 = -1;
    for (var i = 0; i < m.length; i++) {
      if (m[i] == 0) continue;
      final x = i % l, y = i ~/ l;
      x0 = math.min(x0, x);
      y0 = math.min(y0, y);
      x1 = math.max(x1, x);
      y1 = math.max(y1, y);
    }
    if (x1 < 0) return;
    final pts = <(int, int, int)>[];
    for (var i = 0; i < m.length; i++) {
      if (m[i] != 0 && cam.px[i] != 0) pts.add((i % l - x0, i ~/ l - y0, cam.px[i]));
    }
    area = AreaCopiada(x1 - x0 + 1, y1 - y0 + 1, pts);
  }

  /// Cola a area copiada no canto superior esquerdo (x,y) e seleciona o que foi colado.
  bool colar(int x, int y) {
    final ar = area;
    if (ar == null) return false;
    guardar();
    final m = Uint8List(l * a);
    for (final (dx, dy, cor) in ar.pontos) {
      final px = x + dx, py = y + dy;
      if (!dentro(px, py)) continue;
      cam.px[py * l + px] = cor;
      m[py * l + px] = 1;
    }
    sel = m;
    return true;
  }

  /// Levanta os pixels selecionados para mover. Devolve o "molde" (camada sem eles) e a lista levantada.
  ({Uint32List base, List<(int, int)> levantado, Uint8List selOriginal}) levantar() {
    final m = sel!;
    final base = Uint32List.fromList(cam.px);
    final lev = <(int, int)>[];
    for (var i = 0; i < m.length; i++) {
      if (m[i] != 0) {
        lev.add((i, cam.px[i]));
        base[i] = 0;
      }
    }
    return (base: base, levantado: lev, selOriginal: Uint8List.fromList(m));
  }

  void posicionar(({Uint32List base, List<(int, int)> levantado, Uint8List selOriginal}) lv, int dx, int dy) {
    final px = Uint32List.fromList(lv.base);
    final m = Uint8List(l * a);
    for (final (i, cor) in lv.levantado) {
      final x = i % l + dx, y = i ~/ l + dy;
      if (!dentro(x, y)) continue;
      final n = y * l + x;
      px[n] = cor;
      m[n] = 1;
    }
    cam.px = px;
    sel = m;
  }

  // ------------------------------------------------------------ composicao e exportacao
  /// RGBA pre-multiplicado (formato do Flutter) com todas as camadas visiveis.
  Uint8List compor() {
    final n = l * a;
    final out = Uint8List(n * 4);
    for (var i = 0; i < n; i++) {
      var r = 0.0, g = 0.0, b = 0.0, al = 0.0; // pre-multiplicados, 0..1
      for (final c in camadas) {
        if (!c.visivel) continue;
        final p = c.px[i];
        final sa = (((p >>> 24) & 255) / 255.0) * c.opac;
        if (sa <= 0) continue;
        final sr = ((p >>> 16) & 255) / 255.0, sg = ((p >>> 8) & 255) / 255.0, sb = (p & 255) / 255.0;
        r = sr * sa + r * (1 - sa);
        g = sg * sa + g * (1 - sa);
        b = sb * sa + b * (1 - sa);
        al = sa + al * (1 - sa);
      }
      out[i * 4] = (r * 255).round();
      out[i * 4 + 1] = (g * 255).round();
      out[i * 4 + 2] = (b * 255).round();
      out[i * 4 + 3] = (al * 255).round();
    }
    return out;
  }

  Future<ui.Image> imagem() {
    final c = Completer<ui.Image>();
    ui.decodeImageFromPixels(compor(), l, a, ui.PixelFormat.rgba8888, c.complete);
    return c.future;
  }

  Future<Uint8List> png() async {
    final img = await imagem();
    final d = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    if (d == null) throw StateError('Falha ao gerar o PNG');
    return d.buffer.asUint8List();
  }

  /// Salva o PNG na pasta do app (desenhos/<nome>.png). Devolve o arquivo.
  Future<File> salvarPng() async {
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/desenhos');
    if (!await dir.exists()) await dir.create(recursive: true);
    final seguro = config.nome.replaceAll(RegExp(r'[^A-Za-z0-9_\-À-ÿ ]'), '_').trim();
    final f = File('${dir.path}/${seguro.isEmpty ? 'desenho' : seguro}.png');
    await f.writeAsBytes(await png());
    return f;
  }
}
