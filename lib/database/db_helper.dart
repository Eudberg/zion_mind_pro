import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  // Corrigido de DBHelper para DbHelper
  static final DbHelper _instance = DbHelper._internal();
  static Database? _database;

  DbHelper._internal();

  factory DbHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'zion_mind_pro.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabela completa com campos legados + novos
    await db.execute('''
      CREATE TABLE tarefas_trilha(
        id INTEGER PRIMARY KEY,
        ordemGlobal INTEGER,
        disciplina TEXT,
        assunto TEXT,
        duracaoMinutos INTEGER,
        chPlanejadaMin INTEGER,
        concluida INTEGER,

        -- Campos Legados restaurados
        descricao TEXT,
        fonteQuestoes TEXT,
        questoes INTEGER,
        acertos INTEGER,
        trilha TEXT,
        tarefaCodigo TEXT,
        chEfetivaMin INTEGER,

        -- Novos Campos (7-30-60)
        estagioRevisao INTEGER DEFAULT 0,
        dataConclusao TEXT,
        dataProximaRevisao TEXT,
        dataIgnorarRevisaoAte TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sessoes_estudo(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarefaId INTEGER,
        disciplina TEXT,
        dataInicio TEXT,
        duracaoMinutos INTEGER,
        questoesFeitas INTEGER,
        questoesAcertadas INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE questoes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        disciplina TEXT,
        assunto TEXT,
        quantidade INTEGER,
        acertos INTEGER,
        data TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE materias(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        nomeNormalizado TEXT NOT NULL UNIQUE,
        origem TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE assuntos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        materiaId INTEGER NOT NULL,
        nome TEXT NOT NULL,
        nomeNormalizado TEXT NOT NULL,
        origem TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        UNIQUE(materiaId, nomeNormalizado),
        FOREIGN KEY(materiaId) REFERENCES materias(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _safeExecute(Database db, String sql) async {
    try {
      await db.execute(sql);
    } catch (_) {}
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _safeExecute(
        db,
        'ALTER TABLE tarefas_trilha ADD COLUMN estagioRevisao INTEGER DEFAULT 0',
      );
      await _safeExecute(
        db,
        'ALTER TABLE tarefas_trilha ADD COLUMN dataConclusao TEXT',
      );
      await _safeExecute(
        db,
        'ALTER TABLE tarefas_trilha ADD COLUMN dataProximaRevisao TEXT',
      );
      // Garantindo colunas legados caso nao existam
      await _safeExecute(
        db,
        'ALTER TABLE tarefas_trilha ADD COLUMN descricao TEXT',
      );
      await _safeExecute(
        db,
        'ALTER TABLE tarefas_trilha ADD COLUMN fonteQuestoes TEXT',
      );

      await _safeExecute(db, '''
        CREATE TABLE IF NOT EXISTS sessoes_estudo(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tarefaId INTEGER,
          disciplina TEXT,
          dataInicio TEXT,
          duracaoMinutos INTEGER,
          questoesFeitas INTEGER,
          questoesAcertadas INTEGER
        )
      ''');

      await _safeExecute(db, '''
        CREATE TABLE IF NOT EXISTS questoes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          disciplina TEXT,
          assunto TEXT,
          quantidade INTEGER,
          acertos INTEGER,
          data TEXT
        )
      ''');
    }

    if (oldVersion < 3) {
      await _safeExecute(db, '''
        CREATE TABLE IF NOT EXISTS materias(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL,
          nomeNormalizado TEXT NOT NULL UNIQUE,
          origem TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');

      await _safeExecute(db, '''
        CREATE TABLE IF NOT EXISTS assuntos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          materiaId INTEGER NOT NULL,
          nome TEXT NOT NULL,
          nomeNormalizado TEXT NOT NULL,
          origem TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          UNIQUE(materiaId, nomeNormalizado),
          FOREIGN KEY(materiaId) REFERENCES materias(id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 4) {
      await _safeExecute(
        db,
        'ALTER TABLE tarefas_trilha ADD COLUMN dataIgnorarRevisaoAte TEXT',
      );
    }
  }
}
