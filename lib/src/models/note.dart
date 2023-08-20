import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../keys.dart';

void handleError(e) {
  if (e.toString().contains("SocketException")) {
    Fluttertoast.showToast(msg: "Make sure you're connected to the internet");
  } else {
    Fluttertoast.showToast(msg: "Something went wrong");
  }
}

Future<List<Note>> getNotes({bool isStarred = false}) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('userToken') ?? "";

    Response response = await Dio().get(
      Keys.BASE_URL + '/notes/',
      queryParameters: isStarred ? {"isStarred": isStarred} : {},
      options: Options(
        responseType: ResponseType.json,
        headers: {"Authorization": "Bearer " + token},
      ),
    );

    return compute(parseNotes, response.data);
  } catch (e) {
    debugPrint("ERR " + e.toString());
    handleError(e);
    return [];
  }
}

Future<List> getLocalNotes() async {
  try {
    var db = NotesDBProvider();
    await db.open();
    List<Note> notes = await db.getNotes();
    await db.close();
    return notes;
  } catch (e) {
    debugPrint("ERR " + e.toString());
    handleError(e);
    return [];
  }
}

Future<Note?> getNote({required String noteId}) async {
  try {
    bool isMongoId = noteId.length == 24;
    if (isMongoId) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('userToken') ?? "";
      Response response = await Dio().get(Keys.BASE_URL + '/notes/$noteId/',
          options: Options(
            responseType: ResponseType.json,
            headers: {
              "Authorization": "Bearer " + token,
            },
          ));
      return compute(parseNote, response.data);
    } else {
      var db = NotesDBProvider();
      await db.open();
      Note? note = await db.getNote(noteId);
      await db.close();
      return note;
    }
  } catch (e) {
    handleError(e);
    return null;
  }
}

Future createNote({required Map note}) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('userToken') ?? "";
    Response response = await Dio().post(Keys.BASE_URL + '/notes/',
        data: note,
        options: Options(
          responseType: ResponseType.json,
          headers: {"Authorization": "Bearer " + token},
        ));
    print(response.data.toString());
    return response.data;
  } catch (e) {
    handleError(e);
    return null;
  }
}

void updateLocalNote({required Map<String, dynamic> note}) async {
  try {
    var db = NotesDBProvider();
    await db.open();
    await db.update(note);
    await db.close();
  } catch (e) {
    handleError(e);
  }
}

Future updateNote({required Map<String, dynamic> note}) async {
  try {
    if (note['id'].length != 24) {
      updateLocalNote(note: note);
      return note;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('userToken') ?? "";
    Response response = await Dio().put(Keys.BASE_URL + "/notes/${note['id']}/",
        data: note,
        options: Options(
          responseType: ResponseType.json,
          headers: {
            "Authorization": "Bearer " + token,
          },
        ));
    return response.data;
  } catch (e) {
    handleError(e);
    return null;
  }
}

Future deleteNote(String id) async {
  try {
    bool isMongoId = id.length == 24;
    if (isMongoId) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('userToken') ?? "";
      Response response = await Dio().delete(Keys.BASE_URL + "/notes/$id/",
          options: Options(
            responseType: ResponseType.json,
            headers: {
              "Authorization": "Bearer " + token,
            },
          ));
      return response.data;
    } else {
      var db = NotesDBProvider();
      await db.open();
      await db.delete(id);
      await db.close();
    }
  } catch (e) {
    handleError(e);
    return null;
  }
}

List<Note> parseNotes(dynamic json) {
  debugPrint("HERE");
  return json['notes'].map<Note>((json) => Note.fromJson(json)).toList();
}

Note parseNote(dynamic json) {
  return Note.fromJson(json['note']);
}

final String tableNotes = 'Notes';
final String columnTitle = 'title';
final String columnBody = 'body';
final String columnIsStarred = 'isStarred';
final String columnDate = 'date';
final String tempNotes = 'temp_notes';

class Note {
  final String id;
  final String title;
  final String body;
  final String date;
  final bool isStarred;

  Note({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.isStarred,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['_id'],
        title: json['title'],
        body: json['body'] ?? '',
        date: json['date'],
        isStarred: json['isStarred'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        columnTitle: title,
        columnBody: body,
        columnIsStarred: isStarred,
        columnDate: date,
      };
}

class NotesDBProvider {
  late Database db;
  late Database tmpDb;

  Future open() async {
    final path = join(await getDatabasesPath(), 'online.diarme.db');
    db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
      CREATE TABLE $tableNotes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTitle TEXT,
        $columnIsStarred INTEGER,
        $columnDate TEXT,
        $columnBody TEXT)
        ''');
    });
  }

  Future openTemp() async {
    final path = join(await getDatabasesPath(), 'online.diarme.temp.db');
    tmpDb =
        await openDatabase(path, version: 1, onCreate: (temp, version) async {
      await temp.execute('''
      CREATE TABLE $tempNotes(
        $columnTitle TEXT,
        $columnBody TEXT,
        $columnDate TEXT
        )
        ''');
    });
  }

  Future insert(Map note) async {
    await db.insert(tableNotes, note as Map<String, Object?>,
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<Note?> getNote(String id) async {
    List<Map> maps = await db.query(tableNotes,
        columns: [columnTitle, columnBody, columnIsStarred, columnDate],
        where: 'id=$id');
    if (maps.length > 0) {
      bool isStarred = maps.first['isStarred'] == "0" ? false : true;
      var note = Note(
          id: maps.first['id'].toString(),
          title: maps.first['title'],
          body: maps.first['body'],
          date: maps.first['date'],
          isStarred: isStarred);
      return note;
    }
    return null;
  }

  Future getNotes() async {
    List<Map> notes = await db.query(tableNotes,
        columns: ['id', columnTitle, columnBody, columnIsStarred, columnDate]);

    return notes.map((note) {
      bool isStarred = note['isStarred'] == "0" ? false : true;
      var n = Note(
          id: note['id'].toString(),
          title: note['title'],
          body: note['body'],
          date: note['date'],
          isStarred: isStarred);
      return n;
    }).toList();
  }

  Future update(Map<String, dynamic> note) async {
    await db.update(tableNotes, note, where: "id=${note['id']}");
  }

  Future delete(String id) async {
    await db.delete(tableNotes, where: 'id=$id');
    return id;
  }

  Future saveTemp(Map<String, dynamic> note) async {
    await tmpDb.insert(tempNotes, note,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future getTemp() async {
    List<Map> maps = await tmpDb.query(tempNotes);
    debugPrint(maps.toString());
    return maps.first;
  }

  Future clearTemp() async {
    await tmpDb.delete(tempNotes);
  }

  Future close() async => await db.close();
  Future closeTmpDb() async => await tmpDb.close();
}
