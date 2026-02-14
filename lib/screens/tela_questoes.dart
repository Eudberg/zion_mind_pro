import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../database/questoes_dao.dart';
import '../models/questao.dart';

class TelaQuestoes extends StatefulWidget {
  const TelaQuestoes({super.key});

  @override
  State<TelaQuestoes> createState() => _TelaQuestoesState();
}

class _TelaQuestoesState extends State<TelaQuestoes> {
  final QuestoesDao _questoesDao = QuestoesDao();

  final _materiaController = TextEditingController();
  final _assuntoController = TextEditingController();
  final _feitasController = TextEditingController();
  final _acertosController = TextEditingController();

  void _adicionarQuestao() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Registrar Batalha",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _materiaController,
              decoration: InputDecoration(
                labelText: 'Matéria (Ex: Direito Constitucional)',
              ),
            ),
            TextField(
              controller: _assuntoController,
              decoration: InputDecoration(
                labelText: 'Assunto (Ex: Controle de Constitucionalidade)',
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _feitasController,
                    decoration: InputDecoration(labelText: 'Qtd Feitas'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _acertosController,
                    decoration: InputDecoration(labelText: 'Qtd Acertos'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvarNoBanco,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("Salvar Desempenho"),
            ),
          ],
        ),
      ),
    );
  }

  void _salvarNoBanco() async {
    final feitas = int.tryParse(_feitasController.text) ?? 0;
    final acertos = int.tryParse(_acertosController.text) ?? 0;

    if (feitas > 0 && acertos <= feitas) {
      final novaQuestao = Questao(
        materia: _materiaController.text,
        assunto: _assuntoController.text,
        data: DateTime.now(),
        qtdFeitas: feitas,
        qtdAcertos: acertos,
      );
      await _questoesDao.inserir(novaQuestao);

      if (!mounted) {
        return;
      }

      // Limpa e fecha
      _materiaController.clear();
      _assuntoController.clear();
      _feitasController.clear();
      _acertosController.clear();
      Navigator.pop(context);
      setState(() {}); // Atualiza a lista
    }
  }

  Color _getCorDesempenho(double porcentagem) {
    if (porcentagem >= 80) return Colors.greenAccent; // Excelente
    if (porcentagem >= 60) return Colors.amberAccent; // Atenção
    return Colors.redAccent; // Perigo
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Histórico de Questões"),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<List<Questao>>(
        future: _questoesDao.listarTodas(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final lista = snapshot.data!;

          if (lista.isEmpty) {
            return Center(
              child: Text(
                "Nenhuma questão registrada.\nVamos treinar?",
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: lista.length,
            itemBuilder: (ctx, i) {
              final q = lista[i];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            q.materia,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "${q.desempenho.toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getCorDesempenho(q.desempenho),
                            ),
                          ),
                        ],
                      ),
                      Text(q.assunto, style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 10),
                      LinearPercentIndicator(
                        lineHeight: 8.0,
                        percent: q.desempenho / 100,
                        progressColor: _getCorDesempenho(q.desempenho),
                        backgroundColor: Colors.grey[800],
                        barRadius: Radius.circular(4),
                        padding: EdgeInsets.zero,
                      ),
                      SizedBox(height: 5),
                      Text(
                        "${q.qtdAcertos} acertos de ${q.qtdFeitas} questões",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarQuestao,
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.quiz),
      ),
    );
  }
}
