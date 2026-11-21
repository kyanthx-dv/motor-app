import 'package:flutter/material.dart';

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
  final _campo = TextEditingController();
  late final List<Comentario> _c = List.of(widget.comentarios);

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
              ...widget.topo,
              const Divider(),
              Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 4), child: Text('${_c.length} comentários', style: const TextStyle(fontSize: 18))),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: Column(children: [
                  if (_c.isEmpty) const Padding(padding: EdgeInsets.all(28), child: Center(child: Text('Vazio', style: TextStyle(color: Cores.texto2)))),
                  for (var i = 0; i < _c.length; i++)
                    Aparece(
                      key: ValueKey<int>(i),
                      indice: i,
                      child: ListTile(leading: CircleAvatar(radius: 18, child: Text(_c[i].autor[0].toUpperCase())), title: Text(_c[i].autor, style: const TextStyle(color: Cores.texto2, fontSize: 13)), subtitle: Text(_c[i].texto, style: const TextStyle(fontSize: 15))),
                    ),
                ]),
              ),
              const SizedBox(height: 24),
            ]),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), // o Scaffold ja sobe com o teclado
              child: Row(children: [
                Expanded(child: TextField(controller: _campo, decoration: const InputDecoration(hintText: 'Comentar…'))),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(72, 48)),
                  onPressed: () {
                    final t = _campo.text.trim();
                    if (t.isEmpty) return;
                    setState(() => _c.add(Comentario('você', t)));
                    _campo.clear();
                  },
                  child: const Text('Enviar'),
                ),
              ]),
            ),
          ),
        ]),
      );
}

class _Acoes extends StatefulWidget {
  const _Acoes({required this.curtidas, required this.favoritos, this.doar = false});
  final int curtidas;
  final int favoritos;
  final bool doar;

  @override
  State<_Acoes> createState() => _AcoesState();
}

class _AcoesState extends State<_Acoes> {
  bool _c = false;
  bool _f = false;

  Widget _b(Widget icone, String n, VoidCallback f) => Toque(
        aoTocar: f,
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20), child: Column(children: [icone, const SizedBox(height: 2), Text(n, style: const TextStyle(color: Cores.texto2))])),
      );

  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _b(IconeAnim(ligado: _c, ligadoIcone: Icons.favorite, desligadoIcone: Icons.favorite_border, cor: Colors.redAccent, tamanho: 32), abreviar(widget.curtidas + (_c ? 1 : 0)), () => setState(() => _c = !_c)),
        _b(IconeAnim(ligado: _f, ligadoIcone: Icons.star, desligadoIcone: Icons.star_border, cor: _ouro, tamanho: 32), abreviar(widget.favoritos + (_f ? 1 : 0)), () => setState(() => _f = !_f)),
        if (widget.doar) _b(const Icon(Icons.volunteer_activism_outlined, size: 32), 'Doar', () => emBreve(context, 'Doações')),
      ]);
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
          SafeArea(bottom: false, child: Row(children: [IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)), const Spacer(), IconButton(icon: const Icon(Icons.more_horiz), onPressed: () => emBreve(context, 'Opções'))])),
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
              Row(children: [IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)), const Spacer(), IconButton(icon: const Icon(Icons.more_horiz), onPressed: () => emBreve(context, 'Opções'))]),
              SizedBox(width: 140, height: 140, child: Capa(cor1: i.cor1, cor2: i.cor2, icone: i.icone, tamanhoIcone: 60, raio: i.pfp ? 70 : 20)),
              const SizedBox(height: 10),
              Text(i.titulo, style: const TextStyle(fontSize: 22)),
              Text(i.pfp ? 'PFP' : 'Asset', style: const TextStyle(color: Cores.texto2)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.monetization_on, color: _ouro),
                const SizedBox(width: 6),
                Text(i.preco == 0 ? 'Grátis' : '${i.preco}', style: TextStyle(fontSize: 26, color: i.preco == 0 ? Cores.verde : const Color(0xFFFF7A33))),
              ]),
              const SizedBox(height: 12),
              BotaoPrimario(texto: i.preco == 0 ? 'Obter' : 'Comprar', aoTocar: () => emBreve(context, i.preco == 0 ? 'Baixar' : 'Compra')),
              const SizedBox(height: 16),
            ]),
          ),
        ),
        _autor(i.autor, 'Criador'),
        const _Acoes(curtidas: 42, favoritos: 12, doar: true),
      ],
    );
  }
}
