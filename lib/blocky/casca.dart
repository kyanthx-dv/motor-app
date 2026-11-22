import 'package:flutter/material.dart';

import 'icones.dart';
import 'abas.dart';
import 'criar.dart';
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

  Widget? _acao() {
    switch (_aba) {
      case 1:
        return _Acao(chave: 'loja', icone: Ic.subir, texto: 'Publicar', aoTocar: () => menuPublicar(context));
      case 2:
        return _Acao(chave: 'post', icone: Ic.lapis, texto: 'Postar', aoTocar: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NovoPostTela())));
    }
    return null;
  }

  static const _nomes = <String>['Início', 'Loja', 'Comunidade', 'Perfil'];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: FadeTransition(opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut), child: IndexedStack(index: _aba, children: const [JogosAba(), AssetsAba(), PostsAba(), PerfilAba()])),
        ),
        floatingActionButton: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
          child: _acao() ?? const SizedBox.shrink(key: ValueKey('nenhuma')),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(color: Cores.fundo, border: Border(top: BorderSide(color: Cores.divisor))),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 56,
              child: Row(children: [
                for (var i = 0; i < _icones.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _tocar(i),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(_aba == i ? _icones2[i] : _icones[i], color: _aba == i ? Cores.texto : Cores.texto2, size: 24),
                        const SizedBox(height: 2),
                        Text(_nomes[i], style: TextStyle(fontSize: 11, fontWeight: _aba == i ? FontWeight.w600 : FontWeight.w400, color: _aba == i ? Cores.texto : Cores.texto2)),
                      ]),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      );
}

class _Acao extends StatelessWidget {
  const _Acao({required this.chave, required this.icone, required this.texto, required this.aoTocar});
  final String chave;
  final IconData icone;
  final String texto;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
        key: ValueKey<String>(chave),
        onPressed: aoTocar,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: Cores.acento,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        icon: Icon(icone, size: 22),
        label: Text(texto, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}
