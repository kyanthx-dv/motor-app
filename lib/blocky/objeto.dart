import 'package:flutter/material.dart';

import 'mapa.dart';
import 'projetos.dart';
import 'widgets.dart';

/// Comportamentos que podem ser anexados a um objeto do mapa (a engine entende cada id).
const scriptsDisponiveis = <String, (String, String)>{
  'coletavel': ('Coletável', 'Some ao ser tocado pelo herói e conta moeda.'),
  'vitoria': ('Vitória', 'Tocar nele termina a fase.'),
  'perigo': ('Perigo', 'Tocar nele reinicia a fase.'),
  'perseguir': ('Perseguir herói', 'Anda atrás do herói quando ele chega perto.'),
  'patrulha': ('Patrulha', 'Vai e volta na horizontal.'),
};

bool solidoPadrao(ItemPaleta it) => it.aba == 'Tile' && const {'Grama', 'Terra', 'Pedra', 'Areia'}.contains(it.nome);

List<String> scriptsPadrao(ItemPaleta it) => switch (it.nome) {
      'Moeda' => ['coletavel'],
      'Bandeira' => ['vitoria'],
      'Slime' || 'Fantasma' => ['perseguir', 'perigo'],
      _ => [],
    };

bool ehTile(ItemPaleta it) => it.aba == 'Tile';

/// Tile nao muda de tamanho; os outros tipos sim.
bool podeRedimensionar(ItemPaleta it) => !ehTile(it);

/// Scripts que o tipo aceita: Tile nenhum; Deco so movimento; Ator comportamentos de inimigo; Objeto interacoes.
List<String> scriptsPermitidos(ItemPaleta it) => switch (it.aba) {
      'Tile' => const [],
      'Deco' => const ['patrulha'],
      'Ator' => const ['perseguir', 'patrulha', 'perigo'],
      _ => const ['coletavel', 'vitoria', 'perigo', 'patrulha'],
    };

/// Propriedades finais de um objeto (o que foi mudado por cima do padrao do tipo).
Map<String, dynamic> objetoEfetivo(ObjetoCena o, ItemPaleta it) {
  final p = o.props;
  final ok = scriptsPermitidos(it);
  return {
    'nome': (p['nome'] as String?) ?? it.nome,
    'camada': (p['camada'] as num?)?.toInt() ?? 0,
    'solido': (p['solido'] as bool?) ?? solidoPadrao(it),
    'visivel': (p['visivel'] as bool?) ?? true,
    'textura': (p['textura'] as num?)?.toInt(),
    'scripts': [for (final s in ((p['scripts'] as List?) ?? scriptsPadrao(it))) if (ok.contains(s)) s as String],
  };
}

/// Painel que aparece no lugar da paleta enquanto um objeto esta selecionado.
class PainelObjeto extends StatelessWidget {
  const PainelObjeto({super.key, required this.item, required this.imagem, required this.aoTrocarImagem, required this.dados, required this.id, required this.aoMudar, required this.aoRestaurar});
  final ItemPaleta item;
  final Widget imagem; // sprite atual do objeto
  final VoidCallback aoTrocarImagem;
  final Map<String, dynamic> dados; // resultado de objetoEfetivo
  final int id;
  final void Function(String chave, Object? valor) aoMudar;
  final VoidCallback aoRestaurar;

  Widget _secao(String t) => Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Cores.texto2)));

  @override
  Widget build(BuildContext context) {
    final camada = dados['camada'] as int;
    final scripts = (dados['scripts'] as List).cast<String>();
    final permitidos = scriptsPermitidos(item);
    final livres = [for (final id in permitidos) if (!scripts.contains(id)) id];
    return ListView(padding: const EdgeInsets.only(bottom: 16), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(children: [
          Toque(
            aoTocar: aoTrocarImagem,
            child: Container(width: 64, height: 64, padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Cores.cartao2, borderRadius: BorderRadius.circular(12), border: Border.all(color: Cores.acento, width: 1.5)), child: imagem),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Toque na imagem para trocar. Para animar (várias imagens), em breve.', style: TextStyle(fontSize: 12, color: Cores.texto2))),
        ]),
      ),
      _secao('PRIORIDADES'),
      ListTile(
        dense: true,
        title: const Text('Camada de desenho'),
        subtitle: const Text('Maior = desenha por cima', style: TextStyle(fontSize: 12, color: Cores.texto2)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: const Icon(Icons.remove_rounded), onPressed: camada <= -5 ? null : () => aoMudar('camada', camada - 1)),
          SizedBox(width: 24, child: Text('$camada', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))),
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: camada >= 5 ? null : () => aoMudar('camada', camada + 1)),
        ]),
      ),
      SwitchListTile(dense: true, title: const Text('Sólido (bloqueia o herói)'), value: dados['solido'] as bool, onChanged: (v) => aoMudar('solido', v)),
      SwitchListTile(dense: true, title: const Text('Visível'), value: dados['visivel'] as bool, onChanged: (v) => aoMudar('visivel', v)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextFormField(
          key: ValueKey('nome$id'),
          initialValue: (dados['nome'] as String) == item.nome ? '' : dados['nome'] as String,
          maxLength: 30,
          decoration: InputDecoration(labelText: 'Nome do objeto', hintText: item.nome, counterText: ''),
          onChanged: (v) => aoMudar('nome', v.trim().isEmpty ? null : v.trim()),
        ),
      ),
      _secao('SCRIPTS ANEXADOS'),
      if (permitidos.isEmpty) const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Text('Tiles não aceitam scripts (são só cenário sólido ou decorativo).', style: TextStyle(color: Cores.texto2)))
      else if (scripts.isEmpty) const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Text('Nenhum script.', style: TextStyle(color: Cores.texto2))),
      for (final id in scripts)
        ListTile(
          dense: true,
          leading: const Icon(Icons.bolt_outlined, size: 20),
          title: Text(scriptsDisponiveis[id]?.$1 ?? id),
          subtitle: Text(scriptsDisponiveis[id]?.$2 ?? '', style: const TextStyle(fontSize: 12, color: Cores.texto2)),
          trailing: IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => aoMudar('scripts', [...scripts]..remove(id))),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final id in livres)
            Toque(
              aoTocar: () => aoMudar('scripts', [...scripts, id]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Cores.cartao2, borderRadius: BorderRadius.circular(8)),
                child: Text('+ ${scriptsDisponiveis[id]!.$1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 8),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: aoRestaurar, child: const Text('Restaurar padrão do tipo')))),
    ]);
  }
}
