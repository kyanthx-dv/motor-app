import 'dart:async';

import 'package:flutter/foundation.dart';

import 'avisos.dart';
import 'nuvem.dart';

/// Fotos de perfil por @usuario (url publica do Storage). Busca em lotes e guarda em memoria.
/// null = sem foto (mostra a foto de perfil padrao).
class Avatares extends ChangeNotifier {
  Avatares._();
  static final Avatares i = Avatares._();

  final Map<String, String?> _cache = {};
  final Set<String> _pedidos = {};
  Timer? _lote;

  String? de(String usuario) {
    if (_cache.containsKey(usuario)) return _cache[usuario];
    if (_pedidos.add(usuario)) _lote ??= Timer(const Duration(milliseconds: 60), _buscar);
    return null;
  }

  Future<void> _buscar() async {
    _lote = null;
    final nomes = _pedidos.toList();
    _pedidos.clear();
    if (nomes.isEmpty) return;
    try {
      final validos = nomes.where((n) => RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(n)).toList();
      final achados = validos.isEmpty ? <String, String?>{} : await Nuvem.i.avataresDe(validos);
      for (final n in nomes) {
        _cache[n] = achados[n];
      }
      notifyListeners();
    } on ErroNuvem catch (e) {
      Avisos.add(Nivel.aviso, 'Fotos de perfil: ${e.msg}');
      for (final n in nomes) {
        _cache[n] = null; // tenta de novo so ao reabrir o app
      }
    }
  }

  void definir(String usuario, String? url) {
    _cache[usuario] = url;
    notifyListeners();
  }
}
