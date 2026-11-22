import 'package:flutter/material.dart';

import 'icones.dart';
/// Dados de EXEMPLO para desenhar e testar as telas. Quando o Supabase for ligado, estas listas viram consultas.

enum Orientacao { paisagem, retrato, qualquer }

String rotuloOrientacao(Orientacao o) => switch (o) {
      Orientacao.paisagem => 'Horizontal',
      Orientacao.retrato => 'Vertical',
      Orientacao.qualquer => 'Horizontal ou vertical',
    };

String abreviar(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}

class Comentario {
  const Comentario(this.autor, this.texto);
  final String autor;
  final String texto;
}

class Jogo {
  const Jogo({
    required this.id,
    required this.titulo,
    required this.autor,
    required this.descricao,
    required this.cor1,
    required this.cor2,
    required this.icone,
    this.orientacao = Orientacao.paisagem,
    this.curtidas = 0,
    this.favoritos = 0,
    this.visitas = 0,
    this.comentarios = const [],
  });
  final String id;
  final String titulo;
  final String autor;
  final String descricao;
  final Color cor1;
  final Color cor2;
  final IconData icone;
  final Orientacao orientacao;
  final int curtidas;
  final int favoritos;
  final int visitas;
  final List<Comentario> comentarios;
}

class Post {
  const Post({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.autor,
    required this.cor1,
    required this.cor2,
    required this.icone,
    this.video = false,
    this.curtidas = 0,
    this.comentarios = const [],
    this.autorId = '',
    this.totalComentarios = -1,
    this.midia,
  });
  final String? midia; // url da foto/video enviado (null = capa colorida)
  final String id;
  final String autorId; // uuid do autor (vazio nos exemplos)
  final int totalComentarios; // -1 = usa comentarios.length
  int get numComentarios => totalComentarios >= 0 ? totalComentarios : comentarios.length;
  final String titulo;
  final String descricao;
  final String autor;
  final Color cor1;
  final Color cor2;
  final IconData icone;
  final bool video;
  final int curtidas;
  final List<Comentario> comentarios;
}

class ItemLoja {
  const ItemLoja({
    required this.id,
    required this.titulo,
    required this.autor,
    required this.pfp,
    required this.cor1,
    required this.cor2,
    required this.icone,
    this.preco = 0,
  });
  final String id;
  final String titulo;
  final String autor;
  final bool pfp;
  final Color cor1;
  final Color cor2;
  final IconData icone;
  final int preco; // 0 = gratis
}

/// Selos de perfil (vem do servidor; so a equipe concede verificado, bot, dono).
enum Selo { dono, verificado, premium, bot }

class Pessoa {
  // seguindo: quantas pessoas ela segue
  const Pessoa(this.usuario, this.nome, this.seguidores, {this.id = 0, this.selos = const [], this.bio = '', this.seguindo = 0});
  final String usuario;
  final String nome;
  final int seguindo;
  final int seguidores;
  final int id; // ID numerico fixo da conta (nao muda como o @usuario)
  final List<Selo> selos;
  final String bio;
}

class Aviso {
  const Aviso(this.tipo, this.titulo, this.texto);
  final String tipo; // info | novidade | erro
  final String titulo;
  final String texto;
}

const jogosExemplo = <Jogo>[
  Jogo(
    id: 'j1',
    titulo: 'Mini-RPG da Vila',
    autor: 'kyanthx',
    descricao: 'Converse com o aldeão, pegue poções e enfrente o slime. Feito com os modelos de RPG do Motor.',
    cor1: Color(0xFF16A34A),
    cor2: Color(0xFF065F46),
    icone: Ic.castelo,
    curtidas: 1280,
    favoritos: 340,
    visitas: 15400,
    comentarios: [Comentario('ana_01', 'Muito legal o inventário!'), Comentario('bob', 'Como derrota o slime?')],
  ),
  Jogo(
    id: 'j2',
    titulo: 'Pega-moedas',
    autor: 'kyanthx',
    descricao: 'Pegue todas as moedas antes que o tempo acabe. Ideal para jogar com uma mão.',
    cor1: Color(0xFFF59E0B),
    cor2: Color(0xFFB45309),
    icone: Ic.moeda,
    orientacao: Orientacao.retrato,
    curtidas: 860,
    favoritos: 120,
    visitas: 9800,
  ),
  Jogo(
    id: 'j3',
    titulo: 'Futebol de Botão',
    autor: 'luna',
    descricao: 'Partida rápida estilo Haxball, 1 contra 1 com física Matter.',
    cor1: Color(0xFF2563EB),
    cor2: Color(0xFF1E3A8A),
    icone: Ic.futebol,
    curtidas: 2210,
    favoritos: 560,
    visitas: 40200,
    comentarios: [Comentario('luna', 'Atualizei a física da bola!')],
  ),
  Jogo(
    id: 'j4',
    titulo: 'Labirinto Neon',
    autor: 'zed',
    descricao: 'Encontre a saída do labirinto antes de a luz acabar.',
    cor1: Color(0xFF9333EA),
    cor2: Color(0xFF4C1D95),
    icone: Icons.grid_on,
    orientacao: Orientacao.qualquer,
    curtidas: 430,
    favoritos: 80,
    visitas: 5100,
  ),
  Jogo(
    id: 'j5',
    titulo: 'Corrida de Nave',
    autor: 'zed',
    descricao: 'Desvie dos asteroides e bata seu recorde.',
    cor1: Color(0xFFDC2626),
    cor2: Color(0xFF7F1D1D),
    icone: Ic.foguete,
    curtidas: 300,
    favoritos: 45,
    visitas: 3200,
  ),
  Jogo(
    id: 'j6',
    titulo: 'Fazenda Zen',
    autor: 'luna',
    descricao: 'Plante, colha e decore sua fazenda, sem pressa.',
    cor1: Color(0xFF65A30D),
    cor2: Color(0xFF365314),
    icone: Icons.agriculture,
    orientacao: Orientacao.retrato,
    curtidas: 990,
    favoritos: 410,
    visitas: 12000,
  ),
];

const postsExemplo = <Post>[
  Post(
    id: 'p1',
    titulo: 'Novo mapa do Mini-RPG',
    descricao: 'Mostrando a vila nova com camadas e paralaxe. O que acharam?',
    autor: 'kyanthx',
    cor1: Color(0xFF16A34A),
    cor2: Color(0xFF14532D),
    icone: Icons.map,
    curtidas: 210,
    comentarios: [Comentario('ana_01', 'Ficou lindo!')],
  ),
  Post(
    id: 'p2',
    titulo: 'Gameplay da Corrida de Nave',
    descricao: 'Meu melhor recorde até agora.',
    autor: 'zed',
    cor1: Color(0xFFDC2626),
    cor2: Color(0xFF450A0A),
    icone: Ic.foguete,
    video: true,
    curtidas: 98,
  ),
  Post(
    id: 'p3',
    titulo: 'Pack de árvores grátis',
    descricao: 'Publiquei 12 árvores em pixel art na aba Assets.',
    autor: 'luna',
    cor1: Color(0xFF65A30D),
    cor2: Color(0xFF1A2E05),
    icone: Ic.arvore,
    curtidas: 340,
    comentarios: [Comentario('bob', 'Baixei, obrigado!'), Comentario('zed', 'Top')],
  ),
];

const itensLojaExemplo = <ItemLoja>[
  ItemLoja(id: 'a1', titulo: 'Pack de árvores', autor: 'luna', pfp: false, cor1: Color(0xFF65A30D), cor2: Color(0xFF1A2E05), icone: Ic.arvore),
  ItemLoja(id: 'a2', titulo: 'Sons 8-bit', autor: 'zed', pfp: false, cor1: Color(0xFF9333EA), cor2: Color(0xFF3B0764), icone: Ic.musica),
  ItemLoja(id: 'a3', titulo: 'Tiles de masmorra', autor: 'kyanthx', pfp: false, cor1: Color(0xFF475569), cor2: Color(0xFF0F172A), icone: Ic.grade),
  ItemLoja(id: 'a4', titulo: 'Efeitos de explosão', autor: 'luna', pfp: false, cor1: Color(0xFFF97316), cor2: Color(0xFF7C2D12), icone: Ic.fogo, preco: 50),
  ItemLoja(id: 'f1', titulo: 'Gatinho pixel', autor: 'luna', pfp: true, cor1: Color(0xFFEC4899), cor2: Color(0xFF831843), icone: Ic.pata),
  ItemLoja(id: 'f2', titulo: 'Robô azul', autor: 'zed', pfp: true, cor1: Color(0xFF0EA5E9), cor2: Color(0xFF0C4A6E), icone: Ic.robo2),
  ItemLoja(id: 'f3', titulo: 'Cavaleiro', autor: 'kyanthx', pfp: true, cor1: Color(0xFF64748B), cor2: Color(0xFF1E293B), icone: Icons.shield, preco: 30),
];

const pessoasExemplo = <Pessoa>[
  Pessoa('kyanthx', 'Kyan', 1200, id: 1, selos: [Selo.dono, Selo.verificado], bio: 'Criando jogos 2D com o Motor.'),
  Pessoa('luna', 'Luna Games', 8400, id: 1042, selos: [Selo.verificado, Selo.premium], bio: 'RPGs e pixel art.'),
  Pessoa('zed', 'Zed', 560, id: 2210, selos: [Selo.premium], bio: 'Plataformas rápidas.'),
  Pessoa('ana_01', 'Ana', 90, id: 3871, bio: 'Aprendendo a fazer jogos.'),
  Pessoa('bob', 'Bob', 33, id: 4120),
  Pessoa('blocky', 'Blocky', 15000, id: 2, selos: [Selo.bot, Selo.verificado], bio: 'Conta oficial de avisos e novidades.'),
];

const avisosExemplo = <Aviso>[
  Aviso('novidade', 'Novidade', 'Campo de texto e lista rolável chegaram ao Motor. Use no seu jogo!'),
  Aviso('info', 'Dica', 'Toque em ＋ para criar um jogo, publicar um asset ou fazer um post.'),
  Aviso('erro', 'Modo demonstração', 'Os jogos, posts e pessoas mostrados aqui são de exemplo. A conta real será ligada em breve.'),
];
