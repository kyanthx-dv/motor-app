import 'package:flutter/material.dart';

import 'busca.dart';
import 'dados.dart';
import 'editor_web.dart';
import 'entrada.dart';
import 'jogo.dart';
import 'widgets.dart';

// ---------------------------------------------------------------- Jogos

class JogosAba extends StatelessWidget {
  const JogosAba({super.key});

  void _abrir(BuildContext context, Jogo j) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => JogoPagina(jogo: j)));

  @override
  Widget build(BuildContext context) {
    final recomendados = jogosExemplo.take(4).toList();
    final novos = jogosExemplo.reversed.toList();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      Row(children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BuscaTela())),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(14)),
              child: const Row(children: [
                Icon(Icons.search, color: Cores.texto2),
                SizedBox(width: 8),
                Text('Buscar jogos, pessoas, posts…', style: TextStyle(color: Cores.texto2)),
              ]),
            ),
          ),
        ),
        IconButton(tooltip: 'Notificações', icon: const Badge(label: Text('3'), child: Icon(Icons.notifications_none)), onPressed: () => _notificacoes(context)),
        IconButton(tooltip: 'Mensagens', icon: const Icon(Icons.mail_outline), onPressed: () => emBreve(context, 'Mensagens')),
        ActionChip(avatar: const Icon(Icons.monetization_on, color: Color(0xFFFBBF24), size: 18), label: const Text('120'), onPressed: () => _moedas(context)),
      ]),
      const SizedBox(height: 16),
      const Text('Recomendados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: recomendados.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => CartaoJogo(jogo: recomendados[i], largura: 180, aoTocar: () => _abrir(context, recomendados[i])),
        ),
      ),
      const SizedBox(height: 20),
      const Text('Novos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
        children: [for (final j in novos) CartaoJogo(jogo: j, aoTocar: () => _abrir(context, j))],
      ),
    ]);
  }

  void _notificacoes(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Cores.cartao,
        builder: (_) => ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: const [
          Text('Notificações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ListTile(leading: Icon(Icons.thumb_up_alt_outlined), title: Text('luna curtiu seu jogo'), subtitle: Text('Mini-RPG da Vila')),
          ListTile(leading: Icon(Icons.person_add_alt), title: Text('zed começou a seguir você')),
          ListTile(leading: Icon(Icons.comment_outlined), title: Text('ana_01 comentou'), subtitle: Text('Muito legal o inventário!')),
        ]),
      );

  void _moedas(BuildContext context) => showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Suas moedas'),
          content: const Text('Por enquanto as moedas vêm de anúncios. No futuro será possível comprar BCoins. Esta tela é só uma demonstração.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                emBreve(context, 'Anúncios');
              },
              child: const Text('Ganhar moedas'),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------- Assets e PFPs

class AssetsAba extends StatelessWidget {
  const AssetsAba({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Column(children: [
          const TabBar(tabs: [Tab(text: 'Assets'), Tab(text: 'PFPs')]),
          Expanded(
            child: TabBarView(children: [
              _Grade(itens: itensLojaExemplo.where((i) => !i.pfp).toList()),
              _Grade(itens: itensLojaExemplo.where((i) => i.pfp).toList()),
            ]),
          ),
        ]),
      );
}

class _Grade extends StatelessWidget {
  const _Grade({required this.itens});
  final List<ItemLoja> itens;

  @override
  Widget build(BuildContext context) => GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
        children: [
          for (final i in itens)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => detalheItem(context, i),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: SizedBox(width: double.infinity, child: Capa(cor1: i.cor1, cor2: i.cor2, icone: i.icone))),
                const SizedBox(height: 6),
                Text(i.titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                Row(children: [
                  Expanded(child: Text('@${i.autor}', style: const TextStyle(color: Cores.texto2, fontSize: 12))),
                  Text(i.preco == 0 ? 'Grátis' : '🪙 ${i.preco}', style: TextStyle(color: i.preco == 0 ? Cores.verde : const Color(0xFFFBBF24), fontSize: 12)),
                ]),
              ]),
            ),
        ],
      );
}

void detalheItem(BuildContext context, ItemLoja i) => showModalBottomSheet<void>(
      context: context,
      backgroundColor: Cores.cartao,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 140, width: double.infinity, child: Capa(cor1: i.cor1, cor2: i.cor2, icone: i.icone, tamanhoIcone: 56)),
          const SizedBox(height: 12),
          Text(i.titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          Text('${i.pfp ? 'PFP' : 'Asset'} de @${i.autor}', style: const TextStyle(color: Cores.texto2)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                emBreve(context, i.preco == 0 ? 'Baixar' : 'Compra');
              },
              child: Text(i.preco == 0 ? 'Obter (grátis)' : 'Comprar por ${i.preco} moedas'),
            ),
          ),
        ]),
      ),
    );

// ---------------------------------------------------------------- Posts

class PostsAba extends StatelessWidget {
  const PostsAba({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Column(children: [
          const TabBar(tabs: [Tab(text: 'Recomendados'), Tab(text: 'Seguindo')]),
          Expanded(
            child: TabBarView(children: [
              ListView(padding: const EdgeInsets.all(16), children: [for (final p in postsExemplo) CartaoPost(post: p)]),
              ListView(padding: const EdgeInsets.all(16), children: [for (final p in postsExemplo.where((p) => p.autor != 'zed')) CartaoPost(post: p)]),
            ]),
          ),
        ]),
      );
}

class CartaoPost extends StatefulWidget {
  const CartaoPost({super.key, required this.post});
  final Post post;

  @override
  State<CartaoPost> createState() => _CartaoPostState();
}

class _CartaoPostState extends State<CartaoPost> {
  bool _curtiu = false;
  bool _fav = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 14, child: Text(p.autor[0].toUpperCase())),
          const SizedBox(width: 8),
          Text('@${p.autor}', style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        AspectRatio(aspectRatio: 16 / 9, child: Capa(cor1: p.cor1, cor2: p.cor2, icone: p.icone, video: p.video, tamanhoIcone: 56)),
        const SizedBox(height: 10),
        Text(p.titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(p.descricao, style: const TextStyle(color: Cores.texto2)),
        const SizedBox(height: 8),
        Row(children: [
          IconButton(
            tooltip: 'Curtir',
            icon: Icon(_curtiu ? Icons.favorite : Icons.favorite_border, color: _curtiu ? Colors.redAccent : null),
            onPressed: () => setState(() => _curtiu = !_curtiu),
          ),
          Text(abreviar(p.curtidas + (_curtiu ? 1 : 0))),
          IconButton(tooltip: 'Comentários', icon: const Icon(Icons.chat_bubble_outline), onPressed: () => abrirComentarios(context, p.comentarios)),
          Text('${p.comentarios.length}'),
          const Spacer(),
          IconButton(
            tooltip: 'Favoritar',
            icon: Icon(_fav ? Icons.bookmark : Icons.bookmark_border, color: _fav ? const Color(0xFFFBBF24) : null),
            onPressed: () => setState(() => _fav = !_fav),
          ),
        ]),
      ]),
    );
  }
}

void abrirComentarios(BuildContext context, List<Comentario> lista) {
  final itens = List<Comentario>.of(lista);
  final campo = TextEditingController();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Cores.cartao,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Comentários (${itens.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(shrinkWrap: true, children: [
              if (itens.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('Seja o primeiro a comentar.', style: TextStyle(color: Cores.texto2))),
              for (final c in itens) ListTile(dense: true, leading: CircleAvatar(radius: 14, child: Text(c.autor[0].toUpperCase())), title: Text(c.autor), subtitle: Text(c.texto)),
            ]),
          ),
          Row(children: [
            Expanded(child: TextField(controller: campo, decoration: const InputDecoration(hintText: 'Escreva um comentário'))),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                final t = campo.text.trim();
                if (t.isEmpty) return;
                setS(() => itens.add(Comentario('você', t)));
                campo.clear();
              },
            ),
          ]),
        ]),
      ),
    ),
  );
}

// ---------------------------------------------------------------- Perfil

class PerfilAba extends StatelessWidget {
  const PerfilAba({super.key});

  @override
  Widget build(BuildContext context) {
    final meus = jogosExemplo.where((j) => j.autor == 'kyanthx').toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Align(alignment: Alignment.centerRight, child: IconButton(tooltip: 'Menu', icon: const Icon(Icons.menu), onPressed: () => _menuPerfil(context))),
      const Center(child: CircleAvatar(radius: 42, backgroundColor: Cores.acento, child: Text('K', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800)))),
      const SizedBox(height: 10),
      const Center(child: Text('Kyan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
      const Center(child: Text('@kyanthx', style: TextStyle(color: Cores.texto2))),
      const SizedBox(height: 6),
      const Center(child: Text('Criando jogos 2D com o Motor.', style: TextStyle(color: Cores.texto2))),
      const SizedBox(height: 14),
      const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_Numero('1,2k', 'seguidores'), _Numero('48', 'seguindo'), _Numero('2', 'jogos')]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => emBreve(context, 'Editar perfil'), child: const Text('Editar perfil'))),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EditorWebTela())),
            child: const Text('Abrir editor'),
          ),
        ),
      ]),
      const SizedBox(height: 18),
      const Text('Meus jogos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
        children: [for (final j in meus) CartaoJogo(jogo: j, aoTocar: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => JogoPagina(jogo: j))))],
      ),
      const SizedBox(height: 18),
      TextButton.icon(
        onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const EntradaTela()), (_) => false),
        icon: const Icon(Icons.logout),
        label: const Text('Sair'),
      ),
    ]);
  }
}

void _menuPerfil(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      backgroundColor: Cores.cartao,
      builder: (_) => SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: temaEscuro,
          builder: (_, escuro, __) => Column(mainAxisSize: MainAxisSize.min, children: [
            const Padding(padding: EdgeInsets.all(14), child: Text('Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
            SwitchListTile(
              secondary: Icon(escuro ? Icons.dark_mode : Icons.light_mode),
              title: const Text('Tema preto'),
              subtitle: Text(escuro ? 'Ligado' : 'Desligado (tema branco)'),
              value: escuro,
              onChanged: (v) => temaEscuro.value = v,
            ),
          ]),
        ),
      ),
    );

class _Numero extends StatelessWidget {
  const _Numero(this.valor, this.rotulo);
  final String valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        Text(rotulo, style: const TextStyle(color: Cores.texto2, fontSize: 12)),
      ]);
}
