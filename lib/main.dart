import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

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
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final servidor = await iniciarServidor();
  runApp(MotorApp(porta: servidor.port));
}

class MotorApp extends StatelessWidget {
  const MotorApp({super.key, required this.porta});
  final int porta;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Motor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: Tela(porta: porta),
      );
}

class Tela extends StatefulWidget {
  const Tela({super.key, required this.porta});
  final int porta;

  @override
  State<Tela> createState() => _TelaState();
}

class _TelaState extends State<Tela> {
  late final WebViewController _web;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF111827))
      ..setOnConsoleMessage((m) => debugPrint('[web] ${m.message}'))
      ..loadRequest(Uri.parse('http://127.0.0.1:${widget.porta}/editor/index.html'));
    final p = _web.platform;
    if (p is AndroidWebViewController) {
      p.setMediaPlaybackRequiresUserGesture(false); // sons do jogo sem exigir toque previo
      if (kDebugMode) AndroidWebViewController.enableDebugging(true);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (await _web.canGoBack()) {
            await _web.goBack();
          } else {
            await SystemNavigator.pop();
          }
        },
        child: Scaffold(body: SafeArea(child: WebViewWidget(controller: _web))),
      );
}
