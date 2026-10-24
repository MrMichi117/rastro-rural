import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../api.dart';
import '../widgets.dart';

class ReportForm extends StatefulWidget {
  const ReportForm({super.key, required this.api, this.id});
  final RastroApi api;
  final int? id;
  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  final form = GlobalKey<FormState>();
  final fields = {
    for (final key in [
      'nombre_animal',
      'identificador_campo',
      'especie_otro',
      'senas',
      'descripcion',
      'sector',
    ])
      key: TextEditingController(),
  };
  final date = TextEditingController();
  int? species;
  Data original = {};
  String? photo, photoName;
  bool removePhoto = false, busy = false;
  late Future<Data> future;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    future = widget.id == null
        ? Future.value({})
        : widget.api.request('reportes/${widget.id}').then((r) {
            original = r;
            for (final entry in fields.entries) {
              entry.value.text = label(r, entry.key);
            }
            species = r['especie_id'];
            date.text = label(r, 'fecha_perdida');
            return r;
          });
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    date.dispose();
    super.dispose();
  }

  bool get other => (widget.api.catalogs['especies'] as List).any(
    (s) => s['id'] == species && s['nombre'] == 'Otro',
  );
  Future<void> pickPhoto() async {
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'Fotografías JPEG o PNG',
            extensions: ['jpg', 'jpeg', 'png'],
            mimeTypes: ['image/jpeg', 'image/png'],
          ),
        ],
      );
      if (file == null) return;
      if (await file.length() > 2000000) {
        throw const ApiError('La fotografía supera los 2 MB.');
      }
      final bytes = await file.readAsBytes();
      final png =
          bytes.length >= 8 &&
          bytes[0] == 137 &&
          bytes[1] == 80 &&
          bytes[2] == 78 &&
          bytes[3] == 71;
      final jpeg =
          bytes.length >= 3 &&
          bytes[0] == 255 &&
          bytes[1] == 216 &&
          bytes[2] == 255;
      if (!png && !jpeg) {
        throw const ApiError('Selecciona una imagen JPEG o PNG.');
      }
      if (mounted) {
        setState(() {
          photo =
              'data:image/${png ? 'png' : 'jpeg'};base64,${base64Encode(bytes)}';
          photoName = file.name;
          removePhoto = false;
        });
      }
    } catch (e) {
      if (mounted) notice(context, e.toString());
    }
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final body = <String, dynamic>{
        for (final entry in fields.entries) entry.key: entry.value.text.trim(),
        'especie_id': species,
        'fecha_perdida': date.text,
        if (widget.id != null) 'version': original['version'],
        if (photo != null) 'foto': photo,
        if (photo == null && removePhoto) 'foto': null,
      };
      final result = await widget.api.request(
        widget.id == null ? 'reportes' : 'reportes/${widget.id}',
        method: widget.id == null ? 'POST' : 'PUT',
        body: body,
      );
      if (!mounted) return;
      notice(
        context,
        'Tu reporte quedó guardado. Ya puedes recibir pistas de tus vecinos.',
      );
      go(context, '/reporte/${widget.id ?? result['id']}');
    } catch (e) {
      if (mounted) notice(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget input(
    String key,
    String title,
    int max, {
    bool required = false,
    int lines = 1,
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: TextFormField(
      controller: fields[key],
      enabled: !busy,
      maxLength: max,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: '$title${required ? ' *' : ''}',
        hintText: hint,
      ),
      validator: (value) => required && (value == null || value.trim().isEmpty)
          ? 'Completa este dato.'
          : null,
    ),
  );
  Widget catalog(
    String name,
    String title,
    int? value,
    ValueChanged<int?> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: '$title *'),
      items: [
        for (final row in widget.api.catalogs[name])
          DropdownMenuItem(
            value: row['id'] as int,
            child: Text(row['nombre'].toString()),
          ),
      ],
      onChanged: busy ? null : onChanged,
      validator: (value) => value == null ? 'Selecciona una opción.' : null,
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (!widget.api.authenticated) return const AccessNeeded();
    return LoadView(
      future: future,
      retry: () => setState(load),
      builder: (_) {
        if (widget.id != null &&
            (original['es_autor'] != true ||
                original['estado'] != 'BUSCANDO')) {
          return const Heading('Este reporte no está disponible para editar.');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Guide(
              widget.id == null
                  ? 'Vamos a contarle a la comunidad qué animal perdiste'
                  : 'Aquí puedes corregir tu reporte',
              'Completa los datos marcados con *. Si no tienes una foto puedes dejarla vacía. Al terminar, guarda y espera la confirmación del servidor.',
            ),
            Heading(
              widget.id == null
                  ? 'Reportar un animal perdido'
                  : 'Editar reporte',
            ),
            Panel(
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    catalog(
                      'especies',
                      'Tipo de animal',
                      species,
                      (v) => setState(() => species = v),
                    ),
                    if (other)
                      input(
                        'especie_otro',
                        '¿Qué tipo de animal es?',
                        80,
                        required: true,
                      ),
                    input('nombre_animal', 'Nombre del animal', 100),
                    input(
                      'identificador_campo',
                      'Arete, marca o identificación',
                      100,
                    ),
                    input(
                      'senas',
                      'Señas particulares',
                      1000,
                      required: true,
                      lines: 3,
                      hint: 'Color, tamaño, manchas, collar…',
                    ),
                    input(
                      'sector',
                      'Describe el último sector conocido',
                      250,
                      required: true,
                      lines: 3,
                      hint:
                          'Ejemplo: vereda La Esperanza, cerca del puente y la escuela.',
                    ),
                    TextFormField(
                      controller: date,
                      readOnly: true,
                      enabled: !busy,
                      decoration: const InputDecoration(
                        labelText: 'Fecha de pérdida *',
                        suffixIcon: Icon(Icons.calendar_month),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Selecciona la fecha.'
                          : null,
                      onTap: () async {
                        final now = bogotaNow();
                        final selected = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(now.year, now.month, now.day),
                          initialDate: DateTime.tryParse(date.text) ?? now,
                        );
                        if (selected != null) date.text = isoDate(selected);
                      },
                    ),
                    const SizedBox(height: 20),
                    input(
                      'descripcion',
                      'Descripción de lo ocurrido',
                      2000,
                      required: true,
                      lines: 4,
                    ),
                    OutlinedButton.icon(
                      onPressed: busy ? null : pickPhoto,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(photoName ?? 'Agregar fotografía opcional'),
                    ),
                    const SizedBox(height: 10),
                    const Text('JPEG o PNG. Máximo 2 MB y 16 megapíxeles.'),
                    if (original['tiene_foto'] == true || photo != null)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Quitar fotografía'),
                        value: removePhoto,
                        onChanged: busy
                            ? null
                            : (v) => setState(() {
                                removePhoto = v ?? false;
                                if (removePhoto) {
                                  photo = null;
                                  photoName = null;
                                }
                              }),
                      ),
                    const SizedBox(height: 24),
                    const Text(
                      'Los datos del reporte serán públicos. Evita incluir teléfonos, documentos o direcciones privadas.',
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: busy ? null : submit,
                      child: Text(
                        busy
                            ? 'Guardando…'
                            : widget.id == null
                            ? 'Publicar reporte'
                            : 'Guardar cambios',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: busy
                          ? null
                          : () => go(
                              context,
                              widget.id == null
                                  ? '/tablero'
                                  : '/reporte/${widget.id}',
                            ),
                      child: const Text('Volver'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
