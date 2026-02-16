import '../models/questao.dart';
import 'db_helper.dart';

class QuestoesDao {
  Future<int> inserir(Questao questao) async {
    final db = await DbHelper().database;

    // Pega o map vindo do model (pode estar no formato novo ou legado)
    final m = questao.toMap();

    // Monta um map "canônico" para o schema atual do DbHelper:
    // questoes(disciplina, assunto, quantidade, acertos, data)
    final canonical = <String, Object?>{
      // disciplina pode vir como 'disciplina' (novo) ou 'materia' (legado)
      'disciplina': (m['disciplina'] ?? m['materia'])?.toString(),

      // assunto geralmente é igual
      'assunto': m['assunto']?.toString(),

      // quantidade pode vir como 'quantidade' (novo) ou 'qtd_feitas' (legado)
      'quantidade': m['quantidade'] ?? m['qtd_feitas'],

      // acertos pode vir como 'acertos' (novo) ou 'qtd_acertos' (legado)
      'acertos': m['acertos'] ?? m['qtd_acertos'],

      // data (mantém como string ISO, se já vier assim)
      'data': m['data']?.toString(),
    };

    // Remove chaves nulas pra evitar inserir null desnecessariamente
    canonical.removeWhere((k, v) => v == null);

    // Tenta inserir no schema NOVO primeiro.
    try {
      return await db.insert('questoes', canonical);
    } catch (_) {
      // Fallback para schema LEGADO:
      // questoes(materia, assunto, qtd_feitas, qtd_acertos, data)
      final legacy = <String, Object?>{
        'materia': (m['materia'] ?? m['disciplina'])?.toString(),
        'assunto': m['assunto']?.toString(),
        'qtd_feitas': m['qtd_feitas'] ?? m['quantidade'],
        'qtd_acertos': m['qtd_acertos'] ?? m['acertos'],
        'data': m['data']?.toString(),
      };

      legacy.removeWhere((k, v) => v == null);
      return await db.insert('questoes', legacy);
    }
  }

  Future<List<Questao>> listarTodas() async {
    final db = await DbHelper().database;
    final result = await db.query('questoes', orderBy: 'data DESC');
    return result.map((json) => Questao.fromMap(json)).toList();
  }

  Future<Map<String, Map<String, int>>> agregadosPorMateria() async {
    final db = await DbHelper().database;
    List<Map<String, Object?>> rows;

    try {
      rows = await db.rawQuery('''
        SELECT disciplina, SUM(quantidade) AS feitas, SUM(acertos) AS acertos
        FROM questoes
        GROUP BY disciplina
      ''');
    } catch (_) {
      // Fallback para bases legadas que usam nomes antigos de colunas.
      rows = await db.rawQuery('''
        SELECT materia AS disciplina, SUM(qtd_feitas) AS feitas, SUM(qtd_acertos) AS acertos
        FROM questoes
        GROUP BY materia
      ''');
    }

    final agregados = <String, Map<String, int>>{};
    for (final row in rows) {
      final materia = (row['disciplina']?.toString() ?? '').trim();
      if (materia.isEmpty) continue;

      final feitas = (row['feitas'] as num?)?.toInt() ?? 0;
      final acertos = (row['acertos'] as num?)?.toInt() ?? 0;

      agregados[materia] = {'feitas': feitas, 'acertos': acertos};
    }
    return agregados;
  }

  Future<Map<String, Map<String, int>>>
  agregadosPorDisciplinaNormalizada() async {
    final db = await DbHelper().database;

    String norm(String s) =>
        s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

    List<Map<String, Object?>> rows;

    try {
      rows = await db.query(
        'questoes',
        columns: ['disciplina', 'quantidade', 'acertos'],
      );
    } catch (_) {
      // Fallback para bases legadas que usam nomes antigos.
      rows = await db.rawQuery('''
        SELECT materia AS disciplina, qtd_feitas AS quantidade, qtd_acertos AS acertos
        FROM questoes
      ''');
    }

    final out = <String, Map<String, int>>{};
    for (final row in rows) {
      final disc = norm((row['disciplina'] ?? '').toString());
      if (disc.isEmpty) continue;

      final feitas = (row['quantidade'] as num?)?.toInt() ?? 0;
      final acertos = (row['acertos'] as num?)?.toInt() ?? 0;

      final atual = out[disc] ?? {'feitas': 0, 'acertos': 0};
      atual['feitas'] = (atual['feitas'] ?? 0) + feitas;
      atual['acertos'] = (atual['acertos'] ?? 0) + acertos;
      out[disc] = atual;
    }

    return out;
  }
}
