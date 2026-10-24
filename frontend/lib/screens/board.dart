import 'package:flutter/material.dart';
import '../api.dart';
import '../widgets.dart';
import '../theme.dart';

class Board extends StatefulWidget {
  const Board({super.key, required this.api, this.mine = false});
  final RastroApi api;
  final bool mine;
  @override
  State<Board> createState() => _BoardState();
}

class _BoardState extends State<Board> {
  final search = TextEditingController();
  int species = 0, sector = 0, page = 1;
  late Future<Data> future;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void load() {
    final params = {
      'page': '$page',
      if (widget.mine) 'mine': 'true',
      if (species > 0) 'especie': '$species',
      if (sector > 0) 'sector': '$sector',
      if (search.text.isNotEmpty) 'q': search.text,
    };
    future = widget.mine && !widget.api.authenticated
        ? Future.value({})
        : Future.wait([
            widget.api.request(
              'reportes?${Uri(queryParameters: params).query}',
            ),
            widget.api.request('estadisticas'),
          ]).then((values) => {...values[0], 'stats': values[1]});
  }

  void refresh({bool first = false}) => setState(() {
    if (first) page = 1;
    load();
  });
  @override
  Widget build(BuildContext context) {
    if (widget.mine && !widget.api.authenticated) return const AccessNeeded();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Guide(
          widget.mine
              ? 'Aquí están los animales que tú reportaste'
              : 'Aquí puedes ver los animales perdidos',
          widget.mine
              ? 'Abre un reporte para leer las pistas. Usa “Editar” para corregir datos o “Ya lo encontré” cuando recuperes tu animal.'
              : 'Mira las fotos y señas. Busca por nombre, especie o sector. Toca “Ver animal y avisar dónde lo vi” para compartir una pista.',
        ),
        Heading(
          widget.mine ? 'Mis reportes' : 'Ayudemos a que vuelvan a casa',
          subtitle: 'Cada avistamiento cuenta. Comparte lo que has visto.',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: () => go(context, '/crear'),
            icon: const Icon(Icons.add),
            label: const Text('Reportar pérdida'),
          ),
        ),
        const SizedBox(height: 24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: search,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Busca una coincidencia',
                  hintText: 'Nombre, señas, arete o descripción',
                ),
                onSubmitted: (_) => refresh(first: true),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: sector,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Sector'),
                items: [
                  const DropdownMenuItem(
                    value: 0,
                    child: Text('Todos los sectores'),
                  ),
                  for (final s in widget.api.catalogs['sectores'])
                    DropdownMenuItem(
                      value: s['id'] as int,
                      child: Text(s['nombre'].toString()),
                    ),
                ],
                onChanged: (value) {
                  sector = value ?? 0;
                  refresh(first: true);
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => refresh(first: true),
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in [
                    {'id': 0, 'nombre': 'Todas'},
                    ...widget.api.catalogs['especies'],
                  ])
                    ChoiceChip(
                      label: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 8,
                        ),
                        child: Text(s['nombre'].toString()),
                      ),
                      selected: species == s['id'],
                      onSelected: (_) {
                        species = s['id'] as int;
                        refresh(first: true);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        LoadView(
          future: future,
          retry: refresh,
          builder: (data) {
            final items = data['items'] as List;
            final stats = data['stats'] as Data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    for (final stat in [
                      ('buscando', 'En búsqueda'),
                      ('encontrados', 'Encontrados'),
                      ('avistamientos', 'Avistamientos'),
                    ])
                      SizedBox(
                        width: 150,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${stats[stat.$1]}',
                              style: const TextStyle(
                                color: green,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(stat.$2),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                if (items.isEmpty)
                  const Panel(
                    child: Text(
                      'No encontramos reportes con estos filtros. Puedes cambiar la búsqueda o publicar tu animal perdido.',
                    ),
                  ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1000
                        ? 3
                        : constraints.maxWidth >= 620
                        ? 2
                        : 1;
                    final width =
                        (constraints.maxWidth - (columns - 1) * 20) / columns;
                    return Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        for (final value in items)
                          SizedBox(
                            width: width,
                            child: _card(Map<String, dynamic>.from(value)),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: page > 1
                          ? () {
                              page--;
                              refresh();
                            }
                          : null,
                      child: const Text('Anterior'),
                    ),
                    Text('Página $page · ${data['total']} reportes'),
                    OutlinedButton(
                      onPressed: page * 12 < (data['total'] as num)
                          ? () {
                              page++;
                              refresh();
                            }
                          : null,
                      child: const Text('Siguiente'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _card(Data r) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimalPhoto(report: r, api: widget.api),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusBadge(label(r, 'estado')),
              const SizedBox(height: 14),
              Text(
                animalName(r),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(label(r, 'especie_otro', label(r, 'especie'))),
              const SizedBox(height: 12),
              Text(
                label(r, 'senas'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: green,
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(label(r, 'sector'))),
                ],
              ),
              Text(dateText(r['fecha_perdida'])),
              const Divider(height: 28),
              TextButton(
                onPressed: () => go(context, '/reporte/${r['id']}'),
                child: const Text('Ver animal y avisar dónde lo vi'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
