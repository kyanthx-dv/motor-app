import 'package:flutter/material.dart';

import 'avisos.dart';
import 'icones.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dados.dart';

/// true = tema preto, false = tema branco. Trocar reconstroi o app (ver main.dart).
final ValueNotifier<bool> temaEscuro = ValueNotifier<bool>(true);

/// Estilo: escuro, chapado (flat) e utilitario. Sem gradiente, sem sombra, sem brilho. Cores solidas.
class Cores {
  static Color get fundo => temaEscuro.value ? const Color(0xFF141414) : const Color(0xFFFFFFFF);
  static Color get cartao => temaEscuro.value ? const Color(0xFF232426) : const Color(0xFFF1F2F4);
  static Color get cartao2 => temaEscuro.value ? const Color(0xFF2B2D30) : const Color(0xFFE4E6E9);
  static Color get divisor => temaEscuro.value ? const Color(0xFF262626) : const Color(0xFFE3E4E6);
  static Color get texto => temaEscuro.value ? const Color(0xFFFFFFFF) : const Color(0xFF111214);
  static const acento = Color(0xFF1D9BF0); // azul: aba ativa, +, Seguir, badge New
  static const acento2 = Color(0xFF1D9BF0);
  static const ambar = Color(0xFFF59E0B); // moedas, saldo
  static const laranja = Color(0xFFF97316); // acoes de moeda, badge Hot
  static const verde = Color(0xFF23A55A); // Publicado
  static const coral = Color(0xFFF23F43); // Em desenvolvimento, fechar
  static const texto2 = Color(0xFF8E9297); // legivel nos dois temas
}

ThemeData temaBlocky(bool escuro) {
  final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
  return ThemeData(
    textTheme: GoogleFonts.interTextTheme(ThemeData(brightness: escuro ? Brightness.dark : Brightness.light).textTheme),
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
    appBarTheme: AppBarTheme(backgroundColor: Cores.fundo, elevation: 0, scrolledUnderElevation: 0, surfaceTintColor: Colors.transparent),
    dividerTheme: DividerThemeData(color: Cores.divisor, thickness: 1, space: 1),
    splashFactory: NoSplash.splashFactory,
    // botoes sem contorno: preenchido (acao principal) e "suave" (secundario)
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: forma, elevation: 0, minimumSize: const Size(64, 46), textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: forma, side: BorderSide.none, backgroundColor: Cores.cartao2, foregroundColor: Cores.texto, minimumSize: const Size(64, 46), textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: forma, textStyle: const TextStyle(fontWeight: FontWeight.w700))),
    segmentedButtonTheme: SegmentedButtonThemeData(style: SegmentedButton.styleFrom(side: BorderSide.none, backgroundColor: Cores.cartao2, selectedBackgroundColor: Cores.acento)),
    chipTheme: ChipThemeData(side: BorderSide.none, backgroundColor: Cores.cartao2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: Cores.cartao, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), surfaceTintColor: Colors.transparent),
    snackBarTheme: SnackBarThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), backgroundColor: const Color(0xFF2B2D30), contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500), behavior: SnackBarBehavior.floating),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Cores.cartao,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    ),
  );
}

/// Abas: texto simples e uma linha azul curta (3px) so embaixo da aba ativa.
class BarraAbas extends StatelessWidget implements PreferredSizeWidget {
  const BarraAbas(this.rotulos, {super.key, this.rolavel = false});
  final List<String> rotulos;
  final bool rolavel;

  @override
  Size get preferredSize => const Size.fromHeight(46);

  @override
  Widget build(BuildContext context) => Container(
        height: 46,
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Cores.divisor))),
        child: TabBar(
          isScrollable: rolavel,
          tabAlignment: rolavel ? TabAlignment.start : null,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.label,
          indicator: const UnderlineTabIndicator(borderSide: BorderSide(width: 3, color: Cores.acento), borderRadius: BorderRadius.all(Radius.circular(2))),
          labelColor: Cores.texto,
          unselectedLabelColor: Cores.texto2,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          labelPadding: const EdgeInsets.symmetric(horizontal: 14),
          tabs: [for (final r in rotulos) Tab(text: r)],
        ),
      );
}

/// Botao principal: retangulo de cantos suaves, azul solido, sem borda nem sombra.
class BotaoPrimario extends StatefulWidget {
  const BotaoPrimario({super.key, required this.texto, required this.aoTocar, this.icone, this.altura = 48, this.cor, this.pulsa = false});
  final String texto;
  final IconData? icone;
  final VoidCallback? aoTocar;
  final double altura;
  final Color? cor;
  final bool pulsa; // "respira" de leve (escala), sem brilho

  @override
  State<BotaoPrimario> createState() => _BotaoPrimarioState();
}

class _BotaoPrimarioState extends State<BotaoPrimario> with SingleTickerProviderStateMixin {
  late final AnimationController _p = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

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
  Widget build(BuildContext context) => Opacity(
        opacity: widget.aoTocar == null ? 0.45 : 1,
        child: Toque(
          aoTocar: widget.aoTocar ?? () {},
          child: AnimatedBuilder(
            animation: _p,
            builder: (_, child) => Transform.scale(
              scale: 1 + 0.018 * Curves.easeInOut.transform(_p.value),
              child: Container(
                height: widget.altura,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(color: widget.cor ?? Cores.acento, borderRadius: BorderRadius.circular(10)),
                child: child,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
              if (widget.icone != null) ...[Icon(widget.icone, color: Colors.white, size: 21), const SizedBox(width: 8)],
              Text(widget.texto, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );
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
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: ativo ? c.withAlpha(45) : Cores.cartao, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          IconeAnim(ligado: ativo, ligadoIcone: iconeAtivo ?? icone, desligadoIcone: icone, cor: c, tamanho: 22),
          const SizedBox(width: 8),
          TextoRolante(rotulo, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ativo ? c : null)),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(raio),
      child: Container(
        color: a,
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

const Color mentaEditor = Cores.acento; // = acento (nome historico)
const Color azulEditor = Cores.acento;
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

/// Texto que "rola" quando muda (contadores): o novo valor sobe e o antigo sai.
class TextoRolante extends StatelessWidget {
  const TextoRolante(this.texto, {super.key, this.style});
  final String texto;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, anim) => ClipRect(
          child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.7), end: Offset.zero).animate(anim), child: FadeTransition(opacity: anim, child: child)),
        ),
        child: Text(texto, key: ValueKey(texto), style: style),
      );
}

/// Medidor de forca da senha (4 barras): tamanho, letras, numeros e simbolos.
class ForcaSenha extends StatelessWidget {
  const ForcaSenha(this.senha, {super.key});
  final String senha;

  int get nivel {
    if (senha.isEmpty) return 0;
    var n = 0;
    if (senha.length >= 8) n++;
    if (RegExp(r'[a-z]').hasMatch(senha) && RegExp(r'[A-Z]').hasMatch(senha)) n++;
    if (RegExp(r'\d').hasMatch(senha)) n++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(senha) || senha.length >= 14) n++;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final n = nivel;
    final cor = [Cores.texto2, Colors.redAccent, const Color(0xFFF59E0B), const Color(0xFF84CC16), Cores.verde][n];
    final rot = ['', 'Fraca', 'Média', 'Boa', 'Forte'][n];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 4,
              margin: EdgeInsets.only(right: i < 3 ? 5 : 0),
              decoration: BoxDecoration(color: i < n ? cor : Cores.cartao2, borderRadius: BorderRadius.circular(3)),
            ),
          ),
        SizedBox(width: 52, child: Text(rot, textAlign: TextAlign.end, style: TextStyle(fontSize: 12, color: cor, fontWeight: FontWeight.w700))),
      ]),
    );
  }
}
