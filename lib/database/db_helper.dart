import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sessao_estudo.dart';
import '../models/questao.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('zion_mind_pro_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await _createCoreTables(db);
    await _createTrilhaTables(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    await _createTrilhaTables(db);
  }

  Future _createCoreTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sessoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        materia TEXT NOT NULL,
        data TEXT NOT NULL,
        minutos INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS questoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        materia TEXT NOT NULL,
        assunto TEXT,
        data TEXT NOT NULL,
        qtd_feitas INTEGER NOT NULL,
        qtd_acertos INTEGER NOT NULL,
        tarefa_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS tarefas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ordem INTEGER,
        materia TEXT NOT NULL,
        assunto TEXT NOT NULL,
        descricao TEXT,
        status TEXT DEFAULT 'pendente',
        data_conclusao TEXT,
        desempenho_medio REAL,
        proxima_revisao TEXT
      )
    ''');
  }

  Future _createTrilhaTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tarefas_trilha (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trilha TEXT,
        data_planejada TEXT,
        tarefa_codigo TEXT,
        disciplina TEXT,
        descricao TEXT,
        ch_planejada_min INTEGER,
        ch_efetiva_min INTEGER,
        questoes INTEGER,
        acertos INTEGER,
        desempenho REAL,
        rev_24h TEXT,
        rev_7d TEXT,
        rev_15d TEXT,
        rev_30d TEXT,
        rev_60d TEXT,
        json_extra TEXT,
        hash_linha TEXT
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
      CREATE TABLE IF NOT EXISTS revisoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarefa_id INTEGER,
        tipo TEXT,
        data_prevista TEXT,
        status TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tarefas_trilha_data ON tarefas_trilha(data_planejada)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_plano_diario_data ON plano_diario(data)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_revisoes_data ON revisoes(data_prevista)',
    );
  }

  // Sessao (tempo) - legado
  Future<int> inserirSessao(SessaoEstudo sessao) async {
    final db = await instance.database;
    return await db.insert('sessoes', sessao.toLegacyMap());
  }

  Future<List<SessaoEstudo>> listarSessoes() async {
    final db = await instance.database;
    final result = await db.query('sessoes', orderBy: 'data DESC');
    return result.map((json) => SessaoEstudo.fromLegacyMap(json)).toList();
  }

  // Questoes
  Future<int> inserirQuestao(Questao questao) async {
    final db = await instance.database;
    return await db.insert('questoes', questao.toMap());
  }

  Future<List<Questao>> listarQuestoes() async {
    final db = await instance.database;
    final result = await db.query('questoes', orderBy: 'data DESC');
    return result.map((json) => Questao.fromMap(json)).toList();
  }

  Future<int> totalQuestoesFeitas() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(qtd_feitas) as total FROM questoes',
    );
    return result.first['total'] as int? ?? 0;
  }
}
