import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/estudo_controller.dart';
import '../data/disciplinas_mock.dart';
import '../widgets/lista_disciplinas.dart';
import '../widgets/progresso_geral.dart';
import '../widgets/resumo_geral.dart';
import 'detalhe_disciplina.dart';
import 'tela_trilha.dart';

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'Dashboard de Estudos',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.track_changes),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TelaTrilha(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<EstudoController>(
        builder: (context, controller, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResumoGeral(),
                SizedBox(height: 16),
                ProgressoGeral(),
                SizedBox(height: 16),
                ListaDisciplinas(
                  disciplinas: disciplinasMock,
                  onTap: (disciplina) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DetalheDisciplina(disciplina: disciplina),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
