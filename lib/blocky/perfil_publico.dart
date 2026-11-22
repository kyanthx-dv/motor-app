import 'package:flutter/material.dart';

import 'icones.dart';
import 'package:flutter/services.dart';

import 'abas.dart';
import 'dados.dart';
import 'detalhes.dart';
import 'extras.dart';
import 'jogo.dart';
import 'widgets.dart';

/// Cor estavel por usuario (para o avatar enquanto nao ha foto).
List<Color> _coresDe(String u) {
  const solidos = [Color(0xFF1D9BF0), Color(0xFFF97316), Color(0xFF23A55A), Color(0xFFF23F43), Color(0xFFF59E0B), Color(0xFF3A3D42)];
  final c = solidos[u.codeUnits.fold<int>(0, (a, b) => a + b) % solidos.length];
  return [c, c];
}

Pessoa pessoaDe(String usuario) => pessoasExemplo.firstWhere((p) => p.usuario == usuario, orElse: () => Pessoa(usuario, usuario, 0));

IconData iconeSelo(Selo s) => switch (s) {
      Selo.dono => Ic.coroa,
      Selo.verificado => Ic.selo,
      Selo.premium => Ic.diamante,
      Selo.bot => Ic.robo,
    };

Color corSelo(Selo s) => switch (s) {
      Selo.dono => const Color(0xFFE5A93B),
      Selo.verificado => const Color(0xFF3B9EF5),
      Selo.premium => const Color(0xFFD16BA5),
      Selo.bot => const Color(0xFF3FB6A8),
    };

String nomeSelo(Selo s) => switch (s) {
      Selo.dono => 'Dono',
      Selo.verificado => 'Verificado',
      Selo.premium => 'Premium',
      Selo.bot => 'Bot',
    };

String descSelo(Selo s) => switch (s) {
      Selo.dono => 'Fundador ou dono da plataforma.',
      Selo.verificado => 'Conta confirmada pela equipe do Blocky.',
      Selo.premium => 'Apoia o Blocky com a assinatura Premium.',
      Selo.bot => 'Conta automática (não é uma pessoa).',
    };

/// Selos ao lado do nome. Toque em um para ver o que significa.
class Selos extends StatelessWidget {
  const Selos(this.selos, {super.key, this.tamanho = 18});
  final List<Selo> selos;
  final double tamanho;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (final s in selos)
          GestureDetector(
            onTap: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(iconeSelo(s), color: corSelo(s), size: 44), const SizedBox(height: 8), Text(nomeSelo(s), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(descSelo(s), textAlign: TextAlign.center, style: const TextStyle(color: Cores.texto2))]))),
            ),
            child: Padding(padding: const EdgeInsets.only(left: 4), child: Icon(iconeSelo(s), color: corSelo(s), size: tamanho)),
          ),
      ]);
}

void abrirPerfil(BuildContext context, String usuario) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PerfilPublicoTela(usuario: usuario)));

/// Foto de perfil (por enquanto, inicial sobre degrade).
class AvatarUsuario extends StatelessWidget {
  const AvatarUsuario(this.usuario, {super.key, this.raio = 18, this.anel = false});
  final String usuario;
  final double raio;
  final bool anel; // moldura azul (perfis)

  @override
  Widget build(BuildContext context) {
    final c = _coresDe(usuario);
    if (anel) {
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Cores.acento),
        child: Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: Cores.fundo, shape: BoxShape.circle), child: AvatarUsuario(usuario, raio: raio)),
      );
    }
    return Container(
      width: raio * 2,
      height: raio * 2,
      decoration: BoxDecoration(shape: BoxShape.circle, color: c.first),
      child: Center(child: Text(usuario[0].toUpperCase(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: raio * 0.95))),
    );
  }
}

/// Autor compacto: foto + nome + @id. Toque abre o perfil (la fica o botao de seguir).
class ChipAutor extends StatelessWidget {
  const ChipAutor(this.usuario, {super.key, this.legenda, this.raio = 18});
  final String usuario;
  final String? legenda; // ex.: data
  final double raio;

  @override
  Widget build(BuildContext context) {
    final p = pessoaDe(usuario);
    return Toque(
      aoTocar: () => abrirPerfil(context, usuario),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        AvatarUsuario(usuario, raio: raio),
        const SizedBox(width: 10),
        Flexible(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(child: Text(p.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
              for (final x in p.selos) Padding(padding: const EdgeInsets.only(left: 3), child: Icon(iconeSelo(x), color: corSelo(x), size: 14)),
            ]),
            Text(legenda == null ? '@${p.usuario}' : '@${p.usuario} · $legenda', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Cores.texto2, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}

/// Perfil de outra pessoa: aqui (e so aqui, alem das notificacoes) existe o botao Seguir.
class PerfilPublicoTela extends StatelessWidget {
  const PerfilPublicoTela({super.key, required this.usuario});
  final String usuario;

  void _ir(BuildContext context, Widget w) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    final p = pessoaDe(usuario);
    final jogos = jogosExemplo.where((j) => j.autor == usuario).toList();
    final posts = postsExemplo.where((x) => x.autor == usuario).toList();
    final itens = itensLojaExemplo.where((i) => i.autor == usuario).toList();
    Widget vazio() => const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Nada publicado ainda.', style: TextStyle(color: Cores.texto2))));
    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(
              child: CabecalhoPerfil(
                usuario: usuario,
                esquerda: IconButton.filledTonal(icon: const Icon(Ic.voltar), onPressed: () => Navigator.pop(context)),
                stats: [('${jogos.length + posts.length + itens.length}', 'Publicações'), (abreviar(p.seguidores), 'Seguidores'), ('${p.seguindo}', 'Seguindo')],
                botoes: Row(children: [
                  BotaoSeguir(usuario: usuario),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton(onPressed: () => emBreve(context, 'Mensagens'), child: const Text('Mensagem'))),
                ]),
              ),
            ),
            SliverPersistentHeader(pinned: true, delegate: TabsFixas(const BarraAbas(['Jogos', 'Assets', 'Posts']))),
          ],
          body: TabBarView(children: [
            jogos.isEmpty
                ? vazio()
                : GridView.count(padding: const EdgeInsets.all(14), crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 12, childAspectRatio: 1.2, children: [for (final j in jogos) CartaoJogo(jogo: j, aoTocar: () => _ir(context, JogoPagina(jogo: j)))]),
            itens.isEmpty
                ? vazio()
                : GridView.count(padding: const EdgeInsets.all(14), crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, children: [for (final i in itens) Toque(aoTocar: () => _ir(context, ItemPagina(item: i)), child: Capa(cor1: i.cor1, cor2: i.cor2, icone: i.icone))]),
            posts.isEmpty ? vazio() : ListView(padding: const EdgeInsets.all(14), children: [for (final x in posts) CartaoPost(post: x)]),
          ]),
        ),
      ),
    );
  }
}

/// Topo de perfil (proprio e publico): banner, foto, nome + selos, @usuario e ID.
/// O banner e um espaco pronto: hoje degrade; depois mostra a imagem enviada.
class CabecalhoPerfil extends StatelessWidget {
  const CabecalhoPerfil({super.key, required this.usuario, this.esquerda, this.direita, this.proprio = false, this.stats = const [], this.botoes});
  final String usuario;
  final Widget? esquerda; // ex.: voltar
  final Widget? direita; // ex.: configuracoes
  final bool proprio;
  final List<(String, String)> stats; // numeros ao lado da foto
  final Widget? botoes; // linha de botoes abaixo da bio

  @override
  Widget build(BuildContext context) {
    final p = pessoaDe(usuario);
    final c = _coresDe(usuario);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Stack(clipBehavior: Clip.none, children: [
        Container(
          height: 130,
          width: double.infinity,
          decoration: BoxDecoration(color: c.first.withAlpha(150)),
          child: SafeArea(
            bottom: false,
            child: Padding(padding: const EdgeInsets.all(8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [if (esquerda != null) esquerda!, const Spacer(), if (direita != null) direita!])),
          ),
        ),
        if (proprio)
          Positioned(
            right: 12,
            bottom: 10,
            child: Toque(
              aoTocar: () => emBreve(context, 'Alterar banner'),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.black.withAlpha(110), borderRadius: BorderRadius.circular(14)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Ic.camera, size: 15, color: Colors.white), SizedBox(width: 5), Text('Banner', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700))])),
            ),
          ),
        Positioned(left: 16, bottom: -42, child: AvatarUsuario(usuario, raio: 40, anel: true)),
      ]),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(children: [
          const SizedBox(width: 100),
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              for (final s in stats) Column(children: [Text(s.$1, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), Text(s.$2, style: const TextStyle(color: Cores.texto2, fontSize: 12))]),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Flexible(child: Text(p.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))), Selos(p.selos, tamanho: 20)]),
          const SizedBox(height: 4),
          Row(children: [
            Text('@${p.usuario}', style: const TextStyle(color: Cores.texto2)),
            const SizedBox(width: 8),
            Toque(
              aoTocar: () {
                Clipboard.setData(ClipboardData(text: '${p.id}'));
                aviso(context, 'ID ${p.id} copiado.');
              },
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Cores.cartao2, borderRadius: BorderRadius.circular(8)), child: Text('ID ${p.id}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Cores.texto2))),
            ),
          ]),
          if (p.bio.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(p.bio)),
        ]),
      ),
      if (botoes != null) Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 12), child: botoes),
    ]);
  }
}
