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

  static const _itens = <(IconData, String)>[
    (Icons.sports_esports_outlined, 'Jogos'),
    (Icons.inventory_2_outlined, 'Assets'),
    (Icons.add, ''),
    (Icons.dynamic_feed_outlined, 'Posts'),
    (Icons.person_outline, 'Perfil'),
  ];

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
        onDestinationSelected: _tocar,
        destinations: [
          for (var i = 0; i < _itens.length; i++)
            if (i == 2)
              const NavigationDestination(icon: CircleAvatar(radius: 20, child: Icon(Icons.add, size: 26)), label: 'Criar')
            else
              NavigationDestination(icon: Icon(_itens[i].$1), label: _itens[i].$2),
        ],
      ),
    );
  }
}
