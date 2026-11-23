import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'avisos.dart';
import 'dados.dart';
import 'mapa.dart';
import 'objeto.dart';
import 'projetos.dart';
import 'servidor.dart';
import 'widgets.dart';

/// Roda um projeto do editor de celular com a engine real (jogar.html do motor), em tela cheia.
Future<void> executar(BuildContext context, Projeto p, {Cena? daCena}) {
  if (p.cenas.isEmpty) {
    aviso(context, 'Crie uma cena antes de executar.');
    return Future.value();
  }
  return Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => JogarTela(projeto: p, daCena: daCena)));
}

class JogarTela extends StatefulWidget {
  const JogarTela({super.key, required this.projeto, this.daCena});
  final Projeto projeto;
  final Cena? daCena;

  @override
  State<JogarTela> createState() => _JogarTelaState();
}

class _JogarTelaState extends State<JogarTela> {
  late final WebViewController _web;

  @override
  void initState() {
    super.initState();
    final retrato = widget.projeto.orientacao == Orientacao.retrato;
    SystemChrome.setPreferredOrientations(retrato ? [DeviceOrientation.portraitUp] : [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    final json = widget.projeto.toJson();
    final cenasJson = json['cenas'] as List;
    for (var i = 0; i < cenasJson.length; i++) {
      final ce = widget.projeto.cenas[i];
      (cenasJson[i] as Map<String, dynamic>)['obj'] = {
        for (final e in ce.celulas.entries)
          if (e.value >= 0 && e.value < paleta.length) e.key: objetoEfetivo(ce, e.key, paleta[e.value]),
      };
    }
    if (widget.daCena != null) {
      final cenas = cenasJson;
      for (var i = 0; i < cenas.length; i++) {
        (cenas[i] as Map<String, dynamic>)['ini'] = identical(widget.projeto.cenas[i], widget.daCena);
      }
    }
    final dados = jsonEncode({
      'projeto': json,
      'paleta': [
        for (final it in paleta)
          // ignore: deprecated_member_use
          {'nome': it.nome, 'aba': it.aba, 'cor': it.cor.value},
      ],
    });
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF141414))
      ..setOnConsoleMessage((m) {
        if (m.level == JavaScriptLogLevel.error) Avisos.add(Nivel.erro, 'Jogo: ${m.message}');
      })
      ..addJavaScriptChannel('Sair', onMessageReceived: (_) {
        if (mounted) Navigator.of(context).pop();
      })
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) => _web.runJavaScript('iniciarProjeto($dados)')))
      ..loadRequest(Uri.parse('http://127.0.0.1:$portaLocal/jogar.html'));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFF141414), body: WebViewWidget(controller: _web));
}
