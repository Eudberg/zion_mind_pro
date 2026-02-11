import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/sessao_estudo.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('zion_mind_pro_v3.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await _createTrilhaTables(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    await _createTrilhaTables(db);

    // tenta adicionar colunas novas sem quebrar
    if (oldVersion < 3) {
      for (final sql in [
        "ALTER TABLE tarefas_trilha ADD COLUMN concluida INTEGER DEFAULT 0",
        "ALTER TABLE tarefas_trilha ADD COLUMN ordem_global INTEGER",
        "ALTER TABLE tarefas_trilha ADD COLUMN fonte_questoes TEXT",
      ]) {
        try {
          await db.execute(sql);
        } catch (_) {}
      }
    }
  }

  Future _createTrilhaTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tarefas_trilha (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trilha TEXT,
        data_planejada TEXT,
        tarefa_codigo TEXT,
        ordem_global INTEGER,
        disciplina TEXT,
        descricao TEXT,
        ch_planejada_min INTEGER,
        ch_efetiva_min INTEGER,
        questoes INTEGER,
        acertos INTEGER,
        fonte_questoes TEXT,
        desempenho REAL,
        rev_7d TEXT,
        rev_30d TEXT,
        rev_60d TEXT,
        json_extra TEXT,
        hash_linha TEXT,
        concluida INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS plano_diario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT,
        tarefa_id INTEGER,
        tipo TEXT,
        minutos_sugeridos INTEGER,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS revisoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarefa_id INTEGER,
        tipo TEXT,
        data_prevista TEXT,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS questoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        materia TEXT,
        assunto TEXT,
        data TEXT,
        qtd_feitas INTEGER,
        qtd_acertos INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sessoes_estudo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarefa_id INTEGER,
        inicio TEXT,
        fim TEXT,
        minutos INTEGER,
        questoes INTEGER,
        acertos INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sessoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        materia TEXT,
        data TEXT,
        minutos INTEGER
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tarefas_trilha_data ON tarefas_trilha(data_planejada)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tarefas_trilha_ordem ON tarefas_trilha(ordem_global)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_plano_diario_data ON plano_diario(data)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_revisoes_data ON revisoes(data_prevista)',
    );
  }

  Future<int> inserirSessao(SessaoEstudo sessao) async {
    final db = await database;
    return db.insert('sessoes', sessao.toLegacyMap());
  }
}
