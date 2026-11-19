import 'package:flutter/material.dart';

import 'abas.dart';
import 'criar.dart';

/// Estrutura principal: 4 abas + botao ＋ no meio da barra de baixo.
class Casca extends StatefulWidget {
  const Casca({super.key});

  @override
  State<Casca> createState() => _CascaState();
}

class _CascaState extends State<Casca> {
  int _aba = 0; // 0 Jogos, 1 Assets, 2 Posts, 3 Perfil

  static const _icones = <IconData>[Icons.home_outlined, Icons.shopping_bag_outlined, Icons.add, Icons.public, Icons.person_outline];
  static const _icones2 = <IconData>[Icons.home, Icons.shopping_bag, Icons.add, Icons.public, Icons.person];

  void _tocar(int i) {
    if (i == 2) {
      abrirMenuCriar(context);
      return;
    }
    setState(() => _aba = i > 2 ? i - 1 : i);
  }

  @override
  Widget build(BuildContext context) {
    final ativo = _aba >= 2 ? _aba + 1 : _aba; // indice na barra
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _aba, children: const [JogosAba(), AssetsAba(), PostsAba(), PerfilAba()]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: ativo,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        onDestinationSelected: _tocar,
        destinations: [
          for (var i = 0; i < _icones.length; i++)
            if (i == 2)
              NavigationDestination(
                icon: Container(
                  width: 54,
                  height: 36,
                  decoration: BoxDecoration(color: const Color(0xFF0EA5FF), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
                label: 'Criar',
              )
            else
              NavigationDestination(icon: Icon(_icones[i]), selectedIcon: Icon(_icones2[i]), label: '$i'),
        ],
      ),
    );
  }
}
