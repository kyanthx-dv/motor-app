import 'package:flutter/material.dart';

import 'entrada.dart';
import 'widgets.dart';

const _blocos = <Color>[Color(0xFF8B5CF6), Color(0xFF38BDF8), Color(0xFFF472B6), Color(0xFFFBBF24)];

/// Logo: quatro blocos arredondados.
class LogoBlocky extends StatelessWidget {
  const LogoBlocky({super.key, this.tamanho = 96});
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final b = tamanho * 0.46;
    final g = tamanho * 0.08;
    Widget bloco(int i) => Container(width: b, height: b, decoration: BoxDecoration(color: _blocos[i], borderRadius: BorderRadius.circular(b * 0.28)));
    return SizedBox(
      width: tamanho,
      height: tamanho,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [bloco(0), SizedBox(width: g), bloco(1)]),
        SizedBox(height: g),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [bloco(2), SizedBox(width: g), bloco(3)]),
      ]),
    );
  }
}

/// Animacao de abertura: os blocos entram de fora, encaixam, o nome aparece e vai para o login.
class AberturaTela extends StatefulWidget {
  const AberturaTela({super.key});

  @override
  State<AberturaTela> createState() => _AberturaTelaState();
}

class _AberturaTelaState extends State<AberturaTela> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2300));

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const EntradaTela(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
      ));
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const t = 110.0;
    const b = t * 0.46;
    const g = t * 0.08;
    const dirs = [Offset(-1, -1), Offset(1, -1), Offset(-1, 1), Offset(1, 1)];
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D12),
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          double iv(double a, double z, Curve cv) => cv.transform(((_c.value - a) / (z - a)).clamp(0.0, 1.0));
          final texto = iv(0.55, 0.85, Curves.easeOutCubic);
          final saida = iv(0.9, 1.0, Curves.easeIn);
          return Opacity(
            opacity: 1 - saida,
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: t,
                  height: t,
                  child: Stack(children: [
                    for (var i = 0; i < 4; i++)
                      Builder(builder: (_) {
                        final k = iv(i * 0.07, 0.45 + i * 0.07, Curves.easeOutBack);
                        final alvo = Offset(i % 2 == 0 ? 0 : b + g, i < 2 ? 0 : b + g);
                        final fora = dirs[i] * 160;
                        return Positioned(
                          left: alvo.dx + fora.dx * (1 - k),
                          top: alvo.dy + fora.dy * (1 - k),
                          child: Opacity(opacity: k.clamp(0.0, 1.0), child: Transform.rotate(angle: (1 - k) * 0.9, child: Container(width: b, height: b, decoration: BoxDecoration(color: _blocos[i], borderRadius: BorderRadius.circular(b * 0.28), boxShadow: [BoxShadow(color: _blocos[i].withAlpha(90), blurRadius: 18)])))),
                        );
                      }),
                  ]),
                ),
                const SizedBox(height: 26),
                Opacity(
                  opacity: texto,
                  child: Transform.translate(offset: Offset(0, (1 - texto) * 14), child: const Text('Blocky', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 1.2))),
                ),
                const SizedBox(height: 4),
                Opacity(opacity: texto, child: const Text('crie · jogue · compartilhe', style: TextStyle(color: Cores.texto2, fontSize: 13))),
              ]),
            ),
          );
        },
      ),
    );
  }
}
