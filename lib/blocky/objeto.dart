import 'package:flutter/material.dart';

import 'mapa.dart';
import 'projetos.dart';
import 'widgets.dart';

// ---------------------------------------------------------------------------
// Componentes de um objeto.
//   Obrigatorios (todo objeto tem): Transformacao (posicao e tamanho), Aparencia (imagem, nome, camada, visivel).
//   Opcionais (liga/desliga por tipo): Corpo, Movimento, Coletavel, Vitoria, Dano.
//   Do ator principal: Controle do jogador (velocidade e pulo).
// Tudo e guardado como dados simples em ObjetoCena.props, para um script poder ler e trocar no futuro.
// ---------------------------------------------------------------------------

const componentesOpcionais = <String, (String, String)>{
  'corpo': ('Corpo', 'Sólido: bloqueia quem passa.'),
  'movimento': ('Movimento', 'Anda sozinho.'),
  'coletavel': ('Coletável', 'Some ao ser tocado pelo ator principal e conta moeda.'),
  'vitoria': ('Vitória', 'Tocar nele termina a fase.'),
  'dano': ('Dano', 'Tocar nele reinicia a fase.'),
};

bool solidoPadrao(ItemPaleta it) => it.aba == 'Tile' && const {'Grama', 'Terra', 'Pedra', 'Areia'}.contains(it.nome);

bool ehTile(ItemPaleta it) => it.aba == 'Tile';

/// Tile nao muda de tamanho; os outros tipos sim.
bool podeRedimensionar(ItemPaleta it) => !ehTile(it);

/// Quais componentes opcionais o tipo aceita.
bool compPermitido(String id, ItemPaleta it) => switch (id) {
      'corpo' => true,
      'movimento' => it.aba != 'Tile',
      'coletavel' || 'vitoria' => it.aba == 'Objeto',
      'dano' => it.aba == 'Ator' || it.aba == 'Objeto',
      _ => false,
    };

/// Modos de movimento do tipo (perseguir so para Ator).
List<String> modosMovimento(ItemPaleta it) => it.aba == 'Ator' ? const ['patrulha', 'perseguir'] : const ['patrulha'];

/// Componentes que o tipo/sprite ja traz ligados.
Map<String, Map<String, dynamic>> compPadrao(ItemPaleta it) {
  final m = <String, Map<String, dynamic>>{};
  if (solidoPadrao(it)) m['corpo'] = {};
  if (it.nome == 'Moeda') m['coletavel'] = {};
  if (it.nome == 'Bandeira') m['vitoria'] = {};
  if (it.nome == 'Slime' || it.nome == 'Fantasma') {
    m['movimento'] = {'modo': 'perseguir', 'vel': 60};
    m['dano'] = {};
  }
  return m;
}

/// Componentes opcionais ligados no objeto (o que o usuario mudou por cima do padrao; le tambem o formato antigo solido/scripts).
Map<String, Map<String, dynamic>> compsDe(ObjetoCena o, ItemPaleta it) {
  final p = o.props;
  final c = p['comp'];
  Map<String, Map<String, dynamic>> r;
  if (c is Map) {
    r = {for (final e in c.entries) e.key as String: Map<String, dynamic>.from((e.value as Map?) ?? {})};
  } else {
    r = compPadrao(it);
    if (p['solido'] is bool) {
      if (p['solido'] == true) {
        r['corpo'] = {};
      } else {
        r.remove('corpo');
      }
    }
    if (p['scripts'] is List) {
      for (final k in const ['coletavel', 'vitoria', 'dano', 'movimento']) {
        r.remove(k);
      }
      for (final s in (p['scripts'] as List)) {
        switch (s) {
          case 'coletavel':
            r['coletavel'] = {};
          case 'vitoria':
            r['vitoria'] = {};
          case 'perigo':
            r['dano'] = {};
          case 'perseguir':
            r['movimento'] = {'modo': 'perseguir', 'vel': 60};
          case 'patrulha':
            r['movimento'] = {'modo': 'patrulha', 'vel': 48};
        }
      }
    }
  }
  r.removeWhere((k, _) => !compPermitido(k, it));
  final mov = r['movimento'];
  if (mov != null && !modosMovimento(it).contains(mov['modo'])) mov['modo'] = 'patrulha';
  return r;
}

/// Propriedades finais de um objeto (para o painel e para a engine).
Map<String, dynamic> objetoEfetivo(ObjetoCena o, ItemPaleta it) {
  final p = o.props;
  final comps = compsDe(o, it);
  final mov = comps['movimento'];
  return {
    'nome': (p['nome'] as String?) ?? it.nome,
    'camada': (p['camada'] as num?)?.toInt() ?? 0,
    'visivel': (p['visivel'] as bool?) ?? true,
    'textura': (p['textura'] as num?)?.toInt(),
    'comps': comps,
    // derivados que a engine entende
    'solido': comps.containsKey('corpo'),
    'scripts': [
      if (comps.containsKey('coletavel')) 'coletavel',
      if (comps.containsKey('vitoria')) 'vitoria',
      if (comps.containsKey('dano')) 'perigo',
      if (mov != null) (mov['modo'] == 'perseguir' ? 'perseguir' : 'patrulha'),
    ],
    'movVel': (mov?['vel'] as num?)?.toInt(),
    'vel': (p['vel'] as num?)?.toInt(),
    'pulo': (p['pulo'] as num?)?.toInt(),
  };
}

/// Painel que aparece no lugar da paleta enquanto um objeto esta selecionado.
class PainelObjeto extends StatelessWidget {
  const PainelObjeto({
    super.key,
    required this.item,
    required this.imagem,
    required this.aoTrocarImagem,
    required this.dados,
    required this.id,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.principal,
    required this.aoMudar,
    required this.aoRestaurar,
  });
  final ItemPaleta item;
  final Widget imagem; // sprite atual do objeto
  final VoidCallback aoTrocarImagem;
  final Map<String, dynamic> dados; // resultado de objetoEfetivo
  final int id, x, y, w, h;
  final bool principal; // e o ator principal da cena
  final void Function(String chave, Object? valor) aoMudar;
  final VoidCallback aoRestaurar;

  Widget _secao(String t, [String? sub]) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Cores.texto2)),
          if (sub != null) ...[const SizedBox(width: 8), Expanded(child: Text(sub, style: const TextStyle(fontSize: 11, color: Cores.texto2)))],
        ]),
      );

  Widget _cartao(String titulo, IconData icone, List<Widget> filhos, {VoidCallback? aoRemover, String? sub}) => Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
        decoration: BoxDecoration(color: Cores.cartao2, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icone, size: 18, color: Cores.texto2),
            const SizedBox(width: 8),
            Expanded(child: Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
            if (aoRemover != null) IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.close_rounded, size: 19), onPressed: aoRemover),
          ]),
          if (sub != null) Padding(padding: const EdgeInsets.only(right: 8, bottom: 4), child: Text(sub, style: const TextStyle(fontSize: 12, color: Cores.texto2))),
          ...filhos,
        ]),
      );

  Widget _deslize(String rot, double v, double min, double max, int div, ValueChanged<double> mudou) => Row(children: [
        SizedBox(width: 74, child: Text(rot, style: const TextStyle(fontSize: 13))),
        Expanded(child: Slider(value: v.clamp(min, max), min: min, max: max, divisions: div, onChanged: mudou)),
        SizedBox(width: 38, child: Text('${v.round()}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
      ]);

  @override
  Widget build(BuildContext context) {
    final camada = dados['camada'] as int;
    final comps = (dados['comps'] as Map).map((k, v) => MapEntry(k as String, Map<String, dynamic>.from(v as Map)));
    void salvarComps(Map<String, Map<String, dynamic>> m) => aoMudar('comp', m);
    final livres = [for (final k in componentesOpcionais.keys) if (compPermitido(k, item) && !comps.containsKey(k)) k];
    final tile = ehTile(item);
    return ListView(padding: const EdgeInsets.only(bottom: 16), children: [
      _secao('OBRIGATÓRIOS', 'todo objeto tem'),
      _cartao('Transformação', Icons.open_with_rounded, [
        Text('Posição  ($x, $y)     Tamanho  $w × $h', style: const TextStyle(fontWeight: FontWeight.w600)),
        Padding(padding: const EdgeInsets.only(top: 2, right: 8), child: Text(tile ? 'Tile: tamanho fixo de 1 célula.' : 'Arraste o objeto para mover e as alças brancas (ou o botão de esticar) para o tamanho.', style: const TextStyle(fontSize: 12, color: Cores.texto2))),
      ]),
      _cartao('Aparência', Icons.palette_outlined, [
        Row(children: [
          Toque(
            aoTocar: aoTrocarImagem,
            child: Container(width: 58, height: 58, padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Cores.cartao, borderRadius: BorderRadius.circular(12), border: Border.all(color: Cores.acento, width: 1.5)), child: imagem),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('Toque na imagem para trocar. Animação (várias imagens): em breve.', style: TextStyle(fontSize: 12, color: Cores.texto2))),
        ]),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextFormField(
            key: ValueKey('nome$id'),
            initialValue: (dados['nome'] as String) == item.nome ? '' : dados['nome'] as String,
            maxLength: 30,
            decoration: InputDecoration(labelText: 'Nome do objeto', hintText: item.nome, counterText: '', isDense: true),
            onChanged: (v) => aoMudar('nome', v.trim().isEmpty ? null : v.trim()),
          ),
        ),
        Row(children: [
          const Expanded(child: Text('Camada (maior = por cima)', style: TextStyle(fontSize: 13))),
          IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.remove_rounded), onPressed: camada <= -5 ? null : () => aoMudar('camada', camada - 1)),
          SizedBox(width: 22, child: Text('$camada', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))),
          IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.add_rounded), onPressed: camada >= 5 ? null : () => aoMudar('camada', camada + 1)),
        ]),
        Row(children: [
          const Expanded(child: Text('Visível', style: TextStyle(fontSize: 13))),
          Switch(value: dados['visivel'] as bool, onChanged: (v) => aoMudar('visivel', v)),
        ]),
      ]),
      if (principal)
        _cartao('Controle do jogador', Icons.sports_esports_outlined, [
          _deslize('Velocidade', ((dados['vel'] as int?) ?? 170).toDouble(), 60, 400, 34, (v) => aoMudar('vel', v.round() == 170 ? null : v.round())),
          _deslize('Pulo', ((dados['pulo'] as int?) ?? 520).toDouble(), 200, 900, 35, (v) => aoMudar('pulo', v.round() == 520 ? null : v.round())),
        ], sub: 'Este é o ator principal: o joystick e o botão Pular controlam ele.'),
      _secao('OPCIONAIS', tile ? 'Tile aceita só Corpo' : 'ligue só o que precisa'),
      for (final e in comps.entries)
        _cartao(
          componentesOpcionais[e.key]!.$1,
          switch (e.key) { 'corpo' => Icons.crop_square_rounded, 'movimento' => Icons.directions_walk_rounded, 'coletavel' => Icons.monetization_on_outlined, 'vitoria' => Icons.flag_outlined, _ => Icons.warning_amber_rounded },
          [
            if (e.key == 'movimento') ...[
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 2),
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [for (final m in modosMovimento(item)) ButtonSegment(value: m, label: Text(m == 'perseguir' ? 'Perseguir ator' : 'Patrulha'))],
                  selected: {(e.value['modo'] as String?) ?? 'patrulha'},
                  onSelectionChanged: (s) => salvarComps({...comps, 'movimento': {...e.value, 'modo': s.first}}),
                ),
              ),
              _deslize('Velocidade', ((e.value['vel'] as num?) ?? 48).toDouble(), 10, 200, 19, (v) => salvarComps({...comps, 'movimento': {...e.value, 'vel': v.round()}})),
            ],
          ],
          sub: componentesOpcionais[e.key]!.$2,
          aoRemover: () => salvarComps({...comps}..remove(e.key)),
        ),
      if (livres.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final k in livres)
              Toque(
                aoTocar: () => salvarComps({...comps, k: k == 'movimento' ? {'modo': modosMovimento(item).first, 'vel': 48} : <String, dynamic>{}}),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Cores.cartao2, borderRadius: BorderRadius.circular(8)),
                  child: Text('+ ${componentesOpcionais[k]!.$1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
          ]),
        ),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: aoRestaurar, child: const Text('Restaurar padrão do tipo')))),
    ]);
  }
}
