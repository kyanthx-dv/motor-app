import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'abas.dart';
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

  @override
  Widget build(BuildContext context) {
    final j = widget.jogo;
    return Scaffold(
      appBar: AppBar(title: Text(j.titulo)),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        AspectRatio(aspectRatio: 16 / 9, child: Capa(cor1: j.cor1, cor2: j.cor2, icone: j.icone, tamanhoIcone: 64)),
        const SizedBox(height: 12),
        Text(j.titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        Text('por @${j.autor}', style: const TextStyle(color: Cores.texto2)),
        const SizedBox(height: 8),
        Wrap(spacing: 14, children: [
          Estatistica(Icons.visibility_outlined, '${abreviar(j.visitas)} visitas'),
          Estatistica(Icons.thumb_up_alt_outlined, abreviar(j.curtidas + (_curtiu ? 1 : 0))),
          Estatistica(Icons.bookmark_border, abreviar(j.favoritos + (_fav ? 1 : 0))),
          Estatistica(j.orientacao == Orientacao.retrato ? Icons.stay_current_portrait : Icons.stay_current_landscape, rotuloOrientacao(j.orientacao)),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Cores.verde, foregroundColor: Colors.black),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Jogar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => JogoPlayer(jogo: j))),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () => setState(() => _curtiu = !_curtiu), icon: Icon(_curtiu ? Icons.thumb_up : Icons.thumb_up_alt_outlined), label: const Text('Curtir'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(onPressed: () => setState(() => _fav = !_fav), icon: Icon(_fav ? Icons.bookmark : Icons.bookmark_border), label: const Text('Favoritar'))),
        ]),
        const SizedBox(height: 16),
        const Text('Sobre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(j.descricao, style: const TextStyle(color: Cores.texto2)),
        const SizedBox(height: 16),
        const Text('Criadores', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(child: Text(j.autor[0].toUpperCase())), title: Text('@${j.autor}'), subtitle: const Text('Dono · equipe (Team Create) no futuro')),
        const SizedBox(height: 4),
        OutlinedButton.icon(onPressed: () => emBreve(context, 'Doações'), icon: const Icon(Icons.volunteer_activism), label: const Text('Doar ao criador')),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () => abrirComentarios(context, j.comentarios), icon: const Icon(Icons.chat_bubble_outline), label: Text('Comentários (${j.comentarios.length})')),
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
                Positioned(left: 8, top: 8, child: SafeArea(child: IconButton.filledTonal(tooltip: 'Menu', icon: const Icon(Icons.menu), onPressed: _menu))),
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
