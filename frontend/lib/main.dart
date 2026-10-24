import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'api.dart';
import 'theme.dart';
import 'widgets.dart';
import 'screens/board.dart';
import 'screens/detail.dart';
import 'screens/report_form.dart';
import 'screens/survey.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RastroApp(api: RastroApi()));
}

class RastroApp extends StatefulWidget {
  const RastroApp({super.key, required this.api});
  final RastroApi api;
  @override
  State<RastroApp> createState() => _RastroAppState();
}

class _RastroAppState extends State<RastroApp> {
  late Future<void> ready;
  @override
  void initState() {
    super.initState();
    ready = widget.api.initialize();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    key: ValueKey(ready),
    title: 'Rastro Rural · Travesías',
    debugShowCheckedModeBanner: false,
    theme: rastroTheme(),
    locale: const Locale('es', 'CO'),
    supportedLocales: const [Locale('es', 'CO')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    onGenerateRoute: (settings) => MaterialPageRoute(
      settings: settings,
      builder: (context) => ListenableBuilder(
        listenable: widget.api,
        builder: (context, _) => FutureBuilder<void>(
          future: ready,
          builder: (context, snapshot) {
            final route = settings.name ?? '/inicio';
            Widget body;
            if (snapshot.hasError) {
              body = Panel(
                child: Column(
                  children: [
                    const Heading('No pudimos conectar'),
                    Text(snapshot.error.toString()),
                    ElevatedButton(
                      onPressed: () =>
                          setState(() => ready = widget.api.initialize()),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            } else if (snapshot.connectionState != ConnectionState.done) {
              body = const Center(child: CircularProgressIndicator());
            } else {
              final parts = route
                  .split('/')
                  .where((s) => s.isNotEmpty)
                  .toList();
              final id = parts.length > 1 ? int.tryParse(parts[1]) : null;
              body = switch (parts.firstOrNull ?? 'inicio') {
                'inicio' => Home(api: widget.api),
                'tablero' => Board(api: widget.api),
                'mis-reportes' => Board(api: widget.api, mine: true),
                'crear' => ReportForm(api: widget.api),
                'editar' when id != null => ReportForm(api: widget.api, id: id),
                'reporte' when id != null => ReportDetail(
                  api: widget.api,
                  id: id,
                ),
                'encuesta' => Survey(api: widget.api),
                _ => const Heading('Página no encontrada'),
              };
            }
            return ListenableBuilder(
              listenable: widget.api,
              builder: (context, _) =>
                  RastroShell(api: widget.api, child: body),
            );
          },
        ),
      ),
    ),
  );
}

class RastroShell extends StatelessWidget {
  const RastroShell({super.key, required this.api, required this.child});
  final RastroApi api;
  final Widget child;
  static const destinations = [
    ('Inicio y ayuda', '/inicio', Icons.home_outlined),
    ('Animales perdidos', '/tablero', Icons.pets),
    ('Mis reportes', '/mis-reportes', Icons.assignment_outlined),
    ('Tu opinión', '/encuesta', Icons.favorite_border),
  ];
  Widget brand() => Row(
    children: [
      Image.asset(
        'assets/logos/red_comunitaria.png',
        width: 42,
        height: 48,
        fit: BoxFit.contain,
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rastro Rural',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text('RED COMUNITARIA TRAVESÍAS', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: MediaQuery.sizeOf(context).width < 800
        ? AppBar(
            backgroundColor: green,
            foregroundColor: Colors.white,
            toolbarHeight: 76,
            leadingWidth: 64,
            leading: Builder(
              builder: (context) => IconButton(
                tooltip: 'Abrir menú',
                icon: const Icon(Icons.menu, size: 30),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: brand(),
          )
        : null,
    drawer: MediaQuery.sizeOf(context).width < 800
        ? Drawer(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: green,
                    padding: const EdgeInsets.all(24),
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white),
                      child: brand(),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      '¿A dónde quieres ir?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  for (final item in destinations)
                    ListTile(
                      minTileHeight: 76,
                      leading: Icon(item.$3, color: green),
                      title: Text(item.$1),
                      selected:
                          ModalRoute.of(context)?.settings.name == item.$2,
                      selectedColor: green,
                      selectedTileColor: const Color(0xFFEAF3EB),
                      onTap: () {
                        Navigator.pop(context);
                        go(context, item.$2);
                      },
                    ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Cerrar menú'),
                    ),
                  ),
                ],
              ),
            ),
          )
        : null,
    body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (MediaQuery.sizeOf(context).width >= 800)
              ColoredBox(
                color: green,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1220),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/logos/red_comunitaria.png',
                                width: 50,
                                height: 50,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Rastro Rural',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'RED COMUNITARIA TRAVESÍAS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const routes = [
                                '/inicio',
                                '/tablero',
                                '/mis-reportes',
                                '/encuesta',
                              ];
                              const names = [
                                'Inicio y ayuda',
                                'Animales perdidos',
                                'Mis reportes',
                                'Tu opinión',
                              ];
                              final width = constraints.maxWidth < 650
                                  ? (constraints.maxWidth - 12) / 2
                                  : (constraints.maxWidth - 36) / 4;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  for (var i = 0; i < routes.length; i++)
                                    SizedBox(
                                      width: width,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(0, 60),
                                          side: const BorderSide(
                                            color: Colors.white54,
                                          ),
                                        ),
                                        onPressed: () => go(context, routes[i]),
                                        child: Text(
                                          names[i],
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const ColoredBox(
              color: Color(0xFFEAF1EB),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Travesías · Florencia, Caquetá · Consulta y envío en línea',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1220),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 28,
                  ),
                  child: child,
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final logo in [
                        'universidad_amazonia',
                        'ingenieria_sistemas',
                        'red_comunitaria',
                      ])
                        Image.asset(
                          'assets/logos/$logo.png',
                          height: 60,
                          width: logo == 'ingenieria_sistemas' ? 140 : 70,
                          fit: BoxFit.contain,
                          semanticLabel: logo.replaceAll('_', ' '),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Rastro Rural · Grupo 2 · Juntos cuidamos nuestra comunidad',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class Home extends StatelessWidget {
  const Home({super.key, required this.api});
  final RastroApi api;
  @override
  Widget build(BuildContext context) {
    const actions = [
      (
        'Ver animales perdidos',
        'Mira las fotos y las señas. Si reconoces uno, abre su reporte para avisar dónde lo viste.',
        Icons.search,
        '/tablero',
      ),
      (
        'Reportar un animal perdido',
        'Cuenta cómo es tu animal y dónde se perdió para que tus vecinos te ayuden.',
        Icons.add,
        '/crear',
      ),
      (
        'Revisar mis reportes',
        'Lee las pistas de tus vecinos, corrige tus datos o avisa que ya encontraste tu animal.',
        Icons.check_circle_outline,
        '/mis-reportes',
      ),
      (
        'Dar mi opinión',
        'Responde cinco preguntas para contarnos si fue fácil usar esta aplicación.',
        Icons.favorite_border,
        '/encuesta',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RASTRO RURAL · GRUPO 2 · TRAVESÍAS',
                style: TextStyle(
                  color: green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              Heading(
                api.authenticated
                    ? 'Hola, ${api.name}'
                    : 'Bienvenido a Rastro Rural',
                subtitle:
                    'Aquí nos ayudamos a encontrar los animales que se han perdido.',
              ),
              const Text(
                'Si perdiste un animal, cuéntanos cómo es. Si viste uno, avisa dónde lo viste para ayudar a su dueño.',
              ),
              const SizedBox(height: 20),
              Text(
                '¿Qué quieres hacer?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 18),
              for (final action in actions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Material(
                    color: const Color(0xFFF5F8F4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFD9E4DA)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => go(context, action.$4),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(action.$3, color: green),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    action.$1,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: green,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(action.$2),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, color: green),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Heading('¿Cómo nos ayudamos?'),
              Text(
                '1. Una persona publica su animal perdido.\nComparte sus señas y el lugar donde se perdió.\n\n2. Un vecino cuenta dónde lo vio.\nAbre el reporte y registra una pista.\n\n3. El dueño avisa cuando lo encuentra.\nAsí la comunidad sabe que la búsqueda terminó.',
              ),
              SizedBox(height: 20),
              Text(
                'Necesitas conexión para enviar información. Espera siempre el mensaje que confirma que quedó guardada.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
