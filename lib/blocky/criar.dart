import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'avisos.dart';
import 'icones.dart';
import 'nuvem.dart';
import 'repo.dart';
import 'widgets.dart';

/// Loja > Publicar: escolhe entre asset e PFP.
void menuPublicar(BuildContext context) {
  Widget opcao(BuildContext ctx, IconData i, String t, String d, bool pfp) => ListTile(
        leading: CircleAvatar(backgroundColor: Cores.cartao2, child: Icon(i, color: Cores.acento)),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(d, style: const TextStyle(color: Cores.texto2)),
        onTap: () {
          Navigator.pop(ctx);
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => NovoItemTela(pfp: pfp)));
        },
      );
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 18, 8, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Publicar na loja', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          opcao(ctx, Ic.pacote, 'Asset', 'Sprites, sons, tiles, efeitos', false),
          opcao(ctx, Ic.rosto, 'PFP', 'Foto de perfil', true),
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
  int _paleta = 0;
  int _icone = 0;
  bool _enviando = false;
  File? _arquivo;
  bool _ehVideo = false;

  @override
  void dispose() {
    _titulo.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _escolher(bool video) async {
    try {
      final picker = ImagePicker();
      final x = video ? await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 3)) : await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, imageQuality: 85);
      if (x == null || !mounted) return;
      final f = File(x.path);
      if (await f.length() > Nuvem.limiteMidia) {
        if (mounted) aviso(context, 'Arquivo grande demais (máximo 50 MB).');
        return;
      }
      setState(() {
        _arquivo = f;
        _ehVideo = video;
      });
    } catch (e) {
      Avisos.add(Nivel.erro, 'Escolher arquivo: $e');
      if (mounted) aviso(context, 'Não consegui abrir a galeria.');
    }
  }

  Future<void> _publicar() async {
    if (_enviando) return;
    if (!Nuvem.i.logado) return aviso(context, 'Entre na sua conta para publicar.');
    if (_titulo.text.trim().isEmpty) return aviso(context, 'Escreva um título.');
    setState(() => _enviando = true);
    try {
      final url = _arquivo == null ? null : await Nuvem.i.enviarMidia(_arquivo!);
      await RepoPosts.i.publicar(titulo: _titulo.text, descricao: _desc.text, paleta: _paleta, icone: _icone, midia: url, video: _ehVideo);
      if (!mounted) return;
      Navigator.pop(context);
      aviso(context, 'Post publicado!');
    } on ErroNuvem catch (e) {
      Avisos.add(Nivel.aviso, 'Publicar: ${e.msg}');
      if (mounted) aviso(context, e.msg);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Novo post')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _arquivo != null && !_ehVideo
                ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_arquivo!, fit: BoxFit.cover))
                : Capa(cor1: capasCores[_paleta].$1, cor2: capasCores[_paleta].$2, icone: capasIcones[_icone], tamanhoIcone: 56, raio: 16, video: _arquivo != null && _ehVideo),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: _enviando ? null : () => _escolher(false), icon: const Icon(Ic.imagem), label: const Text('Foto'))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(onPressed: _enviando ? null : () => _escolher(true), icon: const Icon(Ic.play), label: const Text('Vídeo'))),
            if (_arquivo != null) IconButton(tooltip: 'Remover', onPressed: () => setState(() => _arquivo = null), icon: const Icon(Ic.fechar)),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (var i = 0; i < capasCores.length; i++)
              Toque(
                aoTocar: () => setState(() => _paleta = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: capasCores[i].$1, border: Border.all(color: _paleta == i ? Colors.white : Colors.transparent, width: 2.5)),
                ),
              ),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (var i = 0; i < capasIcones.length; i++)
              Toque(
                aoTocar: () => setState(() => _icone = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: _icone == i ? Cores.acento : Cores.cartao2, borderRadius: BorderRadius.circular(14)),
                  child: Icon(capasIcones[i], size: 22, color: _icone == i ? Colors.white : Cores.texto2),
                ),
              ),
          ]),
          const SizedBox(height: 6),
          Text(_arquivo == null ? 'Sem arquivo, o post usa a capa colorida acima.' : (_ehVideo ? 'Vídeo escolhido (até 50 MB).' : 'Foto escolhida.'), style: const TextStyle(color: Cores.texto2, fontSize: 12)),
          const SizedBox(height: 14),
          TextField(controller: _titulo, maxLength: 80, decoration: const InputDecoration(labelText: 'Título')),
          const SizedBox(height: 8),
          TextField(controller: _desc, minLines: 3, maxLines: 6, maxLength: 2000, decoration: const InputDecoration(labelText: 'Descrição')),
          const SizedBox(height: 12),
          BotaoPrimario(texto: _enviando ? 'Publicando…' : 'Publicar', aoTocar: _enviando ? null : _publicar),
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
