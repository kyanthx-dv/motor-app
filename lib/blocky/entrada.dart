import 'package:flutter/material.dart';

import 'casca.dart';
import 'dados.dart';
import 'abertura.dart';
import 'widgets.dart';

/// Login (modo demonstracao: ainda nao liga no Supabase).
class EntradaTela extends StatefulWidget {
  const EntradaTela({super.key});

  @override
  State<EntradaTela> createState() => _EntradaTelaState();
}

class _EntradaTelaState extends State<EntradaTela> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _idade = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  void _entrar() => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const BoasVindasTela()));

  void _criar() {
    if (!_idade) {
      aviso(context, 'É preciso ter 13 anos ou mais para criar conta.');
      return;
    }
    _entrar();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const LogoBlocky(tamanho: 84),
                  const SizedBox(height: 8),
                  const Text('Blocky', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
                  const Text('Crie, jogue e compartilhe jogos 2D', style: TextStyle(color: Cores.texto2)),
                  const SizedBox(height: 28),
                  TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'E-mail')),
                  const SizedBox(height: 12),
                  TextField(controller: _senha, obscureText: true, decoration: const InputDecoration(hintText: 'Senha (8+ caracteres)')),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _idade,
                    onChanged: (v) => setState(() => _idade = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tenho 13 anos ou mais', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity, child: BotaoPrimario(texto: 'Entrar', aoTocar: _entrar)),
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity, height: 48, child: OutlinedButton(onPressed: _criar, child: const Text('Criar conta'))),
                  const SizedBox(height: 16),
                  const Text('Modo demonstração: dados de exemplo.', style: TextStyle(color: Cores.texto2, fontSize: 12)),
                ]),
              ),
            ),
          ),
        ),
      );
}

/// Painel de boas-vindas: lista de avisos (novidades, dicas, erros) que podera vir do servidor.
class BoasVindasTela extends StatelessWidget {
  const BoasVindasTela({super.key});

  Color _cor(String tipo) => switch (tipo) {
        'novidade' => Cores.acento,
        'erro' => const Color(0xFFF59E0B),
        _ => const Color(0xFF38BDF8),
      };

  IconData _icone(String tipo) => switch (tipo) {
        'novidade' => Icons.auto_awesome,
        'erro' => Icons.warning_amber_rounded,
        _ => Icons.lightbulb_outline,
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 12),
              const Text('Bem-vindo ao Blocky!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const Text('Veja o que há de novo', style: TextStyle(color: Cores.texto2)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(children: [
                  for (final a in avisosExemplo)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Cores.cartao,
                        borderRadius: BorderRadius.circular(14),
                        border: Border(left: BorderSide(color: _cor(a.tipo), width: 4)),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(_icone(a.tipo), color: _cor(a.tipo)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(a.titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(a.texto, style: const TextStyle(color: Cores.texto2)),
                          ]),
                        ),
                      ]),
                    ),
                ]),
              ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const Casca())),
                  child: const Text('Continuar'),
                ),
              ),
            ]),
          ),
        ),
      );
}
