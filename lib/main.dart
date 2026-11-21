import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'dart:ui' show PlatformDispatcher;
import 'blocky/abertura.dart';
import 'blocky/avisos.dart';
import 'blocky/projetos.dart';
import 'blocky/servidor.dart';
import 'blocky/widgets.dart';

/// Servidor HTTP local (127.0.0.1, porta livre) que serve o motor empacotado em assets/web.
/// Por que: Workers, service worker e fetch do editor precisam de origem http, nao file://.
Future<HttpServer> iniciarServidor() async {
  final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  servidor.listen((req) async {
    final r = req.response;
    try {
      var caminho = Uri.decodeComponent(req.uri.path);
      if (caminho.contains('..')) {
        r.statusCode = HttpStatus.forbidden;
      } else {
        if (caminho.endsWith('/')) caminho += 'index.html';
        final dados = await rootBundle.load('assets/web$caminho');
        r.headers.contentType =
            ContentType.parse(lookupMimeType(caminho) ?? 'application/octet-stream');
        r.headers.set('Cache-Control', 'no-cache');
        r.add(dados.buffer.asUint8List(dados.offsetInBytes, dados.lengthInBytes));
      }
    } catch (_) {
      r.statusCode = HttpStatus.notFound;
    }
    await r.close();
  });
  return servidor;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (d) {
    Avisos.add(Nivel.erro, d.exceptionAsString());
    FlutterError.presentError(d);
  };
  PlatformDispatcher.instance.onError = (e, s) {
    Avisos.add(Nivel.erro, '$e');
    return true;
  };
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final servidor = await iniciarServidor();
  portaLocal = servidor.port;
  await RepositorioProjetos.instancia.carregar();
  runApp(const BlockyApp());
}

class BlockyApp extends StatefulWidget {
  const BlockyApp({super.key});

  @override
  State<BlockyApp> createState() => _BlockyAppState();
}

class _BlockyAppState extends State<BlockyApp> {
  @override
  void initState() {
    super.initState();
    temaEscuro.addListener(_trocou);
  }

  @override
  void dispose() {
    temaEscuro.removeListener(_trocou);
    super.dispose();
  }

  // Troca o tema SEM recriar o Navigator (assim a sessao/telas abertas continuam).
  // As cores vem de getters (Cores.*), entao forcamos reconstruir toda a arvore.
  void _trocou() {
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void refazer(Element e) {
        e.markNeedsBuild();
        e.visitChildren(refazer);
      }

      (context as Element).visitChildren(refazer);
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Blocky',
        debugShowCheckedModeBanner: false,
        theme: temaBlocky(temaEscuro.value),
        builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(0.9)), child: child!),
        home: const AberturaTela(),
      );
}
