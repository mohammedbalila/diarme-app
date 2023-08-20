import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const String tableUser = 'User';
const String columnId = '_id';
const String columnUsername = 'username';
const String columnEmail = 'email';

class User {
  String id;
  String username;
  String email;

  User({required this.id, required this.username, required this.email});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json[columnId],
        username: json[columnUsername],
        email: json[columnEmail],
      );

  Map<String, dynamic> toMap() => {
        columnId: id,
        columnUsername: username,
        columnEmail: email,
      };
}

class UserDBProvider {
  late Database db;

  Future open() async {
    final path = join(await getDatabasesPath(), 'diame_user.db');
    db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
      CREATE TABLE $tableUser(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnUsername TEXT,
        $columnEmail TEXT,
        $columnId TEXT NOT NULL)
        ''');
    });
  }

  Future insert(User user) async {
    await db.insert(tableUser, user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<User?> getUser() async {
    List<Map<String, dynamic>> maps = await db.query(tableUser);
    if (maps.length > 0) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  Future update(Map<String, dynamic> user) async {
    await db.update(tableUser, user);
  }

  Future delete() async {
    await db.delete(tableUser);
  }

  Future close() async => await db.close();
}
