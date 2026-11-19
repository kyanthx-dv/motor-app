import 'package:flutter/material.dart';

import 'abas.dart';
import 'dados.dart';
import 'jogo.dart';
import 'widgets.dart';

enum _Tipo { jogos, assets, pessoas, posts }

class BuscaTela extends StatefulWidget {
  const BuscaTela({super.key});

  @override
  State<BuscaTela> createState() => _BuscaTelaState();
}

class _BuscaTelaState extends State<BuscaTela> {
  final _campo = TextEditingController();
  _Tipo _tipo = _Tipo.jogos;

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  bool _casa(String s) => s.toLowerCase().contains(_campo.text.trim().toLowerCase());

  @override
  Widget build(BuildContext context) {
    final q = _campo.text.trim();
    final widgets = <Widget>[];
    switch (_tipo) {
      case _Tipo.jogos:
        for (final j in jogosExemplo.where((j) => _casa(j.titulo) || _casa(j.autor))) {
          widgets.add(ListTile(
            leading: SizedBox(width: 64, height: 40, child: Capa(cor1: j.cor1, cor2: j.cor2, icone: j.icone, tamanhoIcone: 20, raio: 8)),
            title: Text(j.titulo),
            subtitle: Text('@${j.autor} · ${abreviar(j.visitas)} visitas'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => JogoPagina(jogo: j))),
          ));
        }
      case _Tipo.assets:
        for (final i in itensLojaExemplo.where((i) => _casa(i.titulo) || _casa(i.autor))) {
          widgets.add(ListTile(
            leading: SizedBox(width: 48, height: 48, child: Capa(cor1: i.cor1, cor2: i.cor2, icone: i.icone, tamanhoIcone: 22, raio: 8)),
            title: Text(i.titulo),
            subtitle: Text('${i.pfp ? 'PFP' : 'Asset'} · @${i.autor}'),
            trailing: Text(i.preco == 0 ? 'Grátis' : '🪙 ${i.preco}'),
            onTap: () => detalheItem(context, i),
          ));
        }
      case _Tipo.pessoas:
        for (final p in pessoasExemplo.where((p) => _casa(p.usuario) || _casa(p.nome))) {
          widgets.add(ListTile(
            leading: CircleAvatar(child: Text(p.nome[0])),
            title: Text(p.nome),
            subtitle: Text('@${p.usuario} · ${abreviar(p.seguidores)} seguidores'),
            trailing: OutlinedButton(onPressed: () => emBreve(context, 'Seguir'), child: const Text('Seguir')),
          ));
        }
      case _Tipo.posts:
        for (final p in postsExemplo.where((p) => _casa(p.titulo) || _casa(p.descricao) || _casa(p.autor))) {
          widgets.add(CartaoPost(post: p));
        }
    }
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _campo,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Buscar…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: q.isEmpty ? null : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(_campo.clear)),
          ),
        ),
      ),
      body: Column(children: [
        SizedBox(
          height: 48,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
            for (final t in _Tipo.values)
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
                child: ChoiceChip(
                  label: Text(switch (t) { _Tipo.jogos => 'Jogos', _Tipo.assets => 'Assets', _Tipo.pessoas => 'Pessoas', _Tipo.posts => 'Posts' }),
                  selected: _tipo == t,
                  onSelected: (_) => setState(() => _tipo = t),
                ),
              ),
          ]),
        ),
        Expanded(
          child: widgets.isEmpty
              ? const Center(child: Text('Nada encontrado.', style: TextStyle(color: Cores.texto2)))
              : ListView(padding: const EdgeInsets.all(12), children: widgets),
        ),
      ]),
    );
  }
}
