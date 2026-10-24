import 'package:flutter/material.dart';
import 'api.dart';
import 'theme.dart';

void go(BuildContext context, String route) =>
    Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
void notice(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 6)),
    );
String label(Data data, String key, [String fallback = '']) =>
    data[key]?.toString() ?? fallback;
String animalName(Data r) => label(r, 'nombre_animal').isNotEmpty
    ? label(r, 'nombre_animal')
    : label(r, 'especie_otro', label(r, 'especie'));
String dateText(dynamic raw) {
  final d = DateTime.tryParse(raw?.toString() ?? '');
  if (d == null) return '';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

DateTime bogotaNow() =>
    DateTime.now().toUtc().subtract(const Duration(hours: 5));
String isoDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.color});
  final Widget child;
  final Color? color;
  @override
  Widget build(BuildContext context) => Card(
    color: color,
    child: Padding(padding: const EdgeInsets.all(24), child: child),
  );
}

class Heading extends StatelessWidget {
  const Heading(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        if (subtitle != null) ...[const SizedBox(height: 12), Text(subtitle!)],
      ],
    ),
  );
}

class Guide extends StatelessWidget {
  const Guide(this.title, this.message, {super.key});
  final String title, message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Panel(
      color: const Color(0xFFEDF5EE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TE ACOMPAÑAMOS PASO A PASO',
            style: TextStyle(
              color: green,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(message),
          TextButton(
            onPressed: () => go(context, '/inicio'),
            child: const Text('Volver a la guía de inicio'),
          ),
        ],
      ),
    ),
  );
}

class AccessNeeded extends StatelessWidget {
  const AccessNeeded({super.key});
  @override
  Widget build(BuildContext context) => const Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Heading('Participa con tu comunidad'),
        Text(
          'Entra a Rastro Rural desde el servidor de la comunidad para publicar o avisar dónde viste un animal. Usa tu misma cuenta de la comunidad.',
        ),
      ],
    ),
  );
}

class LoadView extends StatelessWidget {
  const LoadView({
    super.key,
    required this.future,
    required this.builder,
    required this.retry,
  });
  final Future<Data> future;
  final Widget Function(Data) builder;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => FutureBuilder<Data>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Panel(
          child: Column(
            children: [
              const Heading('No pudimos cargar esta vista'),
              Text(snapshot.error.toString()),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: retry, child: const Text('Reintentar')),
            ],
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return builder(snapshot.data!);
    },
  );
}

class AnimalPhoto extends StatelessWidget {
  const AnimalPhoto({
    super.key,
    required this.report,
    required this.api,
    this.height = 210,
  });
  final Data report;
  final RastroApi api;
  final double height;
  Widget placeholder() => Container(
    height: height,
    color: const Color(0xFFEAF1E8),
    alignment: Alignment.center,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.pets, size: 58, color: green),
        const SizedBox(height: 12),
        Text(
          'Sin fotografía · ${label(report, 'especie')}',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: report['tiene_foto'] == true
        ? Image.network(
            api.photoUrl(report['id'] as int),
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            semanticLabel: 'Fotografía de ${animalName(report)}',
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : SizedBox(
                    height: height,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
            errorBuilder: (_, _, _) => placeholder(),
          )
        : placeholder(),
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: status == 'BUSCANDO'
          ? const Color(0xFFFFF0E7)
          : const Color(0xFFEAF3EB),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      status == 'BUSCANDO' ? 'EN BÚSQUEDA' : status,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: status == 'BUSCANDO' ? const Color(0xFF974710) : green,
      ),
    ),
  );
}
