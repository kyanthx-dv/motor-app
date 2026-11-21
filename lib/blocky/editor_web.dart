import 'package:flutter/foundation.dart';

import 'icones.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'servidor.dart';

/// PROVISORIO: editor web do PC dentro de um WebView. O editor de celular sera nativo (Flutter) e usara so a engine.
class EditorWebTela extends StatefulWidget {
  const EditorWebTela({super.key});

  @override
  State<EditorWebTela> createState() => _EditorWebTelaState();
}

class _EditorWebTelaState extends State<EditorWebTela> {
  late final WebViewController _web;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF111827))
      ..setOnConsoleMessage((m) => debugPrint('[web] ${m.message}'))
      ..loadRequest(Uri.parse('http://127.0.0.1:$portaLocal/editor/index.html'));
    final p = _web.platform;
    if (p is AndroidWebViewController) {
      p.setMediaPlaybackRequiresUserGesture(false);
      if (kDebugMode) AndroidWebViewController.enableDebugging(true);
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (await _web.canGoBack()) {
            await _web.goBack();
          } else if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: Stack(children: [
              WebViewWidget(controller: _web),
              Positioned(
                left: 4,
                top: 4,
                child: IconButton.filledTonal(tooltip: 'Voltar ao Blocky', icon: const Icon(Ic.voltar), onPressed: () => Navigator.of(context).pop()),
              ),
            ]),
          ),
        ),
      );
}
