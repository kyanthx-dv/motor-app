import 'package:flutter/material.dart';

import 'avatares.dart';
import 'avisos.dart';
import 'biblioteca.dart';
import 'desenho.dart';
import 'nuvem.dart';
import 'perfil_publico.dart';
import 'pre_arte.dart';
import 'widgets.dart';

/// "Seus PFP": fotos de perfil desenhadas por voce, o + para criar outra e a escolha da atual.
class PfpTela extends StatefulWidget {
  const PfpTela({super.key});

  @override
  State<PfpTela> createState() => _PfpTelaState();
}

class _PfpTelaState extends State<PfpTela> {
  int? _sel; // id do desenho escolhido (null com _padrao = foto padrao)
  bool _padrao = false;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    Biblioteca.i.carregar();
  }

  Future<void> _usar() async {
    if (!Nuvem.i.logado) {
      aviso(context, 'Entre na sua conta para trocar a foto.');
      return;
    }
    setState(() => _enviando = true);
    try {
      final arq = _padrao ? null : await Biblioteca.i.arquivoPng(_sel!);
      final url = await Nuvem.i.definirAvatar(arq);
      Avatares.i.definir(Nuvem.i.usuario ?? '', url);
      if (mounted) {
        aviso(context, _padrao ? 'Foto padrão restaurada.' : 'Foto de perfil atualizada.');
        setState(() {
          _sel = null;
          _padrao = false;
        });
      }
    } on ErroNuvem catch (e) {
      Avisos.add(Nivel.erro, 'Foto de perfil: ${e.msg}');
      if (mounted) aviso(context, e.msg);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Widget _quadro({required Widget filho, required bool ativo, required VoidCallback aoTocar}) => Toque(
        aoTocar: aoTocar,
        child: Container(
          decoration: BoxDecoration(color: Cores.cartao, shape: BoxShape.circle, border: Border.all(color: ativo ? Cores.acento : Cores.divisor, width: ativo ? 3 : 1)),
          clipBehavior: Clip.antiAlias,
          child: filho,
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Biblioteca.i,
        builder: (context, _) {
          final meus = [for (final a in Biblioteca.i.itens) if (a.cat == 'PFP') a];
          final escolheu = _padrao || _sel != null;
          return Scaffold(
            appBar: AppBar(title: const Text('Fotos de perfil')),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: BotaoPrimario(texto: _enviando ? 'Enviando…' : 'Usar como foto de perfil', aoTocar: escolheu && !_enviando ? _usar : null),
              ),
            ),
            body: ListView(padding: const EdgeInsets.all(16), children: [
              Center(child: AvatarUsuario(Nuvem.i.usuario ?? 'kyanthx', raio: 52, anel: true)),
              const SizedBox(height: 6),
              const Center(child: Text('Foto atual', style: TextStyle(color: Cores.texto2, fontSize: 12))),
              const SizedBox(height: 20),
              const Text('Seus PFP', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Desenhe sua foto aqui dentro: ela é 100% sua e pode ser vendida.', style: TextStyle(color: Cores.texto2, fontSize: 12)),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _quadro(
                    ativo: false,
                    aoTocar: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NovoDesenhoTela(categoria: 'PFP'))),
                    filho: const Center(child: Icon(Icons.add_rounded, color: Cores.acento, size: 32)),
                  ),
                  _quadro(
                    ativo: _padrao,
                    aoTocar: () => setState(() {
                      _padrao = true;
                      _sel = null;
                    }),
                    filho: CustomPaint(painter: _PintorPadrao()),
                  ),
                  for (final a in meus)
                    _quadro(
                      ativo: _sel == a.id,
                      aoTocar: () => setState(() {
                        _sel = a.id;
                        _padrao = false;
                      }),
                      filho: FutureBuilder(
                        key: ValueKey('${a.id}-${Biblioteca.i.versoes[a.id]}'),
                        future: Biblioteca.i.pngBytes(a.id),
                        builder: (_, s) => s.data == null ? const SizedBox.shrink() : Image.memory(s.data!, fit: BoxFit.cover, filterQuality: FilterQuality.none, gaplessPlayback: true),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('A primeira foto com o desenho de pessoa é a padrão do app.', style: TextStyle(color: Cores.texto2, fontSize: 12)),
            ]),
          );
        },
      );
}

class _PintorPadrao extends CustomPainter {
  @override
  void paint(Canvas c, Size s) => desenharPre(c, Offset.zero & s, nomePfpPadrao);

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
