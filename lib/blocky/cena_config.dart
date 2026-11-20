import 'package:flutter/material.dart';

import 'projetos.dart';
import 'widgets.dart';

const _cores = <int>[0xFF4DD0FF, 0xFF87CEEB, 0xFF9AE6B4, 0xFFFDE68A, 0xFFFCA5A5, 0xFFC4B5FD, 0xFF334155, 0xFF0F172A, 0xFFFFFFFF];

/// Config da cena: nome, tipo de fisica, tamanho (com limite) e cor de fundo.
Future<void> abrirConfigCena(BuildContext context, Cena c) => showDialog<void>(
      context: context,
      builder: (_) => _ConfigCena(c),
    );

class _ConfigCena extends StatefulWidget {
  const _ConfigCena(this.c);
  final Cena c;

  @override
  State<_ConfigCena> createState() => _ConfigCenaState();
}

class _ConfigCenaState extends State<_ConfigCena> {
  late final _nome = TextEditingController(text: widget.c.nome);
  late Fisica _fisica = widget.c.fisica;
  late int _l = widget.c.largura;
  late int _a = widget.c.altura;
  late int _cor = widget.c.corFundo;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Widget _passo(int v, ValueChanged<int> mudou) => Row(children: [
        IconButton.filledTonal(onPressed: v > mapaMin ? () => mudou(v - 1) : null, icon: const Icon(Icons.remove)),
        Expanded(child: Center(child: Text('$v', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)))),
        IconButton.filledTonal(onPressed: v < mapaMax ? () => mudou(v + 1) : null, icon: const Icon(Icons.add)),
      ]);

  void _confirmar() {
    final c = widget.c;
    c.nome = _nome.text.trim().isEmpty ? c.nome : _nome.text.trim();
    c.fisica = _fisica;
    c.largura = _l;
    c.altura = _a;
    c.corFundo = _cor;
    c.celulas.removeWhere((k, _) {
      final p = k.split(',');
      return int.parse(p[0]) >= _l || int.parse(p[1]) >= _a; // celulas fora do novo tamanho
    });
    RepositorioProjetos.instancia.salvar();
    Navigator.pop(context);
  }

  Widget _linha(String r, Widget w) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [SizedBox(width: 92, child: Text(r, style: const TextStyle(fontSize: 15))), Expanded(child: w)]));

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Cores.cartao,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            height: 56,
            color: Cores.cartao2,
            child: Row(children: [
              const SizedBox(width: 48),
              const Expanded(child: Center(child: Text('Configurar cena', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)))),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _linha('Nome', TextField(controller: _nome, textAlign: TextAlign.center, decoration: const InputDecoration(isDense: true))),
                _linha(
                  'Física',
                  SegmentedButton<Fisica>(
                    showSelectedIcon: false,
                    segments: const [ButtonSegment(value: Fisica.plataforma, label: Text('Plataforma')), ButtonSegment(value: Fisica.rpg, label: Text('RPG'))],
                    selected: {_fisica},
                    onSelectionChanged: (s) => setState(() => _fisica = s.first),
                  ),
                ),
                _linha('Largura', _passo(_l, (v) => setState(() => _l = v))),
                _linha('Altura', _passo(_a, (v) => setState(() => _a = v))),
                Padding(padding: const EdgeInsets.only(left: 92), child: Text('Máximo $mapaMax × $mapaMax', style: const TextStyle(color: Cores.texto2, fontSize: 12))),
                _linha(
                  'Fundo',
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final k in _cores)
                      GestureDetector(
                        onTap: () => setState(() => _cor = k),
                        child: AnimatedContainer(duration: const Duration(milliseconds: 150), width: 34, height: 34, decoration: BoxDecoration(color: Color(k), borderRadius: BorderRadius.circular(10), border: Border.all(color: _cor == k ? azulEditor : Colors.white24, width: _cor == k ? 3 : 1))),
                      ),
                  ]),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: double.infinity, child: BotaoPrimario(texto: 'Confirmar', aoTocar: _confirmar)),
          ),
        ]),
      );
}
