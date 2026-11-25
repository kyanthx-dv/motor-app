import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'icones.dart';
import 'jogar_tela.dart';
import 'biblioteca.dart';
import 'desenho.dart';
import 'objeto.dart';
import 'pre_arte.dart';
import 'cena_config.dart';
import 'projetos.dart';
import 'widgets.dart';

/// Item da paleta: sprite pronto (pixel art que vem no app), ou desenho do usuario ([assetId]).
class ItemPaleta {
  const ItemPaleta(this.nome, this.aba, this.cor, [this.assetId]);
  final int? assetId;
  final String nome;
  final String aba; // Tile | Deco | Ator | Objeto
  final Color cor;
}

const paleta = <ItemPaleta>[
  ItemPaleta('Grama', 'Tile', Color(0xFF5DBB2F)),
  ItemPaleta('Terra', 'Tile', Color(0xFFB4713A)),
  ItemPaleta('Pedra', 'Tile', Color(0xFF9AA5B1)),
  ItemPaleta('Água', 'Tile', Color(0xFF3BA7F0)),
  ItemPaleta('Areia', 'Tile', Color(0xFFF2D58A)),
  ItemPaleta('Árvore', 'Deco', Color(0xFF2E9E4F)),
  ItemPaleta('Flor', 'Deco', Color(0xFFEC4899)),
  ItemPaleta('Nuvem', 'Deco', Color(0xFFF1F3F5)),
  ItemPaleta('Herói', 'Ator', Color(0xFF1D9BF0)),
  ItemPaleta('Slime', 'Ator', Color(0xFF23A55A)),
  ItemPaleta('Fantasma', 'Ator', Color(0xFFE6E8EB)),
  ItemPaleta('Baú', 'Objeto', Color(0xFFB4713A)),
  ItemPaleta('Moeda', 'Objeto', Color(0xFFF59E0B)),
  ItemPaleta('Bandeira', 'Objeto', Color(0xFFF23F43)),
];

const abasPaleta = ['Tile', 'Deco', 'Ator', 'Objeto'];

/// Item para um valor de celula (indice da paleta ou desenho da biblioteca). null = invalido/apagado.
ItemPaleta? itemDe(int v) {
  if (v >= baseAsset) {
    final a = Biblioteca.i.porId(v - baseAsset);
    return a == null ? null : ItemPaleta(a.nome, a.cat, const Color(0xFFFFFFFF), a.id);
  }
  return v >= 0 && v < paleta.length ? paleta[v] : null;
}

/// Desenha um item dentro de [r] (pixels nitidos).
void pintarItem(Canvas c, Rect r, ItemPaleta it) {
  final aid = it.assetId;
  if (aid != null) {
    final im = Biblioteca.i.imagem(aid);
    if (im != null) c.drawImageRect(im, Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()), r, Paint()..filterQuality = FilterQuality.none..isAntiAlias = false);
    return;
  }
  if (preArtes.containsKey(it.nome)) {
    desenharPre(c, r, it.nome);
  } else {
    c.drawRect(r, Paint()..color = it.cor);
  }
}

/// Valores de celula de todos os sprites (prontos + do usuario), na ordem da paleta; [cat] filtra por categoria.
List<int> valoresPaleta({String? cat}) => [
      for (var i = 0; i < paleta.length; i++)
        if (cat == null || paleta[i].aba == cat) i,
      for (final a in Biblioteca.i.itens)
        if (a.cat != 'PFP' && (cat == null || a.cat == cat)) baseAsset + a.id,
    ];

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
  // arrastar o objeto selecionado para outra celula
  bool _movendo = false;
  (int, int)? _destino;

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

  void _aoMudarBiblioteca() {
    if (mounted) {
      _versao.value++;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    Biblioteca.i.carregar();
    Biblioteca.i.addListener(_aoMudarBiblioteca);
  }

  @override
  void dispose() {
    Biblioteca.i.removeListener(_aoMudarBiblioteca);
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
    c.props.remove(k);
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

  bool get _temSel => _selX != null && _selY != null && c.celulas.containsKey('$_selX,$_selY');

  /// Trocar a imagem do objeto selecionado: escolhe entre todos os sprites (prontos e seus).
  Future<void> _escolherSprite() async {
    final k = '$_selX,$_selY';
    final proprio = c.celulas[k];
    final v = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Cores.cartao,
      isScrollControlled: true,
      builder: (ctx) => ListenableBuilder(
        listenable: Biblioteca.i,
        builder: (ctx, _) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.fromLTRB(16, 14, 16, 8), child: Text('Imagem do objeto', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
              Flexible(
                child: GridView.count(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    Toque(
                      aoTocar: () => Navigator.of(ctx).push(MaterialPageRoute<void>(builder: (_) => const NovoDesenhoTela())),
                      child: Container(
                        decoration: BoxDecoration(color: Cores.cartao2, borderRadius: BorderRadius.circular(12), border: Border.all(color: Cores.acento, width: 1.5)),
                        child: const Center(child: Icon(Icons.add_rounded, color: Cores.acento, size: 28)),
                      ),
                    ),
                    for (final i in valoresPaleta())
                      Toque(
                        aoTocar: () => Navigator.pop(ctx, i),
                        child: Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: Cores.cartao2, borderRadius: BorderRadius.circular(12)), child: CustomPaint(painter: _Miniatura(itemDe(i) ?? paleta[0]))),
                      ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
    if (v != null) _mudarProp('textura', v == proprio ? null : v);
  }

  void _mudarProp(String chave, Object? valor) {
    final k = '$_selX,$_selY';
    final p = c.props.putIfAbsent(k, () => {});
    if (valor == null) {
      p.remove(chave);
    } else {
      p[chave] = valor;
    }
    if (p.isEmpty) c.props.remove(k);
    RepositorioProjetos.instancia.salvar();
    setState(() {});
    _versao.value++;
  }

  void _terminou(ScaleEndDetails _) {
    _seg?.cancel();
    if (_movendo) {
      final d = _destino, ox = _selX, oy = _selY;
      _movendo = false;
      _destino = null;
      if (d != null && ox != null && oy != null && (d.$1 != ox || d.$2 != oy)) {
        final de = '$ox,$oy', para = '${d.$1},${d.$2}';
        if (!c.celulas.containsKey(para)) {
          _desfazer.add({de: c.celulas[de], para: null});
          _refazer.clear();
          c.celulas[para] = c.celulas.remove(de)!;
          final p = c.props.remove(de);
          if (p != null) c.props[para] = p;
          _selX = d.$1;
          _selY = d.$2;
          RepositorioProjetos.instancia.salvar();
        }
      }
      _versao.value++;
      setState(() {});
      return;
    }
    if (_pintando && _traco.isNotEmpty) {
      _desfazer.add(_traco);
      if (_desfazer.length > 100) _desfazer.removeAt(0);
      _refazer.clear();
      _traco = {};
      RepositorioProjetos.instancia.salvar(); // salva sozinho a cada traco
    } else if (!_pintando && !_mexeu) {
      final cel = _celulaEm(_ini); // toque curto: seleciona um OBJETO (celula vazia limpa a selecao)
      final valido = cel != null && c.celulas.containsKey('${cel.$1},${cel.$2}');
      _selX = valido ? cel.$1 : null;
      _selY = valido ? cel.$2 : null;
      if (valido && _altPainel < 100) _altPainel = _alturas[1];
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
    _movendo = false;
    _destino = null;
    if (d.pointerCount == 1 && _temSel) {
      final sob = _celulaEm(d.localFocalPoint);
      if (sob != null && sob.$1 == _selX && sob.$2 == _selY) {
        _movendo = true; // dedo em cima do objeto selecionado: arrastar = mover o objeto
        _destino = sob;
        return;
      }
    }
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
        _movendo = false;
        _destino = null;
        _mexeu = true;
        _seg?.cancel();
      }
      return;
    }
    if (_movendo && d.pointerCount == 1) {
      _destino = _celulaEm(d.localFocalPoint) ?? _destino;
      _versao.value++;
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
    final itens = valoresPaleta(cat: abasPaleta[_aba]);
    final grande = _altPainel > 300;
    final objK = _temSel ? '$_selX,$_selY' : null;
    final objIdx = objK == null ? null : c.celulas[objK];
    final objItem = objIdx == null ? null : itemDe(objIdx);
    final objDados = objItem == null ? null : objetoEfetivo(c, objK!, objItem);
    final objVisual = objDados == null ? null : (itemDe(objDados['textura'] as int? ?? objIdx!) ?? objItem);
    Widget celula(int i) => Toque(
          aoTocar: () => setState(() {
            _sel = i;
            _apagar = false;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: Cores.cartao2, borderRadius: BorderRadius.circular(12), border: Border.all(color: _sel == i && !_apagar ? azulEditor : Colors.transparent, width: 2.5)),
            child: CustomPaint(painter: _Miniatura(itemDe(i) ?? paleta[0])),
          ),
        );
    Widget mais() => Toque(
          aoTocar: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => NovoDesenhoTela(categoria: abasPaleta[_aba]))),
          child: Container(
            decoration: BoxDecoration(color: Cores.cartao2, borderRadius: BorderRadius.circular(12), border: Border.all(color: Cores.acento, width: 1.5)),
            child: const Center(child: Icon(Icons.add_rounded, color: Cores.acento, size: 28)),
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
                    if (sx == null || sy == null || _movendo) return const SizedBox.shrink();
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
                        c.props.remove(k);
                        _selX = null;
                        _selY = null;
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
                          aoTocar: () => executar(context, widget.projeto, daCena: widget.cena),
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
                    SizedBox(width: 30, height: 30, child: CustomPaint(painter: _Miniatura(objVisual ?? itemDe(_sel) ?? paleta[0]))),
                    const SizedBox(width: 10),
                    Flexible(child: Text(objItem == null ? (itemDe(_sel) ?? paleta[0]).nome : '${objDados!['nome']}  ·  ($_selX, $_selY)', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
                    const Spacer(),
                    Container(width: 36, height: 4, decoration: BoxDecoration(color: Cores.texto2.withAlpha(120), borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 50),
                    const Spacer(),
                    Icon(_altPainel > 100 ? Ic.baixo : Ic.cima, size: 20, color: Cores.texto2),
                    const SizedBox(width: 16),
                  ]),
                ),
              ),
              if (_altPainel > 100 && objItem != null)
                Expanded(
                  child: PainelObjeto(
                    item: objItem,
                    imagem: CustomPaint(painter: _Miniatura(objVisual ?? objItem)),
                    aoTrocarImagem: _escolherSprite,
                    dados: objDados!,
                    x: _selX!,
                    y: _selY!,
                    aoMudar: _mudarProp,
                    aoRestaurar: () {
                      c.props.remove(objK);
                      RepositorioProjetos.instancia.salvar();
                      setState(() {});
                      _versao.value++;
                    },
                  ),
                )
              else if (_altPainel > 100) ...[
                SizedBox(
                  height: 34,
                  child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
                    for (var i = 0; i < abasPaleta.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Toque(
                          aoTocar: () => setState(() => _aba = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: _aba == i ? azulEditor : Cores.cartao2, borderRadius: BorderRadius.circular(17)),
                            child: Text(abasPaleta[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _aba == i ? Colors.white : Cores.texto2)),
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
                          children: [mais(), for (final i in itens) celula(i)],
                        )
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          children: [Padding(padding: const EdgeInsets.only(right: 8), child: AspectRatio(aspectRatio: 1, child: mais())), for (final i in itens) Padding(padding: const EdgeInsets.only(right: 8), child: AspectRatio(aspectRatio: 1, child: celula(i)))],
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
    int camadaDe(String k) => (c.props[k]?['camada'] as num?)?.toInt() ?? 0;
    final ordem = c.celulas.keys.toList()..sort((a, b) => camadaDe(a).compareTo(camadaDe(b)));
    for (final k in ordem) {
      final i = c.celulas[k]!;
      final item = itemDe((c.props[k]?['textura'] as num?)?.toInt() ?? i) ?? itemDe(i);
      if (item == null) continue;
      final p = k.split(',');
      final x = int.parse(p[0]), y = int.parse(p[1]);
      final r = Rect.fromLTWH(x * cs, (c.altura - 1 - y) * cs, cs, cs);
      final oculto = c.props[k]?['visivel'] == false;
      if (oculto) canvas.saveLayer(r, Paint()..color = const Color(0x55FFFFFF));
      pintarItem(canvas, r, item);
      if (oculto) canvas.restore();
    }
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
      final dest = s._movendo ? s._destino : null;
      final gx = dest?.$1 ?? s._selX!, gy = dest?.$2 ?? s._selY!;
      final r = Rect.fromLTWH(gx * cs, (c.altura - 1 - gy) * cs, cs, cs);
      if (dest != null) {
        final i = c.celulas['${s._selX},${s._selY}'];
        final item = i == null ? null : itemDe(i);
        if (item != null) {
          canvas.saveLayer(r, Paint()..color = const Color(0xB3FFFFFF));
          pintarItem(canvas, r, item);
          canvas.restore();
        }
      }
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
