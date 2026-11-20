import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cena_config.dart';
import 'dados.dart';
import 'mapa.dart';
import 'projetos.dart';
import 'widgets.dart';

/// Pede so o nome e cria o projeto com o inicial (uma cena de plataforma). Abre o projeto.
Future<void> novoJogo(BuildContext context) async {
  final ctl = TextEditingController();
  final nome = await showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: Cores.cartao,
        title: const Text('Novo jogo'),
        content: TextField(controller: ctl, autofocus: true, maxLength: 40, onChanged: (_) => setS(() {}), decoration: const InputDecoration(labelText: 'Nome do jogo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: ctl.text.trim().isEmpty ? null : () => Navigator.pop(ctx, ctl.text.trim()), child: const Text('Criar')),
        ],
      ),
    ),
  );
  ctl.dispose();
  if (nome == null || !context.mounted) return;
  final p = RepositorioProjetos.instancia.criar(nome);
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ProjetoTela(projeto: p)));
}

/// Tela inicial do projeto: cenas (mapas), config do jogo, executar, publicar.
class ProjetoTela extends StatefulWidget {
  const ProjetoTela({super.key, required this.projeto});
  final Projeto projeto;

  @override
  State<ProjetoTela> createState() => _ProjetoTelaState();
}

class _ProjetoTelaState extends State<ProjetoTela> {
  Projeto get p => widget.projeto;
  final _cam = TransformationController();
  static const double _tab = 3000; // tamanho do tabuleiro
  static const double _cw = 118; // largura do cartao
  Cena? _movendo;
  Offset _iniPos = Offset.zero;

  @override
  void initState() {
    super.initState();
    _posicionar();
  }

  @override
  void dispose() {
    _cam.dispose();
    super.dispose();
  }

  /// Cenas sem posicao entram em grade, perto do centro do tabuleiro.
  void _posicionar() {
    var n = 0;
    for (final c in p.cenas) {
      if (c.px < 0) {
        c.px = _tab / 2 - 200 + (n % 3) * (_cw + 24);
        c.py = _tab / 2 - 120 + (n ~/ 3) * 110;
      }
      n++;
    }
  }

  bool _centrou = false;
  void _centrar(Size v) {
    if (_centrou || p.cenas.isEmpty) return;
    _centrou = true;
    final c = p.cenas.first;
    _cam.value = Matrix4.identity()..translate(-(c.px - 20), -(c.py - 20));
  }

  void _mudou() {
    RepositorioProjetos.instancia.salvar();
    setState(() {});
  }

  Future<void> _novaCena() async {
    final f = await showModalBottomSheet<Fisica>(
      context: context,
      backgroundColor: Cores.cartao,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Nova cena', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(children: [
              _tipo(ctx, Fisica.plataforma, Icons.directions_run, const Color(0xFF38BDF8), 'Plataforma', 'Gravidade, pulo, vista lateral'),
              const SizedBox(width: 12),
              _tipo(ctx, Fisica.rpg, Icons.map_outlined, const Color(0xFF84CC16), 'RPG', 'Vista de cima, 4 direções'),
            ]),
          ]),
        ),
      ),
    );
    if (f == null) return;
    final c = Cena(nome: 'Cena ${p.cenas.length + 1}', fisica: f, corFundo: f == Fisica.rpg ? 0xFF9AE6B4 : 0xFF4DD0FF);
    c.px = _tab / 2 - 200 + (p.cenas.length % 3) * (_cw + 24);
    c.py = _tab / 2 - 120 + (p.cenas.length ~/ 3) * 110;
    p.cenas.add(c);
    _mudou();
    if (mounted) await abrirConfigCena(context, c);
    _mudou();
  }

  Widget _tipo(BuildContext ctx, Fisica f, IconData i, Color cor, String nome, String desc) => Expanded(
        child: Toque(
          aoTocar: () => Navigator.pop(ctx, f),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: cor.withAlpha(40), borderRadius: BorderRadius.circular(16), border: Border.all(color: cor, width: 2)),
            child: Column(children: [Icon(i, color: cor, size: 44), const SizedBox(height: 8), Text(nome, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Cores.texto2, fontSize: 12))]),
          ),
        ),
      );

  Future<void> _menuCena(Cena c) async {
    final a = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Cores.cartao,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.flag_outlined), title: const Text('Definir como cena inicial'), onTap: () => Navigator.pop(ctx, 'ini')),
          ListTile(leading: const Icon(Icons.tune), title: const Text('Configurar'), onTap: () => Navigator.pop(ctx, 'cfg')),
          ListTile(leading: const Icon(Icons.copy), title: const Text('Copiar'), onTap: () => Navigator.pop(ctx, 'cp')),
          ListTile(leading: const Icon(Icons.delete_outline, color: Colors.redAccent), title: const Text('Excluir', style: TextStyle(color: Colors.redAccent)), onTap: () => Navigator.pop(ctx, 'del')),
        ]),
      ),
    );
    switch (a) {
      case 'ini':
        for (final x in p.cenas) {
          x.inicial = x == c;
        }
      case 'cfg':
        await abrirConfigCena(context, c);
      case 'cp':
        p.cenas.insert(p.cenas.indexOf(c) + 1, c.copia());
      case 'del':
        if (p.cenas.length <= 1) {
          if (mounted) aviso(context, 'O jogo precisa de pelo menos uma cena.');
          return;
        }
        p.cenas.remove(c);
        if (!p.cenas.any((x) => x.inicial)) p.cenas.first.inicial = true;
    }
    _mudou();
  }

  Future<void> _configJogo() async {
    final nome = TextEditingController(text: p.nome);
    var ori = p.orientacao == Orientacao.retrato ? Orientacao.retrato : Orientacao.paisagem;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Cores.cartao,
          title: const Text('Configurações do jogo'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome')),
            const SizedBox(height: 14),
            const Text('Orientação da tela', style: TextStyle(color: Cores.texto2)),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<Orientacao>(
                segments: const [ButtonSegment(value: Orientacao.paisagem, label: Text('Horizontal'), icon: Icon(Icons.stay_current_landscape)), ButtonSegment(value: Orientacao.retrato, label: Text('Vertical'), icon: Icon(Icons.stay_current_portrait))],
                selected: {ori},
                onSelectionChanged: (s) => setS(() => ori = s.first),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (nome.text.trim().isNotEmpty) p.nome = nome.text.trim();
                p.orientacao = ori;
                Navigator.pop(ctx);
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
    nome.dispose();
    _mudou();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
              child: Row(children: [
                BotaoGrosso(icone: Icons.arrow_back, cor: mentaEditor, aoTocar: () => Navigator.pop(context)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('${rotuloOrientacao(p.orientacao)} · ${p.cenas.length} ${p.cenas.length == 1 ? 'cena' : 'cenas'}', style: const TextStyle(color: Cores.texto2, fontSize: 12)),
                  ]),
                ),
              ]),
            ),
            Expanded(
              child: LayoutBuilder(builder: (ctx, box) {
                _centrar(box.biggest);
                return Stack(children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                  decoration: BoxDecoration(color: const Color(0xFF64C8F0), borderRadius: BorderRadius.circular(24)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: InteractiveViewer(
                      transformationController: _cam,
                      constrained: false,
                      minScale: 0.4,
                      maxScale: 2,
                      boundaryMargin: const EdgeInsets.all(400),
                      child: SizedBox(
                        width: _tab,
                        height: _tab,
                        child: Stack(children: [
                          Positioned.fill(child: CustomPaint(painter: _PontosPainter())),
                          for (final c in p.cenas) Positioned(left: c.px, top: c.py, child: _cartaoCena(c)),
                        ]),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 22,
                  top: 16,
                  child: Column(children: [
                    BotaoGrosso(icone: Icons.settings, rotulo: 'Config', cor: mentaEditor, largura: 56, aoTocar: _configJogo),
                    const SizedBox(height: 8),
                    BotaoGrosso(icone: Icons.play_arrow, rotulo: 'Rodar', cor: mentaEditor, largura: 56, aoTocar: () => emBreve(context, 'Executar (engine)')),
                  ]),
                ),
              ]);
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
              child: Row(children: [
                Expanded(child: _grande(Icons.upload, 'Publicar', azulEditor, () => emBreve(context, 'Publicar'))),
                const SizedBox(width: 12),
                Expanded(child: _grande(Icons.add_location_alt, 'Nova cena', mentaEditor, _novaCena)),
              ]),
            ),
          ]),
        ),
      );

  Widget _grande(IconData i, String t, Color cor, VoidCallback f) => Toque(
        aoTocar: f,
        child: Container(
          height: 44,
          decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFF111111), width: 2)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, color: Colors.black87, size: 20), const SizedBox(width: 6), Text(t, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w800))]),
        ),
      );

  Widget _cartaoCena(Cena c) {
    final rpg = c.fisica == Fisica.rpg;
    final erguido = _movendo == c;
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CenaTela(projeto: p, cena: c)));
        if (mounted) setState(() {});
      },
      // segurar e arrastar move o cartao; arrastar direto move o tabuleiro
      onLongPressStart: (_) {
        HapticFeedback.mediumImpact();
        setState(() {
          _movendo = c;
          _iniPos = Offset(c.px, c.py);
        });
      },
      onLongPressMoveUpdate: (d) {
        final esc = _cam.value.getMaxScaleOnAxis();
        setState(() {
          c.px = (_iniPos.dx + d.offsetFromOrigin.dx / esc).clamp(0, _tab - _cw);
          c.py = (_iniPos.dy + d.offsetFromOrigin.dy / esc).clamp(0, _tab - 100);
        });
      },
      onLongPressEnd: (_) {
        setState(() => _movendo = null);
        RepositorioProjetos.instancia.salvar();
      },
      child: AnimatedScale(
        scale: erguido ? 1.06 : 1,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: _cw,
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: const Color(0xFF111111), width: 2),
            boxShadow: erguido ? const [BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 6))] : null,
          ),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.black87),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(rotuloFisica(c.fisica), style: const TextStyle(fontSize: 10)),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: rpg ? const Color(0xFF84CC16) : azulEditor, borderRadius: BorderRadius.circular(4)), child: const Text('Solo', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 4),
              Center(child: Text(c.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
              Center(child: Text('${c.largura}×${c.altura}', style: const TextStyle(fontSize: 10, color: Colors.black45))),
              const SizedBox(height: 4),
              Row(children: [
                if (c.inicial) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: mentaEditor, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF111111), width: 1.5)), child: const Text('Inicial', style: TextStyle(fontSize: 10.5))),
                const Spacer(),
                GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _menuCena(c), child: const Padding(padding: EdgeInsets.all(2), child: Icon(Icons.settings, size: 18, color: Colors.black87))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PontosPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withAlpha(70);
    for (double x = 0; x < size.width; x += 40) {
      for (double y = 0; y < size.height; y += 40) {
        canvas.drawCircle(Offset(x, y), 1.6, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PontosPainter old) => false;
}
