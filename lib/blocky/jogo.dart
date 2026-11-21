import 'dart:async';

import 'package:flutter/material.dart';

import 'icones.dart';
import 'package:flutter/services.dart';

import 'perfil_publico.dart';
import 'comentarios.dart';
import 'dados.dart';
import 'widgets.dart';

class JogoPagina extends StatefulWidget {
  const JogoPagina({super.key, required this.jogo});
  final Jogo jogo;

  @override
  State<JogoPagina> createState() => _JogoPaginaState();
}

class _JogoPaginaState extends State<JogoPagina> {
  bool _curtiu = false;
  bool _fav = false;
  late final ControleComentarios _cc = ControleComentarios(widget.jogo.comentarios);

  @override
  void dispose() {
    _cc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.jogo;
    return Scaffold(
      body: Column(children: [
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            Container(
              height: 340,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [j.cor1.withAlpha(180), Cores.fundo], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              child: SafeArea(
                child: Column(children: [
                  Row(children: [IconButton(icon: const Icon(Ic.voltar), onPressed: () => Navigator.pop(context)), const Spacer(), IconButton(icon: const Icon(Ic.maisHoriz), onPressed: () => emBreve(context, 'Opções'))]),
                  SizedBox(width: 130, height: 130, child: Capa(cor1: j.cor1, cor2: j.cor2, icone: j.icone, tamanhoIcone: 56, raio: 20)),
                  const SizedBox(height: 10),
                  Text(j.titulo, style: const TextStyle(fontSize: 22)),
                  Text('${abreviar(j.visitas)} visitas · ${rotuloOrientacao(j.orientacao)}', style: const TextStyle(color: Cores.texto2)),
                  const SizedBox(height: 14),
                  BotaoPrimario(pulsa: true, texto: 'Jogar', icone: Ic.play, cor: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)]), aoTocar: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => JogoPlayer(jogo: j)))),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Align(alignment: Alignment.centerLeft, child: ChipAutor(j.autor, legenda: 'criador', raio: 22)),
                const SizedBox(height: 14),
                Text(j.descricao),
                const SizedBox(height: 14),
                Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 8, children: [
                  PilulaAcao(icone: Ic.coracao, iconeAtivo: Ic.coracaoCheio, rotulo: abreviar(j.curtidas + (_curtiu ? 1 : 0)), ativo: _curtiu, cor: Colors.redAccent, aoTocar: () => setState(() => _curtiu = !_curtiu)),
                  PilulaAcao(icone: Ic.estrela, iconeAtivo: Ic.estrelaCheia, rotulo: abreviar(j.favoritos + (_fav ? 1 : 0)), ativo: _fav, cor: const Color(0xFFFBBF24), aoTocar: () => setState(() => _fav = !_fav)),
                  PilulaAcao(icone: Ic.presente, rotulo: 'Doar', aoTocar: () => emBreve(context, 'Doações')),
                ]),
                const Divider(),
                ListenableBuilder(listenable: _cc, builder: (_, __) => Text('${_cc.total} comentários', style: const TextStyle(fontSize: 18))),
                ListaComentarios(_cc),
              ]),
            ),
          ]),
        ),
        SafeArea(top: false, child: BarraComentario(_cc)),
      ]),
    );
  }
}

/// Tela de jogar: carregamento estilo Roblox, tela cheia na orientacao escolhida pelo criador, menu de saida.
/// PROVISORIO: o jogo real (engine) entra pela ponte MotorAPI; aqui e uma superficie de demonstracao.
class JogoPlayer extends StatefulWidget {
  const JogoPlayer({super.key, required this.jogo});
  final Jogo jogo;

  @override
  State<JogoPlayer> createState() => _JogoPlayerState();
}

class _JogoPlayerState extends State<JogoPlayer> {
  double _progresso = 0;
  bool _pronto = false;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(switch (widget.jogo.orientacao) {
      Orientacao.paisagem => [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
      Orientacao.retrato => [DeviceOrientation.portraitUp],
      Orientacao.qualquer => DeviceOrientation.values,
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _t = Timer.periodic(const Duration(milliseconds: 80), (t) {
      if (!mounted) return;
      setState(() {
        _progresso += 0.04;
        if (_progresso >= 1) {
          _progresso = 1;
          _pronto = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _menu() => showDialog<void>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Menu'),
          children: [
            SimpleDialogOption(onPressed: () => Navigator.pop(ctx), child: const Text('Continuar')),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Sair do jogo', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final j = widget.jogo;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _menu();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _pronto
            ? Stack(children: [
                Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [j.cor1, j.cor2], begin: Alignment.topLeft, end: Alignment.bottomRight)), child: Center(child: Icon(j.icone, size: 96, color: Colors.white54)))),
                Positioned(left: 8, top: 8, child: SafeArea(child: IconButton.filledTonal(tooltip: 'Menu', icon: const Icon(Ic.menu), onPressed: _menu))),
                const Positioned(bottom: 12, left: 0, right: 0, child: Center(child: Text('Demonstração: aqui roda o jogo (engine)', style: TextStyle(color: Colors.white70)))),
              ])
            : Container(
                decoration: BoxDecoration(gradient: LinearGradient(colors: [j.cor2, Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(j.icone, size: 64, color: Colors.white70),
                    const SizedBox(height: 12),
                    Text(j.titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    Text('@${j.autor}', style: const TextStyle(color: Cores.texto2)),
                    const SizedBox(height: 18),
                    SizedBox(width: 220, child: LinearProgressIndicator(value: _progresso, minHeight: 6, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 10),
                    const Text('Carregando…', style: TextStyle(color: Cores.texto2)),
                  ]),
                ),
              ),
      ),
    );
  }
}
