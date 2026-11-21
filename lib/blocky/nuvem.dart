import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'avisos.dart';

// Chave PUBLICA (anon): pode ficar no app. A seguranca vem das regras (RLS) no banco, nao do segredo desta chave.
const _url = 'https://lzydscfeqzifxtvcpnmz.supabase.co';
const _chave = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6eWRzY2ZlcXppZnh0dmNwbm16Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUwMzY2NDksImV4cCI6MjExMDYxMjY0OX0.ZdzvztGOWjZ0qfZ2nfEcpH9FaYA9paBQTJTQcDC9Ybc';

class ErroNuvem implements Exception {
  ErroNuvem(this.msg);
  final String msg;
  @override
  String toString() => msg;
}

final _reUsuario = RegExp(r'^[a-z0-9_]{3,20}$');

/// Cliente do Supabase (REST puro, sem pacotes): login, sessao guardada no aparelho e perfil.
class Nuvem extends ChangeNotifier {
  Nuvem._();
  static final i = Nuvem._();

  String? _token;
  String? _refresh;
  DateTime? _expira;
  String? usuarioId;
  String? usuario; // @nome (da tabela perfis)

  bool get logado => _token != null && usuarioId != null;

  static bool usuarioValido(String u) => _reUsuario.hasMatch(u);

  Future<File> _arq() async => File('${(await getApplicationDocumentsDirectory()).path}/sessao.json');

  Future<void> carregar() async {
    try {
      final f = await _arq();
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _token = j['t'] as String?;
        _refresh = j['r'] as String?;
        _expira = DateTime.tryParse((j['e'] as String?) ?? '');
        usuarioId = j['id'] as String?;
        usuario = j['u'] as String?;
        await _renovarSeVencido();
      }
    } catch (e) {
      Avisos.add(Nivel.aviso, 'Sessão não carregada: $e');
    }
    notifyListeners();
  }

  Future<void> _guardar() async {
    try {
      final f = await _arq();
      if (_token == null) {
        if (await f.exists()) await f.delete();
        return;
      }
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(jsonEncode({'t': _token, 'r': _refresh, 'e': _expira?.toIso8601String(), 'id': usuarioId, 'u': usuario}));
      await tmp.rename(f.path);
    } catch (e) {
      Avisos.add(Nivel.aviso, 'Sessão não salva: $e');
    }
  }

  void _limpar() {
    _token = _refresh = usuarioId = usuario = null;
    _expira = null;
  }

  void _aplicar(Map<String, dynamic> j) {
    _token = j['access_token'] as String?;
    _refresh = j['refresh_token'] as String?;
    final seg = (j['expires_in'] as num?)?.toInt() ?? 3600;
    _expira = DateTime.now().add(Duration(seconds: seg));
    final u = j['user'] as Map<String, dynamic>?;
    usuarioId = u?['id'] as String?;
  }

  Future<void> _renovarSeVencido() async {
    if (_token == null || _expira == null || _refresh == null) return;
    if (DateTime.now().isBefore(_expira!.subtract(const Duration(seconds: 60)))) return;
    try {
      final j = await _req('POST', '/auth/v1/token?grant_type=refresh_token', corpo: {'refresh_token': _refresh}, auth: false) as Map<String, dynamic>;
      _aplicar(j);
      await _guardar();
    } on ErroNuvem catch (e) {
      if (e.msg == 'Sem internet.' || e.msg.startsWith('Demorou')) return; // offline: mantem a sessao para tentar depois
      _limpar();
      await _guardar();
    }
  }

  Future<dynamic> _req(String metodo, String caminho, {Object? corpo, bool auth = true, Map<String, String>? extra}) async {
    if (auth) await _renovarSeVencido();
    final c = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final r = await c.openUrl(metodo, Uri.parse('$_url$caminho'));
      r.headers.set('apikey', _chave);
      r.headers.set('Authorization', 'Bearer ${auth && _token != null ? _token : _chave}');
      r.headers.contentType = ContentType.json;
      extra?.forEach(r.headers.set);
      if (corpo != null) r.write(jsonEncode(corpo));
      final resp = await r.close().timeout(const Duration(seconds: 15));
      final txt = await resp.transform(utf8.decoder).join();
      dynamic j;
      if (txt.isNotEmpty) {
        try {
          j = jsonDecode(txt);
        } catch (_) {}
      }
      if (resp.statusCode >= 400) throw ErroNuvem(_traduzir(j, resp.statusCode));
      return j;
    } on SocketException {
      throw ErroNuvem('Sem internet.');
    } on TimeoutException {
      throw ErroNuvem('Demorou demais. Tente de novo.');
    } on HandshakeException {
      throw ErroNuvem('Falha de conexão segura. Verifique a internet.');
    } finally {
      c.close();
    }
  }

  String _traduzir(dynamic j, int status) {
    final m = j is Map ? '${j['msg'] ?? j['error_description'] ?? j['message'] ?? ''}' : '';
    final cod = j is Map ? '${j['code'] ?? j['error_code'] ?? ''}' : '';
    final baixo = m.toLowerCase();
    if (baixo.contains('invalid login')) return 'E-mail ou senha incorretos.';
    if (baixo.contains('already registered') || cod == 'user_already_exists') return 'Esse e-mail já tem conta. Use Entrar.';
    if (baixo.contains('email not confirmed') || cod == 'email_not_confirmed') return 'Confirme seu e-mail (veja a caixa de entrada) e entre de novo.';
    if (baixo.contains('password') && (baixo.contains('least') || baixo.contains('weak'))) return 'Senha fraca: use 8 caracteres ou mais.';
    if (baixo.contains('rate limit') || status == 429) return 'Muitas tentativas. Espere um pouco e tente de novo.';
    if (baixo.contains('valid email') || baixo.contains('invalid email') || cod == 'validation_failed') return 'E-mail inválido.';
    if (cod == '23505') return 'Esse nome de usuário já existe.';
    if (status == 401 || status == 403) return 'Sem permissão. Entre de novo.';
    return m.isEmpty ? 'Algo deu errado ($status).' : m;
  }

  Future<bool> usuarioLivre(String u) async {
    final l = await _req('GET', '/rest/v1/perfis?usuario=eq.${Uri.encodeQueryComponent(u)}&select=id', auth: false) as List;
    return l.isEmpty;
  }

  /// Entra e garante que o perfil exista (criado com o @ guardado no cadastro).
  Future<void> entrar(String email, String senha) async {
    final j = await _req('POST', '/auth/v1/token?grant_type=password', corpo: {'email': email.trim(), 'password': senha}, auth: false) as Map<String, dynamic>;
    _aplicar(j);
    final meta = ((j['user'] as Map<String, dynamic>?)?['user_metadata'] as Map<String, dynamic>?)?['usuario'] as String?;
    await _garantirPerfil(meta);
    await _guardar();
    notifyListeners();
  }

  /// true = entrou direto; false = precisa confirmar o e-mail antes.
  Future<bool> criarConta(String email, String senha, String nome) async {
    final u = nome.trim().toLowerCase();
    if (!usuarioValido(u)) throw ErroNuvem('Usuário: 3 a 20 letras minúsculas, números ou _.');
    if (senha.length < 8) throw ErroNuvem('Senha fraca: use 8 caracteres ou mais.');
    if (!await usuarioLivre(u)) throw ErroNuvem('Esse nome de usuário já existe.');
    final j = await _req('POST', '/auth/v1/signup', corpo: {'email': email.trim(), 'password': senha, 'data': {'usuario': u}}, auth: false) as Map<String, dynamic>;
    if (j['access_token'] == null) return false;
    _aplicar(j);
    await _garantirPerfil(u);
    await _guardar();
    notifyListeners();
    return true;
  }

  Future<void> _garantirPerfil(String? meta) async {
    final l = await _req('GET', '/rest/v1/perfis?id=eq.$usuarioId&select=usuario') as List;
    if (l.isNotEmpty) {
      usuario = (l.first as Map)['usuario'] as String?;
      return;
    }
    if (meta == null || !usuarioValido(meta)) throw ErroNuvem('Conta sem nome de usuário. Crie a conta de novo.');
    await _req('POST', '/rest/v1/perfis', corpo: {'id': usuarioId, 'usuario': meta}, extra: {'Prefer': 'return=minimal'});
    usuario = meta;
  }

  Future<void> sair() async {
    try {
      if (logado) await _req('POST', '/auth/v1/logout');
    } catch (_) {}
    _limpar();
    await _guardar();
    notifyListeners();
  }
}
