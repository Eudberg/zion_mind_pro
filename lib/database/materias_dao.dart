import '../database/db_helper.dart';
import '../models/materia.dart';

class MateriasDao {
  final DbHelper _dbHelper = DbHelper();

  String normalize(String s) {
    return s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  Future<int> upsertMateria({
    required String nome,
    required String origem,
  }) async {
    final db = await _dbHelper.database;
    final nomeNormalizado = normalize(nome);

    try {
      return await db.insert('materias', {
        'nome': nome,
        'nomeNormalizado': nomeNormalizado,
        'origem': origem,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      final rows = await db.rawQuery(
        'SELECT id FROM materias WHERE nomeNormalizado = ?',
        [nomeNormalizado],
      );
      if (rows.isNotEmpty && rows.first['id'] != null) {
        return rows.first['id'] as int;
      }
      rethrow;
    }
  }

  Future<List<Materia>> listarOrdenado() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT * FROM materias ORDER BY nome COLLATE NOCASE',
    );
    return rows.map((m) => Materia.fromMap(m)).toList();
  }
}
