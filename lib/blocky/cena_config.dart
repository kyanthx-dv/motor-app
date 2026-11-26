import 'package:flutter/material.dart';

import 'icones.dart';
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
  late ModoCamera _modo = widget.c.camera.modo;
  late double _zoom = widget.c.camera.zoom;
  late int _fx = widget.c.camera.fx ?? widget.c.largura ~/ 2;
  late int _fy = widget.c.camera.fy ?? widget.c.altura ~/ 2;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Widget _passo(int v, ValueChanged<int> mudou) => Row(children: [
        IconButton.filledTonal(onPressed: v > mapaMin ? () => mudou(v - 1) : null, icon: const Icon(Ic.menos)),
        Expanded(child: Center(child: Text('$v', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)))),
        IconButton.filledTonal(onPressed: v < mapaMax ? () => mudou(v + 1) : null, icon: const Icon(Ic.mais)),
      ]);

  static const _nomesModo = <ModoCamera, (String, String)>{
    ModoCamera.fixo: ('Fixo', 'Parada numa posição da cena.'),
    ModoCamera.arrastar: ('Arrastar', 'O jogador arrasta o dedo para mover a câmera.'),
    ModoCamera.seguir: ('Seguir', 'Acompanha o ator principal, sem limites.'),
    ModoCamera.restrito: ('Restrito', 'Acompanha o ator principal e fica dentro do mapa.'),
  };

  Widget _passoLivre(int v, int min, int max, ValueChanged<int> mudou) => Row(children: [
        IconButton.filledTonal(onPressed: v > min ? () => mudou(v - 1) : null, icon: const Icon(Ic.menos)),
        Expanded(child: Center(child: Text('$v', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)))),
        IconButton.filledTonal(onPressed: v < max ? () => mudou(v + 1) : null, icon: const Icon(Ic.mais)),
      ]);

  void _confirmar() {
    final c = widget.c;
    c.nome = _nome.text.trim().isEmpty ? c.nome : _nome.text.trim();
    c.fisica = _fisica;
    c.largura = _l;
    c.altura = _a;
    c.corFundo = _cor;
    final cam = c.camera;
    cam.modo = _modo;
    cam.zoom = _zoom;
    cam.fx = _modo == ModoCamera.fixo ? _fx.clamp(0, _l - 1).toInt() : null; // posicao so vale no modo Fixo
    cam.fy = _modo == ModoCamera.fixo ? _fy.clamp(0, _a - 1).toInt() : null;
    cam.lim = null; // limites proprios: em breve (por enquanto o mapa inteiro)
    c.objetos.removeWhere((o) => o.x >= _l || o.y >= _a); // objetos fora do novo tamanho
    final at = c.ator;
    if (at != null) {
      at.x = at.x.clamp(0, _l - 1).toInt();
      at.y = at.y.clamp(0, _a - 1).toInt();
      if (at.objetoId != null && !c.objetos.any((o) => o.id == at.objetoId)) at.objetoId = null; // ator removido pelo novo tamanho
    }
    for (final o in c.objetos) {
      o.w = o.w.clamp(1, _l - o.x).toInt();
      o.h = o.h.clamp(1, _a - o.y).toInt();
    }
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
              IconButton(icon: const Icon(Ic.fechar), onPressed: () => Navigator.pop(context)),
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
                const Padding(padding: EdgeInsets.fromLTRB(0, 14, 0, 4), child: Text('CÂMERA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Cores.texto2))),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final m in ModoCamera.values)
                    ChoiceChip(
                      label: Text(_nomesModo[m]!.$1),
                      selected: _modo == m,
                      onSelected: (_) => setState(() => _modo = m),
                    ),
                ]),
                Padding(padding: const EdgeInsets.only(top: 6), child: Text(_nomesModo[_modo]!.$2, style: const TextStyle(color: Cores.texto2, fontSize: 12))),
                _linha('Zoom', Row(children: [
                  Expanded(child: Slider(value: _zoom, min: 0.5, max: 3, divisions: 25, onChanged: (v) => setState(() => _zoom = double.parse(v.toStringAsFixed(1))))),
                  SizedBox(width: 40, child: Text('${_zoom.toStringAsFixed(1)}x', style: const TextStyle(fontWeight: FontWeight.w700))),
                ])),
                if (_modo == ModoCamera.fixo) ...[
                  _linha('Posição X', _passoLivre(_fx, 0, _l - 1, (v) => setState(() => _fx = v))),
                  _linha('Posição Y', _passoLivre(_fy, 0, _a - 1, (v) => setState(() => _fy = v))),
                ],
                if (_modo == ModoCamera.seguir || _modo == ModoCamera.restrito)
                  const Text('Sem ator principal na cena, a câmera fica parada no centro (a cena continua válida).', style: TextStyle(color: Cores.texto2, fontSize: 12)),
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
