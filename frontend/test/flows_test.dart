import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rastro_rural/api.dart';
import 'package:rastro_rural/main.dart';
import 'package:rastro_rural/screens/report_form.dart';
import 'package:rastro_rural/screens/survey.dart';
import 'package:rastro_rural/screens/board.dart';
import 'package:rastro_rural/theme.dart';

void main() {
  test(
    'Bearer identity comes from server, and an expired token clears access',
    () async {
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer signed-local-token');
        return http.Response(jsonEncode({'error': 'Acceso vencido'}), 401);
      });
      final api =
          RastroApi(client: client, base: Uri.parse('http://localhost/api/'))
            ..token = 'signed-local-token'
            ..user = {'usuario_id': 'admin'};
      await expectLater(api.request('me'), throwsA(isA<ApiError>()));
      expect(api.authenticated, isFalse);
      expect(api.token, isNull);
      api.dispose();
    },
  );

  for (final width in [360.0, 390.0, 1280.0]) {
    testWidgets('Welcome fits $width with four large actions', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = RastroApi(base: Uri.parse('http://localhost/api/'));
      await tester.pumpWidget(
        MaterialApp(
          theme: rastroTheme(),
          home: RastroShell(
            api: api,
            child: Home(api: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ver animales perdidos'), findsOneWidget);
      expect(find.text('Reportar un animal perdido'), findsOneWidget);
      expect(find.text('Revisar mis reportes'), findsOneWidget);
      expect(find.text('Dar mi opinión'), findsOneWidget);
      expect(
        find.byIcon(Icons.menu),
        width < 800 ? findsOneWidget : findsNothing,
      );
      if (width < 800) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        expect(find.text('¿A dónde quieres ir?'), findsOneWidget);
        for (final title in [
          'Inicio y ayuda',
          'Animales perdidos',
          'Mis reportes',
          'Tu opinión',
        ]) {
          expect(find.widgetWithText(ListTile, title), findsOneWidget);
        }
      }
      expect(tester.takeException(), isNull);
      api.dispose();
    });
  }
  testWidgets('Species filters are green and sector filter is free text', (
    tester,
  ) async {
    final api =
        RastroApi(
            base: Uri.parse('http://localhost/api/'),
            client: MockClient(
              (request) async => http.Response(
                jsonEncode(
                  request.url.path.endsWith('estadisticas')
                      ? {'buscando': 0, 'encontrados': 0, 'avistamientos': 0}
                      : {'items': [], 'total': 0},
                ),
                200,
              ),
            ),
          )
          ..catalogs = {
            'especies': [
              {'id': 1, 'nombre': 'Bovino'},
            ],
            'sectores': [],
          };
    await tester.pumpWidget(
      MaterialApp(
        theme: rastroTheme(),
        home: RastroShell(
          api: api,
          child: Board(api: api),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Todas'),
    );
    expect(chip.selectedColor, green);
    expect(find.widgetWithText(TextField, 'Buscar por sector'), findsOneWidget);
    api.dispose();
  });
  testWidgets(
    'An incomplete report is validated before it reaches the server',
    (tester) async {
      var requests = 0;
      final api =
          RastroApi(
              base: Uri.parse('http://localhost/api/'),
              client: MockClient((_) async {
                requests++;
                return http.Response('{}', 200);
              }),
            )
            ..token = 'dev-vecino-1'
            ..user = {'usuario_id': 'vecino-1'}
            ..catalogs = {
              'especies': [
                {'id': 1, 'nombre': 'Bovino'},
              ],
              'sectores': [
                {'id': 1, 'nombre': 'La Vega'},
              ],
            };
      await tester.pumpWidget(
        MaterialApp(
          theme: rastroTheme(),
          home: RastroShell(
            api: api,
            child: ReportForm(api: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Publicar reporte'));
      await tester.tap(find.text('Publicar reporte'));
      await tester.pumpAndSettle();
      expect(requests, 0);
      expect(find.text('Completa este dato.'), findsWidgets);
      expect(tester.takeException(), isNull);
      api.dispose();
    },
  );
  testWidgets('Survey submission requires all five answers', (tester) async {
    final api = RastroApi(base: Uri.parse('http://localhost/api/'))
      ..token = 'dev-vecino-1'
      ..user = {'usuario_id': 'vecino-1'};
    await tester.pumpWidget(
      MaterialApp(
        theme: rastroTheme(),
        home: RastroShell(
          api: api,
          child: Survey(api: api),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final send = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Enviar mi opinión'),
    );
    expect(send.onPressed, isNull);
    expect(tester.takeException(), isNull);
    api.dispose();
  });
}
