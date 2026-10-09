import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'user.dart';

class DatabaseHelper{
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async{
    if(_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async{
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'users.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL 
          )
      ''');
      },
      );
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert(
      'users',
      user.toMap()..remove('id'),
    );
  }

  Future<List<User>> getUsers() async{
    final db = await database;
    final res = await db.query('users');

    return res.map((map) => User.fromMap(map)).toList();
  }

  Future<User?> getUserById(int id) async{
    final db = await database;
    final res = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if(res.isEmpty) return null;

    return User.fromMap(res.first); //gets the first row from the results
  }

  Future<int> updateUser(int id,String newName ,String newEmail) async{
    final db = await database;

    return await db.update('users', {'name': newName, 'email': newEmail}, where: 'id = ?',whereArgs: [id],);
  }

  Future<int> deleteUser(int id) async{
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}