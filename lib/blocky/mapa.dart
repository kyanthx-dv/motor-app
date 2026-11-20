import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'cena_config.dart';
import 'projetos.dart';
import 'widgets.dart';

enum Arte { grama, terra, pedra, agua, areia, icone }

/// Item da paleta de exemplo (depois vira o catalogo real de assets da engine).
class ItemPaleta {
  const ItemPaleta(this.nome, this.aba, this.arte, this.cor, [this.icone = Icons.circle]);
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
  ItemPaleta('Árvore', 'Deco', Arte.icone, Color(0xFF2E9E4F), Icons.park),
  ItemPaleta('Flor', 'Deco', Arte.icone, Color(0xFFEC4899), Icons.local_florist),
  ItemPaleta('Nuvem', 'Deco', Arte.icone, Color(0xFF94A3B8), Icons.cloud),
  ItemPaleta('Herói', 'Ator', Arte.icone, Color(0xFFF59E0B), Icons.face),
  ItemPaleta('Slime', 'Ator', Arte.icone, Color(0xFF22D3EE), Icons.bug_report),
  ItemPaleta('Fantasma', 'Ator', Arte.icone, Color(0xFFA78BFA), Icons.sentiment_very_dissatisfied),
  ItemPaleta('Baú', 'Objeto', Arte.icone, Color(0xFFB45309), Icons.inventory_2),
  ItemPaleta('Moeda', 'Objeto', Arte.icone, Color(0xFFFBBF24), Icons.monetization_on),
  ItemPaleta('Bandeira', 'Objeto', Arte.icone, Color(0xFFEF4444), Icons.flag),
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
  bool _mover = false;
  int _aba = 0;
  int _sel = 0;
  double _altPainel = 220; // altura do painel (puxavel)
  static const _alturas = [44.0, 220.0, 430.0];
  int? _ultimo;

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
    _versao.dispose();
    RepositorioProjetos.instancia.salvar();
    super.dispose();
  }

  void _ajustar(Size s) {
    final mw = c.largura * _cs, mh = c.altura * _cs;
    _esc = math.min((s.width - 70) / mw, (s.height - 90) / mh).clamp(0.3, 1.6);
    _desl = Offset((s.width - mw * _esc) / 2 + 8, (s.height - mh * _esc) / 2 - 8);
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
    if (_apagar) {
      c.celulas.remove('$x,$y');
    } else {
      c.celulas['$x,$y'] = _sel;
    }
    _versao.value++;
  }

  void _comecou(ScaleStartDetails d) {
    _cont = d.pointerCount;
    _rebase(d.localFocalPoint);
    _ultimo = null;
    if (d.pointerCount == 1 && !_mover) _pintarEm(d.localFocalPoint);
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
      return;
    }
    if (d.pointerCount >= 2 || _mover) {
      final nova = (_escIni * (d.pointerCount >= 2 ? d.scale : 1)).clamp(0.3, 3.0);
      final mundo = (_focoIni - _deslIni) / _escIni; // ponto do mapa sob o foco inicial
      _esc = nova;
      _desl = d.localFocalPoint - mundo * nova;
      _versao.value++;
    } else {
      _pintarEm(d.localFocalPoint);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itens = [for (var i = 0; i < paleta.length; i++) if (paleta[i].aba == _abas[_aba]) i];
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
                    child: CustomPaint(painter: _CenaPainter(this, _versao)),
                  ),
                ),
                SafeArea(
                  child: Stack(children: [
                    Positioned(left: 12, top: 8, child: BotaoGrosso(icone: Icons.arrow_back, cor: mentaEditor, aoTocar: () => Navigator.pop(context))),
                    Positioned(
                      right: 10,
                      top: 62,
                      child: Column(children: [
                        BotaoGrosso(icone: Icons.settings, rotulo: 'Config', cor: mentaEditor, largura: 56, aoTocar: () async {
                          await abrirConfigCena(context, c);
                          _ajustou = false;
                          if (mounted) setState(() {});
                        }),
                        const SizedBox(height: 8),
                        BotaoGrosso(icone: Icons.pin, rotulo: 'Dados', cor: mentaEditor, largura: 56, aoTocar: () => emBreve(context, 'Dados do jogo')),
                        const SizedBox(height: 8),
                        BotaoGrosso(icone: Icons.save, rotulo: 'Salvar', cor: mentaEditor, largura: 56, aoTocar: () {
                          RepositorioProjetos.instancia.salvar();
                          aviso(context, 'Salvo.');
                        }),
                        const SizedBox(height: 8),
                        BotaoGrosso(icone: Icons.play_arrow, rotulo: 'Rodar', cor: mentaEditor, largura: 56, aoTocar: () => emBreve(context, 'Executar (engine)')),
                      ]),
                    ),
                    Positioned(left: 12, bottom: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: mentaEditor, borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFF111111), width: 2)), child: Text('${c.nome} · ${c.largura}×${c.altura}', style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w800)))),
                    Positioned(
                      right: 12,
                      bottom: 10,
                      child: Row(children: [
                        BotaoGrosso(icone: Icons.open_with, cor: mentaEditor, ativo: _mover, aoTocar: () => setState(() => _mover = !_mover)),
                        const SizedBox(width: 8),
                        BotaoGrosso(icone: Icons.auto_fix_normal, cor: mentaEditor, ativo: _apagar, aoTocar: () => setState(() => _apagar = !_apagar)),
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
          decoration: const BoxDecoration(color: Color(0xFF1B1D22), borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
          child: ClipRect(
            child: Column(children: [
              // puxe a alca para cima/baixo; ao soltar, encaixa em fechado / medio / alto
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (d) => setState(() => _altPainel = (_altPainel - d.delta.dy).clamp(_alturas.first, _alturas.last)),
                onVerticalDragEnd: (_) => setState(() => _altPainel = _alturas.reduce((x, y) => (x - _altPainel).abs() < (y - _altPainel).abs() ? x : y)),
                onTap: () => setState(() => _altPainel = _altPainel > 100 ? _alturas.first : _alturas[1]),
                child: SizedBox(height: 44, child: Center(child: Container(width: 46, height: 5, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(3))))),
              ),
              SizedBox(
                height: 36,
                child: Row(children: [
                  for (var i = 0; i < _abas.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _aba = i),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(_abas[i], style: TextStyle(fontSize: 15, color: _aba == i ? Colors.white : Colors.white54, fontWeight: _aba == i ? FontWeight.w800 : FontWeight.w500)),
                          const SizedBox(height: 4),
                          AnimatedContainer(duration: const Duration(milliseconds: 200), height: 3, width: _aba == i ? 28 : 0, decoration: BoxDecoration(color: azulEditor, borderRadius: BorderRadius.circular(2))),
                        ]),
                      ),
                    ),
                ]),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (final i in itens)
                      Toque(
                        aoTocar: () => setState(() {
                          _sel = i;
                          _apagar = false;
                          _mover = false;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(color: const Color(0xFF2C2F37), borderRadius: BorderRadius.circular(11), border: Border.all(color: _sel == i && !_apagar ? azulEditor : Colors.transparent, width: 2.5)),
                          child: CustomPaint(painter: _Miniatura(paleta[i])),
                        ),
                      ),
                  ],
                ),
              ),
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
    canvas.drawRect(Offset.zero & size, Paint()..color = Color(c.corFundo));
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black.withAlpha(60)); // fora do mapa fica mais escuro
    canvas.save();
    canvas.translate(s._desl.dx, s._desl.dy);
    canvas.scale(s._esc);
    final area = Rect.fromLTWH(0, 0, c.largura * cs, c.altura * cs);
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
    canvas.drawRect(area, Paint()
      ..color = Colors.black.withAlpha(170)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 / s._esc);
    // numeros nos eixos (0 = canto inferior esquerdo)
    final st = TextStyle(color: Colors.white.withAlpha(235), fontSize: 11, fontWeight: FontWeight.w700);
    for (var x = 0; x < c.largura; x++) {
      final tp = TextPainter(text: TextSpan(text: '$x', style: st), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x * cs + cs / 2 - tp.width / 2, area.height + 5));
    }
    for (var y = 0; y < c.altura; y++) {
      final tp = TextPainter(text: TextSpan(text: '$y', style: st), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(-6 - tp.width, (c.altura - 1 - y) * cs + cs / 2 - tp.height / 2));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CenaPainter old) => true;
}
