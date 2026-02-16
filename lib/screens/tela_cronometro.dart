import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/estudo_controller.dart';
import '../controllers/trilha_controller.dart';

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
                    onPressed: controller.pausarOuRetomar,
                    icon: Icon(controller.estudando ? Icons.pause : Icons.play_arrow),
                    label: Text(controller.estudando ? 'Pausar' : 'Retomar'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => controller.adicionarMinutos(1),
                        child: const Text('+1 min'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => controller.adicionarMinutos(5),
                        child: const Text('+5 min'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => controller.adicionarMinutos(15),
                        child: const Text('+15 min'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final tarefaId = controller.tarefaAtivaId;
                      final ordemGlobal = controller.tarefaAtivaOrdemGlobal;
                      final disciplina =
                          controller.tarefaAtivaDisciplina ??
                          controller.disciplinaAtiva?.nome;
                      final assunto = controller.tarefaAtivaAssunto;
                      final minutos = controller.finalizarSessaoEmMinutos();

                      if (minutos > 0) {
                        await context
                            .read<TrilhaController>()
                            .registrarTempoCronometro(
                              tarefaId: tarefaId,
                              ordemGlobal: ordemGlobal,
                              disciplina: disciplina,
                              assunto: assunto,
                              minutos: minutos,
                            );
                      }

                      if (context.mounted) {
                        Navigator.pop(context); // volta pro detalhe
                      }
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
