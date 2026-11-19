import 'package:flutter/material.dart';

import 'editor_web.dart';
import 'projeto.dart';
import 'widgets.dart';

void abrirMenuCriar(BuildContext context) {
  Widget botao(BuildContext ctx, IconData i, Color cor, String nome, Widget? destino) => Expanded(child: InkWell(
        borderRadius: BorderRadius.circular(80),
        onTap: () {
          Navigator.pop(ctx);
          if (destino == null) {
            novoJogo(context);
          } else {
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => destino));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(radius: 30, backgroundColor: Cores.cartao2, child: Icon(i, color: cor, size: 30)),
            const SizedBox(height: 8),
            Text(nome, style: const TextStyle(fontSize: 15)),
          ]),
        ),
      ));
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Cores.cartao,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            botao(ctx, Icons.sports_esports, const Color(0xFF0EA5FF), 'Jogo', null),
            botao(ctx, Icons.shopping_bag, const Color(0xFFFF7A33), 'Assets', const NovoItemTela(pfp: false)),
            botao(ctx, Icons.face, const Color(0xFF22C55E), 'PFP', const NovoItemTela(pfp: true)),
            botao(ctx, Icons.article, const Color(0xFFFF5C7A), 'Post', const NovoPostTela()),
          ]),
          const SizedBox(height: 18),
          InkWell(
            onTap: () => Navigator.pop(ctx),
            child: Container(width: 64, height: 40, decoration: BoxDecoration(color: const Color(0xFFFF5C7A), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.close, color: Colors.white)),
          ),
        ]),
      ),
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
