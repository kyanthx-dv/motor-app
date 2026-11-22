import 'package:flutter/material.dart';

import 'avisos.dart';
import 'icones.dart';
import 'nuvem.dart';
import 'widgets.dart';

/// Editar perfil: nome e bio salvos no Supabase (o @ nao muda por aqui).
class EditarPerfilTela extends StatefulWidget {
  const EditarPerfilTela({super.key});

  @override
  State<EditarPerfilTela> createState() => _EditarPerfilTelaState();
}

class _EditarPerfilTelaState extends State<EditarPerfilTela> {
  final _nome = TextEditingController();
  final _bio = TextEditingController();
  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _nome.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final p = await Nuvem.i.meuPerfil();
      _nome.text = (p?['nome'] as String?) ?? '';
      _bio.text = (p?['bio'] as String?) ?? '';
    } on ErroNuvem catch (e) {
      Avisos.add(Nivel.aviso, 'Perfil: ${e.msg}');
      if (mounted) aviso(context, e.msg);
    }
    if (mounted) setState(() => _carregando = false);
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      await Nuvem.i.atualizarPerfil(_nome.text, _bio.text);
      if (!mounted) return;
      aviso(context, 'Perfil salvo.');
      Navigator.pop(context);
    } on ErroNuvem catch (e) {
      Avisos.add(Nivel.aviso, 'Perfil: ${e.msg}');
      if (mounted) aviso(context, e.msg);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Editar perfil'), leading: IconButton(icon: const Icon(Ic.voltar), onPressed: () => Navigator.pop(context))),
        body: _carregando
            ? const Center(child: CircularProgressIndicator())
            : ListView(padding: const EdgeInsets.all(20), children: [
                Row(children: [
                  Icon(Ic.arroba, size: 18, color: Cores.texto2),
                  const SizedBox(width: 6),
                  Text(Nuvem.i.usuario ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  const Text('(o nome de usuário não muda)', style: TextStyle(color: Cores.texto2, fontSize: 12)),
                ]),
                const SizedBox(height: 18),
                TextField(controller: _nome, maxLength: 40, decoration: const InputDecoration(labelText: 'Nome')),
                const SizedBox(height: 12),
                TextField(controller: _bio, maxLength: 280, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Bio')),
                const SizedBox(height: 18),
                BotaoPrimario(texto: _salvando ? 'Salvando…' : 'Salvar', aoTocar: _salvando ? null : _salvar),
              ]),
      );
}
