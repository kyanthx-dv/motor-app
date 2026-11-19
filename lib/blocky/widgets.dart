import 'package:flutter/material.dart';

import 'dados.dart';

/// true = tema preto, false = tema branco. Trocar reconstroi o app (ver main.dart).
final ValueNotifier<bool> temaEscuro = ValueNotifier<bool>(true);

class Cores {
  static Color get fundo => temaEscuro.value ? const Color(0xFF0F1115) : const Color(0xFFF4F5F8);
  static Color get cartao => temaEscuro.value ? const Color(0xFF1A1D24) : const Color(0xFFFFFFFF);
  static Color get cartao2 => temaEscuro.value ? const Color(0xFF242833) : const Color(0xFFE8EAF0);
  static const acento = Color(0xFF7C5CFF);
  static const verde = Color(0xFF22C55E);
  static const texto2 = Color(0xFF8A93A3); // legivel nos dois temas
}

ThemeData temaBlocky(bool escuro) => ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: TransicaoSuave(),
        TargetPlatform.iOS: TransicaoSuave(),
      }),
      brightness: escuro ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: Cores.fundo,
      colorScheme: escuro
          ? ColorScheme.dark(primary: Cores.acento, secondary: Cores.verde, surface: Cores.cartao)
          : ColorScheme.light(primary: Cores.acento, secondary: Cores.verde, surface: Cores.cartao),
      appBarTheme: AppBarTheme(backgroundColor: Cores.fundo, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Cores.cartao,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );

/// Imagem de capa de exemplo: degrade com icone (no lugar de imagens reais).
class Capa extends StatelessWidget {
  const Capa({super.key, required this.cor1, required this.cor2, required this.icone, this.raio = 14, this.video = false, this.tamanhoIcone = 44});
  final Color cor1;
  final Color cor2;
  final IconData icone;
  final double raio;
  final bool video;
  final double tamanhoIcone;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(raio),
        child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [cor1, cor2], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Stack(children: [
            Center(child: Icon(icone, size: tamanhoIcone, color: Colors.white.withAlpha(220))),
            if (video)
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black.withAlpha(150), borderRadius: BorderRadius.circular(10)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.play_arrow, size: 16), Text('vídeo', style: TextStyle(fontSize: 12))]),
                ),
              ),
          ]),
        ),
      );
}

class Estatistica extends StatelessWidget {
  const Estatistica(this.icone, this.valor, {super.key});
  final IconData icone;
  final String valor;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icone, size: 15, color: Cores.texto2),
        const SizedBox(width: 3),
        Text(valor, style: const TextStyle(color: Cores.texto2, fontSize: 12)),
      ]);
}

class CartaoJogo extends StatelessWidget {
  const CartaoJogo({super.key, required this.jogo, required this.aoTocar, this.largura});
  final Jogo jogo;
  final VoidCallback aoTocar;
  final double? largura;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: largura,
        child: Toque(
          aoTocar: aoTocar,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AspectRatio(aspectRatio: 16 / 10, child: Capa(cor1: jogo.cor1, cor2: jogo.cor2, icone: jogo.icone)),
            const SizedBox(height: 6),
            Text(jogo.titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            Row(children: [
              Expanded(child: Text('@${jogo.autor}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Cores.texto2, fontSize: 12))),
              Estatistica(Icons.thumb_up_alt_outlined, abreviar(jogo.curtidas)),
            ]),
          ]),
        ),
      );
}

void aviso(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating));
}

void emBreve(BuildContext context, String o) => aviso(context, '$o: em breve (precisa de segurança antes de ligar).');

/// Transicao de paginas: fade + leve subida (mais suave que o padrao).
class TransicaoSuave extends PageTransitionsBuilder {
  const TransicaoSuave();

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final entra = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final sai = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(entra),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(entra),
        child: FadeTransition(opacity: Tween<double>(begin: 1, end: 0.6).animate(sai), child: child),
      ),
    );
  }
}

/// Toque com "afundar" suave (escala) em vez de InkWell seco.
class Toque extends StatefulWidget {
  const Toque({super.key, required this.child, required this.aoTocar});
  final Widget child;
  final VoidCallback aoTocar;

  @override
  State<Toque> createState() => _ToqueState();
}

class _ToqueState extends State<Toque> {
  bool _p = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _p = true),
        onTapCancel: () => setState(() => _p = false),
        onTapUp: (_) => setState(() => _p = false),
        onTap: widget.aoTocar,
        child: AnimatedScale(scale: _p ? 0.96 : 1, duration: const Duration(milliseconds: 120), curve: Curves.easeOut, child: widget.child),
      );
}

/// Entrada suave (fade + subida) com atraso crescente pelo indice.
class Aparece extends StatelessWidget {
  const Aparece({super.key, required this.child, this.indice = 0});
  final Widget child;
  final int indice;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: 280 + (indice > 8 ? 8 : indice) * 45),
        curve: Curves.easeOutCubic,
        builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 18), child: c)),
        child: child,
      );
}

/// Icone que "pula" ao mudar (curtir/favoritar).
class IconeAnim extends StatelessWidget {
  const IconeAnim({super.key, required this.ligado, required this.ligadoIcone, required this.desligadoIcone, this.cor, this.tamanho = 26});
  final bool ligado;
  final IconData ligadoIcone;
  final IconData desligadoIcone;
  final Color? cor;
  final double tamanho;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: c),
        child: Icon(ligado ? ligadoIcone : desligadoIcone, key: ValueKey<bool>(ligado), color: ligado ? cor : null, size: tamanho),
      );
}
