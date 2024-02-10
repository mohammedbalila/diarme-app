import 'package:diarme/src/providers/cache.dart';
import 'package:sentry/sentry.dart';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter/foundation.dart';
import '../keys.dart';

Future handleError(e) async {
  await Sentry.captureException(e);
  if (e.toString().contains("SocketException")) {
    Fluttertoast.showToast(msg: "Make sure you're connected to the internet");
  } else {
    Fluttertoast.showToast(msg: "Something went wrong");
  }
}

Future<void> shouldUpdateCache(
    SharedPreferences prefs, List<Note> notes, LocalCacheProvider db) async {
  bool shouldFlushCache = prefs.getBool('shouldFlushCache') ?? false;

  int cachedNotesCount = await db.getCachedNotesCount();
  bool hasOutDatedCache = cachedNotesCount != notes.length;

  if ((shouldFlushCache || hasOutDatedCache) && !notes.isEmpty) {
    await db.flushCache();
    await db.writeNotesToCatch(notes);
    await prefs.setBool('shouldFlushCache', false);
  }
  await db.close();
}

Future<List<Note>> getNotes({bool isStarred = false}) async {
  List<Note> notes;
  var db = await LocalCacheProvider();
  await db.open();
  bool connected = await InternetConnectionChecker().hasConnection;
  if (connected) {
    notes = await getRemoteNotes(isStarred: isStarred, db: db);
  } else {
    notes = await db.getCachedNotes();
  }

  await db.close();
  return notes;
}

Future<void> syncLocalUpdates(LocalCacheProvider db) async {
  List<Map<String, dynamic>> notes = await db.getUnSyncedNotes();
  List<Future> updates = notes
      .map((note) => updateNote(note: note, shouldFlushCache: false))
      .toList();

  if (updates.isEmpty) {
    return;
  }
  await Future.wait(updates);
  await db.flushCache();
}

Future<List<Note>> getRemoteNotes(
    {bool isStarred = false, LocalCacheProvider? db = null}) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('userToken') ?? "";

    bool hasUnSyncedLocalUpdates =
        prefs.getBool("hasUnSyncedLocalUpdates") ?? false;
    if (hasUnSyncedLocalUpdates && db != null) {
      await syncLocalUpdates(db);
      await prefs.setBool("hasUnSyncedLocalUpdates", false);
      await prefs.setBool('shouldFlushCache', false);
    }

    Response response = await Dio().get(
      Keys.BASE_URL + '/notes/',
      queryParameters: isStarred ? {"isStarred": isStarred} : {},
      options: Options(
        responseType: ResponseType.json,
        sendTimeout: Duration(seconds: 3),
        headers: {"Authorization": "Bearer " + token},
      ),
    );

    List<Note> notes = await compute(parseNotes, response.data);

    // avoid updating cache when filtering
    if (!isStarred && db != null) {
      await shouldUpdateCache(prefs, notes, db);
    }
    return notes;
  } catch (e) {
    handleError(e);
    return [];
  }
}

Future<Map<String, dynamic>> getNote({required String noteId}) async {
  Note? note;
  bool connected = await InternetConnectionChecker().hasConnection;

  if (connected) {
    note = await getRemoteNote(noteId: noteId);
    return {"note": note, "servedFromCache": false};
  } else {
    var db = LocalCacheProvider();
    await db.open();
    note = await db.getCachedNote(noteId);
    await db.close();
    return {"note": note, "servedFromCache": true};
  }
}

Future<Note?> getRemoteNote({required String noteId}) async {
  try {
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
  } catch (e) {
    await handleError(e);
    return null;
  }
}

Future<bool> createCachedNote(
    {required Map<String, dynamic> note,
    required LocalCacheProvider db}) async {
  try {
    await db.addNoteToCache(note);
  } catch (ex) {
    return false;
  }
  return true;
}

Future createNote(
    {required Map<String, dynamic> note, bool servedFromCache = false}) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (servedFromCache) {
      var db = LocalCacheProvider();
      await createCachedNote(note: note, db: db);
      await db.close();
      prefs.setBool("hasUnSyncedLocalUpdates", true);
      return;
    }

    String token = prefs.getString('userToken') ?? "";
    Response response = await Dio().post(Keys.BASE_URL + '/notes/',
        data: note,
        options: Options(
          responseType: ResponseType.json,
          headers: {"Authorization": "Bearer " + token},
        ));
    prefs.setBool("shouldFlushCache", true);
    return response.data;
  } catch (e) {
    await handleError(e);
    return null;
  }
}

Future<bool> updateCachedNote({required Map<String, dynamic> note}) async {
  try {
    var db = LocalCacheProvider();
    await db.open();
    await db.updateCachedNote(note);
    await db.close();
  } catch (ex) {
    return false;
  }
  return true;
}

Future updateNote(
    {required Map<String, dynamic> note,
    bool servedFromCache = false,
    bool shouldFlushCache = true}) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (servedFromCache) {
      await updateCachedNote(note: note);
      prefs.setBool("hasUnSyncedLocalUpdates", true);
      return;
    }

    String token = prefs.getString('userToken') ?? "";
    Response response = await Dio().put(Keys.BASE_URL + "/notes/${note['id']}/",
        data: note,
        options: Options(
          responseType: ResponseType.json,
          headers: {
            "Authorization": "Bearer " + token,
          },
        ));
    prefs.setBool("shouldFlushCache", shouldFlushCache);
    return response.data;
  } catch (e) {
    await handleError(e);
    return null;
  }
}

Future deleteNote(String id) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('userToken') ?? "";
    Response response = await Dio().delete(Keys.BASE_URL + "/notes/$id/",
        options: Options(
          responseType: ResponseType.json,
          headers: {
            "Authorization": "Bearer " + token,
          },
        ));
    prefs.setBool("shouldFlushCache", true);
    return response.data;
  } catch (e) {
    await handleError(e);
    return null;
  }
}

List<Note> parseNotes(dynamic json) {
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
