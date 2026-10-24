import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

// Only /api/me determines the identity; the URL user name is untrusted.
String? takeUrlToken() {
  final uri = Uri.parse(web.window.location.href);
  final token = uri.queryParameters['token'];
  if (uri.queryParameters.containsKey('token') ||
      uri.queryParameters.containsKey('usuario')) {
    final params = Map<String, String>.from(uri.queryParameters)
      ..remove('token')
      ..remove('usuario');
    final clean = uri.replace(
      query: params.isEmpty ? '' : Uri(queryParameters: params).query,
    );
    web.window.history.replaceState(null, '', clean.toString());
  }
  if (token == null || token.length > 16384) return null;
  var value = token.trim();
  if (value.startsWith('"')) {
    try {
      value = jsonDecode(value) as String;
    } catch (_) {
      return null;
    }
  }
  return value.isEmpty ? null : value;
}

void listenForIdentity(String origin, void Function(String) receive) {
  if (origin.isEmpty || web.window.opener == null) return;
  web.window.addEventListener(
    'message',
    ((web.MessageEvent event) {
      if (event.origin != origin || event.source != web.window.opener) return;
      final data = event.data.dartify();
      if (data is Map &&
          data['type'] == 'rastro:identity' &&
          data['token'] is String) {
        receive(data['token'] as String);
      }
    }).toJS,
  );
  (web.window.opener as web.Window).postMessage(
    {'type': 'rastro:ready'}.jsify(),
    origin.toJS,
  );
}

void openCentral(String url) {
  if (url.isNotEmpty) web.window.location.assign(url);
}
