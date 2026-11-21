import 'package:flutter/material.dart';

import 'icones.dart';
import 'comentarios.dart';
import 'dados.dart';
import 'perfil_publico.dart';
import 'widgets.dart';

const _ouro = Color(0xFFFBBF24);

/// Pagina com conteudo no topo + aba de comentarios + campo fixo embaixo (base de Post e Asset).
class _Base extends StatefulWidget {
  const _Base({required this.topo, required this.comentarios});
  final List<Widget> topo;
  final List<Comentario> comentarios;

  @override
  State<_Base> createState() => _BaseState();
}

class _BaseState extends State<_Base> {
  late final ControleComentarios _cc = ControleComentarios(widget.comentarios);

  @override
  void dispose() {
    _cc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
              ...widget.topo,
              const Divider(),
              Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 4), child: ListenableBuilder(listenable: _cc, builder: (_, __) => Text('${_cc.total} comentários', style: const TextStyle(fontSize: 18)))),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: ListaComentarios(_cc)),
              const SizedBox(height: 24),
            ]),
          ),
          SafeArea(top: false, child: BarraComentario(_cc)),
        ]),
      );
}

class _Acoes extends StatefulWidget {
  const _Acoes({required this.curtidas, required this.favoritos});
  final int curtidas;
  final int favoritos;

  @override
  State<_Acoes> createState() => _AcoesState();
}

class _AcoesState extends State<_Acoes> {
  bool _c = false;
  bool _f = false;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 8, children: [
          PilulaAcao(icone: Ic.coracao, iconeAtivo: Ic.coracaoCheio, rotulo: abreviar(widget.curtidas + (_c ? 1 : 0)), ativo: _c, cor: Colors.redAccent, aoTocar: () => setState(() => _c = !_c)),
          PilulaAcao(icone: Ic.estrela, iconeAtivo: Ic.estrelaCheia, rotulo: abreviar(widget.favoritos + (_f ? 1 : 0)), ativo: _f, cor: _ouro, aoTocar: () => setState(() => _f = !_f)),
        ]),
      );
}

Widget _autor(String autor, String sub) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Align(alignment: Alignment.centerLeft, child: ChipAutor(autor, legenda: sub, raio: 22)),
    );

/// Post de FOTO: imagem, titulo, descricao, curtir/favoritar e comentarios. (Video tera estilo proprio.)
class PostPagina extends StatelessWidget {
  const PostPagina({super.key, required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) => _Base(
        comentarios: post.comentarios,
        topo: [
          SafeArea(bottom: false, child: Row(children: [IconButton(icon: const Icon(Ic.voltar), onPressed: () => Navigator.pop(context)), const Spacer(), IconButton(icon: const Icon(Ic.maisHoriz), onPressed: () => emBreve(context, 'Opções'))])),
          _autor(post.autor, '11 nov'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AspectRatio(aspectRatio: 4 / 3, child: Capa(cor1: post.cor1, cor2: post.cor2, icone: post.icone, video: post.video, tamanhoIcone: 72, raio: 16)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(post.titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(post.descricao, style: const TextStyle(fontSize: 16)),
            ]),
          ),
          _Acoes(curtidas: post.curtidas, favoritos: post.curtidas ~/ 3),
        ],
      );
}

/// Asset ou PFP: capa, preco, obter/comprar, criador, curtir/favoritar e comentarios.
class ItemPagina extends StatelessWidget {
  const ItemPagina({super.key, required this.item});
  final ItemLoja item;

  @override
  Widget build(BuildContext context) {
    final i = item;
    return _Base(
      comentarios: const [Comentario('luna', 'Ficou ótimo!'), Comentario('zed', 'Posso usar em jogo comercial?')],
      topo: [
        Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [i.cor1.withAlpha(180), Cores.fundo], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Row(children: [IconButton(icon: const Icon(Ic.voltar), onPressed: () => Navigator.pop(context)), const Spacer(), IconButton(icon: const Icon(Ic.maisHoriz), onPressed: () => emBreve(context, 'Opções'))]),
              SizedBox(width: 140, height: 140, child: Capa(cor1: i.cor1, cor2: i.cor2, icone: i.icone, tamanhoIcone: 60, raio: i.pfp ? 70 : 20)),
              const SizedBox(height: 10),
              Text(i.titulo, style: const TextStyle(fontSize: 22)),
              Text(i.pfp ? 'PFP' : 'Asset', style: const TextStyle(color: Cores.texto2)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Ic.moeda, color: _ouro),
                const SizedBox(width: 6),
                Text(i.preco == 0 ? 'Grátis' : '${i.preco}', style: TextStyle(fontSize: 26, color: i.preco == 0 ? Cores.verde : const Color(0xFFFF7A33))),
              ]),
              const SizedBox(height: 12),
              BotaoPrimario(pulsa: true, texto: i.preco == 0 ? 'Obter' : 'Comprar', aoTocar: () => emBreve(context, i.preco == 0 ? 'Baixar' : 'Compra')),
              const SizedBox(height: 16),
            ]),
          ),
        ),
        _autor(i.autor, 'Criador'),
        const _Acoes(curtidas: 42, favoritos: 12),
      ],
    );
  }
}
