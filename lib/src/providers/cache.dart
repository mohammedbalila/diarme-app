import 'package:diarme/src/models/note.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

final String tableNotesCache = 'note_cache';

class LocalCacheProvider {
  late Database db;

  Future open() async {
    final path = join(await getDatabasesPath(), 'online.diarme.db');
    db = await openDatabase(
      path,
      version: 2,
      onOpen: (db) => {
        db.execute('''
                create table if not exists $tableNotesCache (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                note_id text,
                title text,
                body text,
                date date,
                is_starred tinyint,
                requires_sync tinyint default 0
              )
              ''')
      },
      onUpgrade: (db, oldV, newV) => {
        if (oldV < newV)
          {
            db.execute(
                "alter table $tableNotesCache add column requires_sync tinyint default 0;")
          }
      },
    );
  }

  Future close() async => await db.close();
  // CACHE functions

  // update cache
  Future writeNotesToCatch(List<Note> notes) async {
    List<Map<String, dynamic>> notesRecords = notes
        .map((note) => {
              "note_id": note.id,
              "title": note.title,
              "body": note.body,
              "date": note.date,
              "is_starred": note.isStarred ? 1 : 0, // no boolean only tiny int
            })
        .toList();

    Batch batch = db.batch();
    notesRecords.forEach((record) {
      batch.insert(tableNotesCache, record);
    });
    await batch.commit(noResult: true);
  }

  Future flushCache() async {
    await db.delete(tableNotesCache, where: ' 1 = 1');
  }

  Future<int> getCachedNotesCount() async {
    int? count = Sqflite.firstIntValue(
        await db.rawQuery('select count(*) from $tableNotesCache'));
    return count ?? 0;
  }

  Future<List<Note>> getCachedNotes() async {
    List<Map> notes = await db.query(tableNotesCache);

    return notes.map((note) {
      bool isStarred = note['is_starred'] == 0 ? false : true;
      var n = Note(
          id: note['note_id'],
          title: note['title'],
          body: note['body'],
          date: note['date'],
          isStarred: isStarred);
      return n;
    }).toList();
  }

  Future<Note?> getCachedNote(String noteID) async {
    List<Map> notes = await db
        .query(tableNotesCache, where: 'note_id = ?', whereArgs: [noteID]);
    if (notes.isEmpty) {
      return null;
    }

    Map note = notes.first;
    bool isStarred = note['is_starred'] == 0 ? false : true;
    return Note(
        id: note['note_id'],
        title: note['title'],
        body: note['body'],
        date: note['date'],
        isStarred: isStarred);
  }

  Future updateCachedNote(Map<String, dynamic> note) async {
    note["requires_sync"] = 1;
    note["note_id"] = note["id"];
    note["is_starred"] = note['isStarred'] ? 1 : 0;
    note.remove('id');
    note.remove('isStarred');
    await db.update(tableNotesCache, note,
        where: 'note_id = ?', whereArgs: [note['note_id']]);
  }

  Future addNoteToCache(Map<String, dynamic> note) async {
    note["requires_sync"] = 1;
    note["note_id"] = note["id"];
    note["is_starred"] = 0;
    note.remove('isStarred');
    note.remove('id');
    await db.insert(tableNotesCache, note);
  }

  Future<List<Map<String, dynamic>>> getUnSyncedNotes() async {
    List<Map> records = await db
        .query(tableNotesCache, where: 'requires_sync = ?', whereArgs: [1]);

    List<Map<String, dynamic>> notes = records
        .map((record) => {
              "id": record['note_id'],
              "title": record['title'],
              "body": record['body'],
              "date": record['date'],
              "isStarred": record['is_starred'] == 0 ? false : true,
            })
        .toList();

    return notes;
  }
}
