import 'package:flutter/material.dart';

import 'avisos.dart';
import 'icones.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dados.dart';

/// true = tema preto, false = tema branco. Trocar reconstroi o app (ver main.dart).
final ValueNotifier<bool> temaEscuro = ValueNotifier<bool>(true);

class Cores {
  static Color get fundo => temaEscuro.value ? const Color(0xFF111215) : const Color(0xFFF3F0EA);
  static Color get cartao => temaEscuro.value ? const Color(0xFF1A1C20) : const Color(0xFFFFFFFF);
  static Color get cartao2 => temaEscuro.value ? const Color(0xFF24262C) : const Color(0xFFE8E4DB);
  static const acento = Color(0xFF6C63F2);
  static const acento2 = Color(0xFF38BDF8);
  static const verde = Color(0xFF22C55E);
  static const texto2 = Color(0xFF8A93A3); // legivel nos dois temas
}

/// Degrade da marca (violeta -> azul).
/// Marca: indigo solido (degrade quase imperceptivel, so para dar corpo ao botao).
const LinearGradient degradeMarca = LinearGradient(colors: [Color(0xFF6F66F5), Color(0xFF5E56E6)], begin: Alignment.topCenter, end: Alignment.bottomCenter);

ThemeData temaBlocky(bool escuro) {
  final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  return ThemeData(
    textTheme: GoogleFonts.nunitoTextTheme(ThemeData(brightness: escuro ? Brightness.dark : Brightness.light).textTheme),
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: TransicaoSuave(),
      TargetPlatform.iOS: TransicaoSuave(),
    }),
    brightness: escuro ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: Cores.fundo,
    colorScheme: (escuro ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
      primary: Cores.acento,
      secondary: Cores.verde,
      surface: Cores.cartao,
      surfaceContainerHigh: Cores.cartao2,
      surfaceContainerHighest: Cores.cartao2,
    ),
    appBarTheme: AppBarTheme(backgroundColor: Cores.fundo, elevation: 0, scrolledUnderElevation: 0),
    // botoes sem contorno: preenchido (acao principal) e "suave" (secundario)
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: forma, elevation: 0, minimumSize: const Size(64, 46), textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: forma, side: BorderSide.none, backgroundColor: Cores.cartao2, foregroundColor: escuro ? Colors.white : Colors.black87, minimumSize: const Size(64, 46), textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: forma, textStyle: const TextStyle(fontWeight: FontWeight.w700))),
    segmentedButtonTheme: SegmentedButtonThemeData(style: SegmentedButton.styleFrom(side: BorderSide.none, backgroundColor: Cores.cartao2, selectedBackgroundColor: Cores.acento.withAlpha(70))),
    chipTheme: ChipThemeData(side: BorderSide.none, backgroundColor: Cores.cartao2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: Cores.cartao, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28)))),
    snackBarTheme: SnackBarThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), behavior: SnackBarBehavior.floating),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Cores.cartao,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    ),
  );
}

/// Abas em "pilula" (indicador suave, sem linha).
class BarraAbas extends StatelessWidget implements PreferredSizeWidget {
  const BarraAbas(this.rotulos, {super.key, this.rolavel = false});
  final List<String> rotulos;
  final bool rolavel;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: TabBar(
          isScrollable: rolavel,
          tabAlignment: rolavel ? TabAlignment.start : null,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.symmetric(vertical: 6),
          indicator: BoxDecoration(color: Cores.acento.withAlpha(55), borderRadius: BorderRadius.circular(20)),
          labelColor: temaEscuro.value ? Colors.white : Colors.black87,
          unselectedLabelColor: Cores.texto2,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          splashBorderRadius: BorderRadius.circular(20),
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          tabs: [for (final r in rotulos) Tab(text: r)],
        ),
      );
}

/// Botao principal: degrade da marca, sem contorno.
class BotaoPrimario extends StatefulWidget {
  const BotaoPrimario({super.key, required this.texto, required this.aoTocar, this.icone, this.altura = 50, this.cor, this.pulsa = false});
  final String texto;
  final IconData? icone;
  final VoidCallback? aoTocar;
  final double altura;
  final Gradient? cor;
  final bool pulsa; // brilho suave pulsando (botoes importantes)

  @override
  State<BotaoPrimario> createState() => _BotaoPrimarioState();
}

class _BotaoPrimarioState extends State<BotaoPrimario> with SingleTickerProviderStateMixin {
  late final AnimationController _p = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    if (widget.pulsa) _p.repeat(reverse: true);
  }

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.cor ?? degradeMarca;
    final brilho = g.colors.first;
    return Opacity(
      opacity: widget.aoTocar == null ? 0.45 : 1,
      child: Toque(
        aoTocar: widget.aoTocar ?? () {},
        child: AnimatedBuilder(
          animation: _p,
          builder: (_, child) => Container(
            height: widget.altura,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              gradient: g,
              borderRadius: BorderRadius.circular(widget.altura / 2.8),
              boxShadow: [
                widget.pulsa
                    ? BoxShadow(color: brilho.withAlpha((40 + 90 * _p.value).round()), blurRadius: 8 + 14 * _p.value, spreadRadius: 1.5 * _p.value, offset: const Offset(0, 3))
                    : BoxShadow(color: Colors.black.withAlpha(temaEscuro.value ? 70 : 28), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: child,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            if (widget.icone != null) ...[Icon(widget.icone, color: Colors.white, size: 22), const SizedBox(width: 8)],
            Text(widget.texto, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }
}

/// Botao de acao em pilula (curtir, favoritar, doar...). Ativo = tingido com a cor.
class PilulaAcao extends StatelessWidget {
  const PilulaAcao({super.key, required this.icone, required this.rotulo, required this.aoTocar, this.iconeAtivo, this.ativo = false, this.cor});
  final IconData icone;
  final IconData? iconeAtivo;
  final String rotulo;
  final VoidCallback aoTocar;
  final bool ativo;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final c = cor ?? Cores.acento;
    return Toque(
      aoTocar: aoTocar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: ativo ? c.withAlpha(45) : Cores.cartao2, borderRadius: BorderRadius.circular(22)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          IconeAnim(ligado: ativo, ligadoIcone: iconeAtivo ?? icone, desligadoIcone: icone, cor: c, tamanho: 22),
          const SizedBox(width: 8),
          Text(rotulo, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ativo ? c : null)),
        ]),
      ),
    );
  }
}

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
  Widget build(BuildContext context) {
    // tons dessaturados: a cor do jogo so "tinge" uma base neutra, para o texto ser o protagonista
    final base = Cores.cartao2;
    final a = Color.alphaBlend(cor1.withAlpha(temaEscuro.value ? 78 : 110), base);
    final b = Color.alphaBlend(cor2.withAlpha(temaEscuro.value ? 46 : 70), base);
    return ClipRRect(
      borderRadius: BorderRadius.circular(raio),
      child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [a, b], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Stack(children: [
          Center(child: Icon(icone, size: tamanhoIcone * 0.8, color: (temaEscuro.value ? Colors.white : Colors.black).withAlpha(95))),
          if (video)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black.withAlpha(150), borderRadius: BorderRadius.circular(10)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Ic.play, size: 16, color: Colors.white), Text('vídeo', style: TextStyle(fontSize: 12, color: Colors.white))]),
              ),
            ),
        ]),
      ),
    );
  }
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
              Estatistica(Ic.curtir, abreviar(jogo.curtidas)),
            ]),
          ]),
        ),
      );
}

void aviso(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating));
  Avisos.add(Nivel.info, texto);
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

const Color mentaEditor = Color(0xFF7C5CFF); // = acento (nome historico)
const Color azulEditor = Color(0xFF7C5CFF);
const Color rosaEditor = Color(0xFFFF7B93);

/// Cabecalho de abas fixo (perfis).
class TabsFixas extends SliverPersistentHeaderDelegate {
  TabsFixas(this.tabs);
  final BarraAbas tabs;

  @override
  double get minExtent => tabs.preferredSize.height;
  @override
  double get maxExtent => tabs.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: Cores.fundo, child: tabs);
  @override
  bool shouldRebuild(covariant TabsFixas old) => true;
}
