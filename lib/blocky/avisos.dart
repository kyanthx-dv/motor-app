import 'package:flutter/material.dart';

import 'icones.dart';
import 'widgets.dart';

enum Nivel { info, aviso, erro }

class Registro {
  Registro(this.nivel, this.texto) : hora = DateTime.now();
  final Nivel nivel;
  final String texto;
  final DateTime hora;
}

/// Painel de erros e avisos: tudo que o app registra (erros de tela, falhas, avisos) fica aqui.
class Avisos {
  static final lista = ValueNotifier<List<Registro>>([]);

  static void add(Nivel n, String texto) {
    lista.value = [Registro(n, texto), ...lista.value.take(199)];
  }

  static int get erros => lista.value.where((r) => r.nivel == Nivel.erro).length;
}

void abrirAvisos(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Cores.cartao,
    builder: (ctx) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.7,
      child: ValueListenableBuilder<List<Registro>>(
        valueListenable: Avisos.lista,
        builder: (_, itens, __) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
            child: Row(children: [
              const Expanded(child: Text('Avisos e erros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              TextButton(onPressed: itens.isEmpty ? null : () => Avisos.lista.value = [], child: const Text('Limpar')),
            ]),
          ),
          Expanded(
            child: itens.isEmpty
                ? const Center(child: Text('Nada por aqui.', style: TextStyle(color: Cores.texto2)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: itens.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final r = itens[i];
                      final cor = switch (r.nivel) { Nivel.erro => Colors.redAccent, Nivel.aviso => const Color(0xFFFBBF24), Nivel.info => Cores.texto2 };
                      final h = r.hora;
                      final hh = '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}:${h.second.toString().padLeft(2, '0')}';
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Cores.cartao2, borderRadius: BorderRadius.circular(12)),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(r.nivel == Nivel.info ? Ic.ideia : Ic.alerta, size: 20, color: cor),
                          const SizedBox(width: 10),
                          Expanded(child: Text(r.texto, maxLines: 6, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5))),
                          const SizedBox(width: 8),
                          Text(hh, style: const TextStyle(fontSize: 11, color: Cores.texto2)),
                        ]),
                      );
                    },
                  ),
          ),
        ]),
      ),
    ),
  );
}
