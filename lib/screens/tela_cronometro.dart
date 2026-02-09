import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/estudo_controller.dart';

class TelaCronometro extends StatelessWidget {
  const TelaCronometro({super.key});

  String _formatar(int segundos) {
    final m = segundos ~/ 60;
    final s = segundos % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EstudoController>(
      builder: (context, controller, _) {
        final nome = controller.disciplinaAtiva?.nome ?? 'Sem disciplina';

        return Scaffold(
          appBar: AppBar(title: Text('Estudando: $nome')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatar(controller.segundosSessao),
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      controller.finalizarSessao();
                      Navigator.pop(context); // volta pro detalhe
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Finalizar e salvar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
