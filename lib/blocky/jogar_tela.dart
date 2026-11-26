import 'dart:async';
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
  bool _desempenho = false; // caixa com FPS e tempos num canto
  Map<String, dynamic> _info = {};
  Timer? _poll;
  double _qualidade = 1.5; // dpr maximo do canvas: 3 alta, 1.5 media, 1 baixa
  final _log = <String>[]; // console do jogo (ultimas 150 linhas)

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
        _log.add('${m.level.name.toUpperCase()}  ${m.message}');
        if (_log.length > 150) _log.removeAt(0);
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
          if (itemDe(o.v) != null) {'id': o.id, 'x': o.x, 'y': o.y, 'w': o.w, 'h': o.h, 'v': o.v, ...objetoEfetivo(o, itemDe(o.v)!)},
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

  void _ligarDesempenho(bool v) {
    _desempenho = v;
    _poll?.cancel();
    if (v) {
      _poll = Timer.periodic(const Duration(milliseconds: 500), (_) async {
        try {
          var r = (await _web.runJavaScriptReturningResult('window.dbgInfo ? window.dbgInfo() : "{}"')).toString();
          if (r.startsWith('"')) r = jsonDecode(r) as String; // Android devolve o texto entre aspas
          final m = jsonDecode(r);
          if (mounted && m is Map<String, dynamic>) setState(() => _info = m);
        } catch (_) {/* o jogo ainda esta abrindo: tenta de novo */}
      });
    }
    if (mounted) setState(() {});
  }

  Future<void> _abrirDepuracao() => showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setD) => Dialog(
            backgroundColor: Cores.cartao,
            insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  height: 52,
                  color: Cores.cartao2,
                  child: Row(children: [
                    const SizedBox(width: 18),
                    const Expanded(child: Text('Depuração', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                  ]),
                ),
                SwitchListTile(
                  dense: true,
                  title: const Text('Desempenho'),
                  subtitle: const Text('Mostra FPS, tempo de quadro e contagens num canto.', style: TextStyle(fontSize: 12, color: Cores.texto2)),
                  value: _desempenho,
                  onChanged: (v) {
                    _ligarDesempenho(v);
                    setD(() {});
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Qualidade gráfica', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<double>(
                        showSelectedIcon: false,
                        segments: const [ButtonSegment(value: 3, label: Text('Alta')), ButtonSegment(value: 1.5, label: Text('Média')), ButtonSegment(value: 1, label: Text('Baixa'))],
                        selected: {_qualidade},
                        onSelectionChanged: (s) {
                          _qualidade = s.first;
                          _web.runJavaScript('window.definirQualidade && window.definirQualidade($_qualidade)');
                          setD(() {});
                        },
                      ),
                    ),
                    const Padding(padding: EdgeInsets.only(top: 4), child: Text('Menos pixels = mais FPS em celular fraco.', style: TextStyle(fontSize: 12, color: Cores.texto2))),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                  child: Row(children: [
                    const Expanded(child: Text('CONSOLE DO JOGO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Cores.texto2))),
                    TextButton(onPressed: () => Clipboard.setData(ClipboardData(text: _log.join('\n'))), child: const Text('Copiar')),
                    TextButton(onPressed: () => setD(_log.clear), child: const Text('Limpar')),
                  ]),
                ),
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(10),
                    constraints: const BoxConstraints(minHeight: 80),
                    decoration: BoxDecoration(color: Cores.cartao2, borderRadius: BorderRadius.circular(12)),
                    child: SingleChildScrollView(
                      reverse: true,
                      child: SelectableText(_log.isEmpty ? 'Sem mensagens.' : _log.join('\n'), style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace')),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );

  Widget _redondo(IconData i, VoidCallback f) => Toque(
        aoTocar: f,
        child: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xE62A3340), shape: BoxShape.circle, border: Border.all(color: Colors.white24)), child: Icon(i, size: 22, color: Colors.white)),
      );

  @override
  void dispose() {
    _poll?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String n(String k) => '${_info[k] ?? '-'}';
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Stack(children: [
        Positioned.fill(child: WebViewWidget(controller: _web)),
        SafeArea(
          child: Stack(children: [
            Positioned(
              right: 10,
              top: 8,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _redondo(Icons.bug_report_outlined, _abrirDepuracao),
                const SizedBox(width: 8),
                _redondo(Icons.close_rounded, () => Navigator.of(context).pop()),
              ]),
            ),
            if (_desempenho)
              Positioned(
                left: 0,
                right: 0,
                top: 8,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xCC000000), borderRadius: BorderRadius.circular(10)),
                      child: Text('FPS ${n('fps')}  ·  ${n('ms')} ms  ·  pior ${n('pior')} ms\nobjetos ${n('ent')}  ·  corpos ${n('corpos')}  ·  mem ${n('mem')} MB\ncanvas ${n('res')}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.white, fontFamily: 'monospace', height: 1.35)),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}
