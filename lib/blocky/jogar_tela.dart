import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'avisos.dart';
import 'biblioteca.dart';
import 'dados.dart';
import 'mapa.dart';
import 'objeto.dart';
import 'pre_arte.dart';
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
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF141414))
      ..setOnConsoleMessage((m) {
        if (m.level == JavaScriptLogLevel.error) Avisos.add(Nivel.erro, 'Jogo: ${m.message}');
      })
      ..addJavaScriptChannel('Sair', onMessageReceived: (_) {
        if (mounted) Navigator.of(context).pop();
      })
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) async => _web.runJavaScript('iniciarProjeto(${await _dados()})')))
      ..loadRequest(Uri.parse('http://127.0.0.1:$portaLocal/jogar.html'));
  }

  Future<String> _dados() async {
    await Biblioteca.i.carregar();
    final json = widget.projeto.toJson();
    final cenasJson = json['cenas'] as List;
    for (var i = 0; i < cenasJson.length; i++) {
      final ce = widget.projeto.cenas[i];
      (cenasJson[i] as Map<String, dynamic>)['objs'] = [
        for (final o in ce.objetos)
          if (itemDe(o.v) != null) {'x': o.x, 'y': o.y, 'w': o.w, 'h': o.h, 'v': o.v, ...objetoEfetivo(o, itemDe(o.v)!)},
      ];
    }
    if (widget.daCena != null) {
      final cenas = cenasJson;
      for (var i = 0; i < cenas.length; i++) {
        (cenas[i] as Map<String, dynamic>)['ini'] = identical(widget.projeto.cenas[i], widget.daCena);
      }
    }
    // sprites usados (pela celula ou pela imagem escolhida no objeto): prontos viram PNG 16x16, desenhos do usuario vem da biblioteca
    final usados = <int>{};
    for (final ce in widget.projeto.cenas) {
      for (final o in ce.objetos) {
        usados.add(o.v);
        final t = (o.props['textura'] as num?)?.toInt();
        if (t != null) usados.add(t);
      }
    }
    final imagens = <String, dynamic>{};
    for (final v in usados) {
      if (v >= baseAsset) {
        final a = Biblioteca.i.porId(v - baseAsset), png = a == null ? null : await Biblioteca.i.pngBytes(a.id);
        if (a != null && png != null) imagens['$v'] = {'nome': a.nome, 'l': a.l, 'a': a.a, 'png': 'data:image/png;base64,${base64Encode(png)}'};
      } else if (v >= 0 && v < paleta.length && preArtes.containsKey(paleta[v].nome)) {
        imagens['$v'] = {'nome': paleta[v].nome, 'l': 16, 'a': 16, 'png': 'data:image/png;base64,${base64Encode(await pngPre(paleta[v].nome))}'};
      }
    }
    return jsonEncode({
      'imagens': imagens,
      'projeto': json,
      'paleta': [
        for (final it in paleta)
          // ignore: deprecated_member_use
          {'nome': it.nome, 'aba': it.aba, 'cor': it.cor.value},
      ],
    });
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
