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
  static const double _folga = 10; // deslocamento maximo (px) para ainda ser um "toque certeiro"

  final _versao = ValueNotifier<int>(0);
  bool _apagar = false;
  // toque certeiro = cria 1 objeto (ou seleciona); segurar parado = pintar/apagar; arrastar = mover o mapa
  Timer? _seg;
  bool _pintando = false;
  bool _mexeu = false;
  // rastreio bruto dos dedos (nao depende do reconhecedor de gestos): posicao/tempo do toque e distancia maxima percorrida
  final _relogio = Stopwatch();
  int _dedos = 0;
  bool _multi = false;
  Offset _baixo = Offset.zero;
  double _maxDist = 0;

  ObjetoCena? _so; // objeto selecionado
  int _aba = 0;
  int _sel = 0;
  double _altPainel = 210; // altura do painel (puxavel)
  static const _alturas = [52.0, 210.0, 400.0];
  bool _painelTam = false; // painel de tamanho/posicao aberto

  // arrastar o objeto selecionado para outra celula
  bool _movendo = false;
  (int, int)? _destino; // canto inferior esquerdo proposto
  (int, int) _pega = (0, 0); // celula agarrada dentro do objeto
  bool _destinoOk = true;

  // ordem de desenho em cache e indice de tiles (1 por celula)
  List<ObjetoCena> _ordem = [];
  bool _ordemSuja = true;
  final _tiles = <int, ObjetoCena>{};
  final _visitadas = <int>{};

  // desfazer / refazer por foto da lista de objetos (max 30)
  final _desfazer = <List<ObjetoCena>>[];
  final _refazer = <List<ObjetoCena>>[];
  bool _snap = false; // ja guardou o desfazer neste gesto

  // camera (zoom + deslocamento), controlada a mao: 1 dedo age, 2 dedos movem/zoom
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
      _reindex();
      _ordemSuja = true;
      _versao.value++;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    Biblioteca.i.carregar().then((_) => _aoMudarBiblioteca());
    Biblioteca.i.addListener(_aoMudarBiblioteca);
    _reindex();
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

  // ---------- modelo ----------
  bool _ehTile(ObjetoCena o) => itemDe(o.v)?.aba == 'Tile';

  void _reindex() {
    _tiles.clear();
    for (final o in c.objetos) {
      if (_ehTile(o)) _tiles[o.x * 1000 + o.y] = o;
    }
  }

  int _chaveOrdem(ObjetoCena o) => (_ehTile(o) ? 0 : 1) + ((o.props['camada'] as num?)?.toInt() ?? 0);

  /// Ordem de desenho (tile antes de objeto, depois camada, depois criacao); so recalcula quando algo mudou.
  List<ObjetoCena> get ordem {
    if (_ordemSuja) {
      final ks = {for (final o in c.objetos) o: _chaveOrdem(o)};
      _ordem = [...c.objetos]..sort((a, b) {
          final d = ks[a]!.compareTo(ks[b]!);
          return d != 0 ? d : a.id.compareTo(b.id);
        });
      _ordemSuja = false;
    }
    return _ordem;
  }

  static bool _contem(ObjetoCena o, int x, int y) => x >= o.x && x < o.x + o.w && y >= o.y && y < o.y + o.h;

  ObjetoCena? _noTopo(int x, int y) {
    final l = ordem;
    for (var i = l.length - 1; i >= 0; i--) {
      if (_contem(l[i], x, y)) return l[i];
    }
    return null;
  }

  ObjetoCena? _naoTileEm(int x, int y) {
    final l = ordem;
    for (var i = l.length - 1; i >= 0; i--) {
      if (_contem(l[i], x, y) && !_ehTile(l[i])) return l[i];
    }
    return null;
  }

  List<ObjetoCena> _copiaLista() => [for (final o in c.objetos) o.copia(o.id)];

  /// Guarda o estado para desfazer (uma vez por gesto).
  void _marcar() {
    if (_snap) return;
    _snap = true;
    _desfazer.add(_copiaLista());
    if (_desfazer.length > 30) _desfazer.removeAt(0);
    _refazer.clear();
  }

  void _restaurar(List<ObjetoCena> l) {
    final id = _so?.id;
    c.objetos
      ..clear()
      ..addAll([for (final o in l) o.copia(o.id)]);
    _so = null;
    if (id != null) {
      for (final o in c.objetos) {
        if (o.id == id) _so = o;
      }
    }
    if (_so == null) _painelTam = false;
    _reindex();
    _ordemSuja = true;
    _versao.value++;
  }

  void _undo() {
    if (_desfazer.isEmpty) return;
    _refazer.add(_copiaLista());
    _restaurar(_desfazer.removeLast());
    setState(() {});
    RepositorioProjetos.instancia.salvar();
  }

  void _redo() {
    if (_refazer.isEmpty) return;
    _desfazer.add(_copiaLista());
    _restaurar(_refazer.removeLast());
    setState(() {});
    RepositorioProjetos.instancia.salvar();
  }

  /// Cria 1 objeto na celula (Tile nao pode ir sobre outro Tile). Devolve se criou.
  bool _colocar(int x, int y) {
    final it = itemDe(_sel);
    if (it == null) return false;
    final tile = it.aba == 'Tile';
    if (tile && _tiles.containsKey(x * 1000 + y)) return false;
    if (!tile) {
      final ex = _naoTileEm(x, y);
      if (ex != null && ex.v == _sel && ex.x == x && ex.y == y && ex.w == 1 && ex.h == 1) return false; // nao empilha copia identica
    }
    _marcar();
    final o = ObjetoCena(id: c.novoId(), v: _sel, x: x, y: y);
    c.objetos.add(o);
    if (tile) _tiles[x * 1000 + y] = o;
    _ordemSuja = true;
    _versao.value++;
    return true;
  }

  /// Apaga o objeto de cima da celula.
  bool _apagarEm(int x, int y) {
    final o = _noTopo(x, y);
    if (o == null) return false;
    _marcar();
    _remover(o);
    return true;
  }

  void _remover(ObjetoCena o) {
    c.objetos.remove(o);
    if (_ehTile(o)) _tiles.remove(o.x * 1000 + o.y);
    if (identical(_so, o)) {
      _so = null;
      _painelTam = false;
    }
    _ordemSuja = true;
    _versao.value++;
  }

  (int, int)? _celulaEm(Offset p) {
    final w = (p - _desl) / _esc;
    final x = (w.dx / _cs).floor();
    final y = c.altura - 1 - (w.dy / _cs).floor();
    if (w.dx < 0 || w.dy < 0 || x >= c.largura || y < 0 || y >= c.altura) return null;
    return (x, y);
  }

  (int, int) _celulaPrender(Offset p) {
    final w = (p - _desl) / _esc;
    final x = (w.dx / _cs).floor().clamp(0, c.largura - 1).toInt();
    final y = (c.altura - 1 - (w.dy / _cs).floor()).clamp(0, c.altura - 1).toInt();
    return (x, y);
  }

  void _pintarEm(Offset p) {
    final cel = _celulaEm(p);
    if (cel == null) return;
    if (!_visitadas.add(cel.$1 * 1000 + cel.$2)) return; // 1 vez por celula em cada traco
    if (_apagar) {
      _apagarEm(cel.$1, cel.$2);
    } else {
      _colocar(cel.$1, cel.$2);
    }
  }

  /// Toque certeiro numa celula: apagar / selecionar / criar 1 objeto.
  void _tocar(Offset p) {
    final cel = _celulaEm(p);
    if (cel == null) {
      _so = null;
      _painelTam = false;
      _versao.value++;
      return;
    }
    final x = cel.$1, y = cel.$2;
    if (_apagar) {
      _apagarEm(x, y);
      RepositorioProjetos.instancia.salvar();
      return;
    }
    final item = itemDe(_sel);
    final ehTileAtivo = item?.aba == 'Tile';
    final nt = _naoTileEm(x, y);
    final tl = _tiles[x * 1000 + y];
    ObjetoCena? alvo = nt; // objetos (nao tile) tem prioridade de selecao
    if (alvo == null && tl != null && (ehTileAtivo || item == null)) alvo = tl; // tile so se o item ativo tambem e tile
    if (alvo != null) {
      _so = alvo;
      _painelTam = false;
      if (_altPainel < 100) _altPainel = _alturas[1];
      _versao.value++;
      return;
    }
    if (_so != null) {
      _so = null; // havia selecao: o toque so a limpa (nao cria sem querer)
      _painelTam = false;
      _versao.value++;
      return;
    }
    if (_colocar(x, y)) RepositorioProjetos.instancia.salvar();
  }

  bool _destinoValido(ObjetoCena o, int x, int y) {
    if (!_ehTile(o)) return true;
    final t = _tiles[x * 1000 + y];
    return t == null || identical(t, o);
  }

  /// Trocar a imagem do objeto selecionado: escolhe entre todos os sprites (prontos e seus).
  Future<void> _escolherSprite() async {
    final o = _so;
    if (o == null) return;
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
    if (v != null) _mudarProp('textura', v == o.v ? null : v);
  }

  void _mudarProp(String chave, Object? valor) {
    final o = _so;
    if (o == null) return;
    if (chave != 'nome') {
      _snap = false;
      _marcar();
      _snap = false;
    }
    if (valor == null) {
      o.props.remove(chave);
    } else {
      o.props[chave] = valor;
    }
    if (chave == 'camada') _ordemSuja = true;
    RepositorioProjetos.instancia.salvar();
    setState(() {});
    _versao.value++;
  }

  void _restaurarPadrao() {
    final o = _so;
    if (o == null) return;
    _snap = false;
    _marcar();
    _snap = false;
    o.props.clear();
    _ordemSuja = true;
    RepositorioProjetos.instancia.salvar();
    setState(() {});
    _versao.value++;
  }

  /// Ajusta W/H/X/Y do objeto selecionado dentro dos limites do mapa (Tile nao redimensiona).
  void _ajTam(String campo, int d) {
    final o = _so;
    if (o == null) return;
    final tile = _ehTile(o);
    var w = o.w, h = o.h, x = o.x, y = o.y;
    switch (campo) {
      case 'w':
        if (tile) return;
        w = (w + d).clamp(1, c.largura - x).toInt();
      case 'h':
        if (tile) return;
        h = (h + d).clamp(1, c.altura - y).toInt();
      case 'x':
        x = (x + d).clamp(0, c.largura - w).toInt();
      case 'y':
        y = (y + d).clamp(0, c.altura - h).toInt();
    }
    if (w == o.w && h == o.h && x == o.x && y == o.y) return;
    if (!_destinoValido(o, x, y)) return;
    _snap = false;
    _marcar();
    _snap = false;
    o.w = w;
    o.h = h;
    o.x = x;
    o.y = y;
    if (tile) _reindex();
    RepositorioProjetos.instancia.salvar();
    _versao.value++;
  }

  // ---------- gestos ----------
  void _pBaixo(PointerDownEvent e) {
    _dedos++;
    if (_dedos == 1) {
      _baixo = e.localPosition;
      _maxDist = 0;
      _multi = false;
      _relogio
        ..reset()
        ..start();
    } else {
      _multi = true;
    }
  }

  void _pMove(PointerMoveEvent e) {
    if (_dedos == 1) {
      final d = (e.localPosition - _baixo).distance;
      if (d > _maxDist) _maxDist = d;
    }
  }

  void _pCima(PointerEvent e) {
    _dedos = math.max(0, _dedos - 1);
  }

  void _terminou(ScaleEndDetails _) {
    _seg?.cancel();
    final limpo = !_multi && !_mexeu && !_pintando && !_movendo && _maxDist <= _folga && _relogio.elapsedMilliseconds < 380;
    if (_movendo) {
      final d = _destino, o = _so;
      _movendo = false;
      _destino = null;
      if (o != null && d != null && (d.$1 != o.x || d.$2 != o.y) && _destinoValido(o, d.$1, d.$2)) {
        _snap = false;
        _marcar();
        o.x = d.$1;
        o.y = d.$2;
        if (_ehTile(o)) _reindex();
        RepositorioProjetos.instancia.salvar();
      }
      _snap = false;
      _versao.value++;
      setState(() {});
      return;
    }
    if (_pintando) {
      RepositorioProjetos.instancia.salvar(); // salva sozinho a cada traco
    } else if (limpo) {
      _snap = false;
      _tocar(_baixo); // so um toque curto e parado (nada de pan) cria/seleciona
    }
    _snap = false;
    _pintando = false;
    setState(() {});
  }

  void _comecou(ScaleStartDetails d) {
    _cont = d.pointerCount;
    _rebase(d.localFocalPoint);
    _pintando = false;
    _mexeu = d.pointerCount > 1;
    _seg?.cancel();
    _movendo = false;
    _destino = null;
    _snap = false;
    _visitadas.clear();
    final o = _so;
    if (d.pointerCount == 1 && o != null) {
      final sob = _celulaEm(_baixo);
      if (sob != null && _contem(o, sob.$1, sob.$2)) {
        _movendo = true; // dedo em cima do objeto selecionado: arrastar = mover o objeto
        _pega = (sob.$1 - o.x, sob.$2 - o.y);
        _destino = (o.x, o.y);
        _destinoOk = true;
        return;
      }
    }
    if (d.pointerCount == 1) {
      _seg = Timer(const Duration(milliseconds: 380), () {
        if (_mexeu || _multi || _maxDist > _folga) return;
        _pintando = true; // segurou parado: comeca a pintar (ou apagar)
        HapticFeedback.selectionClick();
        _so = null;
        _painelTam = false;
        _pintarEm(_baixo);
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
    final o = _so;
    if (_movendo && d.pointerCount == 1 && o != null) {
      final cel = _celulaPrender(d.localFocalPoint);
      final nx = (cel.$1 - _pega.$1).clamp(0, c.largura - o.w).toInt(), ny = (cel.$2 - _pega.$2).clamp(0, c.altura - o.h).toInt();
      if (_destino == null || _destino!.$1 != nx || _destino!.$2 != ny) {
        _destino = (nx, ny);
        _destinoOk = _destinoValido(o, nx, ny);
        _versao.value++;
      }
      return;
    }
    if (_pintando && d.pointerCount == 1) {
      _pintarEm(d.localFocalPoint);
      return;
    }
    if (!_mexeu && _maxDist > _folga) {
      _mexeu = true; // arrastou: e mover o mapa (nunca cria objeto)
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

  Widget _mini(IconData i, VoidCallback f) => Toque(
        aoTocar: f,
        child: Container(width: 30, height: 30, decoration: BoxDecoration(color: Cores.cartao2, shape: BoxShape.circle), child: Icon(i, size: 17)),
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
    final so = _so;
    final objItem = so == null ? null : itemDe(so.v);
    final objDados = so == null || objItem == null ? null : objetoEfetivo(so, objItem);
    final objVisual = objDados == null ? null : (itemDe(objDados['textura'] as int? ?? so!.v) ?? objItem);
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
                  child: Listener(
                    onPointerDown: _pBaixo,
                    onPointerMove: _pMove,
                    onPointerUp: _pCima,
                    onPointerCancel: _pCima,
                    child: GestureDetector(
                      onScaleStart: _comecou,
                      onScaleUpdate: _moveu,
                      onScaleEnd: _terminou,
                      child: CustomPaint(painter: _CenaPainter(this, _versao)),
                    ),
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: _versao,
                  builder: (_, __, ___) {
                    final o = _so;
                    if (o == null || _movendo) return const SizedBox.shrink();
                    final cx = _desl.dx + (o.x + o.w / 2) * _cs * _esc;
                    final topo = _desl.dy + (c.altura - o.y - o.h) * _cs * _esc;
                    final tile = _ehTile(o);
                    Widget b(IconData i, VoidCallback f, {bool ativo = false}) => Toque(
                          aoTocar: f,
                          child: Container(width: 38, height: 38, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: ativo ? azulEditor : Cores.cartao, shape: BoxShape.circle), child: Icon(i, size: 19, color: ativo ? Colors.white : null)),
                        );
                    final nb = tile ? 2 : 3;
                    final largura = nb * 42.0;
                    return Positioned(
                      left: (cx - largura / 2).clamp(4.0, math.max(4.0, box.maxWidth - largura - 4)),
                      top: (topo - 46).clamp(60.0, box.maxHeight - 50),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        b(Ic.lixeira, () {
                          _snap = false;
                          _marcar();
                          _snap = false;
                          _remover(o);
                          RepositorioProjetos.instancia.salvar();
                          setState(() {});
                        }),
                        if (!tile) b(Icons.open_in_full_rounded, () => setState(() => _painelTam = !_painelTam), ativo: _painelTam),
                        b(Ic.fechar, () {
                          _so = null;
                          _painelTam = false;
                          _versao.value++;
                          setState(() {});
                        }),
                      ]),
                    );
                  },
                ),
                if (_painelTam && _so != null)
                  Positioned(
                    left: 70,
                    right: 12,
                    bottom: 10,
                    child: ValueListenableBuilder<int>(
                      valueListenable: _versao,
                      builder: (_, __, ___) {
                        final o = _so;
                        if (o == null) return const SizedBox.shrink();
                        final dx = _movendo ? (_destino?.$1 ?? o.x) : o.x, dy = _movendo ? (_destino?.$2 ?? o.y) : o.y;
                        Widget passo(String rot, String campo, int v) => Expanded(
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text(rot, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Cores.texto2)),
                                const SizedBox(width: 2),
                                _mini(Icons.remove_rounded, () => _ajTam(campo, -1)),
                                SizedBox(width: 26, child: Text('$v', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
                                _mini(Icons.add_rounded, () => _ajTam(campo, 1)),
                              ]),
                            );
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                          decoration: BoxDecoration(color: Cores.cartao.withAlpha(240), borderRadius: BorderRadius.circular(14)),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Row(children: [passo('W', 'w', o.w), passo('H', 'h', o.h)]),
                            const SizedBox(height: 2),
                            Row(children: [passo('X', 'x', dx), passo('Y', 'y', dy)]),
                          ]),
                        );
                      },
                    ),
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
                    Flexible(child: Text(so == null || objDados == null ? (itemDe(_sel) ?? paleta[0]).nome : '${objDados['nome']}  ·  (${so.x}, ${so.y})  ·  ${so.w}×${so.h}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
                    const Spacer(),
                    Container(width: 36, height: 4, decoration: BoxDecoration(color: Cores.texto2.withAlpha(120), borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 50),
                    const Spacer(),
                    Icon(_altPainel > 100 ? Ic.baixo : Ic.cima, size: 20, color: Cores.texto2),
                    const SizedBox(width: 16),
                  ]),
                ),
              ),
              if (_altPainel > 100 && objItem != null && objDados != null)
                Expanded(
                  child: PainelObjeto(
                    item: objItem,
                    imagem: CustomPaint(painter: _Miniatura(objVisual ?? objItem)),
                    aoTrocarImagem: _escolherSprite,
                    dados: objDados,
                    id: so!.id,
                    aoMudar: _mudarProp,
                    aoRestaurar: _restaurarPadrao,
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
  final _rotulos = <int, TextPainter>{};
  Color? _rotCor;

  TextPainter _rotulo(int n, Color cor) {
    if (_rotCor != cor) {
      _rotulos.clear();
      _rotCor = cor;
    }
    return _rotulos.putIfAbsent(n, () => TextPainter(text: TextSpan(text: '$n', style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w700)), textDirection: TextDirection.ltr)..layout());
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = s.c;
    const cs = _CenaTelaState._cs;
    final fundo = Color(c.corFundo);
    final claro = fundo.computeLuminance() > 0.5;
    final tinta = claro ? Colors.black : Colors.white; // linhas e numeros legiveis sobre qualquer cor de fundo
    canvas.drawRect(Offset.zero & size, Paint()..color = fundo); // a cor da cena vai ate as bordas da tela
    canvas.save();
    canvas.translate(s._desl.dx, s._desl.dy);
    canvas.scale(s._esc);
    final area = Rect.fromLTWH(0, 0, c.largura * cs, c.altura * cs);
    final visivel = Rect.fromLTWH(-s._desl.dx / s._esc, -s._desl.dy / s._esc, size.width / s._esc, size.height / s._esc);
    // itens (so os que aparecem na tela; ordem em cache)
    for (final o in s.ordem) {
      final r = Rect.fromLTWH(o.x * cs, (c.altura - o.y - o.h) * cs, o.w * cs, o.h * cs);
      if (!r.overlaps(visivel)) continue;
      final item = itemDe((o.props['textura'] as num?)?.toInt() ?? o.v) ?? itemDe(o.v);
      if (item == null) continue;
      final oculto = o.props['visivel'] == false;
      if (oculto) canvas.saveLayer(r, Paint()..color = const Color(0x55FFFFFF));
      pintarItem(canvas, r, item);
      if (oculto) canvas.restore();
    }
    // grade fina (1 pixel de tela, qualquer zoom) e limite do mapa
    final fina = Paint()
      ..color = tinta.withAlpha(34)
      ..strokeWidth = 1 / s._esc;
    for (var x = 0; x <= c.largura; x++) {
      canvas.drawLine(Offset(x * cs, 0), Offset(x * cs, area.height), fina);
    }
    for (var y = 0; y <= c.altura; y++) {
      canvas.drawLine(Offset(0, y * cs), Offset(area.width, y * cs), fina);
    }
    canvas.drawRect(
        area,
        Paint()
          ..color = tinta.withAlpha(110)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 / s._esc);

    // numeros nos eixos (0 = canto inferior esquerdo)
    final cor = tinta.withAlpha(170);
    final passo = s._esc >= 0.75 ? 1 : 5; // zoom afastado: numera de 5 em 5 (leitura limpa)
    final numeros = s._esc >= 0.5; // bem longe: sem numeros
    for (var x = 0; numeros && x < c.largura; x += passo) {
      final tp = _rotulo(x, cor);
      tp.paint(canvas, Offset(x * cs + cs / 2 - tp.width / 2, area.height + 5));
    }
    for (var y = 0; numeros && y < c.altura; y += passo) {
      final tp = _rotulo(y, cor);
      tp.paint(canvas, Offset(-6 - tp.width, (c.altura - 1 - y) * cs + cs / 2 - tp.height / 2));
    }
    final o = s._so;
    if (o != null) {
      final dest = s._movendo ? s._destino : null;
      final gx = dest?.$1 ?? o.x, gy = dest?.$2 ?? o.y;
      final r = Rect.fromLTWH(gx * cs, (c.altura - gy - o.h) * cs, o.w * cs, o.h * cs);
      if (dest != null) {
        final item = itemDe(o.v);
        if (item != null) {
          canvas.saveLayer(r, Paint()..color = const Color(0xB3FFFFFF));
          pintarItem(canvas, r, item);
          canvas.restore();
        }
      }
      final cor2 = dest != null && !s._destinoOk ? const Color(0xFFF23F43) : azulEditor;
      canvas.drawRect(r, Paint()..color = cor2.withAlpha(50));
      canvas.drawRect(
          r,
          Paint()
            ..color = cor2
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5 / s._esc);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CenaPainter old) => true;
}
