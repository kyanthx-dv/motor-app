import 'package:flutter/material.dart';

import 'icones.dart';
import 'casca.dart';
import 'dados.dart';
import 'abertura.dart';
import 'widgets.dart';

/// Login / criar conta (modo demonstracao: ainda nao liga no Supabase).
class EntradaTela extends StatefulWidget {
  const EntradaTela({super.key});

  @override
  State<EntradaTela> createState() => _EntradaTelaState();
}

class _EntradaTelaState extends State<EntradaTela> {
  final _usuario = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _criar = false;
  bool _idade = false;
  bool _ver = false;

  @override
  void dispose() {
    _usuario.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  void _seguir() => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const BoasVindasTela()));

  void _enviar() {
    if (_criar && !_idade) {
      aviso(context, 'É preciso ter 13 anos ou mais para criar conta.');
      return;
    }
    _seguir();
  }

  Widget _modo(String t, bool criar) {
    final ativo = _criar == criar;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _criar = criar),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(color: ativo ? Cores.cartao : Colors.transparent, borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(t, style: TextStyle(fontWeight: FontWeight.w800, color: ativo ? null : Cores.texto2))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          Expanded(
            flex: 2,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const LogoBlocky(tamanho: 76),
                  const SizedBox(height: 14),
                  const Text('Blocky', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
                  const SizedBox(height: 2),
                  Text(_criar ? 'Crie sua conta e comece a construir' : 'Que bom te ver de volta', style: const TextStyle(color: Cores.texto2)),
                ]),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Cores.cartao, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
              child: SafeArea(
                top: false,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Cores.cartao2, borderRadius: BorderRadius.circular(18)),
                          child: Row(children: [_modo('Entrar', false), _modo('Criar conta', true)]),
                        ),
                        const SizedBox(height: 18),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: _criar
                              ? Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: _usuario, decoration: const InputDecoration(hintText: 'Nome de usuário', prefixIcon: Icon(Ic.arroba))))
                              : const SizedBox(width: double.infinity),
                        ),
                        TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'E-mail', prefixIcon: Icon(Ic.email))),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _senha,
                          obscureText: !_ver,
                          decoration: InputDecoration(hintText: 'Senha (8+ caracteres)', prefixIcon: const Icon(Ic.cadeado), suffixIcon: IconButton(icon: Icon(_ver ? Ic.olhoFechado : Ic.olho), onPressed: () => setState(() => _ver = !_ver))),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: _criar
                              ? CheckboxListTile(value: _idade, onChanged: (v) => setState(() => _idade = v ?? false), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, title: const Text('Tenho 13 anos ou mais', style: TextStyle(fontSize: 13)))
                              : Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => emBreve(context, 'Recuperar senha'), child: const Text('Esqueci a senha'))),
                        ),
                        const SizedBox(height: 8),
                        BotaoPrimario(texto: _criar ? 'Criar conta' : 'Entrar', aoTocar: _enviar),
                        const SizedBox(height: 6),
                        TextButton(onPressed: _seguir, child: const Text('Continuar como visitante')),
                        const Text('Modo demonstração: dados de exemplo.', textAlign: TextAlign.center, style: TextStyle(color: Cores.texto2, fontSize: 11)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
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
        'novidade' => Ic.brilho,
        'erro' => Ic.alerta,
        _ => Ic.ideia,
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
