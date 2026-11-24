import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'avisos.dart';
import 'biblioteca.dart';
import 'desenho_nucleo.dart';
import 'widgets.dart';

/// Abre o fluxo de desenho: escolher nome/tamanho e depois o editor. (Ainda nao ligado a nenhuma tela.)
Future<void> abrirDesenho(BuildContext context) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NovoDesenhoTela()));

// ================================================================ novo desenho

class NovoDesenhoTela extends StatefulWidget {
  const NovoDesenhoTela({super.key});

  @override
  State<NovoDesenhoTela> createState() => _NovoDesenhoTelaState();
}

class _NovoDesenhoTelaState extends State<NovoDesenhoTela> {
  final _nome = TextEditingController();
  final _l = TextEditingController(text: '32');
  final _a = TextEditingController(text: '32');
  int? _fundo; // null = transparente
  String? _erro;

  static const _modelos = <(String, int, int)>[
    ('Ícone', 16, 16),
    ('Sprite', 32, 32),
    ('Asset', 64, 64),
    ('PFP', 128, 128),
    ('Cenário', 128, 64),
  ];
  static const _fundos = <(String, int?)>[
    ('Transparente', null),
    ('Branco', 0xFFFFFFFF),
    ('Preto', 0xFF000000),
    ('Cinza', 0xFF8E9297),
  ];
  static const int _max = 256;

  @override
  void dispose() {
    _nome.dispose();
    _l.dispose();
    _a.dispose();
    super.dispose();
  }

  void _criar() {
    final nome = _nome.text.trim();
    final l = int.tryParse(_l.text) ?? 0, a = int.tryParse(_a.text) ?? 0;
    String? erro;
    if (nome.isEmpty) {
      erro = 'Dê um nome ao desenho.';
    } else if (l < 1 || a < 1 || l > _max || a > _max) {
      erro = 'Tamanho: de 1 a $_max pixels em cada lado.';
    }
    setState(() => _erro = erro);
    if (erro != null) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => EditorDesenho(config: ConfigDesenho(nome: nome, largura: l, altura: a, fundo: _fundo))));
  }

  Widget _chip(String t, bool ativo, VoidCallback f) => Toque(
        aoTocar: f,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(color: ativo ? Cores.acento : Cores.cartao2, borderRadius: BorderRadius.circular(8)),
          child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ativo ? Colors.white : Cores.texto)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = int.tryParse(_l.text), a = int.tryParse(_a.text);
    return Scaffold(
      appBar: AppBar(title: const Text('Novo desenho')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _nome, maxLength: 40, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: 'Nome (obrigatório)', errorText: _erro != null && _nome.text.trim().isEmpty ? _erro : null)),
        const SizedBox(height: 8),
        const Text('Modelos', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final m in _modelos)
            _chip('${m.$1} ${m.$2}×${m.$3}', l == m.$2 && a == m.$3, () {
              _l.text = '${m.$2}';
              _a.text = '${m.$3}';
              setState(() {});
            }),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: TextField(controller: _l, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Largura (px)'))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('×')),
          Expanded(child: TextField(controller: _a, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Altura (px)'))),
        ]),
        if (_erro != null && !(_nome.text.trim().isEmpty)) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_erro!, style: const TextStyle(color: Cores.coral, fontSize: 12))),
        const SizedBox(height: 16),
        const Text('Fundo', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final f in _fundos) _chip(f.$1, _fundo == f.$2, () => setState(() => _fundo = f.$2))]),
        const SizedBox(height: 12),
        const Text('Tudo é desenhado aqui dentro, pixel por pixel, em camadas. Como não há imagem importada, o resultado é 100% seu e poderá ser vendido.', style: TextStyle(color: Cores.texto2, fontSize: 12)),
        const SizedBox(height: 20),
        BotaoPrimario(texto: 'Criar', aoTocar: _criar),
      ]),
    );
  }
}

// ================================================================ editor

enum Ferr { lapis, borracha, balde, linha, retangulo, elipse, gotas, selRet, varinha, mover, mao }

enum Pincel { quadrado, redondo, spray, xadrez }

const _nomesFerr = {
  Ferr.lapis: 'Pincel',
  Ferr.borracha: 'Borracha',
  Ferr.balde: 'Balde',
  Ferr.linha: 'Linha',
  Ferr.retangulo: 'Retângulo',
  Ferr.elipse: 'Elipse',
  Ferr.gotas: 'Conta-gotas',
  Ferr.selRet: 'Selecionar',
  Ferr.varinha: 'Varinha',
  Ferr.mover: 'Mover',
  Ferr.mao: 'Mão',
};

const _iconesFerr = {
  Ferr.lapis: Icons.brush_outlined,
  Ferr.borracha: Icons.auto_fix_normal_outlined,
  Ferr.balde: Icons.format_color_fill_outlined,
  Ferr.linha: Icons.show_chart_outlined,
  Ferr.retangulo: Icons.crop_square_outlined,
  Ferr.elipse: Icons.circle_outlined,
  Ferr.gotas: Icons.colorize_outlined,
  Ferr.selRet: Icons.highlight_alt_outlined,
  Ferr.varinha: Icons.auto_awesome_outlined,
  Ferr.mover: Icons.open_with_outlined,
  Ferr.mao: Icons.pan_tool_alt_outlined,
};

const _nomesPincel = {Pincel.quadrado: 'Quadrado', Pincel.redondo: 'Redondo', Pincel.spray: 'Spray', Pincel.xadrez: 'Xadrez'};

const _paleta = <int>[
  0xFF000000, 0xFF1D2B53, 0xFF7E2553, 0xFF008751, 0xFFAB5236, 0xFF5F574F, 0xFFC2C3C7, 0xFFFFF1E8,
  0xFFFF004D, 0xFFFFA300, 0xFFFFEC27, 0xFF00E436, 0xFF29ADFF, 0xFF83769C, 0xFFFF77A8, 0xFFFFCCAA,
  0xFF1D9BF0, 0xFFF97316, 0xFF23A55A, 0xFFF23F43, 0xFFF59E0B, 0xFF3A3D42, 0xFF8E9297, 0xFFFFFFFF,
];

class EditorDesenho extends StatefulWidget {
  const EditorDesenho({super.key, required this.config, this.doc, this.asset});
  final ConfigDesenho config;
  final Documento? doc; // desenho salvo sendo reaberto
  final AssetSalvo? asset;

  @override
  State<EditorDesenho> createState() => _EditorDesenhoState();
}

class _EditorDesenhoState extends State<EditorDesenho> {
  late final Documento d = widget.doc ?? Documento(widget.config);
  late String _nome = widget.doc?.config.nome ?? widget.config.nome;
  late AssetSalvo? _asset = widget.asset;
  Timer? _auto;
  bool _salvando = false;

  Ferr _ferr = Ferr.lapis;
  Pincel _pincel = Pincel.quadrado;
  int _tam = 1;
  int _cor = 0xFF1D9BF0;
  bool _cheia = false;
  bool _grade = true;
  bool _espX = false, _espY = false;
  final List<int> _recentes = [];

  // vista
  double _zoom = 8;
  Offset _off = Offset.zero;
  Size _area = Size.zero;
  bool _ajustado = false;

  // imagem composta
  ui.Image? _img;
  int _seq = 0;

  // ponteiros e gestos
  final Map<int, Offset> _ptrs = {};
  double _distAnt = 0;
  Offset _focoAnt = Offset.zero;
  bool _gesto = false;

  // traco em andamento
  bool _tracando = false;
  Uint32List? _antes;
  (int, int)? _ini;
  (int, int)? _ult;
  ({Uint32List base, List<(int, int)> levantado, Uint8List selOriginal})? _lev;
  final math.Random _rnd = math.Random();

  @override
  void initState() {
    super.initState();
    _recompor();
  }

  @override
  void dispose() {
    _auto?.cancel();
    _img?.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ utilitarios
  void _recompor() {
    final n = ++_seq;
    ui.decodeImageFromPixels(d.compor(), d.l, d.a, ui.PixelFormat.rgba8888, (img) {
      if (!mounted || n != _seq) {
        img.dispose();
        return;
      }
      final velha = _img;
      setState(() => _img = img);
      if (velha != null) WidgetsBinding.instance.addPostFrameCallback((_) => velha.dispose());
    });
  }

  void _mudou() {
    setState(() {});
    _recompor();
    _auto?.cancel();
    _auto = Timer(const Duration(seconds: 2), _salvar); // salva sozinho
  }

  Future<void> _salvar() async {
    _auto?.cancel();
    if (_salvando) {
      _auto = Timer(const Duration(seconds: 1), _salvar);
      return;
    }
    _salvando = true;
    try {
      if (_asset == null) {
        if (d.podeDesfazer) _asset = await Biblioteca.i.criar(d);
      } else {
        await Biblioteca.i.salvar(_asset!, d);
      }
    } catch (e) {
      Avisos.add(Nivel.erro, 'Salvar desenho: $e');
    } finally {
      _salvando = false;
    }
  }

  (int, int) _cel(Offset p) {
    final q = (p - _off) / _zoom;
    return (q.dx.floor(), q.dy.floor());
  }

  void _ajustar(Size s) {
    final z = (math.min(s.width / d.l, s.height / d.a) * 0.92).clamp(1.0, 60.0).toDouble();
    _zoom = z >= 2 ? z.floorToDouble() : z;
    _off = Offset((s.width - d.l * _zoom) / 2, (s.height - d.a * _zoom) / 2);
  }

  static Color _c(int v) => Color(v);

  void _usarCor(int c) {
    _cor = c;
    _recentes.remove(c);
    _recentes.insert(0, c);
    if (_recentes.length > 10) _recentes.removeLast();
  }

  // ------------------------------------------------------------ pincel
  void _carimbar(int cx, int cy, int cor) {
    final n = _tam, meio = n ~/ 2;
    for (var j = 0; j < n; j++) {
      for (var i = 0; i < n; i++) {
        final x = cx - meio + i, y = cy - meio + j;
        if (_pincel == Pincel.redondo && n > 2) {
          final dx = i - (n - 1) / 2, dy = j - (n - 1) / 2;
          if (dx * dx + dy * dy > (n / 2) * (n / 2)) continue;
        }
        if (_pincel == Pincel.spray && _rnd.nextDouble() > 0.35) continue;
        if (_pincel == Pincel.xadrez && (x + y) % 2 != 0) continue;
        d.ponto(x, y, cor, espelhoX: _espX, espelhoY: _espY);
      }
    }
  }

  int get _corAtiva => _ferr == Ferr.borracha ? 0 : _cor;

  void _tracoAte((int, int) de, (int, int) para) {
    for (final (x, y) in Documento.linha(de.$1, de.$2, para.$1, para.$2)) {
      _carimbar(x, y, _corAtiva);
    }
  }

  void _forma((int, int) a, (int, int) b) {
    final cor = _cor;
    List<(int, int)> contorno;
    switch (_ferr) {
      case Ferr.linha:
        contorno = Documento.linha(a.$1, a.$2, b.$1, b.$2);
      case Ferr.retangulo:
        contorno = Documento.contornoRetangulo(a.$1, a.$2, b.$1, b.$2);
      default:
        contorno = Documento.elipse(a.$1, a.$2, b.$1, b.$2, false);
    }
    if (_cheia && _ferr != Ferr.linha) {
      final miolo = _ferr == Ferr.retangulo ? Documento.preenchimentoRetangulo(a.$1, a.$2, b.$1, b.$2) : Documento.elipse(a.$1, a.$2, b.$1, b.$2, true);
      for (final (x, y) in miolo) {
        d.ponto(x, y, cor, espelhoX: _espX, espelhoY: _espY);
      }
    }
    for (final (x, y) in contorno) {
      _carimbar(x, y, cor);
    }
  }

  // ------------------------------------------------------------ ponteiros
  void _down(PointerDownEvent e) {
    _ptrs[e.pointer] = e.localPosition;
    if (_ptrs.length >= 2) {
      _abortarTraco();
      _gesto = true;
      _iniciarGesto();
      return;
    }
    _gesto = false;
    _comecar(e.localPosition);
  }

  void _move(PointerMoveEvent e) {
    final antes = _ptrs[e.pointer];
    if (antes == null) return;
    _ptrs[e.pointer] = e.localPosition;
    if (_ptrs.length >= 2) {
      _atualizarGesto();
      return;
    }
    if (_gesto) return;
    if (_ferr == Ferr.mao) {
      setState(() => _off += e.localPosition - antes);
      return;
    }
    _continuar(e.localPosition);
  }

  void _up(PointerEvent e) {
    final tinha = _ptrs.length;
    _ptrs.remove(e.pointer);
    if (tinha >= 2) {
      if (_ptrs.length == 1) _iniciarGesto();
      return;
    }
    if (_gesto) {
      _gesto = false;
      return;
    }
    _terminar();
  }

  void _iniciarGesto() {
    if (_ptrs.length < 2) return;
    final p = _ptrs.values.take(2).toList();
    _distAnt = (p[0] - p[1]).distance;
    _focoAnt = (p[0] + p[1]) / 2;
  }

  void _atualizarGesto() {
    final p = _ptrs.values.take(2).toList();
    final dist = (p[0] - p[1]).distance, foco = (p[0] + p[1]) / 2;
    if (_distAnt <= 0) {
      _distAnt = dist;
      _focoAnt = foco;
      return;
    }
    final z2 = (_zoom * dist / _distAnt).clamp(1.0, 80.0);
    final fator = z2 / _zoom;
    setState(() {
      _off = foco - (_focoAnt - _off) * fator;
      _zoom = z2;
    });
    _distAnt = dist;
    _focoAnt = foco;
  }

  // ------------------------------------------------------------ acoes por ferramenta
  void _comecar(Offset pos) {
    final c = _cel(pos);
    switch (_ferr) {
      case Ferr.mao:
        return;
      case Ferr.gotas:
        if (d.dentro(c.$1, c.$2)) {
          final v = d.corVisivel(c.$1, c.$2);
          if ((v >>> 24) != 0) setState(() => _usarCor(v));
        }
        return;
      case Ferr.selRet:
        _ini = c;
        _tracando = true;
        d.selecionarRetangulo(c.$1, c.$2, c.$1, c.$2);
        setState(() {});
        return;
      case Ferr.varinha:
        d.varinha(c.$1, c.$2);
        setState(() {});
        return;
      case Ferr.mover:
        if (!d.temSelecao) {
          aviso(context, 'Selecione uma área primeiro.');
          return;
        }
        if (!d.podeEditar()) return _camadaTravada();
        d.guardar();
        _lev = d.levantar();
        _ini = c;
        _tracando = true;
        return;
      default:
        break;
    }
    if (!d.podeEditar()) return _camadaTravada();
    d.guardar();
    _tracando = true;
    _antes = Uint32List.fromList(d.cam.px);
    _ini = c;
    _ult = c;
    switch (_ferr) {
      case Ferr.lapis:
      case Ferr.borracha:
        _carimbar(c.$1, c.$2, _corAtiva);
      case Ferr.balde:
        d.balde(c.$1, c.$2, _cor);
        _tracando = false;
        _usarCor(_cor);
      case Ferr.linha:
      case Ferr.retangulo:
      case Ferr.elipse:
        _forma(c, c);
      default:
        break;
    }
    _mudou();
  }

  void _camadaTravada() => aviso(context, d.cam.visivel ? 'Camada bloqueada.' : 'Camada escondida.');

  void _continuar(Offset pos) {
    if (!_tracando) return;
    final c = _cel(pos);
    switch (_ferr) {
      case Ferr.lapis:
      case Ferr.borracha:
        final u = _ult;
        if (u != null && u != c) _tracoAte(u, c);
        _ult = c;
      case Ferr.linha:
      case Ferr.retangulo:
      case Ferr.elipse:
        d.cam.px = Uint32List.fromList(_antes!);
        _forma(_ini!, c);
      case Ferr.selRet:
        d.selecionarRetangulo(_ini!.$1, _ini!.$2, c.$1, c.$2);
      case Ferr.mover:
        d.posicionar(_lev!, c.$1 - _ini!.$1, c.$2 - _ini!.$2);
      default:
        return;
    }
    _mudou();
  }

  void _terminar() {
    if (!_tracando) return;
    _tracando = false;
    if (_ferr == Ferr.lapis || _ferr == Ferr.linha || _ferr == Ferr.retangulo || _ferr == Ferr.elipse) _usarCor(_cor);
    _antes = null;
    _lev = null;
    _ini = null;
    _ult = null;
    setState(() {});
  }

  /// Um segundo dedo apareceu: o traco em andamento vira gesto de zoom, entao desfaz o que ja tinha desenhado.
  void _abortarTraco() {
    if (!_tracando) return;
    _tracando = false;
    final antes = _antes;
    if (antes != null) d.cam.px = antes;
    final lev = _lev;
    if (lev != null) {
      d.cam.px = lev.base;
      for (final (i, cor) in lev.levantado) {
        d.cam.px[i] = cor;
      }
      d.sel = lev.selOriginal;
    }
    if (_ferr != Ferr.selRet) d.descartarUltimo();
    _antes = null;
    _lev = null;
    _ini = null;
    _ult = null;
    _mudou();
  }

  // ------------------------------------------------------------ menu e paineis
  Future<void> _exportar() async {
    try {
      final f = await d.salvarPng();
      if (mounted) aviso(context, 'PNG salvo: ${f.path.split('/').last}');
    } catch (e) {
      Avisos.add(Nivel.erro, 'Exportar desenho: $e');
      if (mounted) aviso(context, 'Não consegui salvar o PNG.');
    }
  }

  Future<void> _renomear() async {
    final c = TextEditingController(text: _nome);
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nome do desenho'),
        content: TextField(controller: c, autofocus: true, maxLength: 40),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (c.text.trim().isNotEmpty) Navigator.pop(ctx, c.text.trim());
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    c.dispose();
    if (r != null) {
      d.config = ConfigDesenho(nome: r, largura: d.l, altura: d.a, fundo: d.config.fundo);
      setState(() => _nome = r);
      _mudou();
    }
  }

  void _colar() {
    if (!d.podeEditar()) return _camadaTravada();
    if (!d.colar(0, 0)) {
      aviso(context, 'Nada copiado ainda.');
      return;
    }
    _ferr = Ferr.mover;
    _mudou();
    aviso(context, 'Colado no canto. Arraste com Mover.');
  }

  void _menuTela() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Cores.cartao,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SafeArea(
          child: ListView(shrinkWrap: true, children: [
            ListTile(leading: const Icon(Icons.file_download_outlined), title: const Text('Exportar PNG'), subtitle: Text('${d.l}×${d.a} px'), onTap: () {
              Navigator.pop(ctx);
              _exportar();
            }),
            ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Renomear'), onTap: () {
              Navigator.pop(ctx);
              _renomear();
            }),
            SwitchListTile(secondary: const Icon(Icons.grid_on_outlined), title: const Text('Grade de pixels'), value: _grade, onChanged: (v) {
              setState(() => _grade = v);
              setS(() {});
            }),
            SwitchListTile(secondary: const Icon(Icons.flip_outlined), title: const Text('Espelho horizontal'), value: _espX, onChanged: (v) {
              setState(() => _espX = v);
              setS(() {});
            }),
            SwitchListTile(secondary: const Icon(Icons.flip_outlined), title: const Text('Espelho vertical'), value: _espY, onChanged: (v) {
              setState(() => _espY = v);
              setS(() {});
            }),
            ListTile(leading: const Icon(Icons.center_focus_strong_outlined), title: const Text('Centralizar vista'), onTap: () {
              Navigator.pop(ctx);
              setState(() => _ajustar(_area));
            }),
          ]),
        ),
      ),
    );
  }

  void _painelCamadas() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Cores.cartao,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          void mudar(VoidCallback f) {
            f();
            setS(() {});
            _mudou();
          }

          Widget acao(IconData i, String dica, VoidCallback? f) => IconButton(tooltip: dica, icon: Icon(i, size: 22), onPressed: f);
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Padding(padding: EdgeInsets.fromLTRB(16, 14, 16, 4), child: Align(alignment: Alignment.centerLeft, child: Text('Camadas', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)))),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  acao(Icons.add, 'Nova', () => mudar(d.novaCamada)),
                  acao(Icons.copy_outlined, 'Duplicar', () => mudar(d.duplicar)),
                  acao(Icons.arrow_upward, 'Subir', () => mudar(() => d.mover(1))),
                  acao(Icons.arrow_downward, 'Descer', () => mudar(() => d.mover(-1))),
                  acao(Icons.merge_type, 'Juntar com a de baixo', () => mudar(() {
                        if (!d.juntarAbaixo()) aviso(context, 'Não há camada abaixo.');
                      })),
                  acao(Icons.layers_clear_outlined, 'Limpar', () => mudar(d.limparCamada)),
                  acao(Icons.delete_outline, 'Apagar', () => mudar(() {
                        if (!d.apagarCamada()) aviso(context, 'É preciso ter pelo menos uma camada.');
                      })),
                ]),
                Divider(color: Cores.divisor, height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: d.camadas.length,
                    itemBuilder: (_, k) {
                      final i = d.camadas.length - 1 - k; // topo primeiro
                      final c = d.camadas[i];
                      final sel = i == d.atual;
                      return Container(
                        color: sel ? Cores.cartao2 : null,
                        child: Column(children: [
                          ListTile(
                            dense: true,
                            leading: IconButton(icon: Icon(c.visivel ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: c.visivel ? null : Cores.texto2), onPressed: () => mudar(() => c.visivel = !c.visivel)),
                            title: Text(c.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                            subtitle: Text('${(c.opac * 100).round()}%${c.bloqueada ? ' · bloqueada' : ''}', style: const TextStyle(fontSize: 12, color: Cores.texto2)),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () async {
                                final t = TextEditingController(text: c.nome);
                                final r = await showDialog<String>(
                                  context: context,
                                  builder: (dctx) => AlertDialog(
                                    title: const Text('Nome da camada'),
                                    content: TextField(controller: t, autofocus: true, maxLength: 30),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancelar')),
                                      TextButton(
                                        onPressed: () {
                                          if (t.text.trim().isNotEmpty) Navigator.pop(dctx, t.text.trim());
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                                t.dispose();
                                if (r != null) mudar(() => c.nome = r);
                              }),
                              IconButton(icon: Icon(c.bloqueada ? Icons.lock_outline : Icons.lock_open_outlined, size: 20, color: c.bloqueada ? Cores.ambar : null), onPressed: () => mudar(() => c.bloqueada = !c.bloqueada)),
                            ]),
                            onTap: () => mudar(() => d.atual = i),
                          ),
                          if (sel)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(children: [
                                const Text('Opacidade', style: TextStyle(fontSize: 12, color: Cores.texto2)),
                                Expanded(child: Slider(value: c.opac, min: 0, max: 1, onChangeStart: (_) => d.guardar(), onChanged: (v) => mudar(() => c.opac = v))),
                              ]),
                            ),
                        ]),
                      );
                    },
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  void _painelCor() {
    var a = (_cor >>> 24) & 255, r = (_cor >>> 16) & 255, g = (_cor >>> 8) & 255, b = _cor & 255;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Cores.cartao,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          int atual() => (a << 24) | (r << 16) | (g << 8) | b;
          void ajusta(void Function() f) {
            f();
            setS(() {});
            setState(() => _cor = atual());
          }

          Widget canal(String n, int v, Color cor, void Function(int) f) => Row(children: [
                SizedBox(width: 18, child: Text(n, style: const TextStyle(fontWeight: FontWeight.w700))),
                Expanded(child: Slider(value: v.toDouble(), min: 0, max: 255, activeColor: cor, onChanged: (x) => ajusta(() => f(x.round())))),
                SizedBox(width: 32, child: Text('$v', textAlign: TextAlign.right, style: const TextStyle(color: Cores.texto2, fontSize: 12))),
              ]);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: Color(atual()), borderRadius: BorderRadius.circular(8), border: Border.all(color: Cores.divisor))),
                  const SizedBox(width: 12),
                  Text('#${atual().toRadixString(16).padLeft(8, '0').toUpperCase()}', style: const TextStyle(fontFeatures: [ui.FontFeature.tabularFigures()], fontWeight: FontWeight.w600)),
                ]),
                canal('R', r, const Color(0xFFF23F43), (v) => r = v),
                canal('G', g, const Color(0xFF23A55A), (v) => g = v),
                canal('B', b, const Color(0xFF1D9BF0), (v) => b = v),
                canal('A', a, Cores.texto2, (v) => a = v),
                const SizedBox(height: 4),
                Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Pronto'))),
              ]),
            ),
          );
        },
      ),
    ).whenComplete(() => setState(() => _usarCor(_cor)));
  }

  // ------------------------------------------------------------ interface
  Widget _barraTopo() => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: _sair),
          Expanded(
            child: GestureDetector(
              onTap: _renomear,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text('${d.l}×${d.a} · ${d.cam.nome} · ${(_zoom * 100 / 8).round()}%', style: const TextStyle(fontSize: 11, color: Cores.texto2)),
              ]),
            ),
          ),
          IconButton(tooltip: 'Desfazer', icon: const Icon(Icons.undo_rounded), onPressed: d.podeDesfazer ? () {
            d.desfazer();
            _mudou();
          } : null),
          IconButton(tooltip: 'Refazer', icon: const Icon(Icons.redo_rounded), onPressed: d.podeRefazer ? () {
            d.refazer();
            _mudou();
          } : null),
          IconButton(tooltip: 'Camadas', icon: const Icon(Icons.layers_outlined), onPressed: _painelCamadas),
          IconButton(tooltip: 'Mais', icon: const Icon(Icons.more_vert_rounded), onPressed: _menuTela),
        ]),
      );

  Future<void> _sair() async {
    await _salvar();
    if (mounted) Navigator.of(context).pop();
  }

  Widget _opcoes() {
    Widget chip(String t, bool ativo, VoidCallback f) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Toque(
            aoTocar: f,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: ativo ? Cores.acento : Cores.cartao2, borderRadius: BorderRadius.circular(8)),
              child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ativo ? Colors.white : Cores.texto)),
            ),
          ),
        );
    final filhos = <Widget>[];
    if (_ferr == Ferr.lapis || _ferr == Ferr.borracha || _ferr == Ferr.linha || _ferr == Ferr.retangulo || _ferr == Ferr.elipse) {
      filhos.add(const Text('Tam. ', style: TextStyle(fontSize: 12, color: Cores.texto2)));
      filhos.add(SizedBox(width: 140, child: Slider(value: _tam.toDouble(), min: 1, max: 16, divisions: 15, label: '$_tam', onChanged: (v) => setState(() => _tam = v.round()))));
      filhos.add(Text('$_tam px  ', style: const TextStyle(fontSize: 12)));
    }
    if (_ferr == Ferr.lapis || _ferr == Ferr.borracha) {
      for (final p in Pincel.values) {
        filhos.add(chip(_nomesPincel[p]!, _pincel == p, () => setState(() => _pincel = p)));
      }
    }
    if (_ferr == Ferr.retangulo || _ferr == Ferr.elipse) {
      filhos.add(chip('Contorno', !_cheia, () => setState(() => _cheia = false)));
      filhos.add(chip('Cheio', _cheia, () => setState(() => _cheia = true)));
    }
    if (_ferr == Ferr.selRet || _ferr == Ferr.varinha || _ferr == Ferr.mover) {
      filhos.addAll([
        chip('Tudo', false, () {
          d.selecionarTudo();
          setState(() {});
        }),
        chip('Inverter', false, () {
          d.inverterSelecao();
          setState(() {});
        }),
        chip('Limpar seleção', false, () {
          d.desmarcar();
          setState(() {});
        }),
        chip('Copiar', false, () {
          d.copiar();
          aviso(context, d.area == null ? 'Nada selecionado.' : 'Copiado.');
        }),
        chip('Colar', false, _colar),
        chip('Apagar', false, () {
          if (!d.podeEditar()) return _camadaTravada();
          d.apagarSelecao();
          _mudou();
        }),
      ]);
    }
    if (_ferr == Ferr.balde) filhos.add(const Text('Toque numa área para preencher (respeita a seleção).', style: TextStyle(fontSize: 12, color: Cores.texto2)));
    if (_ferr == Ferr.gotas) filhos.add(const Text('Toque no desenho para pegar a cor.', style: TextStyle(fontSize: 12, color: Cores.texto2)));
    if (_ferr == Ferr.mao) filhos.add(const Text('Arraste para mover a vista. Com 2 dedos: zoom e mover (em qualquer ferramenta).', style: TextStyle(fontSize: 12, color: Cores.texto2)));
    return SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), children: [Row(children: filhos)]));
  }

  Widget _ferramentas() => SizedBox(
        height: 54,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 6), children: [
          for (final f in Ferr.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
              child: Tooltip(
                message: _nomesFerr[f]!,
                child: Toque(
                  aoTocar: () => setState(() => _ferr = f),
                  child: Container(
                    width: 46,
                    decoration: BoxDecoration(color: _ferr == f ? Cores.acento : Cores.cartao2, borderRadius: BorderRadius.circular(8)),
                    child: Icon(_iconesFerr[f], size: 22, color: _ferr == f ? Colors.white : Cores.texto),
                  ),
                ),
              ),
            ),
        ]),
      );

  Widget _cores() => SizedBox(
        height: 46,
        child: Row(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
            child: Toque(
              aoTocar: _painelCor,
              child: Container(width: 38, height: 38, decoration: BoxDecoration(color: _c(_cor), borderRadius: BorderRadius.circular(8), border: Border.all(color: Cores.texto2, width: 2))),
            ),
          ),
          Expanded(
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final c in [..._recentes, ..._paleta])
                Padding(
                  padding: const EdgeInsets.only(right: 4, top: 8, bottom: 8),
                  child: Toque(
                    aoTocar: () => setState(() => _cor = c),
                    child: Container(width: 30, decoration: BoxDecoration(color: _c(c), borderRadius: BorderRadius.circular(6), border: Border.all(color: c == _cor ? Cores.texto : Cores.divisor, width: c == _cor ? 2 : 1))),
                  ),
                ),
            ]),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _sair();
        },
        child: Scaffold(
          backgroundColor: Cores.fundo,
          body: SafeArea(
            child: Column(children: [
              _barraTopo(),
              Expanded(
                child: LayoutBuilder(builder: (ctx, box) {
                  if (!_ajustado || _area != box.biggest) {
                    final primeira = !_ajustado;
                    _area = box.biggest;
                    _ajustado = true;
                    if (primeira) _ajustar(box.biggest);
                  }
                  return ClipRect(
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: _down,
                      onPointerMove: _move,
                      onPointerUp: _up,
                      onPointerCancel: _up,
                      child: Container(
                        color: Cores.cartao,
                        child: CustomPaint(size: box.biggest, painter: _PintorTela(img: _img, l: d.l, a: d.a, zoom: _zoom, off: _off, grade: _grade, sel: d.sel, corGrade: Cores.texto2, corSel: Cores.acento, claro: !temaEscuro.value)),
                      ),
                    ),
                  );
                }),
              ),
              Divider(color: Cores.divisor, height: 1),
              _opcoes(),
              _ferramentas(),
              _cores(),
            ]),
          ),
        ),
      );
}

class _PintorTela extends CustomPainter {
  _PintorTela({required this.img, required this.l, required this.a, required this.zoom, required this.off, required this.grade, required this.sel, required this.corGrade, required this.corSel, required this.claro});
  final ui.Image? img;
  final int l, a;
  final double zoom;
  final Offset off;
  final bool grade;
  final Uint8List? sel;
  final Color corGrade;
  final Color corSel;
  final bool claro;

  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.translate(off.dx, off.dy);
    c.scale(zoom);
    final area = Rect.fromLTWH(0, 0, l.toDouble(), a.toDouble());
    // celulas visiveis
    final x0 = math.max(0, (-off.dx / zoom).floor()), y0 = math.max(0, (-off.dy / zoom).floor());
    final x1 = math.min(l, ((s.width - off.dx) / zoom).ceil()), y1 = math.min(a, ((s.height - off.dy) / zoom).ceil());
    // tabuleiro de transparencia
    final claroC = Paint()..color = claro ? const Color(0xFFFFFFFF) : const Color(0xFF4A4C50);
    final escuroC = Paint()..color = claro ? const Color(0xFFD5D7DB) : const Color(0xFF3A3C40);
    c.drawRect(area, claroC);
    final t = math.max(1, (8 / zoom).ceil());
    for (var y = (y0 ~/ t) * t; y < y1; y += t) {
      for (var x = (x0 ~/ t) * t; x < x1; x += t) {
        if (((x ~/ t) + (y ~/ t)) % 2 == 1) {
          c.drawRect(Rect.fromLTRB(x.toDouble(), y.toDouble(), math.min(x + t, l).toDouble(), math.min(y + t, a).toDouble()), escuroC);
        }
      }
    }
    final im = img;
    if (im != null) {
      c.drawImageRect(im, Rect.fromLTWH(0, 0, l.toDouble(), a.toDouble()), area, Paint()..filterQuality = FilterQuality.none);
    }
    if (grade && zoom >= 6) {
      final p = Paint()
        ..color = corGrade.withAlpha(60)
        ..strokeWidth = 1 / zoom;
      for (var x = x0; x <= x1; x++) {
        c.drawLine(Offset(x.toDouble(), y0.toDouble()), Offset(x.toDouble(), y1.toDouble()), p);
      }
      for (var y = y0; y <= y1; y++) {
        c.drawLine(Offset(x0.toDouble(), y.toDouble()), Offset(x1.toDouble(), y.toDouble()), p);
      }
    }
    final m = sel;
    if (m != null) {
      final fill = Paint()..color = corSel.withAlpha(45);
      final borda = Paint()
        ..color = corSel
        ..strokeWidth = 2 / zoom;
      bool tem(int x, int y) => x >= 0 && y >= 0 && x < l && y < a && m[y * l + x] != 0;
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          if (!tem(x, y)) continue;
          c.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), fill);
          if (!tem(x, y - 1)) c.drawLine(Offset(x.toDouble(), y.toDouble()), Offset(x + 1.0, y.toDouble()), borda);
          if (!tem(x, y + 1)) c.drawLine(Offset(x.toDouble(), y + 1.0), Offset(x + 1.0, y + 1.0), borda);
          if (!tem(x - 1, y)) c.drawLine(Offset(x.toDouble(), y.toDouble()), Offset(x.toDouble(), y + 1.0), borda);
          if (!tem(x + 1, y)) c.drawLine(Offset(x + 1.0, y.toDouble()), Offset(x + 1.0, y + 1.0), borda);
        }
      }
    }
    c.drawRect(area, Paint()
      ..style = PaintingStyle.stroke
      ..color = corGrade
      ..strokeWidth = 1 / zoom);
    c.restore();
  }

  @override
  bool shouldRepaint(_PintorTela o) => true;
}
