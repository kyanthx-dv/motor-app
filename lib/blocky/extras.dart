import 'package:flutter/material.dart';

import 'icones.dart';
import 'dados.dart';
import 'avisos.dart';
import 'nuvem.dart';
import 'perfil_publico.dart';
import 'widgets.dart';

/// Seguir/Seguindo: pilula compacta (so aparece no perfil e nas notificacoes de seguidor).
class BotaoSeguir extends StatefulWidget {
  const BotaoSeguir({super.key, this.usuario, this.inicial = false});
  final String? usuario;
  final bool inicial;

  @override
  State<BotaoSeguir> createState() => _BotaoSeguirState();
}

class _BotaoSeguirState extends State<BotaoSeguir> {
  late bool _seguindo = widget.inicial;
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    if (u != null && Nuvem.i.logado) {
      Nuvem.i.sigoUsuario(u).then((v) {
        if (mounted && v) setState(() => _seguindo = true);
      }).catchError((Object _) {});
    }
  }

  Future<void> _alternar() async {
    final u = widget.usuario;
    if (u == null) return setState(() => _seguindo = !_seguindo);
    if (_ocupado) return;
    final novo = !_seguindo;
    setState(() {
      _seguindo = novo;
      _ocupado = true;
    });
    try {
      await Nuvem.i.seguir(u, novo);
    } on ErroNuvem catch (e) {
      if (mounted) {
        setState(() => _seguindo = !novo);
        aviso(context, e.msg);
      }
    } finally {
      _ocupado = false;
    }
  }

  @override
  Widget build(BuildContext context) => Toque(
        aoTocar: _alternar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: _seguindo ? Cores.cartao2 : Cores.acento, borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: Icon(_seguindo ? Ic.ok : Ic.mais, key: ValueKey<bool>(_seguindo), size: 16, color: _seguindo ? Cores.texto2 : Colors.white)),
            const SizedBox(width: 4),
            Text(_seguindo ? 'Seguindo' : 'Seguir', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _seguindo ? Cores.texto2 : Colors.white)),
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
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Ic.moeda, color: _ouro, size: 44), SizedBox(width: 8), Text('120', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w500, color: Color(0xFFFF7A33)))]),
            TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Ganhar moedas'),
                  content: const Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Ic.moeda, color: _ouro, size: 90),
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

class NotificacoesTela extends StatefulWidget {
  const NotificacoesTela({super.key});

  @override
  State<NotificacoesTela> createState() => _NotificacoesTelaState();
}

class _NotificacoesTelaState extends State<NotificacoesTela> {
  List<Map<String, dynamic>>? _itens;
  String? _erro;
  Set<String> _novas = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final l = await Nuvem.i.notificacoes();
      if (!mounted) return;
      setState(() {
        _itens = l;
        _erro = null;
        _novas = {for (final e in l) if (e['lida'] != true) e['id'] as String};
      });
      if (_novas.isNotEmpty) await Nuvem.i.marcarTodasLidas();
    } on ErroNuvem catch (e) {
      if (mounted) setState(() => _erro = e.msg);
      Avisos.add(Nivel.erro, 'Notificações: ${e.msg}');
    }
  }

  static String _tempo(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    final dif = DateTime.now().difference(d);
    if (dif.inMinutes < 1) return 'agora';
    if (dif.inMinutes < 60) return '${dif.inMinutes} min';
    if (dif.inHours < 24) return '${dif.inHours} h';
    if (dif.inDays < 7) return '${dif.inDays} d';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  static String _texto(Map<String, dynamic> n) {
    final alvo = switch (n['alvo_tipo']) { 'jogo' => 'seu jogo', 'asset' => 'seu asset', _ => 'seu post' };
    return switch (n['tipo']) {
      'seguir' => 'começou a seguir você',
      'curtida' => 'curtiu $alvo',
      'comentario' => 'comentou em $alvo',
      'resposta' => 'respondeu seu comentário',
      _ => 'interagiu com você',
    };
  }

  static IconData _icone(String? t) => switch (t) { 'seguir' => Ic.usuario, 'curtida' => Ic.coracao, _ => Ic.balao };

  @override
  Widget build(BuildContext context) {
    final itens = _itens;
    return Scaffold(
      appBar: AppBar(title: const Text('Notificações'), centerTitle: true),
      body: !Nuvem.i.logado
          ? const Center(child: Text('Entre na sua conta para ver suas notificações.', style: TextStyle(color: Cores.texto2)))
          : _erro != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_erro!, style: const TextStyle(color: Cores.texto2)), TextButton(onPressed: _carregar, child: const Text('Tentar de novo'))]))
              : itens == null
                  ? const Center(child: CircularProgressIndicator())
                  : itens.isEmpty
                      ? const Center(child: Text('Nada por aqui ainda.', style: TextStyle(color: Cores.texto2)))
                      : RefreshIndicator(
                          onRefresh: _carregar,
                          child: ListView.separated(
                            itemCount: itens.length,
                            separatorBuilder: (_, __) => Divider(color: Cores.divisor, height: 1),
                            itemBuilder: (_, i) {
                              final n = itens[i];
                              final p = (n['perfis'] as Map?) ?? const {};
                              final usuario = (p['usuario'] as String?) ?? '?';
                              final nova = _novas.contains(n['id']);
                              return ListTile(
                                tileColor: nova ? Cores.cartao : null,
                                leading: AvatarUsuario(usuario, raio: 22),
                                title: Text.rich(TextSpan(children: [
                                  TextSpan(text: '@$usuario ', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  TextSpan(text: _texto(n)),
                                ])),
                                subtitle: Text(_tempo('${n['criado_em']}'), style: const TextStyle(color: Cores.texto2, fontSize: 12)),
                                trailing: Icon(_icone(n['tipo'] as String?), size: 20, color: Cores.texto2),
                                onTap: () => abrirPerfil(context, usuario),
                              );
                            },
                          ),
                        ),
    );
  }
}

class ChatTela extends StatelessWidget {
  const ChatTela({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mensagens'), centerTitle: true, actions: [IconButton(icon: const Icon(Ic.maisCirculo), onPressed: () => emBreve(context, 'Nova conversa'))]),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(readOnly: true, onTap: () => emBreve(context, 'Buscar conversas'), decoration: const InputDecoration(hintText: 'Buscar', prefixIcon: Icon(Ic.busca))),
          const SizedBox(height: 8),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(radius: 28, backgroundColor: Color(0xFF0EA5FF), child: Icon(Ic.aviso, color: Colors.white)),
            title: Text('Notificação do sistema'),
            subtitle: Text('Bem-vindo ao Blocky · hoje', style: TextStyle(color: Cores.texto2)),
          ),
          const Padding(padding: EdgeInsets.all(12), child: Text('Mensagens privadas entram quando a segurança estiver pronta.', style: TextStyle(color: Cores.texto2), textAlign: TextAlign.center)),
        ]),
      );
}
