import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/disciplina.dart';
import '../controllers/estudo_controller.dart';
import 'tela_cronometro.dart';

class DetalheDisciplina extends StatelessWidget {
  final Disciplina disciplina;

  const DetalheDisciplina({super.key, required this.disciplina});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(disciplina.nome)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progresso', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: disciplina.progresso),
            const SizedBox(height: 24),
            Text(
              'Horas estudadas: ${disciplina.horasEstudadas.toStringAsFixed(1)}h',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final controller = context.read<EstudoController>();
                  controller.iniciarSessao(disciplina);

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TelaCronometro()),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar estudo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
