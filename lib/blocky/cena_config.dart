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

  Widget _passo(String rotulo, int v, ValueChanged<int> mudou) => Row(children: [
        SizedBox(width: 80, child: Text(rotulo)),
        IconButton.filledTonal(onPressed: v > mapaMin ? () => mudou(v - 1) : null, icon: const Icon(Icons.remove)),
        SizedBox(width: 48, child: Center(child: Text('$v', style: const TextStyle(fontSize: 18)))),
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

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: Cores.cartao,
        title: const Text('Configurar cena'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome da cena')),
            const SizedBox(height: 14),
            const Text('Tipo de física', style: TextStyle(color: Cores.texto2)),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<Fisica>(
                segments: const [ButtonSegment(value: Fisica.plataforma, label: Text('Plataforma'), icon: Icon(Icons.directions_run)), ButtonSegment(value: Fisica.rpg, label: Text('RPG'), icon: Icon(Icons.map_outlined))],
                selected: {_fisica},
                onSelectionChanged: (s) => setState(() => _fisica = s.first),
              ),
            ),
            const SizedBox(height: 14),
            Text('Tamanho (máx. $mapaMax × $mapaMax)', style: const TextStyle(color: Cores.texto2)),
            _passo('Largura', _l, (v) => setState(() => _l = v)),
            _passo('Altura', _a, (v) => setState(() => _a = v)),
            const SizedBox(height: 10),
            const Text('Cor de fundo', style: TextStyle(color: Cores.texto2)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final k in _cores)
                GestureDetector(
                  onTap: () => setState(() => _cor = k),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: Color(k), shape: BoxShape.circle, border: Border.all(color: _cor == k ? Cores.acento : Colors.white24, width: _cor == k ? 3 : 1)),
                  ),
                ),
            ]),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: _confirmar, child: const Text('Confirmar'))],
      );
}
