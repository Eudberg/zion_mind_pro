import 'package:sqflite/sqflite.dart';
import '../models/tarefa_trilha.dart';
import 'db_helper.dart';

class TarefasTrilhaDAO {
  // Usando DbHelper (com 'b' minúsculo) para manter a compatibilidade
  final DbHelper _dbHelper = DbHelper();

  // Insere uma nova tarefa ou substitui se houver conflito de ID
  Future<int> inserir(TarefaTrilha tarefa) async {
    Database db = await _dbHelper.database;
    return await db.insert(
      'tarefas_trilha',
      tarefa.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Lista todas as tarefas da trilha
  Future<List<TarefaTrilha>> listarTodas() async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('tarefas_trilha');

    return List.generate(maps.length, (i) {
      return TarefaTrilha.fromMap(maps[i]);
    });
  }

  // Atualiza uma tarefa existente baseada no ID
  Future<int> atualizar(TarefaTrilha tarefa) async {
    Database db = await _dbHelper.database;
    return await db.update(
      'tarefas_trilha',
      tarefa.toMap(),
      where: 'id = ?',
      whereArgs: [tarefa.id],
    );
  }

  Future<int> atualizarPorChaveLogica(TarefaTrilha tarefa) async {
    Database db = await _dbHelper.database;
    final dados = tarefa.toMap()..remove('id');
    return await db.update(
      'tarefas_trilha',
      dados,
      where:
          'ordemGlobal = ? AND TRIM(UPPER(disciplina)) = TRIM(UPPER(?)) AND TRIM(assunto) = TRIM(?)',
      whereArgs: [tarefa.ordemGlobal, tarefa.disciplina, tarefa.assunto],
    );
  }

  // Busca uma tarefa específica por ID (útil para detalhes ou sincronização)
  Future<TarefaTrilha?> buscarPorId(int id) async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      'tarefas_trilha',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return TarefaTrilha.fromMap(maps.first);
    }
    return null;
  }

  Future<TarefaTrilha?> buscarPorChaveLogica({
    required int ordemGlobal,
    required String disciplina,
    required String assunto,
  }) async {
    Database db = await _dbHelper.database;
    final maps = await db.query(
      'tarefas_trilha',
      where:
          'ordemGlobal = ? AND TRIM(UPPER(disciplina)) = TRIM(UPPER(?)) AND TRIM(assunto) = TRIM(?)',
      whereArgs: [ordemGlobal, disciplina, assunto],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return TarefaTrilha.fromMap(maps.first);
    }
    return null;
  }

  Future<TarefaTrilha?> buscarPrimeiraPorDisciplina(String disciplina) async {
    Database db = await _dbHelper.database;
    final maps = await db.query(
      'tarefas_trilha',
      where: 'TRIM(UPPER(disciplina)) = TRIM(UPPER(?))',
      whereArgs: [disciplina],
      orderBy: 'ordemGlobal ASC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return TarefaTrilha.fromMap(maps.first);
    }
    return null;
  }

  // Método opcional para deletar (caso precise no futuro)
  Future<int> deletar(int id) async {
    Database db = await _dbHelper.database;
    return await db.delete('tarefas_trilha', where: 'id = ?', whereArgs: [id]);
  }
}
