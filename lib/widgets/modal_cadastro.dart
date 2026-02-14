import 'package:flutter/material.dart';
import '../models/sessao_estudo.dart';
import '../database/sessoes_dao.dart';

class ModalCadastroSessao extends StatefulWidget {
  final int tarefaId;
  final String disciplina;

  const ModalCadastroSessao({
    super.key,
    required this.tarefaId,
    required this.disciplina,
  });

  @override
  State<ModalCadastroSessao> createState() => _ModalCadastroSessaoState();
}

class _ModalCadastroSessaoState extends State<ModalCadastroSessao> {
  final _timeController = TextEditingController();
  final _qTotalController = TextEditingController();
  final _qCorrectController = TextEditingController();

  void _salvar() async {
    final sessao = SessaoEstudo(
      tarefaId: widget.tarefaId,
      disciplina: widget.disciplina,
      dataInicio: DateTime.now(),
      duracaoMinutos: int.tryParse(_timeController.text) ?? 0,
      questoesFeitas: int.tryParse(_qTotalController.text) ?? 0,
      questoesAcertadas: int.tryParse(_qCorrectController.text) ?? 0,
    );

    await SessoesDao().inserir(sessao);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Registrar Sessão"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _timeController,
            decoration: const InputDecoration(labelText: "Minutos"),
          ),
          TextField(
            controller: _qTotalController,
            decoration: const InputDecoration(labelText: "Questões"),
          ),
          TextField(
            controller: _qCorrectController,
            decoration: const InputDecoration(labelText: "Acertos"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(onPressed: _salvar, child: const Text("Salvar")),
      ],
    );
  }
}
