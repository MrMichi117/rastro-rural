import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'browser_bridge.dart';

typedef Data = Map<String, dynamic>;

class ApiError implements Exception {
  const ApiError(this.message, [this.status = 0]);
  final String message;
  final int status;
  @override
  String toString() => message;
}

class RastroApi extends ChangeNotifier {
  RastroApi({http.Client? client, Uri? base})
    : client = client ?? http.Client(),
      base =
          base ??
          Uri.base.resolve(
            const String.fromEnvironment('API_BASE', defaultValue: 'api/'),
          );
  final http.Client client;
  final Uri base;
  String? token;
  Data? user;
  Data config = {};
  Data catalogs = {'especies': <dynamic>[], 'sectores': <dynamic>[]};
  bool get authenticated => token != null && user != null;
  String get name =>
      (user?['nombre_visible'] ?? user?['nombre_usuario'] ?? 'vecino')
          .toString();

  Future<Data> request(String path, {String method = 'GET', Data? body}) async {
    final req = http.Request(method, base.resolve(path));
    req.headers['Accept'] = 'application/json';
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    try {
      final result = await http.Response.fromStream(
        await client.send(req).timeout(const Duration(seconds: 20)),
      );
      final decoded = jsonDecode(utf8.decode(result.bodyBytes));
      if (result.statusCode == 401) {
        token = null;
        user = null;
        notifyListeners();
      }
      if (result.statusCode >= 400) {
        throw ApiError(
          decoded['error']?.toString() ?? 'No pudimos confirmar la operación.',
          result.statusCode,
        );
      }
      return Map<String, dynamic>.from(decoded as Map);
    } on ApiError {
      rethrow;
    } on TimeoutException {
      throw const ApiError(
        'El servidor tardó en responder. Consulta el reporte antes de reenviar.',
      );
    } catch (_) {
      throw const ApiError(
        'No pudimos conectar con el servidor. Revisa la conexión y vuelve a intentarlo.',
      );
    }
  }

  Future<void> acceptToken(String value) async {
    token = value;
    try {
      user = (await request('me'))['usuario'] as Data;
    } catch (_) {
      token = null;
      user = null;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    final incoming = takeUrlToken();
    config = await request('config');
    if (incoming != null) {
      await acceptToken(incoming);
    } else if (config['development'] == true) {
      await acceptToken('dev-vecino-1');
    }
    listenForIdentity(config['platform_origin']?.toString() ?? '', (
      value,
    ) async {
      try {
        await acceptToken(value);
      } catch (_) {
        /* Protected views show expired access. */
      }
    });
    catalogs = await request('catalogos');
  }

  String photoUrl(int id) => base.resolve('reportes/$id/foto').toString();
  @override
  void dispose() {
    client.close();
    super.dispose();
  }
}
