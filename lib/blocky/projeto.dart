import 'package:flutter/material.dart';

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
                    Text(p.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    Text('${rotuloOrientacao(p.orientacao)} · ${p.cenas.length} ${p.cenas.length == 1 ? 'cena' : 'cenas'}', style: const TextStyle(color: Cores.texto2, fontSize: 12)),
                  ]),
                ),
              ]),
            ),
            Expanded(
              child: Stack(children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                  decoration: BoxDecoration(color: const Color(0xFF64C8F0), borderRadius: BorderRadius.circular(28)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 84, 18),
                      child: Wrap(spacing: 14, runSpacing: 14, children: [
                        for (var i = 0; i < p.cenas.length; i++) Aparece(indice: i, child: _cartaoCena(p.cenas[i])),
                      ]),
                    ),
                  ),
                ),
                Positioned(
                  right: 22,
                  top: 24,
                  child: Column(children: [
                    BotaoGrosso(icone: Icons.settings, rotulo: 'Config', cor: mentaEditor, largura: 66, aoTocar: _configJogo),
                    const SizedBox(height: 8),
                    BotaoGrosso(icone: Icons.play_arrow, rotulo: 'Rodar', cor: mentaEditor, largura: 66, aoTocar: () => emBreve(context, 'Executar (engine)')),
                  ]),
                ),
              ]),
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
          height: 54,
          decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF111111), width: 2.5)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, color: Colors.black87), const SizedBox(width: 8), Text(t, style: const TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w800))]),
        ),
      );

  Widget _cartaoCena(Cena c) {
    final rpg = c.fisica == Fisica.rpg;
    return Toque(
      aoTocar: () async {
        await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CenaTela(projeto: p, cena: c)));
        if (mounted) setState(() {});
      },
      child: Container(
        width: 150,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF111111), width: 2.5)),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.black87),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(rotuloFisica(c.fisica), style: const TextStyle(fontSize: 11)),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1), decoration: BoxDecoration(color: rpg ? const Color(0xFF84CC16) : azulEditor, borderRadius: BorderRadius.circular(5)), child: const Text('Solo', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 6),
            Center(child: Text(c.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
            Text('${c.largura}×${c.altura}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black45)),
            const SizedBox(height: 6),
            Row(children: [
              if (c.inicial) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: mentaEditor, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF111111), width: 2)), child: const Text('Inicial', style: TextStyle(fontSize: 12))),
              const Spacer(),
              GestureDetector(onTap: () => _menuCena(c), child: const Icon(Icons.settings, size: 22, color: Colors.black87)),
            ]),
          ]),
        ),
      ),
    );
  }
}
