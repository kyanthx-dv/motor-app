import 'package:flutter/material.dart';

import 'icones.dart';
import 'busca.dart';
import 'avisos.dart';
import 'editar_perfil.dart';
import 'nuvem.dart';
import 'comentarios.dart';
import 'repo.dart';
import 'dados.dart';
import 'video.dart';
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

Widget _lupa(BuildContext c) => IconButton(tooltip: 'Buscar', icon: const Icon(Ic.busca), onPressed: () => _ir(c, const BuscaTela()));

// ---------------------------------------------------------------- Home (Jogos)

class JogosAba extends StatelessWidget {
  const JogosAba({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 5,
        child: Column(children: [
          _Topo('Início', [
            ActionChip(avatar: const Icon(Ic.moeda, color: _ouro, size: 20), label: const Text('120'), onPressed: () => _ir(context, const CarteiraTela())),
            _lupa(context),
            IconButton(tooltip: 'Notificações', icon: const Badge(label: Text('3'), child: Icon(Ic.sino)), onPressed: () => _ir(context, const NotificacoesTela())),
            IconButton(tooltip: 'Mensagens', icon: const Icon(Ic.balao), onPressed: () => _ir(context, const ChatTela())),
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
              child: Container(width: 120, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: Cores.acento.withAlpha(35), borderRadius: BorderRadius.circular(18)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Ic.mais, color: Cores.acento, size: 28), Text('Novo jogo', style: TextStyle(color: Cores.acento, fontWeight: FontWeight.w800, fontSize: 13))])),
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
          _Topo('Loja', [_lupa(context), IconButton(icon: const Icon(Ic.grade), onPressed: () => emBreve(context, 'Meus itens'))]),
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
                        const Icon(Ic.moeda, color: _ouro, size: 18),
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

class PostsAba extends StatefulWidget {
  const PostsAba({super.key});

  @override
  State<PostsAba> createState() => _PostsAbaState();
}

class _PostsAbaState extends State<PostsAba> {
  @override
  void initState() {
    super.initState();
    RepoPosts.i.carregar();
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Column(children: [
          _Topo('Comunidade', [_lupa(context), IconButton(icon: const Icon(Ic.trofeu), onPressed: () => emBreve(context, 'Ranking de criadores'))]),
          BarraAbas(const ['Para você', 'Seguindo', 'Vídeo'], rolavel: true),
          Expanded(
            child: ListenableBuilder(
              listenable: RepoPosts.i,
              builder: (_, __) {
                final r = RepoPosts.i;
                return TabBarView(children: [
                  _Feed(r.posts, vazio: 'Ainda não há posts. Seja o primeiro: toque em Postar.'),
                  _Feed([for (final p in r.posts) if (r.seguindoIds.contains(p.autorId)) p], vazio: Nuvem.i.logado ? 'Siga pessoas para ver os posts delas aqui.' : 'Entre na sua conta para ver quem você segue.'),
                  _Feed([for (final p in r.posts) if (p.video) p], vazio: 'Vídeos chegam quando o envio de vídeo estiver pronto.'),
                ]);
              },
            ),
          ),
        ]),
      );
}

class _Feed extends StatelessWidget {
  const _Feed(this.posts, {required this.vazio});
  final List<Post> posts;
  final String vazio;

  @override
  Widget build(BuildContext context) {
    final r = RepoPosts.i;
    if (r.carregando && r.posts.isEmpty) return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    return RefreshIndicator(
      onRefresh: r.carregar,
      child: posts.isEmpty
          ? ListView(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 90, 32, 0),
                child: Column(children: [
                  Icon(r.erro != null ? Ic.alerta : Ic.comunidade, size: 44, color: Cores.texto2),
                  const SizedBox(height: 12),
                  Text(r.erro ?? vazio, textAlign: TextAlign.center, style: const TextStyle(color: Cores.texto2)),
                  if (r.erro != null) TextButton(onPressed: r.carregar, child: const Text('Tentar de novo')),
                ]),
              ),
            ])
          : ListView(padding: const EdgeInsets.all(12), children: [for (var i = 0; i < posts.length; i++) Aparece(indice: i, child: CartaoPost(post: posts[i]))]),
    );
  }
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
    final real = p.autorId.isNotEmpty;
    return ListenableBuilder(listenable: RepoPosts.i, builder: (context, _) => _cartao(context, p, real));
  }

  Widget _cartao(BuildContext context, Post p, bool real) {
    final r = RepoPosts.i;
    final curtiu = real ? r.curtiu(p) : _curtiu;
    final fav = real ? r.favoritou(p) : _fav;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(20)),
      child: Toque(
        aoTocar: () => _ir(context, p.video ? VideoPostTela(inicial: p) : PostPagina(post: p)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Align(alignment: Alignment.centerLeft, child: ChipAutor(p.autor, legenda: '11 nov'))),
          IconButton(icon: const Icon(Ic.maisVert), onPressed: () => emBreve(context, 'Opções')),
        ]),
        const SizedBox(height: 6),
        Text(p.titulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(p.descricao, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Cores.texto2)),
        const SizedBox(height: 10),
        AspectRatio(aspectRatio: 21 / 9, child: Capa(cor1: p.cor1, cor2: p.cor2, icone: p.icone, video: p.video, tamanhoIcone: 40)),
        const SizedBox(height: 6),
        Row(children: [
          IconButton(icon: IconeAnim(ligado: curtiu, ligadoIcone: Ic.coracaoCheio, desligadoIcone: Ic.coracao, cor: Colors.redAccent), onPressed: () => real ? tentar(context, () => r.alternar(p, 'curtida')) : setState(() => _curtiu = !_curtiu)),
          TextoRolante(abreviar(real ? r.curtidas(p) : p.curtidas + (_curtiu ? 1 : 0))),
          const Spacer(),
          IconButton(icon: IconeAnim(ligado: fav, ligadoIcone: Ic.estrelaCheia, desligadoIcone: Ic.estrela, cor: _ouro), onPressed: () => real ? tentar(context, () => r.alternar(p, 'favorito')) : setState(() => _fav = !_fav)),
          const Spacer(),
          IconButton(icon: const Icon(Ic.balao), onPressed: () => real ? abrirComentarios(context, const [], tipo: 'post', id: p.id) : abrirComentarios(context, p.comentarios)),
          Text('${real ? r.comentarios(p) : p.numComentarios}'),
        ]),
      ]),
      ),
    );
  }
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CabecalhoPerfil(
                usuario: 'kyanthx',
                proprio: true,
                direita: IconButton.filledTonal(tooltip: 'Configurações', icon: const Icon(Ic.engrenagem), onPressed: () => _menuPerfil(context)),
                stats: const [('3', 'Jogos'), ('1,2k', 'Seguidores'), ('48', 'Seguindo')],
                botoes: Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Nuvem.i.logado ? _ir(context, const EditarPerfilTela()) : aviso(context, 'Entre na sua conta para editar o perfil.'), child: const Text('Editar perfil'))),
                  const SizedBox(width: 10),
                  Expanded(child: FilledButton(onPressed: () => _ir(context, const EditorWebTela()), child: const Text('Abrir editor'))),
                ]),
              ),
            ]),
          ),
          SliverPersistentHeader(pinned: true, delegate: TabsFixas(const BarraAbas(['Jogos', 'Assets', 'Posts']))),
        ],
        body: TabBarView(children: [
          ListenableBuilder(
            listenable: RepositorioProjetos.instancia,
            builder: (_, __) => ListView(padding: const EdgeInsets.all(12), children: [
              Padding(padding: const EdgeInsets.only(bottom: 12), child: FilledButton.icon(onPressed: () => novoJogo(context), icon: const Icon(Ic.mais), label: const Text('Novo jogo'))),
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
            const SizedBox(width: 90, height: 90, child: Capa(cor1: Color(0xFF38BDF8), cor2: Color(0xFF0EA5E9), icone: Ic.controle, tamanhoIcone: 36)),
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
              icon: const Icon(Ic.lixeira),
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
            IconButton(icon: const Icon(Ic.maisVert), onPressed: () => emBreve(context, 'Opções do jogo')),
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
                  ListTile(
                    title: const Center(child: Text('Avisos e erros')),
                    onTap: () {
                      Navigator.pop(ctx);
                      abrirAvisos(context);
                    },
                  ),
                  SwitchListTile(secondary: Icon(escuro ? Ic.lua : Ic.sol), title: const Text('Tema preto'), value: escuro, onChanged: (v) => temaEscuro.value = v),
                  ListTile(
                    title: const Center(child: Text('Sair', style: TextStyle(color: Colors.redAccent))),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await Nuvem.i.sair();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const EntradaTela()), (_) => false);
                    },
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar'))),
          ]),
        ),
      ),
    );

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
