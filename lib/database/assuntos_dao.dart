import '../database/db_helper.dart';
import '../models/assunto.dart';

class AssuntosDao {
  final DbHelper _dbHelper = DbHelper();

  String normalize(String s) {
    return s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  Future<int> upsertAssunto({
    required int materiaId,
    required String nome,
    required String origem,
  }) async {
    final db = await _dbHelper.database;
    final nomeNormalizado = normalize(nome);

    try {
      return await db.insert('assuntos', {
        'materiaId': materiaId,
        'nome': nome,
        'nomeNormalizado': nomeNormalizado,
        'origem': origem,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      final rows = await db.rawQuery(
        'SELECT id FROM assuntos WHERE materiaId = ? AND nomeNormalizado = ?',
        [materiaId, nomeNormalizado],
      );
      if (rows.isNotEmpty && rows.first['id'] != null) {
        return rows.first['id'] as int;
      }
      rethrow;
    }
  }

  Future<List<Assunto>> listarPorMateria(int materiaId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT * FROM assuntos WHERE materiaId = ? ORDER BY nome COLLATE NOCASE',
      [materiaId],
    );
    return rows.map((m) => Assunto.fromMap(m)).toList();
  }
}
