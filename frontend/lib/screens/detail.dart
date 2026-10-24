import 'package:flutter/material.dart';
import '../api.dart';
import '../widgets.dart';
import '../theme.dart';

class ReportDetail extends StatefulWidget {
  const ReportDetail({super.key, required this.api, required this.id});
  final RastroApi api;
  final int id;
  @override
  State<ReportDetail> createState() => _ReportDetailState();
}

class _ReportDetailState extends State<ReportDetail> {
  late Future<Data> future;
  final sightingKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    future = widget.api.request('reportes/${widget.id}');
  }

  void refresh() {
    setState(load);
  }

  bool busy = false;
  Future<void> closeReport(Data r, bool found) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          found
              ? '¿Ya encontraste tu animal?'
              : '¿Quieres cancelar esta búsqueda?',
        ),
        content: const Text(
          'Al confirmar, la comunidad sabrá que la búsqueda terminó. Este reporte dejará de recibir pistas.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(found ? 'Sí, ya lo encontré' : 'Sí, cancelar búsqueda'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() => busy = true);
    try {
      await widget.api.request(
        'reportes/${widget.id}/estado',
        method: 'PATCH',
        body: {
          'version': r['version'],
          'estado': found ? 'ENCONTRADO' : 'CANCELADO',
        },
      );
      if (mounted) {
        notice(context, 'El estado del reporte fue actualizado.');
        refresh();
      }
    } catch (e) {
      if (mounted) notice(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => LoadView(
    future: future,
    retry: refresh,
    builder: (r) {
      final open = r['estado'] == 'BUSCANDO';
      final info = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimalPhoto(report: r, api: widget.api, height: 310),
          const SizedBox(height: 24),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadge(label(r, 'estado')),
                const SizedBox(height: 16),
                Heading(
                  animalName(r),
                  subtitle: '${label(r, 'especie')} · Reporte #${r['id']}',
                ),
                Text('Último sector: ${label(r, 'sector')}'),
                Text('Fecha de pérdida: ${dateText(r['fecha_perdida'])}'),
                Text(
                  'Identificación: ${label(r, 'identificador_campo', 'No especificada')}',
                ),
                const SizedBox(height: 24),
                Text(
                  'Señas particulares',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(label(r, 'senas')),
                const SizedBox(height: 24),
                Text(
                  'Lo que sabemos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(label(r, 'descripcion')),
                if (r['es_autor'] == true && open) ...[
                  const Divider(height: 36),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => go(context, '/editar/${widget.id}'),
                        child: const Text('Editar'),
                      ),
                      ElevatedButton(
                        onPressed: busy ? null : () => closeReport(r, true),
                        child: const Text('Ya lo encontré'),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: red,
                          side: const BorderSide(color: red),
                        ),
                        onPressed: busy ? null : () => closeReport(r, false),
                        child: const Text('Cancelar reporte'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      );
      final sightings = r['avistamientos'] as List;
      final side = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Heading(
                  'Avistamientos (${sightings.length})',
                  subtitle:
                      'Observaciones registradas por vecinos, de la más reciente a la más antigua.',
                ),
                if (sightings.isEmpty)
                  const Text(
                    'Todavía no hay avistamientos. Tu información puede ser la primera pista.',
                  ),
                for (final a in sightings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a['sector'].toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: green,
                          ),
                        ),
                        Text(
                          '${dateText(a['fecha_avistamiento'])} · ${a['fecha_avistamiento'].toString().substring(11, 16)} (Bogotá)',
                        ),
                        const SizedBox(height: 8),
                        Text(a['observacion'].toString()),
                        const Divider(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (open)
            Panel(
              key: sightingKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Heading(
                    '¿Lo has visto?',
                    subtitle:
                        'Indica el sector, el día y la hora en que viste al animal. Luego cuenta algo que ayude a reconocerlo.',
                  ),
                  widget.api.authenticated
                      ? SightingForm(api: widget.api, report: r, saved: refresh)
                      : const AccessNeeded(),
                ],
              ),
            )
          else
            const Panel(
              child: Heading(
                'Búsqueda cerrada',
                subtitle: 'Este reporte ya no recibe avistamientos.',
              ),
            ),
        ],
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Guide(
            'Revisa si este es el animal que viste',
            'Compara la foto y sus señas. Si lo reconoces, toca “Lo vi: contar dónde” y registra una pista.',
          ),
          if (open) ...[
            ElevatedButton.icon(
              onPressed: () => Scrollable.ensureVisible(
                sightingKey.currentContext!,
                duration: const Duration(milliseconds: 250),
              ),
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('Lo vi: contar dónde'),
            ),
            const SizedBox(height: 24),
          ],
          LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth < 850
                ? Column(children: [info, const SizedBox(height: 24), side])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: info),
                      const SizedBox(width: 24),
                      Expanded(flex: 5, child: side),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => go(context, '/tablero'),
            child: const Text('Volver al tablero'),
          ),
        ],
      );
    },
  );
}

class SightingForm extends StatefulWidget {
  const SightingForm({
    super.key,
    required this.api,
    required this.report,
    required this.saved,
  });
  final RastroApi api;
  final Data report;
  final VoidCallback saved;
  @override
  State<SightingForm> createState() => _SightingFormState();
}

class _SightingFormState extends State<SightingForm> {
  final form = GlobalKey<FormState>();
  final note = TextEditingController(), when = TextEditingController();
  final sector = TextEditingController();
  DateTime? selected;
  bool busy = false;
  @override
  void dispose() {
    sector.dispose();
    note.dispose();
    when.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final now = bogotaNow();
    final day = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime.parse(widget.report['fecha_perdida']),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;
    selected = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    when.text =
        '${dateText(isoDate(day))} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await widget.api.request(
        'reportes/${widget.report['id']}/avistamientos',
        method: 'POST',
        body: {
          'sector': sector.text.trim(),
          'fecha_avistamiento': selected!.toIso8601String(),
          'observacion': note.text.trim(),
        },
      );
      if (mounted) {
        notice(context, 'Avistamiento registrado. Gracias por ayudar.');
        sector.clear();
        note.clear();
        when.clear();
        selected = null;
        widget.saved();
      }
    } catch (e) {
      if (mounted) notice(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: sector,
          enabled: !busy,
          maxLength: 250,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Describe el sector donde lo viste *',
            hintText: 'Ejemplo: por el camino a la escuela, junto al puente.',
          ),
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Describe el lugar donde viste al animal.'
              : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: when,
          readOnly: true,
          enabled: !busy,
          onTap: pickDate,
          decoration: const InputDecoration(
            labelText: 'Fecha y hora (Bogotá) *',
            suffixIcon: Icon(Icons.calendar_month),
          ),
          validator: (_) =>
              selected == null ? 'Selecciona la fecha y hora.' : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: note,
          enabled: !busy,
          maxLength: 2000,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: '¿Qué observaste? *',
            hintText:
                'Ejemplo: estaba junto al puente, caminando hacia la escuela.',
          ),
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Cuéntanos qué observaste.'
              : null,
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: busy ? null : submit,
          child: Text(busy ? 'Guardando…' : 'Registrar avistamiento'),
        ),
      ],
    ),
  );
}
