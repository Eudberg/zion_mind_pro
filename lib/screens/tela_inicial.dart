import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/sessao_estudo.dart';
import '../widgets/modal_cadastro.dart';

class TelaInicial extends StatefulWidget {
  @override
  _TelaInicialState createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ZionMindPro - Meus Estudos'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<SessaoEstudo>>(
        future: DbHelper.instance.listarSessoes(), // Busca os dados
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final sessoes = snapshot.data!;
          if (sessoes.isEmpty) {
            return Center(
              child: Text(
                'Nenhum estudo registrado.\nHora de focar na SEFAZ-BA!',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: sessoes.length,
            itemBuilder: (ctx, i) {
              final s = sessoes[i];
              return ListTile(
                leading: CircleAvatar(
                  child: Icon(Icons.book),
                  backgroundColor: Colors.indigo,
                ),
                title: Text(
                  s.materia,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Data: ${s.data.day}/${s.data.month}'),
                trailing: Text(
                  '${s.minutos} min',
                  style: TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (ctx) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: ModalCadastro(
                onSave: () {
                  setState(() {}); // Atualiza a lista após salvar
                },
              ),
            ),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }
}
