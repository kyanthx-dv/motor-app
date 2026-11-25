// GERADO: sprites pixel art 16x16 que vem com o app (desenhados aqui, sem arquivo de imagem).
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Sprite pronto: 16 linhas de 16 caracteres; '.' = transparente; cada letra tem uma cor ARGB.
class PreArte {
  const PreArte(this.linhas, this.cores);
  final List<String> linhas;
  final Map<String, int> cores;
}

const preArtes = <String, PreArte>{
  'Grama': PreArte([
    'GGGgGGGGGgGGGGGG',
    'GgGGGGgGGGGGgGGG',
    'gGGGGGGGGgGGGGGg',
    'DgDDgDDDgDDDgDDD',
    'DDDDDDdDDDDDDDdD',
    'DdDDDDDDDdDDDDDD',
    'DDDDdDDDDDDDdDDD',
    'DDDDDDDDdDDDDDDD',
    'DDdDDDDDDDDdDDDD',
    'DDDDDDDdDDDDDDDD',
    'DdDDDDDDDDDDdDDD',
    'DDDDDdDDDDDDDDDd',
    'DDDDDDDDDdDDDDDD',
    'DDdDDDDDDDDDDdDD',
    'DDDDDdDDDDDdDDDD',
    'DDDDDDDDDDDDDDDD',
  ], {'G': 0xFF5DBB2F, 'g': 0xFF3F8F1E, 'D': 0xFFB4713A, 'd': 0xFF8E5528}),
  'Terra': PreArte([
    'DDDDdDDDDDDDdDDD',
    'DdDDDDDDDdDDDDDD',
    'DDDDDDdDDDDDDDdD',
    'DDdDDDDDDDDdDDDD',
    'DDDDDDDdDDDDDDDD',
    'DdDDDDDDDDDDdDDD',
    'DDDDdDDDDDDDDDDD',
    'DDDDDDDDdDDDdDDD',
    'DDdDDDDDDDDDDDDD',
    'DDDDDDDdDDDDDDdD',
    'DdDDDDDDDDdDDDDD',
    'DDDDDdDDDDDDDDDD',
    'DDDDDDDDDdDDdDDD',
    'DDdDDDDDDDDDDDDD',
    'DDDDDDDdDDDDDdDD',
    'DdDDDDDDDDDdDDDD',
  ], {'D': 0xFFB4713A, 'd': 0xFF8E5528}),
  'Pedra': PreArte([
    'ssssssssssssssss',
    'SSSSSSSlSSSSSSSs',
    'SSlSSSSSSSSlSSSs',
    'SSSSSSSSSSSSSSSs',
    'ssssssssssssssss',
    'SSSSlSSSSSSSsSSS',
    'SSSSSSSSlSSSsSSS',
    'SSSSSSSSSSSSsSSS',
    'ssssssssssssssss',
    'SSlSSSSSSSSSSSSs',
    'SSSSSSSlSSSlSSSs',
    'SSSSSSSSSSSSSSSs',
    'ssssssssssssssss',
    'SSSSSlSSSSSSSsSS',
    'SlSSSSSSSSSSSsSS',
    'SSSSSSSSSSSSSsSS',
  ], {'S': 0xFF9AA5B1, 's': 0xFF6B7684, 'l': 0xFFC3CBD4}),
  'Água': PreArte([
    'BBBBBBBBBBBBBBBB',
    'BBbbBBBBBBBbbBBB',
    'BBBBBBBBBBBBBBBB',
    'BBBBBBbbBBBBBBBB',
    'BBBBBBBBBBBBBBBB',
    'BbbBBBBBBBBBBbbB',
    'BBBBBBBBBBBBBBBB',
    'BBBBBBBBbbBBBBBB',
    'BBBBBBBBBBBBBBBB',
    'BBBbbBBBBBBBBBBB',
    'BBBBBBBBBBBBBbbB',
    'BBBBBBBBBBBBBBBB',
    'BBbbBBBBBBBbbBBB',
    'BBBBBBBBBBBBBBBB',
    'BBBBBBbbBBBBBBBB',
    'DBBBBBBBBBBBBBBD',
  ], {'B': 0xFF3BA7F0, 'b': 0xFF7CC4F7, 'D': 0xFF2A86C9}),
  'Areia': PreArte([
    'AAAAAaAAAAAAAAaA',
    'AaAAAAAAAaAAAAAA',
    'AAAAAAaAAAAAAaAA',
    'AAaAAAAAAAAAAAAA',
    'AAAAAAAAaAAAAAAa',
    'AAAAaAAAAAAaAAAA',
    'aAAAAAAAAAAAAAaA',
    'AAAAAAAaAAAAAAAA',
    'AAaAAAAAAAAaAAAA',
    'AAAAAAAAAaAAAAaA',
    'AAAAaAAAAAAAAAAA',
    'aAAAAAAAAaAAAaAA',
    'AAAAAAAaAAAAAAAA',
    'AAaAAAAAAAAAAAaA',
    'AAAAAAAAAaAAAAAA',
    'AAAAAaAAAAAAaAAA',
  ], {'A': 0xFFF2D58A, 'a': 0xFFD9B968}),
  'Árvore': PreArte([
    '................',
    '......GGGGG.....',
    '....GGGGGGGGG...',
    '...GGGgGGGGGGG..',
    '..GGGGGGGGGgGG..',
    '..GGGGGGGGGGGGG.',
    '..GGgGGGGGGGGGG.',
    '..GGGGGGGgGGGGG.',
    '...GGGGGGGGGGG..',
    '...GGGgGGGGGgG..',
    '....GGGGGGGGG...',
    '......TTTT......',
    '......TtTT......',
    '......TtTT......',
    '.....TTtTTT.....',
    '................',
  ], {'G': 0xFF2E9E4F, 'g': 0xFF1F7A3A, 'T': 0xFF8A5A2B, 't': 0xFF6B4220}),
  'Flor': PreArte([
    '................',
    '................',
    '................',
    '......PPP.......',
    '.....PPYPP......',
    '.....PPYPP......',
    '......PPP.......',
    '.......G........',
    '.......G..G.....',
    '....G..G.GG.....',
    '.....GGGGG......',
    '......GGG.......',
    '.......G........',
    '.......G........',
    '......GGG.......',
    '................',
  ], {'P': 0xFFEC4899, 'Y': 0xFFF59E0B, 'G': 0xFF23A55A}),
  'Nuvem': PreArte([
    '................',
    '................',
    '................',
    '................',
    '......WWWW......',
    '....WWWWWWWW.WW.',
    '...WWWWWWWWWWWWW',
    '..WWWWWWWWWWWWWW',
    '..WWWWWWWWWWWWWW',
    '...wwwwwwwwwwwww',
    '................',
    '................',
    '................',
    '................',
    '................',
    '................',
  ], {'W': 0xFFF1F3F5, 'w': 0xFFBFC4CA}),
  'Herói': PreArte([
    '................',
    '.....HHHHH......',
    '....HHHHHHH.....',
    '....HSSSSSH.....',
    '....SSeSSeS.....',
    '....SSSSSSS.....',
    '.....SSmSS......',
    '......SSS.......',
    '....BBBBBBB.....',
    '...BBBBBBBBB....',
    '...SBBBBBBBS....',
    '...SBBBBBBBS....',
    '....BBBBBBB.....',
    '....PPP.PPP.....',
    '....PPP.PPP.....',
    '...KKK...KKK....',
  ], {'H': 0xFF6B3F1D, 'S': 0xFFF2C9A0, 'e': 0xFF1D1D1D, 'm': 0xFFB5523B, 'B': 0xFF1D9BF0, 'P': 0xFF3A3D42, 'K': 0xFF141414}),
  'Slime': PreArte([
    '................',
    '................',
    '................',
    '................',
    '................',
    '......GGGG......',
    '....GGGGGGGG....',
    '...GGGGGGGGGG...',
    '...GGWKGGWKGG...',
    '..GGGGGGGGGGGG..',
    '..GGGGGgGGGGGG..',
    '.GGGGGGGGGGGGGG.',
    '.GGgGGGGGGGgGGG.',
    '.GGGGGGGGGGGGGG.',
    '..dddddddddddd..',
    '................',
  ], {'G': 0xFF23A55A, 'g': 0xFF1B8247, 'd': 0xFF136035, 'W': 0xFFFFFFFF, 'K': 0xFF141414}),
  'Fantasma': PreArte([
    '................',
    '.....WWWWW......',
    '....WWWWWWW.....',
    '...WWWWWWWWW....',
    '...WWKKWWKKW....',
    '...WWKKWWKKW....',
    '...WWWWWWWWW....',
    '...WWWWMMWWW....',
    '...WWWWWWWWW....',
    '...WWWWWWWWw....',
    '...WWWWWWWWw....',
    '...WW.WWW.Ww....',
    '................',
    '................',
    '................',
    '................',
  ], {'W': 0xFFE6E8EB, 'w': 0xFFBFC4CA, 'K': 0xFF141414, 'M': 0xFF3A3D42}),
  'Baú': PreArte([
    '................',
    '................',
    '................',
    '..TTTTTTTTTTTT..',
    '.TtttttttttttT..',
    '.TttttttttttttT.',
    '.TTTTTTTTTTTTTT.',
    '.TddddddddddddT.',
    '.TTTTTTYYTTTTTT.',
    '.TttttTYKTttttT.',
    '.TttttTYYTttttT.',
    '.TttttttttttttT.',
    '.TttttttttttttT.',
    '.TTTTTTTTTTTTTT.',
    '................',
    '................',
  ], {'T': 0xFF8A5A2B, 't': 0xFFB4713A, 'd': 0xFF6B4220, 'Y': 0xFFF59E0B, 'K': 0xFF141414}),
  'Moeda': PreArte([
    '................',
    '................',
    '......oooo......',
    '....ooYYYYoo....',
    '...oYYYYYYYYo...',
    '...oYYyyyYYYo...',
    '..oYYYyYYYYYYo..',
    '..oYYYyYYYYYYo..',
    '..oYYYyYYYYYYo..',
    '..oYYYyyyYYYYo..',
    '...oYYYYYYYYo...',
    '...oYYYYYYYYo...',
    '....ooYYYYoo....',
    '......oooo......',
    '................',
    '................',
  ], {'o': 0xFFB87A0A, 'Y': 0xFFF59E0B, 'y': 0xFFFDE68A}),
  'Bandeira': PreArte([
    '................',
    '..GG............',
    '..GGRRRRRR......',
    '..GGRRRRRRRR....',
    '..GGRRRRRRRRR...',
    '..GGRRRRRRRR....',
    '..GGRRRRRR......',
    '..GG............',
    '..GG............',
    '..GG............',
    '..GG............',
    '..GG............',
    '..GG............',
    '..GG............',
    '..GG............',
    '.GGGG...........',
  ], {'G': 0xFF8E9297, 'R': 0xFFF23F43}),
  'PFP padrão': PreArte([
    'BBBBBBBBBBBBBBBB',
    'BBBBBBBBBBBBBBBB',
    'BBBBBBFFFFBBBBBB',
    'BBBBBFFFFFFBBBBB',
    'BBBBBFFFFFFBBBBB',
    'BBBBBFFFFFFBBBBB',
    'BBBBBBFFFFBBBBBB',
    'BBBBBBBFFBBBBBBB',
    'BBBBBFFFFFFBBBBB',
    'BBBBFFFFFFFFBBBB',
    'BBBFFFFFFFFFFBBB',
    'BBFFFFFFFFFFFFBB',
    'BBFFFFFFFFFFFFBB',
    'BBFFFFFFFFFFFFBB',
    'BBFFFFFFFFFFFFBB',
    'BBFFFFFFFFFFFFBB',
  ], {'B': 0xFF3A3D42, 'F': 0xFF8E9297}),
};

const nomePfpPadrao = 'PFP padrão';

final Map<String, ui.Picture> _figuras = {};

ui.Picture _figura(String nome) => _figuras.putIfAbsent(nome, () {
      final a = preArtes[nome]!;
      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec);
      for (var y = 0; y < 16; y++) {
        for (var x = 0; x < 16; x++) {
          final ch = a.linhas[y][x];
          final cor = a.cores[ch];
          if (cor == null) continue;
          c.drawRect(ui.Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), ui.Paint()..color = ui.Color(cor)..isAntiAlias = false);
        }
      }
      return rec.endRecording();
    });

/// Desenha o sprite [nome] dentro de [r] (pixels nitidos).
void desenharPre(ui.Canvas c, ui.Rect r, String nome) {
  if (!preArtes.containsKey(nome)) return;
  c.save();
  c.translate(r.left, r.top);
  c.scale(r.width / 16, r.height / 16);
  c.drawPicture(_figura(nome));
  c.restore();
}

/// PNG 16x16 do sprite (para a engine e para fotos de perfil).
Future<Uint8List> pngPre(String nome) async {
  final img = await _figura(nome).toImage(16, 16);
  final d = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  return d!.buffer.asUint8List();
}
