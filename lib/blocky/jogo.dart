import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'perfil_publico.dart';
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
  final _campo = TextEditingController();
  late final List<Comentario> _coments = List.of(widget.jogo.comentarios);

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  Widget _acao(IconData i, String n, VoidCallback f, {Color? cor}) => InkWell(
        onTap: f,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          child: Column(children: [Icon(i, size: 34, color: cor), const SizedBox(height: 2), Text(n, style: const TextStyle(color: Cores.texto2))]),
        ),
      );

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
                  Row(children: [IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)), const Spacer(), IconButton(icon: const Icon(Icons.more_horiz), onPressed: () => emBreve(context, 'Opções'))]),
                  SizedBox(width: 130, height: 130, child: Capa(cor1: j.cor1, cor2: j.cor2, icone: j.icone, tamanhoIcone: 56, raio: 20)),
                  const SizedBox(height: 10),
                  Text(j.titulo, style: const TextStyle(fontSize: 22)),
                  Text('${abreviar(j.visitas)} visitas · ${rotuloOrientacao(j.orientacao)}', style: const TextStyle(color: Cores.texto2)),
                  const SizedBox(height: 14),
                  BotaoPrimario(texto: 'Jogar', icone: Icons.play_arrow_rounded, cor: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)]), aoTocar: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => JogoPlayer(jogo: j)))),
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
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _acao(_curtiu ? Icons.favorite : Icons.favorite_border, abreviar(j.curtidas + (_curtiu ? 1 : 0)), () => setState(() => _curtiu = !_curtiu), cor: _curtiu ? Colors.redAccent : null),
                  _acao(_fav ? Icons.star : Icons.star_border, abreviar(j.favoritos + (_fav ? 1 : 0)), () => setState(() => _fav = !_fav), cor: _fav ? const Color(0xFFFBBF24) : null),
                  _acao(Icons.volunteer_activism_outlined, 'Doar', () => emBreve(context, 'Doações')),
                ]),
                const Divider(),
                Text('${_coments.length} comentários', style: const TextStyle(fontSize: 18)),
                if (_coments.isEmpty) const Padding(padding: EdgeInsets.all(28), child: Center(child: Text('Vazio', style: TextStyle(color: Cores.texto2)))),
                for (final c in _coments) ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(radius: 18, child: Text(c.autor[0].toUpperCase())), title: Text(c.autor, style: const TextStyle(color: Cores.texto2, fontSize: 13)), subtitle: Text(c.texto, style: const TextStyle(fontSize: 15))),
              ]),
            ),
          ]),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), // o Scaffold ja sobe com o teclado
            child: Row(children: [
              Expanded(child: TextField(controller: _campo, decoration: const InputDecoration(hintText: 'Comentar…'))),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(72, 48)),
                onPressed: () {
                  final t = _campo.text.trim();
                  if (t.isEmpty) return;
                  setState(() => _coments.add(Comentario('você', t)));
                  _campo.clear();
                },
                child: const Text('Enviar'),
              ),
            ]),
          ),
        ),
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
