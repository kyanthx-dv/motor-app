import 'package:flutter/material.dart';

import 'dados.dart';
import 'icones.dart';
import 'widgets.dart';

/// Comentario com respostas aninhadas.
class Cm {
  Cm(this.autor, this.texto);
  final String autor;
  final String texto;
  final List<Cm> resp = [];
}

/// Estado dos comentarios de uma pagina (lista, alvo da resposta, campo).
class ControleComentarios extends ChangeNotifier {
  ControleComentarios(List<Comentario> base) : itens = [for (final c in base) Cm(c.autor, c.texto)];
  final List<Cm> itens;
  final foco = FocusNode();
  final campo = TextEditingController();
  Cm? alvo;

  int get total => itens.fold(0, (s, c) => s + _conta(c));
  int _conta(Cm c) => 1 + c.resp.fold(0, (s, r) => s + _conta(r));

  void responder(Cm? c) {
    alvo = c;
    notifyListeners();
    if (c != null) foco.requestFocus();
  }

  void enviar() {
    final t = campo.text.trim();
    if (t.isEmpty) return;
    (alvo?.resp ?? itens).add(Cm('você', t));
    alvo = null;
    campo.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    foco.dispose();
    campo.dispose();
    super.dispose();
  }
}

class ListaComentarios extends StatelessWidget {
  const ListaComentarios(this.c, {super.key});
  final ControleComentarios c;

  Widget _linha(Cm m, int nivel) => Padding(
        padding: EdgeInsets.only(left: nivel == 0 ? 0 : 40.0, top: 6, bottom: 2),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(radius: nivel == 0 ? 18 : 14, child: Text(m.autor[0].toUpperCase())),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.autor, style: const TextStyle(color: Cores.texto2, fontSize: 13)),
                Text(m.texto, style: const TextStyle(fontSize: 15)),
                Toque(
                  aoTocar: () => c.responder(m),
                  child: const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Responder', style: TextStyle(color: Cores.texto2, fontSize: 12.5, fontWeight: FontWeight.w700))),
                ),
              ]),
            ),
          ]),
          for (final r in m.resp) _linha(r, 1),
        ]),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: c,
        builder: (_, __) => AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (c.itens.isEmpty) const Padding(padding: EdgeInsets.all(28), child: Center(child: Text('Vazio', style: TextStyle(color: Cores.texto2)))),
            for (final m in c.itens) _linha(m, 0),
          ]),
        ),
      );
}

/// Campo fixo de comentar, com "Respondendo a ...".
class BarraComentario extends StatelessWidget {
  const BarraComentario(this.c, {super.key});
  final ControleComentarios c;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: c,
        builder: (_, __) => Column(mainAxisSize: MainAxisSize.min, children: [
          if (c.alvo != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
              color: Cores.cartao2,
              child: Row(children: [
                Icon(Ic.responder, size: 16, color: Cores.texto2),
                const SizedBox(width: 8),
                Expanded(child: Text('Respondendo a ${c.alvo!.autor}', style: const TextStyle(fontSize: 13, color: Cores.texto2))),
                IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Ic.fechar, size: 18), onPressed: () => c.responder(null)),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(children: [
              Expanded(child: TextField(controller: c.campo, focusNode: c.foco, decoration: InputDecoration(hintText: c.alvo == null ? 'Comentar…' : 'Responder…'))),
              const SizedBox(width: 8),
              FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(72, 48)), onPressed: c.enviar, child: const Text('Enviar')),
            ]),
          ),
        ]),
      );
}

/// Janela de comentarios (usada nos cartoes e no video).
void abrirComentarios(BuildContext context, List<Comentario> lista) {
  final c = ControleComentarios(lista);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Cores.cartao,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 4), child: ListenableBuilder(listenable: c, builder: (_, __) => Text('${c.total} comentários', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)))),
          Flexible(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 16), child: ListaComentarios(c))),
          SafeArea(top: false, child: BarraComentario(c)),
        ]),
      ),
    ),
  ).whenComplete(c.dispose);
}
