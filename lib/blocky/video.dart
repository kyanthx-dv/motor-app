import 'package:flutter/material.dart';

import 'comentarios.dart';
import 'dados.dart';
import 'extras.dart';
import 'icones.dart';
import 'perfil_publico.dart';
import 'widgets.dart';

/// Posts de video: tela cheia vertical, estilo reels. PROVISORIO: o tempo e simulado ate o player real entrar.
class VideoPostTela extends StatefulWidget {
  const VideoPostTela({super.key, required this.inicial});
  final Post inicial;

  @override
  State<VideoPostTela> createState() => _VideoPostTelaState();
}

class _VideoPostTelaState extends State<VideoPostTela> {
  late final List<Post> _videos = postsExemplo.where((p) => p.video).toList();
  late final PageController _pg = PageController(initialPage: _videos.indexWhere((p) => p.id == widget.inicial.id).clamp(0, _videos.length - 1));

  @override
  void dispose() {
    _pg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          PageView.builder(scrollDirection: Axis.vertical, controller: _pg, itemCount: _videos.length, itemBuilder: (_, i) => _Reel(post: _videos[i])),
          SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: IconButton(icon: const Icon(Ic.voltar, color: Colors.white), onPressed: () => Navigator.pop(context)))),
        ]),
      );
}

class _Reel extends StatefulWidget {
  const _Reel({required this.post});
  final Post post;

  @override
  State<_Reel> createState() => _ReelState();
}

class _ReelState extends State<_Reel> with SingleTickerProviderStateMixin {
  static const _dur = 30; // segundos (simulado)
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(seconds: _dur))..repeat();
  bool _curtiu = false;
  bool _fav = false;
  bool _pausado = false;

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  void _pular(int s) {
    final v = (_t.value + s / _dur).clamp(0.0, 1.0);
    _t.value = v;
    if (!_pausado) _t.repeat(min: 0, max: 1, period: const Duration(seconds: _dur));
  }

  void _alternar() {
    setState(() => _pausado = !_pausado);
    if (_pausado) {
      _t.stop();
    } else {
      _t.repeat(period: const Duration(seconds: _dur));
    }
  }

  String _tempo(double v) {
    final s = (v * _dur).round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  Widget _lado(IconData i, String n, VoidCallback f, {Color? cor}) => Toque(
        aoTocar: f,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(children: [
            Container(width: 48, height: 48, decoration: const BoxDecoration(color: Color(0x55000000), shape: BoxShape.circle), child: Icon(i, size: 26, color: cor ?? Colors.white)),
            const SizedBox(height: 3),
            Text(n, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _alternar,
      child: Stack(fit: StackFit.expand, children: [
        Capa(cor1: p.cor1, cor2: p.cor2, icone: p.icone, tamanhoIcone: 120, raio: 0),
        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0x00000000), Color(0xCC000000)], begin: Alignment.center, end: Alignment.bottomCenter))),
        Center(child: AnimatedOpacity(opacity: _pausado ? 1 : 0, duration: const Duration(milliseconds: 150), child: Container(width: 72, height: 72, decoration: const BoxDecoration(color: Color(0x66000000), shape: BoxShape.circle), child: const Icon(Ic.play, size: 40, color: Colors.white)))),
        Positioned(
          right: 10,
          bottom: 120,
          child: Column(children: [
            _lado(_curtiu ? Ic.coracaoCheio : Ic.coracao, abreviar(p.curtidas + (_curtiu ? 1 : 0)), () => setState(() => _curtiu = !_curtiu), cor: _curtiu ? Colors.redAccent : null),
            _lado(Ic.balao, '${p.comentarios.length}', () => abrirComentarios(context, p.comentarios)),
            _lado(_fav ? Ic.estrelaCheia : Ic.estrela, abreviar(p.curtidas ~/ 3 + (_fav ? 1 : 0)), () => setState(() => _fav = !_fav), cor: _fav ? const Color(0xFFFBBF24) : null),
            _lado(Ic.compartilhar, 'Enviar', () => emBreve(context, 'Compartilhar')),
          ]),
        ),
        Positioned(
          left: 16,
          right: 76,
          bottom: 66,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [Flexible(child: ChipAutor(p.autor, raio: 18)), const SizedBox(width: 10), const BotaoSeguir()]),
            const SizedBox(height: 10),
            Text(p.titulo, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(p.descricao, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ]),
        ),
        Positioned(
          left: 6,
          right: 6,
          bottom: 8,
          child: SafeArea(
            top: false,
            child: AnimatedBuilder(
              animation: _t,
              builder: (_, __) => Row(children: [
                IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Ic.volta10, color: Colors.white), onPressed: () => _pular(-10)),
                Text(_tempo(_t.value), style: const TextStyle(color: Colors.white, fontSize: 12)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), overlayShape: SliderComponentShape.noOverlay, activeTrackColor: Colors.white, inactiveTrackColor: Colors.white24, thumbColor: Colors.white),
                    child: Slider(value: _t.value, onChanged: (v) => _t.value = v, onChangeEnd: (_) {
                      if (!_pausado) _t.repeat(period: const Duration(seconds: _dur));
                    }),
                  ),
                ),
                Text(_tempo(1), style: const TextStyle(color: Colors.white, fontSize: 12)),
                IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Ic.avanca10, color: Colors.white), onPressed: () => _pular(10)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
