import 'package:flutter/material.dart';
import '../models/sessao_estudo.dart';
import '../database/db_helper.dart';

class ModalCadastro extends StatefulWidget {
  final Function onSave;
  ModalCadastro({required this.onSave});

  @override
  _ModalCadastroState createState() => _ModalCadastroState();
}

class _ModalCadastroState extends State<ModalCadastro> {
  final _materiaController = TextEditingController();
  final _minutosController = TextEditingController();

  void _confirmar() async {
    final materia = _materiaController.text;
    final minutos = int.tryParse(_minutosController.text) ?? 0;

    if (materia.isEmpty || minutos <= 0) return;

    final novaSessao = SessaoEstudo(
      materia: materia,
      data: DateTime.now(),
      minutos: minutos,
    );

    await DbHelper.instance.inserirSessao(novaSessao);
    widget.onSave(); // Avisa a tela inicial para atualizar a lista
    Navigator.of(context).pop(); // Fecha o modal
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _materiaController,
            decoration: InputDecoration(
              labelText: 'Matéria (Ex: Direito Tributário)',
            ),
          ),
          TextField(
            controller: _minutosController,
            decoration: InputDecoration(labelText: 'Minutos Estudados'),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _confirmar,
            child: Text('Salvar Sessão'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
