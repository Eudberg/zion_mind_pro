import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sessao_estudo.dart'; // Importando seu model

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('estudos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        materia TEXT NOT NULL,
        data TEXT NOT NULL,
        minutos INTEGER NOT NULL
      )
    ''');
  }

  Future<int> inserirSessao(SessaoEstudo sessao) async {
    final db = await instance.database;
    return await db.insert('sessoes', sessao.toMap());
  }

  Future<List<SessaoEstudo>> listarSessoes() async {
    final db = await instance.database;
    final result = await db.query('sessoes', orderBy: 'data DESC');

    return result.map((json) => SessaoEstudo.fromMap(json)).toList();
  }
}
