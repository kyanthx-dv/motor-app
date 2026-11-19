import 'package:flutter/material.dart';

import 'busca.dart';
import 'dados.dart';
import 'editor_web.dart';
import 'entrada.dart';
import 'extras.dart';
import 'jogo.dart';
import 'widgets.dart';

const _ouro = Color(0xFFFBBF24);

void _ir(BuildContext c, Widget w) => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => w));

/// Cabecalho de aba: titulo grande + acoes.
class _Topo extends StatelessWidget {
  const _Topo(this.titulo, this.acoes);
  final String titulo;
  final List<Widget> acoes;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
        child: Row(children: [
          Text(titulo, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          const Spacer(),
          ...acoes,
        ]),
      );
}

Widget _lupa(BuildContext c) => IconButton(tooltip: 'Buscar', icon: const Icon(Icons.search), onPressed: () => _ir(c, const BuscaTela()));

// ---------------------------------------------------------------- Home (Jogos)

class JogosAba extends StatelessWidget {
  const JogosAba({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 5,
        child: Column(children: [
          _Topo('Início', [
            ActionChip(avatar: const Icon(Icons.monetization_on, color: _ouro, size: 20), label: const Text('120'), onPressed: () => _ir(context, const CarteiraTela())),
            _lupa(context),
            IconButton(tooltip: 'Notificações', icon: const Badge(label: Text('3'), child: Icon(Icons.notifications_none)), onPressed: () => _ir(context, const NotificacoesTela())),
            IconButton(tooltip: 'Mensagens', icon: const Icon(Icons.chat_bubble_outline), onPressed: () => _ir(context, const ChatTela())),
          ]),
          const TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [Tab(text: 'Em alta'), Tab(text: 'Descobrir'), Tab(text: 'Novos'), Tab(text: 'Ranking'), Tab(text: 'Seguindo')]),
          Expanded(
            child: TabBarView(children: [
              _HomeAlta(),
              _GradeJogos(jogosExemplo),
              _GradeJogos(jogosExemplo.reversed.toList()),
              _Ranking(),
              _GradeJogos(jogosExemplo.take(3).toList()),
            ]),
          ),
        ]),
      );
}

class _HomeAlta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cont = jogosExemplo.take(4).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
      Row(children: [
        const Text('Continuar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const Spacer(),
        TextButton(onPressed: () {}, child: const Text('Ver tudo  ›')),
      ]),
      SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cont.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => CartaoJogo(jogo: cont[i], largura: 170, aoTocar: () => _ir(context, JogoPagina(jogo: cont[i]))),
        ),
      ),
      const SizedBox(height: 18),
      const Text('Populares', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      _grade(context, jogosExemplo),
    ]);
  }
}

Widget _grade(BuildContext context, List<Jogo> lista) => GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [for (final j in lista) CartaoJogo(jogo: j, aoTocar: () => _ir(context, JogoPagina(jogo: j)))],
    );

class _GradeJogos extends StatelessWidget {
  const _GradeJogos(this.lista);
  final List<Jogo> lista;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [_grade(context, lista)]);
}

class _Ranking extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = [...jogosExemplo]..sort((a, b) => b.visitas.compareTo(a.visitas));
    return ListView(padding: const EdgeInsets.all(12), children: [
      for (var i = 0; i < l.length; i++)
        ListTile(
          leading: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 28, child: Text('${i + 1}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
            SizedBox(width: 56, height: 56, child: Capa(cor1: l[i].cor1, cor2: l[i].cor2, icone: l[i].icone, tamanhoIcone: 24, raio: 10)),
          ]),
          title: Text(l[i].titulo),
          subtitle: Text('${abreviar(l[i].visitas)} visitas', style: const TextStyle(color: Cores.texto2)),
          onTap: () => _ir(context, JogoPagina(jogo: l[i])),
        ),
    ]);
  }
}

// ---------------------------------------------------------------- Loja (Assets e PFPs)

class AssetsAba extends StatelessWidget {
  const AssetsAba({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 4,
        child: Column(children: [
          _Topo('Loja', [_lupa(context), IconButton(icon: const Icon(Icons.grid_view), onPressed: () => emBreve(context, 'Meus itens'))]),
          const TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [Tab(text: 'Para você'), Tab(text: 'Seguindo'), Tab(text: 'Assets'), Tab(text: 'PFPs')]),
          Expanded(
            child: TabBarView(children: [
              _Grade(itens: itensLojaExemplo),
              _Grade(itens: itensLojaExemplo.take(3).toList()),
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
        padding: const EdgeInsets.all(12),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
        children: [
          for (final i in itens)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => detalheItem(context, i),
              child: Container(
                decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(14)),
                clipBehavior: Clip.antiAlias,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: SizedBox(width: double.infinity, child: Capa(cor1: i.cor1, cor2: i.cor2, icone: i.icone, raio: 0))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(i.titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.monetization_on, color: _ouro, size: 18),
                        const SizedBox(width: 4),
                        Text(i.preco == 0 ? 'Grátis' : '${i.preco}', style: TextStyle(color: i.preco == 0 ? Cores.verde : const Color(0xFFFF7A33), fontSize: 18)),
                      ]),
                      Text('@${i.autor}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Cores.texto2, fontSize: 12)),
                    ]),
                  ),
                ]),
              ),
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

// ---------------------------------------------------------------- Comunidade (Posts)

class PostsAba extends StatelessWidget {
  const PostsAba({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 4,
        child: Column(children: [
          _Topo('Comunidade', [_lupa(context), IconButton(icon: const Icon(Icons.emoji_events_outlined), onPressed: () => emBreve(context, 'Ranking de criadores'))]),
          const TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [Tab(text: 'Seguindo'), Tab(text: 'Para você'), Tab(text: 'Vídeo'), Tab(text: 'Gamedev')]),
          Expanded(
            child: TabBarView(children: [
              _Feed(postsExemplo.where((p) => p.autor != 'zed').toList()),
              _Feed(postsExemplo),
              _Feed(postsExemplo.where((p) => p.video).toList()),
              _Feed(postsExemplo.reversed.toList()),
            ]),
          ),
        ]),
      );
}

class _Feed extends StatelessWidget {
  const _Feed(this.posts);
  final List<Post> posts;

  @override
  Widget build(BuildContext context) => posts.isEmpty
      ? const Center(child: Text('Nada por aqui ainda.', style: TextStyle(color: Cores.texto2)))
      : ListView(padding: const EdgeInsets.all(12), children: [for (final p in posts) CartaoPost(post: p)]);
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 22, child: Text(p.autor[0].toUpperCase())),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.autor, style: const TextStyle(fontSize: 16)), const Text('11 nov', style: TextStyle(color: Cores.texto2, fontSize: 12))])),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () => emBreve(context, 'Opções')),
        ]),
        const SizedBox(height: 8),
        AspectRatio(aspectRatio: 16 / 9, child: Capa(cor1: p.cor1, cor2: p.cor2, icone: p.icone, video: p.video, tamanhoIcone: 56)),
        const SizedBox(height: 10),
        Text(p.titulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(p.descricao, maxLines: 3, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Row(children: [
          IconButton(icon: Icon(_curtiu ? Icons.favorite : Icons.favorite_border, color: _curtiu ? Colors.redAccent : null), onPressed: () => setState(() => _curtiu = !_curtiu)),
          Text(abreviar(p.curtidas + (_curtiu ? 1 : 0))),
          const Spacer(),
          IconButton(icon: Icon(_fav ? Icons.star : Icons.star_border, color: _fav ? _ouro : null), onPressed: () => setState(() => _fav = !_fav)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () => abrirComentarios(context, p.comentarios)),
          Text('${p.comentarios.length}'),
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
          Text('${itens.length} comentários', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(shrinkWrap: true, children: [
              if (itens.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Vazio', style: TextStyle(color: Cores.texto2)))),
              for (final c in itens) ListTile(dense: true, leading: CircleAvatar(radius: 16, child: Text(c.autor[0].toUpperCase())), title: Text(c.autor, style: const TextStyle(color: Cores.texto2, fontSize: 13)), subtitle: Text(c.texto, style: const TextStyle(fontSize: 15))),
            ]),
          ),
          Row(children: [
            Expanded(child: TextField(controller: campo, decoration: const InputDecoration(hintText: 'Comentar…'))),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF8A00)),
              onPressed: () {
                final t = campo.text.trim();
                if (t.isEmpty) return;
                setS(() => itens.add(Comentario('você', t)));
                campo.clear();
              },
              child: const Text('Enviar'),
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
    return DefaultTabController(
      length: 3,
      child: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Align(alignment: Alignment.centerRight, child: IconButton(tooltip: 'Configurações', icon: const Icon(Icons.settings_outlined), onPressed: () => _menuPerfil(context))),
                Row(children: [
                  const CircleAvatar(radius: 46, backgroundColor: Cores.acento, child: Text('K', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: Colors.white))),
                  const Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_Numero('48', 'Seguindo'), _Numero('1,2k', 'Seguidores'), _Numero('24', 'Favoritos')])),
                ]),
                const SizedBox(height: 12),
                const Text('Kyan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const Text('@kyanthx', style: TextStyle(color: Cores.texto2)),
                const SizedBox(height: 6),
                const Text('Criando jogos 2D com o Motor.'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => emBreve(context, 'Editar perfil'), child: const Text('Editar perfil'))),
                  const SizedBox(width: 10),
                  Expanded(child: FilledButton(onPressed: () => _ir(context, const EditorWebTela()), child: const Text('Abrir editor'))),
                ]),
              ]),
            ),
          ),
          SliverPersistentHeader(pinned: true, delegate: _TabsFixas(TabBar(tabs: [Tab(text: 'Jogos ${meus.length}'), const Tab(text: 'Assets 4'), const Tab(text: 'Posts 9')]))),
        ],
        body: TabBarView(children: [
          ListView(padding: const EdgeInsets.all(12), children: [
            for (final j in meus) _LinhaJogo(j),
            _LinhaJogo(const Jogo(id: 'rasc', titulo: 'Rascunho', autor: 'kyanthx', descricao: '', cor1: Color(0xFF38BDF8), cor2: Color(0xFF0EA5E9), icone: Icons.sports_esports, orientacao: Orientacao.qualquer, curtidas: 0, favoritos: 0, visitas: 0), rascunho: true),
          ]),
          const Center(child: Text('Seus assets publicados aparecem aqui.', style: TextStyle(color: Cores.texto2))),
          const Center(child: Text('Seus posts aparecem aqui.', style: TextStyle(color: Cores.texto2))),
        ]),
      ),
    );
  }
}

class _TabsFixas extends SliverPersistentHeaderDelegate {
  _TabsFixas(this.tabs);
  final TabBar tabs;

  @override
  double get minExtent => tabs.preferredSize.height;
  @override
  double get maxExtent => tabs.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: Cores.fundo, child: tabs);
  @override
  bool shouldRebuild(covariant _TabsFixas old) => true;
}

class _LinhaJogo extends StatelessWidget {
  const _LinhaJogo(this.j, {this.rascunho = false});
  final Jogo j;
  final bool rascunho;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: () => rascunho ? _ir(context, const EditorWebTela()) : _ir(context, JogoPagina(jogo: j)),
          child: Row(children: [
            SizedBox(width: 90, height: 90, child: Capa(cor1: j.cor1, cor2: j.cor2, icone: j.icone, tamanhoIcone: 36)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(j.titulo, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: rascunho ? const Color(0xFFFF5C7A) : Cores.verde, borderRadius: BorderRadius.circular(6)),
                    child: Text(rascunho ? 'Em dev' : 'Publicado', style: const TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                ]),
                Text('${abreviar(j.visitas)} visitas', style: const TextStyle(color: Cores.texto2)),
              ]),
            ),
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () => emBreve(context, 'Opções do jogo')),
          ]),
        ),
      );
}

void _menuPerfil(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(18)),
              child: ValueListenableBuilder<bool>(
                valueListenable: temaEscuro,
                builder: (_, escuro, __) => Column(mainAxisSize: MainAxisSize.min, children: [
                  for (final t in const ['Conta', 'Código QR', 'Análises', 'Receita'])
                    ListTile(
                      title: Center(child: Text(t)),
                      onTap: () {
                        Navigator.pop(ctx);
                        emBreve(context, t);
                      },
                    ),
                  SwitchListTile(secondary: Icon(escuro ? Icons.dark_mode : Icons.light_mode), title: const Text('Tema preto'), value: escuro, onChanged: (v) => temaEscuro.value = v),
                  ListTile(
                    title: const Center(child: Text('Sair', style: TextStyle(color: Colors.redAccent))),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const EntradaTela()), (_) => false);
                    },
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: Cores.cartao, foregroundColor: Colors.white70, minimumSize: const Size.fromHeight(52)), onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar'))),
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
        Text(valor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
        Text(rotulo, style: const TextStyle(color: Cores.texto2, fontSize: 12)),
      ]);
}
