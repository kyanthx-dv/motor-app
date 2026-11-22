import 'package:flutter/material.dart';

import 'icones.dart';
import 'abas.dart';
import 'criar.dart';
import 'projeto.dart';
import 'widgets.dart';

/// Estrutura principal: 4 abas + botao "+" central (Jogo, Assets, Post).
class Casca extends StatefulWidget {
  const Casca({super.key});

  @override
  State<Casca> createState() => _CascaState();
}

class _CascaState extends State<Casca> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 260), value: 1);
  int _aba = 0; // 0 Inicio, 1 Loja, 2 Comunidade, 3 Perfil

  static const _icones = <IconData>[Ic.casa, Ic.loja, Ic.comunidade, Ic.usuario];
  static const _icones2 = <IconData>[Ic.casaCheia, Ic.lojaCheia, Ic.comunidadeCheia, Ic.usuarioCheio];

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _tocar(int n) {
    if (n != _aba) _fade.forward(from: 0);
    setState(() => _aba = n);
  }

  void _criar() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      barrierColor: const Color(0xF2141414),
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (c, a, _, child) => FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
      pageBuilder: (ctx, _, __) {
        Widget item(IconData i, Color cor, String t, VoidCallback f) => Toque(
              aoTocar: () {
                Navigator.pop(ctx);
                f();
              },
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 64, height: 64, decoration: const BoxDecoration(color: Color(0xFF232426), shape: BoxShape.circle), child: Icon(i, size: 28, color: cor)),
                const SizedBox(height: 8),
                Text(t, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, decoration: TextDecoration.none)),
              ]),
            );
        return Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                item(Ic.controle, Cores.acento, 'Jogo', () => novoJogo(context)),
                item(Ic.pacote, Cores.ambar, 'Assets', () => menuPublicar(context)),
                item(Ic.lapis, Cores.coral, 'Post', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NovoPostTela()))),
              ]),
              const SizedBox(height: 36),
              Toque(aoTocar: () => Navigator.pop(ctx), child: Container(width: 46, height: 38, decoration: BoxDecoration(color: Cores.coral, borderRadius: BorderRadius.circular(10)), child: const Icon(Ic.fechar, color: Colors.white, size: 22))),
              const SizedBox(height: 24),
            ]),
          ),
        );
      },
    );
  }

  Widget _botao(int i) => Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _tocar(i),
          child: Center(child: AnimatedScale(scale: _aba == i ? 1.06 : 1, duration: const Duration(milliseconds: 160), child: Icon(_aba == i ? _icones2[i] : _icones[i], color: _aba == i ? Cores.texto : Cores.texto2, size: 25))),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: FadeTransition(opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut), child: IndexedStack(index: _aba, children: const [JogosAba(), AssetsAba(), PostsAba(), PerfilAba()])),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(color: Cores.fundo, border: Border(top: BorderSide(color: Cores.divisor))),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 54,
              child: Row(children: [
                _botao(0),
                _botao(1),
                Expanded(
                  child: Center(
                    child: Toque(aoTocar: _criar, child: Container(width: 48, height: 34, decoration: BoxDecoration(color: Cores.acento, borderRadius: BorderRadius.circular(10)), child: const Icon(Ic.mais, color: Colors.white, size: 22))),
                  ),
                ),
                _botao(2),
                _botao(3),
              ]),
            ),
          ),
        ),
      );
}

