import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sessao_estudo.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(
      'zion_mind_pro_v2.db',
    ); // Mudamos o nome para criar um banco novo e limpo
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Tabela 1: Sessões de Tempo (O que já tínhamos)
    await db.execute('''
      CREATE TABLE sessoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        materia TEXT NOT NULL,
        data TEXT NOT NULL,
        minutos INTEGER NOT NULL
      )
    ''');

    // Tabela 2: Registro de Questões (NOVO)
    await db.execute('''
      CREATE TABLE questoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        materia TEXT NOT NULL,
        assunto TEXT,
        data TEXT NOT NULL,
        qtd_feitas INTEGER NOT NULL,
        qtd_acertos INTEGER NOT NULL,
        tarefa_id INTEGER -- Para ligar com a mentoria futuramente
      )
    ''');

    // Tabela 3: Tarefas da Mentoria (NOVO - Preparando para o CSV)
    await db.execute('''
      CREATE TABLE tarefas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ordem INTEGER,
        materia TEXT NOT NULL,
        assunto TEXT NOT NULL,
        descricao TEXT,
        status TEXT DEFAULT 'pendente', -- pendente, concluida, revisao
        data_conclusao TEXT,
        desempenho_medio REAL, -- % de acertos
        proxima_revisao TEXT   -- Data da revisão calculada
      )
    ''');
  }

  // --- MÉTODOS DE SESSÃO (TEMPO) ---
  Future<int> inserirSessao(SessaoEstudo sessao) async {
    final db = await instance.database;
    return await db.insert('sessoes', sessao.toMap());
  }

  Future<List<SessaoEstudo>> listarSessoes() async {
    final db = await instance.database;
    final result = await db.query('sessoes', orderBy: 'data DESC');
    return result.map((json) => SessaoEstudo.fromMap(json)).toList();
  }

  // --- MÉTODOS DE QUESTÕES (Faremos a tela em breve) ---
  // Aqui virão os métodos para inserir e buscar questões
}
