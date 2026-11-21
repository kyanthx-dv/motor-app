import 'package:flutter/material.dart';

import 'icones.dart';
import 'abas.dart';
import 'criar.dart';
import 'projeto.dart';
import 'widgets.dart';

/// Estrutura principal: 4 abas. Criar nao tem botao fixo: cada aba tem sua acao no lugar onde faz sentido
/// (Loja: publicar; Comunidade: postar; Perfil: novo jogo; Inicio: "Seus projetos").
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
      case 3:
        return _Acao(chave: 'jogo', icone: Ic.mais, texto: 'Novo jogo', aoTocar: () => novoJogo(context));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: FadeTransition(opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut), child: IndexedStack(index: _aba, children: const [JogosAba(), AssetsAba(), PostsAba(), PerfilAba()])),
        ),
        floatingActionButton: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: FadeTransition(opacity: a, child: c)),
          child: _acao() ?? const SizedBox.shrink(key: ValueKey('nenhuma')),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            height: 60,
            decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withAlpha(temaEscuro.value ? 100 : 25), blurRadius: 18, offset: const Offset(0, 5))]),
            child: Row(children: [
              for (var i = 0; i < _icones.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _tocar(i),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      AnimatedScale(scale: _aba == i ? 1.08 : 1, duration: const Duration(milliseconds: 200), curve: Curves.easeOutBack, child: Icon(_aba == i ? _icones2[i] : _icones[i], color: _aba == i ? Cores.acento : Cores.texto2, size: 25)),
                      const SizedBox(height: 4),
                      AnimatedContainer(duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic, width: _aba == i ? 14 : 0, height: 3, decoration: BoxDecoration(color: Cores.acento, borderRadius: BorderRadius.circular(2))),
                    ]),
                  ),
                ),
            ]),
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
        elevation: 2,
        backgroundColor: Cores.acento,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: Icon(icone, size: 22),
        label: Text(texto, style: const TextStyle(fontWeight: FontWeight.w800)),
      );
}
