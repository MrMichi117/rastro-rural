import 'package:flutter/material.dart';
import '../api.dart';
import '../widgets.dart';
import '../theme.dart';

const questions = [
  'Me resultó fácil aprender a utilizar este subproyecto.',
  'Pude encontrar fácilmente las opciones y funciones que necesitaba.',
  'La información y los textos de la interfaz fueron claros y comprensibles.',
  'Logré realizar las tareas que necesitaba sin dificultades innecesarias.',
  'En general, estoy satisfecho con la experiencia de uso de este subproyecto.',
];
const answers = [
  'Totalmente en desacuerdo',
  'En desacuerdo',
  'Ni de acuerdo ni en desacuerdo',
  'De acuerdo',
  'Totalmente de acuerdo',
];

class Survey extends StatefulWidget {
  const Survey({super.key, required this.api});
  final RastroApi api;
  @override
  State<Survey> createState() => _SurveyState();
}

class _SurveyState extends State<Survey> {
  final values = <int, int>{};
  bool busy = false, saved = false;
  Future<void> submit() async {
    if (busy || values.length != 5) return;
    setState(() => busy = true);
    try {
      await widget.api.request(
        'v1/encuestas/usabilidad',
        method: 'POST',
        body: {
          'subproyecto_id': 'rastro-rural',
          'version_encuesta': 1,
          'respuestas': {
            for (var i = 0; i < 5; i++) 'respuesta_${i + 1}': values[i],
          },
        },
      );
      if (mounted) setState(() => saved = true);
    } catch (e) {
      if (mounted) notice(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.api.authenticated) return const AccessNeeded();
    if (saved) {
      return Panel(
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, size: 60, color: green),
            const Heading(
              'Gracias por compartir tu experiencia',
              subtitle: 'Tu respuesta quedó guardada en el servidor.',
            ),
            ElevatedButton(
              onPressed: () => go(context, '/tablero'),
              child: const Text('Volver al tablero'),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Guide(
          'Tu opinión nos ayuda a mejorar',
          'Lee cada frase y toca una respuesta, del 1 al 5. El 1 significa que no estás de acuerdo y el 5 que estás totalmente de acuerdo. Responde las cinco y toca “Enviar mi opinión”.',
        ),
        const Heading(
          '¿Cómo te fue con Rastro Rural?',
          subtitle:
              'Encuesta de usabilidad y satisfacción · Cuestionario propio · Versión 1',
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${values.length} de 5 preguntas respondidas'),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: values.length / 5),
            ],
          ),
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < questions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${i + 1}. ${questions[i]}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 18),
                  for (var j = 0; j < answers.length; j++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Semantics(
                        selected: values[i] == j + 1,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 64),
                            alignment: Alignment.centerLeft,
                            backgroundColor: values[i] == j + 1
                                ? const Color(0xFFE2F2E8)
                                : Colors.white,
                          ),
                          onPressed: busy
                              ? null
                              : () => setState(() => values[i] = j + 1),
                          child: Text('${j + 1} · ${answers[j]}'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        const Text(
          'Tus respuestas se asocian a la referencia de tu cuenta para evitar duplicados. No se publican en el tablero.',
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: busy || values.length != 5 ? null : submit,
          child: Text(busy ? 'Enviando…' : 'Enviar mi opinión'),
        ),
      ],
    );
  }
}
