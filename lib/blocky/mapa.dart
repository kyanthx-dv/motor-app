import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'icones.dart';
import 'cena_config.dart';
import 'projetos.dart';
import 'widgets.dart';

enum Arte { grama, terra, pedra, agua, areia, icone }

/// Item da paleta de exemplo (depois vira o catalogo real de assets da engine).
class ItemPaleta {
  const ItemPaleta(this.nome, this.aba, this.arte, this.cor, [this.icone = Ic.ponto]);
  final String nome;
  final String aba; // Tile | Deco | Ator | Objeto
  final Arte arte;
  final Color cor;
  final IconData icone;
}

const paleta = <ItemPaleta>[
  ItemPaleta('Grama', 'Tile', Arte.grama, Color(0xFF5DBB2F)),
  ItemPaleta('Terra', 'Tile', Arte.terra, Color(0xFFB4713A)),
  ItemPaleta('Pedra', 'Tile', Arte.pedra, Color(0xFF9AA5B1)),
  ItemPaleta('Água', 'Tile', Arte.agua, Color(0xFF3BA7F0)),
  ItemPaleta('Areia', 'Tile', Arte.areia, Color(0xFFF2D58A)),
  ItemPaleta('Árvore', 'Deco', Arte.icone, Color(0xFF2E9E4F), Ic.arvore),
  ItemPaleta('Flor', 'Deco', Arte.icone, Color(0xFFEC4899), Ic.flor),
  ItemPaleta('Nuvem', 'Deco', Arte.icone, Color(0xFF94A3B8), Ic.nuvem),
  ItemPaleta('Herói', 'Ator', Arte.icone, Color(0xFFF59E0B), Ic.rosto),
  ItemPaleta('Slime', 'Ator', Arte.icone, Color(0xFF22D3EE), Ic.inseto),
  ItemPaleta('Fantasma', 'Ator', Arte.icone, Color(0xFFA78BFA), Ic.fantasma),
  ItemPaleta('Baú', 'Objeto', Arte.icone, Color(0xFFB45309), Ic.pacote),
  ItemPaleta('Moeda', 'Objeto', Arte.icone, Color(0xFFFBBF24), Ic.moeda),
  ItemPaleta('Bandeira', 'Objeto', Arte.icone, Color(0xFFEF4444), Ic.bandeira),
];

const _abas = ['Tile', 'Deco', 'Ator', 'Objeto'];

/// Desenha um item dentro de [r]. Tiles sao desenhados por codigo (sem arquivo de imagem), encaixam sem frestas.
void pintarItem(Canvas c, Rect r, ItemPaleta it) {
  final u = r.width / 10; // unidade de 1/10 da celula
  switch (it.arte) {
    case Arte.terra:
    case Arte.grama:
      c.drawRect(r, Paint()..color = const Color(0xFFB4713A));
      final manchas = Paint()..color = const Color(0xFF8E5528);
      for (final p in const [Offset(2, 5), Offset(6, 4), Offset(4, 8), Offset(8, 7), Offset(1, 9), Offset(7, 9.2)]) {
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + p.dx * u, r.top + p.dy * u, 1.4 * u, 0.8 * u), Radius.circular(u * 0.3)), manchas);
      }
      if (it.arte == Arte.grama) {
        c.drawRect(Rect.fromLTWH(r.left, r.top, r.width, 2.6 * u), Paint()..color = const Color(0xFF5DBB2F));
        final p = Paint()..color = const Color(0xFF5DBB2F);
        for (var i = 0; i < 5; i++) {
          c.drawCircle(Offset(r.left + (i * 2 + 1) * u, r.top + 2.6 * u), 1 * u, p);
        }
        c.drawRect(Rect.fromLTWH(r.left, r.top, r.width, 0.7 * u), Paint()..color = const Color(0xFF86D94F));
      }
    case Arte.pedra:
      c.drawRect(r, Paint()..color = it.cor);
      final l = Paint()
        ..color = const Color(0xFF6B7684)
        ..strokeWidth = u * 0.35;
      c.drawLine(Offset(r.left, r.top + 5 * u), Offset(r.right, r.top + 5 * u), l);
      c.drawLine(Offset(r.left + 5 * u, r.top), Offset(r.left + 5 * u, r.top + 5 * u), l);
      c.drawLine(Offset(r.left + 2.5 * u, r.top + 5 * u), Offset(r.left + 2.5 * u, r.bottom), l);
      c.drawLine(Offset(r.left + 7.5 * u, r.top + 5 * u), Offset(r.left + 7.5 * u, r.bottom), l);
    case Arte.agua:
      c.drawRect(r, Paint()..color = it.cor);
      final w = Paint()
        ..color = Colors.white.withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.5
        ..strokeCap = StrokeCap.round;
      for (final y in const [3.0, 7.0]) {
        final path = Path()
          ..moveTo(r.left + 1 * u, r.top + y * u)
          ..quadraticBezierTo(r.left + 3 * u, r.top + (y - 1.2) * u, r.left + 5 * u, r.top + y * u)
          ..quadraticBezierTo(r.left + 7 * u, r.top + (y + 1.2) * u, r.left + 9 * u, r.top + y * u);
        c.drawPath(path, w);
      }
    case Arte.areia:
      c.drawRect(r, Paint()..color = it.cor);
      final d = Paint()..color = const Color(0xFFD9B865);
      for (final p in const [Offset(2, 2), Offset(6, 3), Offset(4, 6), Offset(8, 7), Offset(2, 8)]) {
        c.drawCircle(Offset(r.left + p.dx * u, r.top + p.dy * u), 0.45 * u, d);
      }
    case Arte.icone:
      final centro = r.center;
      c.drawCircle(centro, r.width * 0.42, Paint()..color = it.cor);
      c.drawCircle(centro, r.width * 0.42, Paint()
        ..color = Colors.black.withAlpha(90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.35);
      final tp = TextPainter(
        text: TextSpan(text: String.fromCharCode(it.icone.codePoint), style: TextStyle(fontFamily: it.icone.fontFamily, package: it.icone.fontPackage, fontSize: r.width * 0.55, color: Colors.white)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, centro - Offset(tp.width / 2, tp.height / 2));
  }
}

class _Miniatura extends CustomPainter {
  _Miniatura(this.it);
  final ItemPaleta it;
  @override
  void paint(Canvas canvas, Size size) {
    final l = math.min(size.width, size.height);
    final r = Rect.fromCenter(center: size.center(Offset.zero), width: l, height: l);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)));
    pintarItem(canvas, r, it);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Miniatura old) => old.it != it;
}

class CenaTela extends StatefulWidget {
  const CenaTela({super.key, required this.projeto, required this.cena});
  final Projeto projeto;
  final Cena cena;

  @override
  State<CenaTela> createState() => _CenaTelaState();
}

class _CenaTelaState extends State<CenaTela> {
  static const double _cs = 40; // celula em unidades do mundo

  final _versao = ValueNotifier<int>(0);
  bool _apagar = false;
  // toque = selecionar; segurar = comecar a pintar/apagar; 1 dedo arrastando = mover o mapa
  Timer? _seg;
  bool _pintando = false;
  bool _mexeu = false;
  Offset _ini = Offset.zero;
  int? _selX;
  int? _selY;
  int _aba = 0;
  int _sel = 0;
  double _altPainel = 210; // altura do painel (puxavel)
  static const _alturas = [52.0, 210.0, 400.0];
  int? _ultimo;

  // desfazer / refazer: cada traco guarda o valor anterior das celulas tocadas
  final _desfazer = <Map<String, int?>>[];
  final _refazer = <Map<String, int?>>[];
  Map<String, int?> _traco = {};

  // camera (zoom + deslocamento), controlada a mao: 1 dedo pinta, 2 dedos movem/zoom
  double _esc = 1;
  Offset _desl = Offset.zero;
  bool _ajustou = false;
  double _escIni = 1;
  Offset _focoIni = Offset.zero;
  Offset _deslIni = Offset.zero;
  int _cont = 0;

  Cena get c => widget.cena;

  @override
  void dispose() {
    _seg?.cancel();
    _versao.dispose();
    RepositorioProjetos.instancia.salvar();
    super.dispose();
  }

  void _ajustar(Size s) {
    final mw = c.largura * _cs, mh = c.altura * _cs;
    _esc = math.min((s.width - 96) / mw, (s.height - 130) / mh).clamp(0.3, 1.6);
    _desl = Offset((s.width - mw * _esc) / 2 + 30, (s.height - mh * _esc) / 2 + 10);
    _ajustou = true;
  }

  void _pintarEm(Offset p) {
    final w = (p - _desl) / _esc;
    final x = (w.dx / _cs).floor();
    final y = c.altura - 1 - (w.dy / _cs).floor();
    if (w.dx < 0 || w.dy < 0 || x >= c.largura || y < 0 || y >= c.altura) return; // limite do mapa
    final chave = x * 100000 + y;
    if (chave == _ultimo) return;
    _ultimo = chave;
    final k = '$x,$y';
    final antes = c.celulas[k];
    final depois = _apagar ? null : _sel;
    if (antes == depois) return;
    _traco.putIfAbsent(k, () => antes);
    if (depois == null) {
      c.celulas.remove(k);
    } else {
      c.celulas[k] = depois;
    }
    _versao.value++;
  }

  /// Aplica um conjunto de valores e devolve o inverso.
  Map<String, int?> _aplicar(Map<String, int?> m) {
    final inv = <String, int?>{};
    m.forEach((k, v) {
      inv[k] = c.celulas[k];
      if (v == null) {
        c.celulas.remove(k);
      } else {
        c.celulas[k] = v;
      }
    });
    _versao.value++;
    return inv;
  }

  void _undo() {
    if (_desfazer.isEmpty) return;
    _refazer.add(_aplicar(_desfazer.removeLast()));
    setState(() {});
    RepositorioProjetos.instancia.salvar();
  }

  void _redo() {
    if (_refazer.isEmpty) return;
    _desfazer.add(_aplicar(_refazer.removeLast()));
    setState(() {});
    RepositorioProjetos.instancia.salvar();
  }

  (int, int)? _celulaEm(Offset p) {
    final w = (p - _desl) / _esc;
    final x = (w.dx / _cs).floor();
    final y = c.altura - 1 - (w.dy / _cs).floor();
    if (w.dx < 0 || w.dy < 0 || x >= c.largura || y < 0 || y >= c.altura) return null;
    return (x, y);
  }

  void _terminou(ScaleEndDetails _) {
    _seg?.cancel();
    if (_pintando && _traco.isNotEmpty) {
      _desfazer.add(_traco);
      if (_desfazer.length > 100) _desfazer.removeAt(0);
      _refazer.clear();
      _traco = {};
      RepositorioProjetos.instancia.salvar(); // salva sozinho a cada traco
    } else if (!_pintando && !_mexeu) {
      final cel = _celulaEm(_ini); // toque curto: seleciona a celula (ou limpa a selecao)
      _selX = cel?.$1;
      _selY = cel?.$2;
      _versao.value++;
    }
    _pintando = false;
    setState(() {});
  }

  void _comecou(ScaleStartDetails d) {
    _cont = d.pointerCount;
    _rebase(d.localFocalPoint);
    _ultimo = null;
    _pintando = false;
    _mexeu = d.pointerCount > 1;
    _ini = d.localFocalPoint;
    _seg?.cancel();
    if (d.pointerCount == 1) {
      _seg = Timer(const Duration(milliseconds: 380), () {
        if (_mexeu) return;
        _pintando = true; // segurou parado: comeca a pintar (ou apagar)
        HapticFeedback.selectionClick();
        _selX = null;
        _selY = null;
        _pintarEm(_ini);
        setState(() {});
      });
    }
  }

  void _rebase(Offset foco) {
    _escIni = _esc;
    _focoIni = foco;
    _deslIni = _desl;
  }

  void _moveu(ScaleUpdateDetails d) {
    if (d.pointerCount != _cont) {
      _cont = d.pointerCount;
      _rebase(d.localFocalPoint);
      if (d.pointerCount > 1) {
        _mexeu = true;
        _seg?.cancel();
      }
      return;
    }
    if (_pintando && d.pointerCount == 1) {
      _pintarEm(d.localFocalPoint);
      return;
    }
    if (!_mexeu && (d.localFocalPoint - _ini).distance > 10) {
      _mexeu = true; // arrastou antes de segurar: e mover o mapa
      _seg?.cancel();
      _rebase(d.localFocalPoint);
    }
    if (!_mexeu) return;
    final nova = (_escIni * (d.pointerCount >= 2 ? d.scale : 1)).clamp(0.3, 3.0);
    final mundo = (_focoIni - _deslIni) / _escIni; // ponto do mapa sob o foco inicial
    _esc = nova;
    _desl = d.localFocalPoint - mundo * nova;
    _versao.value++;
  }

  Widget _ferramenta(IconData i, bool ativo, VoidCallback f) => Toque(
        aoTocar: f,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: ativo ? azulEditor : Cores.cartao.withAlpha(235), borderRadius: BorderRadius.circular(14)),
          child: Icon(i, size: 22, color: ativo ? Colors.white : Cores.texto2),
        ),
      );

  Widget _barra(IconData i, VoidCallback? f) => Toque(
        aoTocar: f ?? () {},
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: Cores.cartao.withAlpha(235), borderRadius: BorderRadius.circular(21)),
          child: Icon(i, size: 21, color: f == null ? Cores.texto2.withAlpha(90) : null),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final itens = [for (var i = 0; i < paleta.length; i++) if (paleta[i].aba == _abas[_aba]) i];
    final grande = _altPainel > 300;
    Widget celula(int i) => Toque(
          aoTocar: () => setState(() {
            _sel = i;
            _apagar = false;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: Cores.cartao2, borderRadius: BorderRadius.circular(12), border: Border.all(color: _sel == i && !_apagar ? azulEditor : Colors.transparent, width: 2.5)),
            child: CustomPaint(painter: _Miniatura(paleta[i])),
          ),
        );
    return Scaffold(
      backgroundColor: Cores.fundo,
      body: Column(children: [
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            if (!_ajustou) _ajustar(box.biggest);
            return ClipRect(
              child: Stack(children: [
                Positioned.fill(
                  child: GestureDetector(
                    onScaleStart: _comecou,
                    onScaleUpdate: _moveu,
                    onScaleEnd: _terminou,
                    child: CustomPaint(painter: _CenaPainter(this, _versao)),
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: _versao,
                  builder: (_, __, ___) {
                    final sx = _selX, sy = _selY;
                    if (sx == null || sy == null) return const SizedBox.shrink();
                    final cx = _desl.dx + (sx + 0.5) * _cs * _esc;
                    final topo = _desl.dy + (c.altura - sy - 1) * _cs * _esc;
                    final tem = c.celulas.containsKey('$sx,$sy');
                    Widget b(IconData i, VoidCallback f) => Toque(
                          aoTocar: f,
                          child: Container(width: 38, height: 38, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: Cores.cartao, shape: BoxShape.circle), child: Icon(i, size: 19)),
                        );
                    void aplicar(int? v) {
                      final k = '$sx,$sy', antes = c.celulas[k];
                      if (antes == v) return;
                      _desfazer.add({k: antes});
                      _refazer.clear();
                      if (v == null) {
                        c.celulas.remove(k);
                      } else {
                        c.celulas[k] = v;
                      }
                      RepositorioProjetos.instancia.salvar();
                      setState(() {});
                      _versao.value++;
                    }
                    return Positioned(
                      left: (cx - 50).clamp(4.0, box.maxWidth - 104),
                      top: (topo - 46).clamp(60.0, box.maxHeight - 50),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        b(Ic.mais, () => aplicar(_sel)),
                        if (tem) b(Ic.lixeira, () => aplicar(null)),
                        b(Ic.fechar, () {
                          _selX = null;
                          _selY = null;
                          _versao.value++;
                        }),
                      ]),
                    );
                  },
                ),
                SafeArea(
                  child: Stack(children: [
                    // barra superior enxuta: voltar | nome da cena (toque = configurar) | desfazer, refazer, rodar
                    Positioned(
                      left: 10,
                      right: 10,
                      top: 6,
                      child: Row(children: [
                        _barra(Ic.voltar, () => Navigator.pop(context)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Toque(
                            aoTocar: () async {
                              await abrirConfigCena(context, c);
                              _ajustou = false;
                              if (mounted) setState(() {});
                            },
                            child: Container(
                              height: 42,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(color: Cores.cartao.withAlpha(235), borderRadius: BorderRadius.circular(21)),
                              child: Row(children: [
                                Expanded(child: Text('${c.nome}  ·  ${c.largura}×${c.altura}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                Icon(Ic.engrenagem, size: 17, color: Cores.texto2),
                              ]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _barra(Ic.desfazer, _desfazer.isEmpty ? null : _undo),
                        const SizedBox(width: 6),
                        _barra(Ic.refazer, _refazer.isEmpty ? null : _redo),
                        const SizedBox(width: 6),
                        Toque(
                          aoTocar: () => emBreve(context, 'Executar (engine)'),
                          child: Container(width: 42, height: 42, decoration: const BoxDecoration(color: azulEditor, shape: BoxShape.circle), child: const Icon(Ic.play, size: 20, color: Colors.white)),
                        ),
                      ]),
                    ),
                    // ferramentas
                    Positioned(
                      left: 10,
                      top: 64,
                      child: Column(children: [
                        _ferramenta(Ic.mao, !_apagar, () => setState(() => _apagar = false)),
                        const SizedBox(height: 8),
                        _ferramenta(Ic.borracha, _apagar, () => setState(() => _apagar = true)),
                        const SizedBox(height: 8),
                        _ferramenta(Ic.centralizar, false, () {
                          _ajustou = false;
                          setState(() {});
                        }),
                      ]),
                    ),
                  ]),
                ),
              ]),
            );
          }),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          height: _altPainel,
          decoration: BoxDecoration(color: Cores.cartao, borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
          child: ClipRect(
            child: Column(children: [
              // puxe a alca; ao soltar encaixa em recolhido / faixa / grade
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (d) => setState(() => _altPainel = (_altPainel - d.delta.dy).clamp(_alturas.first, _alturas.last)),
                onVerticalDragEnd: (_) => setState(() => _altPainel = _alturas.reduce((x, y) => (x - _altPainel).abs() < (y - _altPainel).abs() ? x : y)),
                onTap: () => setState(() => _altPainel = _altPainel > 100 ? _alturas.first : _alturas[1]),
                child: SizedBox(
                  height: 52,
                  child: Row(children: [
                    const SizedBox(width: 14),
                    SizedBox(width: 30, height: 30, child: CustomPaint(painter: _Miniatura(paleta[_sel]))),
                    const SizedBox(width: 10),
                    Text(paleta[_sel].nome, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Container(width: 36, height: 4, decoration: BoxDecoration(color: Cores.texto2.withAlpha(120), borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 50),
                    const Spacer(),
                    Icon(_altPainel > 100 ? Ic.baixo : Ic.cima, size: 20, color: Cores.texto2),
                    const SizedBox(width: 16),
                  ]),
                ),
              ),
              if (_altPainel > 100) ...[
                SizedBox(
                  height: 34,
                  child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
                    for (var i = 0; i < _abas.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Toque(
                          aoTocar: () => setState(() => _aba = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: _aba == i ? azulEditor : Cores.cartao2, borderRadius: BorderRadius.circular(17)),
                            child: Text(_abas[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _aba == i ? Colors.white : Cores.texto2)),
                          ),
                        ),
                      ),
                  ]),
                ),
                Expanded(
                  child: grande
                      ? GridView.count(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          crossAxisCount: 6,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          children: [for (final i in itens) celula(i)],
                        )
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          children: [for (final i in itens) Padding(padding: const EdgeInsets.only(right: 8), child: AspectRatio(aspectRatio: 1, child: celula(i)))],
                        ),
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

class _CenaPainter extends CustomPainter {
  _CenaPainter(this.s, Listenable repaint) : super(repaint: repaint);
  final _CenaTelaState s;

  @override
  void paint(Canvas canvas, Size size) {
    final c = s.c;
    const cs = _CenaTelaState._cs;
    canvas.drawRect(Offset.zero & size, Paint()..color = Cores.fundo); // fora do mapa: neutro, no tema do app
    canvas.save();
    canvas.translate(s._desl.dx, s._desl.dy);
    canvas.scale(s._esc);
    final area = Rect.fromLTWH(0, 0, c.largura * cs, c.altura * cs);
    canvas.drawRRect(RRect.fromRectAndRadius(area.inflate(2), const Radius.circular(6)), Paint()..color = Colors.white.withAlpha(30));
    canvas.drawRect(area, Paint()..color = Color(c.corFundo));
    // itens
    c.celulas.forEach((k, i) {
      if (i < 0 || i >= paleta.length) return;
      final p = k.split(',');
      final x = int.parse(p[0]), y = int.parse(p[1]);
      pintarItem(canvas, Rect.fromLTWH(x * cs, (c.altura - 1 - y) * cs, cs, cs), paleta[i]);
    });
    // grade fina (1 pixel de tela, qualquer zoom)
    final fina = Paint()
      ..color = Colors.black.withAlpha(55)
      ..strokeWidth = 1 / s._esc;
    for (var x = 0; x <= c.largura; x++) {
      canvas.drawLine(Offset(x * cs, 0), Offset(x * cs, area.height), fina);
    }
    for (var y = 0; y <= c.altura; y++) {
      canvas.drawLine(Offset(0, y * cs), Offset(area.width, y * cs), fina);
    }

    // numeros nos eixos (0 = canto inferior esquerdo)
    final st = TextStyle(color: Cores.texto2, fontSize: 11, fontWeight: FontWeight.w700);
    final passo = s._esc >= 0.75 ? 1 : 5; // zoom afastado: numera de 5 em 5 (leitura limpa)
    final numeros = s._esc >= 0.5; // bem longe: sem numeros
    for (var x = 0; numeros && x < c.largura; x += passo) {
      final tp = TextPainter(text: TextSpan(text: '$x', style: st), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x * cs + cs / 2 - tp.width / 2, area.height + 5));
    }
    for (var y = 0; numeros && y < c.altura; y += passo) {
      final tp = TextPainter(text: TextSpan(text: '$y', style: st), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(-6 - tp.width, (c.altura - 1 - y) * cs + cs / 2 - tp.height / 2));
    }
    if (s._selX != null && s._selY != null) {
      final r = Rect.fromLTWH(s._selX! * cs, (c.altura - 1 - s._selY!) * cs, cs, cs);
      canvas.drawRect(r, Paint()..color = azulEditor.withAlpha(50));
      canvas.drawRect(r, Paint()
        ..color = azulEditor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 / s._esc);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CenaPainter old) => true;
}
