import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'blocky/entrada.dart';
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
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final servidor = await iniciarServidor();
  portaLocal = servidor.port;
  runApp(const BlockyApp());
}

class BlockyApp extends StatelessWidget {
  const BlockyApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: temaEscuro,
        builder: (_, escuro, __) => MaterialApp(
          key: ValueKey<bool>(escuro), // recria as telas para pegar as novas cores
          title: 'Blocky',
          debugShowCheckedModeBanner: false,
          theme: temaBlocky(escuro),
          home: const EntradaTela(),
        ),
      );
}
