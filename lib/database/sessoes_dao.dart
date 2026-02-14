import 'package:sqflite/sqflite.dart';
import '../models/sessao_estudo.dart';
import 'db_helper.dart';

class SessoesDao {
  // Correção: Alterado de DBHelper para DbHelper para coincidir com a classe definida no db_helper.dart
  final DbHelper _dbHelper = DbHelper();

  Future<int> inserir(SessaoEstudo sessao) async {
    Database db = await _dbHelper.database;
    return await db.insert('sessoes_estudo', sessao.toMap());
  }

  Future<List<SessaoEstudo>> listarTodas() async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('sessoes_estudo');
    return List.generate(maps.length, (i) {
      return SessaoEstudo.fromMap(maps[i]);
    });
  }
}
