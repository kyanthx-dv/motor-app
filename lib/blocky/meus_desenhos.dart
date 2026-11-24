import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'biblioteca.dart';
import 'desenho.dart';
import 'widgets.dart';

/// Lista os desenhos do usuario (biblioteca de assets feitos no app). Toque abre; segurar abre o menu.
class MeusDesenhosTela extends StatefulWidget {
  const MeusDesenhosTela({super.key});

  @override
  State<MeusDesenhosTela> createState() => _MeusDesenhosTelaState();
}

class _MeusDesenhosTelaState extends State<MeusDesenhosTela> {
  @override
  void initState() {
    super.initState();
    Biblioteca.i.carregar();
    Biblioteca.i.addListener(_atualizar);
  }

  @override
  void dispose() {
    Biblioteca.i.removeListener(_atualizar);
    super.dispose();
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  Future<void> _abrir(AssetSalvo a) async {
    final doc = await Biblioteca.i.abrir(a);
    if (doc == null) {
      if (mounted) aviso(context, 'Não consegui abrir este desenho.');
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EditorDesenho(config: doc.config, doc: doc, asset: a)));
  }

  Future<void> _menu(AssetSalvo a) async {
    final r = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Cores.cartao,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: Text(a.nome, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${a.l}×${a.a} px')),
          ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Abrir'), onTap: () => Navigator.pop(ctx, 'abrir')),
          ListTile(leading: const Icon(Icons.delete_outline, color: Cores.coral), title: const Text('Apagar', style: TextStyle(color: Cores.coral)), onTap: () => Navigator.pop(ctx, 'apagar')),
        ]),
      ),
    );
    if (r == 'abrir') await _abrir(a);
    if (r == 'apagar' && mounted) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Apagar "${a.nome}"?'),
          content: const Text('Mapas que usam este desenho vão mostrar um espaço vazio.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apagar'))],
        ),
      );
      if (ok == true) await Biblioteca.i.apagar(a);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itens = Biblioteca.i.itens;
    return Scaffold(
      appBar: AppBar(title: const Text('Meus desenhos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NovoDesenhoTela())),
        elevation: 0,
        backgroundColor: Cores.acento,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: itens.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Nenhum desenho ainda. Desenhe assets, ícones e fotos de perfil aqui dentro: tudo é seu e pode ser vendido.', textAlign: TextAlign.center, style: TextStyle(color: Cores.texto2))))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.82),
              itemCount: itens.length,
              itemBuilder: (_, i) {
                final a = itens[i];
                return Toque(
                  aoTocar: () => _abrir(a),
                  child: GestureDetector(
                    onLongPress: () => _menu(a),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(10)),
                          clipBehavior: Clip.antiAlias,
                          child: FutureBuilder<Uint8List?>(
                            key: ValueKey('${a.id}-${Biblioteca.i.versoes[a.id]}'),
                            future: Biblioteca.i.pngBytes(a.id),
                            builder: (_, s) => s.data == null ? const SizedBox.shrink() : Padding(padding: const EdgeInsets.all(6), child: Image.memory(s.data!, fit: BoxFit.contain, filterQuality: FilterQuality.none, gaplessPlayback: true)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(a.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${a.l}×${a.a}', style: const TextStyle(fontSize: 11, color: Cores.texto2)),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
