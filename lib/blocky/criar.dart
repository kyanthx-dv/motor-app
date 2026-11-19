import 'package:flutter/material.dart';

import 'dados.dart';
import 'editor_web.dart';
import 'widgets.dart';

void abrirMenuCriar(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Cores.cartao,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(padding: EdgeInsets.all(14), child: Text('Criar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        ListTile(
          leading: const Icon(Icons.sports_esports),
          title: const Text('Criar jogo'),
          subtitle: const Text('Abre o editor (provisório)'),
          onTap: () {
            Navigator.pop(ctx);
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EditorWebTela()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.article_outlined),
          title: const Text('Criar post'),
          onTap: () {
            Navigator.pop(ctx);
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NovoPostTela()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.inventory_2_outlined),
          title: const Text('Publicar asset'),
          onTap: () {
            Navigator.pop(ctx);
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NovoItemTela(pfp: false)));
          },
        ),
        ListTile(
          leading: const Icon(Icons.face),
          title: const Text('Publicar PFP'),
          onTap: () {
            Navigator.pop(ctx);
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NovoItemTela(pfp: true)));
          },
        ),
      ]),
    ),
  );
}

class NovoPostTela extends StatefulWidget {
  const NovoPostTela({super.key});

  @override
  State<NovoPostTela> createState() => _NovoPostTelaState();
}

class _NovoPostTelaState extends State<NovoPostTela> {
  final _titulo = TextEditingController();
  final _desc = TextEditingController();
  bool _video = false;
  bool _midia = false;

  @override
  void dispose() {
    _titulo.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _publicar() {
    if (!_midia) return aviso(context, 'Escolha uma imagem ou vídeo.');
    if (_titulo.text.trim().isEmpty) return aviso(context, 'Escreva um título.');
    if (_desc.text.trim().isEmpty) return aviso(context, 'Escreva uma descrição.');
    Navigator.pop(context);
    emBreve(context, 'Publicar post');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Novo post')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _midia = true),
              child: Container(
                decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(14)),
                child: Center(
                  child: _midia
                      ? Column(mainAxisSize: MainAxisSize.min, children: [Icon(_video ? Icons.videocam : Icons.image, size: 44, color: Cores.verde), Text(_video ? 'Vídeo (exemplo)' : 'Imagem (exemplo)')])
                      : const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_photo_alternate_outlined, size: 44), Text('Toque para escolher imagem ou vídeo (obrigatório)')]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [ButtonSegment(value: false, label: Text('Imagem'), icon: Icon(Icons.image)), ButtonSegment(value: true, label: Text('Vídeo'), icon: Icon(Icons.videocam))],
            selected: {_video},
            onSelectionChanged: (s) => setState(() => _video = s.first),
          ),
          const SizedBox(height: 14),
          TextField(controller: _titulo, maxLength: 80, decoration: const InputDecoration(labelText: 'Título')),
          const SizedBox(height: 8),
          TextField(controller: _desc, maxLines: 4, maxLength: 500, decoration: const InputDecoration(labelText: 'Descrição')),
          const SizedBox(height: 12),
          SizedBox(height: 48, child: FilledButton(onPressed: _publicar, child: const Text('Publicar'))),
        ]),
      );
}

class NovoItemTela extends StatefulWidget {
  const NovoItemTela({super.key, required this.pfp});
  final bool pfp;

  @override
  State<NovoItemTela> createState() => _NovoItemTelaState();
}

class _NovoItemTelaState extends State<NovoItemTela> {
  final _nome = TextEditingController();
  final _preco = TextEditingController(text: '0');

  @override
  void dispose() {
    _nome.dispose();
    _preco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.pfp ? 'Publicar PFP' : 'Publicar asset')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: InkWell(
              onTap: () => emBreve(context, 'Enviar arquivo'),
              child: Container(
                decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(widget.pfp ? 'Toque para escolher a imagem' : 'Toque para escolher o arquivo')),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome')),
          const SizedBox(height: 10),
          TextField(controller: _preco, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Preço em moedas (0 = grátis)')),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                emBreve(context, 'Publicar');
              },
              child: const Text('Publicar'),
            ),
          ),
        ]),
      );
}
