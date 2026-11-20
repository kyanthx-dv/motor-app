import 'package:flutter/material.dart';

import 'abas.dart';
import 'criar.dart';
import 'widgets.dart';

/// Estrutura principal: 4 abas + botao ＋ no meio da barra de baixo.
class Casca extends StatefulWidget {
  const Casca({super.key});

  @override
  State<Casca> createState() => _CascaState();
}

class _CascaState extends State<Casca> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 260), value: 1);

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  int _aba = 0; // 0 Jogos, 1 Assets, 2 Posts, 3 Perfil

  static const _icones = <IconData>[Icons.home_outlined, Icons.shopping_bag_outlined, Icons.add, Icons.public, Icons.person_outline];
  static const _icones2 = <IconData>[Icons.home, Icons.shopping_bag, Icons.add, Icons.public, Icons.person];

  void _tocar(int i) {
    if (i == 2) {
      abrirMenuCriar(context);
      return;
    }
    final n = i > 2 ? i - 1 : i;
    if (n != _aba) _fade.forward(from: 0);
    setState(() => _aba = n);
  }

  @override
  Widget build(BuildContext context) {
    final ativo = _aba >= 2 ? _aba + 1 : _aba; // indice na barra
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut), child: IndexedStack(index: _aba, children: const [JogosAba(), AssetsAba(), PostsAba(), PerfilAba()])),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          height: 64,
          decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withAlpha(temaEscuro.value ? 120 : 30), blurRadius: 20, offset: const Offset(0, 6))]),
          child: Row(children: [
            for (var i = 0; i < _icones.length; i++)
              Expanded(
                child: i == 2
                    ? Toque(
                        aoTocar: () => _tocar(2),
                        child: Center(child: Container(width: 52, height: 40, decoration: BoxDecoration(gradient: degradeMarca, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Cores.acento.withAlpha(90), blurRadius: 12, offset: const Offset(0, 4))]), child: const Icon(Icons.add, color: Colors.white, size: 28))),
                      )
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _tocar(i),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(color: ativo == i ? Cores.acento.withAlpha(45) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
                            child: Icon(ativo == i ? _icones2[i] : _icones[i], color: ativo == i ? Cores.acento : Cores.texto2, size: 26),
                          ),
                        ),
                      ),
              ),
          ]),
        ),
      ),
    );
  }
}
