import 'package:flutter/material.dart';

import 'cena_config.dart';
import 'projetos.dart';
import 'widgets.dart';

/// Item da paleta de exemplo (depois vira o catalogo real de assets da engine).
class ItemPaleta {
  const ItemPaleta(this.nome, this.aba, this.cor, this.icone);
  final String nome;
  final String aba; // Tile | Deco | Ator | Objeto
  final Color cor;
  final IconData icone;
}

const paleta = <ItemPaleta>[
  ItemPaleta('Grama', 'Tile', Color(0xFF65A30D), Icons.grass),
  ItemPaleta('Terra', 'Tile', Color(0xFF92400E), Icons.landscape),
  ItemPaleta('Pedra', 'Tile', Color(0xFF64748B), Icons.view_module),
  ItemPaleta('Água', 'Tile', Color(0xFF0EA5E9), Icons.water),
  ItemPaleta('Areia', 'Tile', Color(0xFFEAB308), Icons.beach_access),
  ItemPaleta('Árvore', 'Deco', Color(0xFF15803D), Icons.park),
  ItemPaleta('Flor', 'Deco', Color(0xFFEC4899), Icons.local_florist),
  ItemPaleta('Nuvem', 'Deco', Color(0xFF94A3B8), Icons.cloud),
  ItemPaleta('Herói', 'Ator', Color(0xFFF59E0B), Icons.face),
  ItemPaleta('Slime', 'Ator', Color(0xFF22D3EE), Icons.bug_report),
  ItemPaleta('Fantasma', 'Ator', Color(0xFFA78BFA), Icons.sentiment_very_dissatisfied),
  ItemPaleta('Baú', 'Objeto', Color(0xFFB45309), Icons.inventory_2),
  ItemPaleta('Moeda', 'Objeto', Color(0xFFFBBF24), Icons.monetization_on),
  ItemPaleta('Bandeira', 'Objeto', Color(0xFFEF4444), Icons.flag),
];

const _abas = ['Tile', 'Deco', 'Ator', 'Objeto'];

enum _Modo { mover, pintar, apagar }

class CenaTela extends StatefulWidget {
  const CenaTela({super.key, required this.projeto, required this.cena});
  final Projeto projeto;
  final Cena cena;

  @override
  State<CenaTela> createState() => _CenaTelaState();
}

class _CenaTelaState extends State<CenaTela> {
  static const double _cs = 44; // tamanho da celula em pixels
  static const double _margem = 30; // espaco para os numeros

  final _versao = ValueNotifier<int>(0);
  _Modo _modo = _Modo.pintar;
  int _aba = 0;
  int _sel = 0;
  bool _painelAberto = true;
  int _dedos = 0;
  int? _ultimo; // ultima celula pintada no arrasto (evita repetir)

  Cena get c => widget.cena;

  @override
  void dispose() {
    _versao.dispose();
    RepositorioProjetos.instancia.salvar();
    super.dispose();
  }

  void _pintarEm(Offset p) {
    if (_modo == _Modo.mover || _dedos != 1) return;
    final x = ((p.dx - _margem) / _cs).floor();
    final yTela = ((p.dy - 4) / _cs).floor();
    final y = c.altura - 1 - yTela;
    if (x < 0 || y < 0 || x >= c.largura || y >= c.altura) return; // limite do mapa
    final chave = x * 100000 + y;
    if (chave == _ultimo) return;
    _ultimo = chave;
    final k = '$x,$y';
    if (_modo == _Modo.apagar) {
      c.celulas.remove(k);
    } else {
      c.celulas[k] = _sel;
    }
    _versao.value++;
  }

  @override
  Widget build(BuildContext context) {
    final itens = [for (var i = 0; i < paleta.length; i++) if (paleta[i].aba == _abas[_aba]) i];
    final larg = _margem + c.largura * _cs + 6;
    final alt = c.altura * _cs + _margem + 4;
    return Scaffold(
      appBar: AppBar(
        title: Text(c.nome),
        actions: [
          IconButton(tooltip: 'Configurar cena', icon: const Icon(Icons.settings_outlined), onPressed: () async {
            await abrirConfigCena(context, c);
            if (mounted) _versao.value++;
            setState(() {});
          }),
          IconButton(tooltip: 'Dados', icon: const Icon(Icons.pin_outlined), onPressed: () => emBreve(context, 'Dados do jogo')),
          IconButton(tooltip: 'Salvar', icon: const Icon(Icons.save_outlined), onPressed: () {
            RepositorioProjetos.instancia.salvar();
            aviso(context, 'Salvo.');
          }),
          IconButton(tooltip: 'Executar', icon: const Icon(Icons.play_arrow_rounded), onPressed: () => emBreve(context, 'Executar (engine)')),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: Container(
            color: Color(c.corFundo),
            child: Stack(children: [
              InteractiveViewer(
                constrained: false,
                minScale: 0.4,
                maxScale: 3,
                panEnabled: _modo == _Modo.mover,
                boundaryMargin: const EdgeInsets.all(160),
                child: Listener(
                  onPointerDown: (e) {
                    _dedos++;
                    _ultimo = null;
                    _pintarEm(e.localPosition);
                  },
                  onPointerMove: (e) => _pintarEm(e.localPosition),
                  onPointerUp: (e) => _dedos = (_dedos - 1).clamp(0, 10),
                  onPointerCancel: (e) => _dedos = (_dedos - 1).clamp(0, 10),
                  child: SizedBox(
                    width: larg,
                    height: alt,
                    child: CustomPaint(painter: _GradePainter(c, _versao, _cs, _margem)),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: Column(children: [
                  for (final m in _Modo.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: _modo == m ? Cores.acento : Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _modo = m),
                          child: SizedBox(width: 44, height: 44, child: Icon(switch (m) { _Modo.mover => Icons.pan_tool_alt_outlined, _Modo.pintar => Icons.brush, _Modo.apagar => Icons.cleaning_services_outlined }, color: Colors.white)),
                        ),
                      ),
                    ),
                ]),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                  child: Text('${c.largura}×${c.altura} · ${rotuloFisica(c.fisica)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ]),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          height: _painelAberto ? 230 : 44,
          decoration: BoxDecoration(color: Cores.cartao, borderRadius: const BorderRadius.vertical(top: Radius.circular(18))),
          child: ClipRect(
            child: Column(children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _painelAberto = !_painelAberto),
                child: SizedBox(height: 44, child: Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Cores.texto2, borderRadius: BorderRadius.circular(3))))),
              ),
              SizedBox(
                height: 40,
                child: Row(children: [
                  for (var i = 0; i < _abas.length; i++)
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _aba = i),
                        child: Center(child: Text(_abas[i], style: TextStyle(fontSize: 15, color: _aba == i ? Cores.acento : Cores.texto2, fontWeight: _aba == i ? FontWeight.w700 : FontWeight.w400))),
                      ),
                    ),
                ]),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(10),
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (final i in itens)
                      Toque(
                        aoTocar: () => setState(() {
                          _sel = i;
                          _modo = _Modo.pintar;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: paleta[i].cor.withAlpha(60),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _sel == i && _modo != _Modo.apagar ? Cores.acento : Colors.transparent, width: 2.5),
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(paleta[i].icone, color: paleta[i].cor, size: 28),
                            Text(paleta[i].nome, style: const TextStyle(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ]),
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

class _GradePainter extends CustomPainter {
  _GradePainter(this.c, Listenable repaint, this.cs, this.margem) : super(repaint: repaint);
  final Cena c;
  final double cs;
  final double margem;

  @override
  void paint(Canvas canvas, Size size) {
    final fundoMapa = Paint()..color = Colors.white.withAlpha(40);
    final linha = Paint()
      ..color = Colors.white.withAlpha(90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final borda = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final area = Rect.fromLTWH(margem, 4, c.largura * cs, c.altura * cs);
    canvas.drawRRect(RRect.fromRectAndRadius(area, const Radius.circular(8)), fundoMapa);
    // celulas: quadradinhos arredondados (visual proprio, nao a grade do editor de PC)
    for (var gx = 0; gx < c.largura; gx++) {
      for (var gy = 0; gy < c.altura; gy++) {
        final r = Rect.fromLTWH(margem + gx * cs, 4 + (c.altura - 1 - gy) * cs, cs, cs).deflate(1.5);
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), linha);
        final i = c.celulas['$gx,$gy'];
        if (i != null && i >= 0 && i < paleta.length) {
          final it = paleta[i];
          canvas.drawRRect(RRect.fromRectAndRadius(r.deflate(1), const Radius.circular(6)), Paint()..color = it.cor.withAlpha(230));
          final tp = TextPainter(
            text: TextSpan(text: String.fromCharCode(it.icone.codePoint), style: TextStyle(fontFamily: it.icone.fontFamily, package: it.icone.fontPackage, fontSize: cs * 0.6, color: Colors.white)),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, r.center - Offset(tp.width / 2, tp.height / 2));
        }
      }
    }
    canvas.drawRRect(RRect.fromRectAndRadius(area, const Radius.circular(8)), borda);
    // numeros: x embaixo, y a esquerda (0 = canto inferior esquerdo)
    final st = TextStyle(color: Colors.white.withAlpha(230), fontSize: 11, fontWeight: FontWeight.w600);
    for (var gx = 0; gx < c.largura; gx++) {
      final tp = TextPainter(text: TextSpan(text: '$gx', style: st), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(margem + gx * cs + cs / 2 - tp.width / 2, 4 + c.altura * cs + 6));
    }
    for (var gy = 0; gy < c.altura; gy++) {
      final tp = TextPainter(text: TextSpan(text: '$gy', style: st), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(margem - 8 - tp.width, 4 + (c.altura - 1 - gy) * cs + cs / 2 - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _GradePainter old) => true;
}
