import 'package:flutter/material.dart';

import 'busca.dart';
import 'dados.dart';
import 'editor_web.dart';
import 'entrada.dart';
import 'detalhes.dart';
import 'extras.dart';
import 'jogo.dart';
import 'perfil_publico.dart';
import 'projeto.dart';
import 'projetos.dart';
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
          BarraAbas(const ['Em alta', 'Descobrir', 'Novos', 'Ranking', 'Seguindo'], rolavel: true),
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
      const Text('Seus projetos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      SizedBox(
        height: 84,
        child: ListenableBuilder(
          listenable: RepositorioProjetos.instancia,
          builder: (context, _) => ListView(scrollDirection: Axis.horizontal, children: [
            Toque(
              aoTocar: () => novoJogo(context),
              child: Container(width: 120, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: Cores.acento.withAlpha(35), borderRadius: BorderRadius.circular(18)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_rounded, color: Cores.acento, size: 28), Text('Novo jogo', style: TextStyle(color: Cores.acento, fontWeight: FontWeight.w800, fontSize: 13))])),
            ),
            for (final pr in RepositorioProjetos.instancia.projetos)
              Toque(
                aoTocar: () => _ir(context, ProjetoTela(projeto: pr)),
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(18)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(pr.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('${pr.cenas.length} ${pr.cenas.length == 1 ? 'cena' : 'cenas'}', style: const TextStyle(color: Cores.texto2, fontSize: 12)),
                  ]),
                ),
              ),
          ]),
        ),
      ),
      const SizedBox(height: 20),
      Row(children: [
        const Text('Continuar jogando', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const Spacer(),
        TextButton(onPressed: () {}, child: const Text('Ver tudo')),
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
      children: [for (var i = 0; i < lista.length; i++) Aparece(indice: i, child: CartaoJogo(jogo: lista[i], aoTocar: () => _ir(context, JogoPagina(jogo: lista[i]))))],
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
          BarraAbas(const ['Para você', 'Seguindo', 'Assets', 'PFPs'], rolavel: true),
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
          for (var n = 0; n < itens.length; n++)
            Aparece(
              indice: n,
              child: Toque(
              aoTocar: () => _ir(context, ItemPagina(item: itens[n])),
              child: Container(
                decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(14)),
                clipBehavior: Clip.antiAlias,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: SizedBox(width: double.infinity, child: Capa(cor1: itens[n].cor1, cor2: itens[n].cor2, icone: itens[n].icone, raio: 0))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(itens[n].titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.monetization_on, color: _ouro, size: 18),
                        const SizedBox(width: 4),
                        Text(itens[n].preco == 0 ? 'Grátis' : '${itens[n].preco}', style: TextStyle(color: itens[n].preco == 0 ? Cores.verde : const Color(0xFFFF7A33), fontSize: 18)),
                      ]),
                      Text('@${itens[n].autor}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Cores.texto2, fontSize: 12)),
                    ]),
                  ),
                ]),
              ),
            ),
            ),
        ],
      );
}

// ---------------------------------------------------------------- Comunidade (Posts)

class PostsAba extends StatelessWidget {
  const PostsAba({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 4,
        child: Column(children: [
          _Topo('Comunidade', [_lupa(context), IconButton(icon: const Icon(Icons.emoji_events_outlined), onPressed: () => emBreve(context, 'Ranking de criadores'))]),
          BarraAbas(const ['Seguindo', 'Para você', 'Vídeo', 'Gamedev'], rolavel: true),
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
      : ListView(padding: const EdgeInsets.all(12), children: [for (var i = 0; i < posts.length; i++) Aparece(indice: i, child: CartaoPost(post: posts[i]))]);
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
      decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(20)),
      child: Toque(
        aoTocar: () => _ir(context, PostPagina(post: p)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Align(alignment: Alignment.centerLeft, child: ChipAutor(p.autor, legenda: '11 nov'))),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () => emBreve(context, 'Opções')),
        ]),
        const SizedBox(height: 6),
        Text(p.titulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(p.descricao, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Cores.texto2)),
        const SizedBox(height: 10),
        AspectRatio(aspectRatio: 21 / 9, child: Capa(cor1: p.cor1, cor2: p.cor2, icone: p.icone, video: p.video, tamanhoIcone: 40)),
        const SizedBox(height: 6),
        Row(children: [
          IconButton(icon: IconeAnim(ligado: _curtiu, ligadoIcone: Icons.favorite, desligadoIcone: Icons.favorite_border, cor: Colors.redAccent), onPressed: () => setState(() => _curtiu = !_curtiu)),
          Text(abreviar(p.curtidas + (_curtiu ? 1 : 0))),
          const Spacer(),
          IconButton(icon: IconeAnim(ligado: _fav, ligadoIcone: Icons.star, desligadoIcone: Icons.star_border, cor: _ouro), onPressed: () => setState(() => _fav = !_fav)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () => abrirComentarios(context, p.comentarios)),
          Text('${p.comentarios.length}'),
        ]),
      ]),
      ),
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
                Align(alignment: Alignment.centerRight, child: IconButton.filledTonal(tooltip: 'Configurações', icon: const Icon(Icons.settings_outlined), onPressed: () => _menuPerfil(context))),
                Row(children: [
                  const AvatarUsuario('kyanthx', raio: 44, anel: true),
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
          SliverPersistentHeader(pinned: true, delegate: _TabsFixas(const BarraAbas(['Jogos', 'Assets', 'Posts']))),
        ],
        body: TabBarView(children: [
          ListenableBuilder(
            listenable: RepositorioProjetos.instancia,
            builder: (_, __) => ListView(padding: const EdgeInsets.all(12), children: [
              for (final pr in RepositorioProjetos.instancia.projetos) _LinhaProjeto(pr),
              for (final j in meus) _LinhaJogo(j),
              if (RepositorioProjetos.instancia.projetos.isEmpty && meus.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Toque em Novo jogo para criar o primeiro.', style: TextStyle(color: Cores.texto2)))),
            ]),
          ),
          const Center(child: Text('Seus assets publicados aparecem aqui.', style: TextStyle(color: Cores.texto2))),
          const Center(child: Text('Seus posts aparecem aqui.', style: TextStyle(color: Cores.texto2))),
        ]),
      ),
    );
  }
}

class _TabsFixas extends SliverPersistentHeaderDelegate {
  _TabsFixas(this.tabs);
  final BarraAbas tabs;

  @override
  double get minExtent => tabs.preferredSize.height;
  @override
  double get maxExtent => tabs.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: Cores.fundo, child: tabs);
  @override
  bool shouldRebuild(covariant _TabsFixas old) => true;
}

class _LinhaProjeto extends StatelessWidget {
  const _LinhaProjeto(this.p);
  final Projeto p;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(14)),
        child: Toque(
          aoTocar: () => _ir(context, ProjetoTela(projeto: p)),
          child: Row(children: [
            const SizedBox(width: 90, height: 90, child: Capa(cor1: Color(0xFF38BDF8), cor2: Color(0xFF0EA5E9), icone: Icons.sports_esports, tamanhoIcone: 36)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Row(children: [
                  const _Estado('Em dev', Color(0xFFF59E0B)),
                  Flexible(child: Text(' · ${p.cenas.length} ${p.cenas.length == 1 ? 'cena' : 'cenas'} · ${rotuloOrientacao(p.orientacao)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Cores.texto2, fontSize: 12))),
                ]),
              ]),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Excluir "${p.nome}"?'),
                  content: const Text('Isso apaga o projeto deste aparelho.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () {
                        RepositorioProjetos.instancia.apagar(p);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Excluir'),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      );
}

class _LinhaJogo extends StatelessWidget {
  const _LinhaJogo(this.j);
  final Jogo j;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: () => _ir(context, JogoPagina(jogo: j)),
          child: Row(children: [
            SizedBox(width: 90, height: 90, child: Capa(cor1: j.cor1, cor2: j.cor2, icone: j.icone, tamanhoIcone: 36)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(j.titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Row(children: [const _Estado('Publicado', Cores.verde), Text(' · ${abreviar(j.visitas)} visitas', style: const TextStyle(color: Cores.texto2, fontSize: 12))]),
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

/// Estado do jogo: bolinha colorida + texto discreto (sem selo chamativo).
class _Estado extends StatelessWidget {
  const _Estado(this.texto, this.cor);
  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(texto, style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w700)),
      ]);
}
