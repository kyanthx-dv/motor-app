import 'package:flutter/material.dart';

import 'dados.dart';
import 'perfil_publico.dart';
import 'widgets.dart';

/// Seguir/Seguindo: pilula compacta (so aparece no perfil e nas notificacoes de seguidor).
class BotaoSeguir extends StatefulWidget {
  const BotaoSeguir({super.key, this.inicial = false});
  final bool inicial;

  @override
  State<BotaoSeguir> createState() => _BotaoSeguirState();
}

class _BotaoSeguirState extends State<BotaoSeguir> {
  late bool _seguindo = widget.inicial;

  @override
  Widget build(BuildContext context) => Toque(
        aoTocar: () => setState(() => _seguindo = !_seguindo),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(gradient: _seguindo ? null : degradeMarca, color: _seguindo ? Cores.cartao2 : null, borderRadius: BorderRadius.circular(17)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: Icon(_seguindo ? Icons.check : Icons.add, key: ValueKey<bool>(_seguindo), size: 16, color: _seguindo ? Cores.texto2 : Colors.white)),
            const SizedBox(width: 4),
            Text(_seguindo ? 'Seguindo' : 'Seguir', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _seguindo ? Cores.texto2 : Colors.white)),
          ]),
        ),
      );
}

const _ouro = Color(0xFFFBBF24);

class CarteiraTela extends StatelessWidget {
  const CarteiraTela({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(title: const Text('Carteira'), centerTitle: true),
          body: Column(children: [
            const SizedBox(height: 20),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.monetization_on, color: _ouro, size: 44), SizedBox(width: 8), Text('120', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w500, color: Color(0xFFFF7A33)))]),
            TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Ganhar moedas'),
                  content: const Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.monetization_on, color: _ouro, size: 90),
                    Text('+100', style: TextStyle(fontSize: 28, color: Color(0xFFFF7A33))),
                    SizedBox(height: 8),
                    Text('Hoje as moedas vêm de anúncios. No futuro: BCoins comprados com dinheiro real.', textAlign: TextAlign.center, style: TextStyle(color: Cores.texto2)),
                  ]),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF7A33)),
                      onPressed: () {
                        Navigator.pop(context);
                        emBreve(context, 'Anúncios');
                      },
                      child: const Text('Ver anúncio'),
                    ),
                  ],
                ),
              ),
              child: const Text('Ganhar moedas  ›'),
            ),
            const BarraAbas(['Entradas', 'Saídas']),
            Expanded(
              child: TabBarView(children: [
                ListView(children: [
                  for (final p in pessoasExemplo)
                    ListTile(leading: CircleAvatar(child: Text(p.nome[0])), title: Text(p.nome), subtitle: const Text('Doação', style: TextStyle(color: Cores.texto2)), trailing: const Text('+15', style: TextStyle(color: Color(0xFFFF7A33), fontSize: 20))),
                ]),
                const Center(child: Text('Nenhuma saída ainda.', style: TextStyle(color: Cores.texto2))),
              ]),
            ),
          ]),
        ),
      );
}

class NotificacoesTela extends StatelessWidget {
  const NotificacoesTela({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Notificações'),
            centerTitle: true,
            bottom: const BarraAbas(['Seguidores', 'Interações', 'Comentários', 'Sistema'], rolavel: true),
          ),
          body: TabBarView(children: [
            ListView(children: [
              for (final p in pessoasExemplo)
                ListTile(
                  leading: AvatarUsuario(p.usuario, raio: 24),
                  title: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('@${p.usuario} · começou a seguir você', style: const TextStyle(color: Cores.texto2, fontSize: 12)),
                  trailing: const BotaoSeguir(),
                  onTap: () => abrirPerfil(context, p.usuario),
                ),
            ]),
            ListView(children: const [
              ListTile(leading: Icon(Icons.favorite_border), title: Text('luna curtiu seu jogo'), subtitle: Text('Mini-RPG da Vila')),
              ListTile(leading: Icon(Icons.star_border), title: Text('zed favoritou seu asset')),
            ]),
            ListView(children: const [ListTile(leading: Icon(Icons.chat_bubble_outline), title: Text('ana_01 comentou'), subtitle: Text('Muito legal o inventário!'))]),
            ListView(children: [for (final a in avisosExemplo) ListTile(leading: const Icon(Icons.campaign_outlined), title: Text(a.titulo), subtitle: Text(a.texto))]),
          ]),
        ),
      );
}

class ChatTela extends StatelessWidget {
  const ChatTela({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mensagens'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => emBreve(context, 'Nova conversa'))]),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(readOnly: true, onTap: () => emBreve(context, 'Buscar conversas'), decoration: const InputDecoration(hintText: 'Buscar', prefixIcon: Icon(Icons.search))),
          const SizedBox(height: 8),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(radius: 28, backgroundColor: Color(0xFF0EA5FF), child: Icon(Icons.campaign, color: Colors.white)),
            title: Text('Notificação do sistema'),
            subtitle: Text('Bem-vindo ao Blocky · hoje', style: TextStyle(color: Cores.texto2)),
          ),
          const Padding(padding: EdgeInsets.all(12), child: Text('Mensagens privadas entram quando a segurança estiver pronta.', style: TextStyle(color: Cores.texto2), textAlign: TextAlign.center)),
        ]),
      );
}
