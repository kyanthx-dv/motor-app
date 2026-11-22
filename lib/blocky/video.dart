import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'avisos.dart';
import 'comentarios.dart';
import 'dados.dart';
import 'extras.dart';
import 'icones.dart';
import 'perfil_publico.dart';
import 'repo.dart';
import 'widgets.dart';

/// Posts de video: tela cheia vertical, estilo reels. PROVISORIO: o tempo e simulado ate o player real entrar.
class VideoPostTela extends StatefulWidget {
  const VideoPostTela({super.key, required this.inicial});
  final Post inicial;

  @override
  State<VideoPostTela> createState() => _VideoPostTelaState();
}

class _VideoPostTelaState extends State<VideoPostTela> {
  late final List<Post> _videos = [...RepoPosts.i.posts.where((p) => p.video), ...postsExemplo.where((p) => p.video)];
  late final PageController _pg = PageController(initialPage: _videos.indexWhere((p) => p.id == widget.inicial.id).clamp(0, _videos.length - 1));
  late int _atual = _pg.initialPage;

  @override
  void dispose() {
    _pg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          PageView.builder(scrollDirection: Axis.vertical, controller: _pg, itemCount: _videos.length, onPageChanged: (i) => setState(() => _atual = i), itemBuilder: (_, i) => _Reel(post: _videos[i], ativo: i == _atual)),
          SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: IconButton(icon: const Icon(Ic.voltar, color: Colors.white), onPressed: () => Navigator.pop(context)))),
        ]),
      );
}

class _Reel extends StatefulWidget {
  const _Reel({required this.post, required this.ativo});
  final Post post;
  final bool ativo;

  @override
  State<_Reel> createState() => _ReelState();
}

class _ReelState extends State<_Reel> with SingleTickerProviderStateMixin {
  static const _dur = 30; // segundos (simulado)
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(seconds: _dur))..repeat();
  bool _curtiu = false;
  bool _fav = false;
  bool _pausado = false;
  VideoPlayerController? _vc; // video real (null = tempo simulado dos exemplos)

  @override
  void initState() {
    super.initState();
    final url = widget.post.midia;
    if (url != null) {
      _t.stop();
      _vc = VideoPlayerController.networkUrl(Uri.parse(url))
        ..setLooping(true)
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {});
          if (widget.ativo) _vc!.play();
        }).catchError((Object e) {
          Avisos.add(Nivel.erro, 'Vídeo: $e');
        });
      _vc!.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(_Reel old) {
    super.didUpdateWidget(old);
    final c = _vc;
    if (c == null || !c.value.isInitialized || old.ativo == widget.ativo) return;
    if (widget.ativo && !_pausado) {
      c.play();
    } else {
      c.pause();
    }
  }

  @override
  void dispose() {
    _t.dispose();
    _vc?.dispose();
    super.dispose();
  }

  void _pular(int s) {
    final c = _vc;
    if (c != null) {
      final d = c.value.duration.inMilliseconds;
      c.seekTo(Duration(milliseconds: (c.value.position.inMilliseconds + s * 1000).clamp(0, d)));
      return;
    }
    final v = (_t.value + s / _dur).clamp(0.0, 1.0);
    _t.value = v;
    if (!_pausado) _t.repeat(min: 0, max: 1, period: const Duration(seconds: _dur));
  }

  void _alternar() {
    setState(() => _pausado = !_pausado);
    final c = _vc;
    if (c != null) {
      _pausado ? c.pause() : c.play();
      return;
    }
    if (_pausado) {
      _t.stop();
    } else {
      _t.repeat(period: const Duration(seconds: _dur));
    }
  }

  bool get _real => widget.post.autorId.isNotEmpty;
  bool get _cur => _real ? RepoPosts.i.curtiu(widget.post) : _curtiu;
  bool get _favo => _real ? RepoPosts.i.favoritou(widget.post) : _fav;

  double get _prog {
    final c = _vc;
    if (c == null) return _t.value;
    final d = c.value.duration.inMilliseconds;
    return d == 0 ? 0 : (c.value.position.inMilliseconds / d).clamp(0.0, 1.0);
  }

  int get _total => _vc != null && _vc!.value.isInitialized ? _vc!.value.duration.inSeconds : _dur;

  String _tempo(double v) {
    final s = (v * _total).round();
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
    return ListenableBuilder(listenable: RepoPosts.i, builder: (context, _) => _corpo(context, p));
  }

  Widget _corpo(BuildContext context, Post p) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _alternar,
      child: Stack(fit: StackFit.expand, children: [
        if (_vc != null && _vc!.value.isInitialized)
          ColoredBox(color: Colors.black, child: Center(child: AspectRatio(aspectRatio: _vc!.value.aspectRatio, child: VideoPlayer(_vc!))))
        else
          Capa(cor1: p.cor1, cor2: p.cor2, icone: p.icone, tamanhoIcone: 120, raio: 0),
        const ColoredBox(color: Color(0x66000000)),
        Center(child: AnimatedOpacity(opacity: _pausado ? 1 : 0, duration: const Duration(milliseconds: 150), child: Container(width: 72, height: 72, decoration: const BoxDecoration(color: Color(0x66000000), shape: BoxShape.circle), child: const Icon(Ic.play, size: 40, color: Colors.white)))),
        Positioned(
          right: 10,
          bottom: 120,
          child: Column(children: [
            _lado(_cur ? Ic.coracaoCheio : Ic.coracao, abreviar(_real ? RepoPosts.i.curtidas(p) : p.curtidas + (_curtiu ? 1 : 0)), () => _real ? tentar(context, () => RepoPosts.i.alternar(p, 'curtida')) : setState(() => _curtiu = !_curtiu), cor: _cur ? Colors.redAccent : null),
            _lado(Ic.balao, '${p.numComentarios}', () => p.autorId.isEmpty ? abrirComentarios(context, p.comentarios) : abrirComentarios(context, const [], tipo: 'post', id: p.id)),
            _lado(_favo ? Ic.estrelaCheia : Ic.estrela, abreviar(_real ? RepoPosts.i.favoritos(p) : p.curtidas ~/ 3 + (_fav ? 1 : 0)), () => _real ? tentar(context, () => RepoPosts.i.alternar(p, 'favorito')) : setState(() => _fav = !_fav), cor: _favo ? const Color(0xFFFBBF24) : null),
            _lado(Ic.compartilhar, 'Enviar', () => emBreve(context, 'Compartilhar')),
          ]),
        ),
        Positioned(
          left: 16,
          right: 76,
          bottom: 66,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [Flexible(child: ChipAutor(p.autor, raio: 18)), const SizedBox(width: 10), BotaoSeguir(usuario: p.autor)]),
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
                Text(_tempo(_prog), style: const TextStyle(color: Colors.white, fontSize: 12)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), overlayShape: SliderComponentShape.noOverlay, activeTrackColor: Colors.white, inactiveTrackColor: Colors.white24, thumbColor: Colors.white),
                    child: Slider(
                      value: _prog,
                      onChanged: (x) {
                        final c = _vc;
                        if (c != null) {
                          c.seekTo(Duration(milliseconds: (x * c.value.duration.inMilliseconds).round()));
                        } else {
                          _t.value = x;
                        }
                      },
                      onChangeEnd: (_) {
                        if (_vc == null && !_pausado) _t.repeat(period: const Duration(seconds: _dur));
                      },
                    ),
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
