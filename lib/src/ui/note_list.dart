import 'package:diarme/src/ui/empty.dart';
import 'package:flutter/material.dart';
import '../models/note.dart';

// ignore: must_be_immutable
class NoteList extends StatefulWidget {
  List<Note> notes;
  NoteList({required this.notes});
  @override
  _NoteListState createState() => _NoteListState(notes);
}

class _NoteListState extends State<NoteList> {
  late List<Note> notes;
  bool loading = false;
  _NoteListState(this.notes);
  @override
  Widget build(BuildContext context) {
    return notes.isEmpty
        ? EmptyScreen(title: 'No notes yet', subTitle: 'Write your first note')
        : ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: ListTile(
                    enabled: !loading,
                    onTap: () {
                      Navigator.pushReplacementNamed(
                          context, "notes/${notes[index].id}");
                    },
                    title: Text(notes[index].title),
                    subtitle: Text(notes[index].date),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.favorite,
                              color: notes[index].isStarred
                                  ? Colors.redAccent
                                  : Colors.grey),
                          onPressed: () {
                            favoriteNote(index);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            _showDialog(notes[index].id);
                          },
                        )
                      ],
                    ),
                  ),
                ),
              );
            });
  }

  void favoriteNote(int idx) {
    toggleLoadingState();
    Map<String, dynamic> note = {
      'id': notes[idx].id,
      'isStarred': !notes[idx].isStarred
    };
    updateNote(note: note).then((_) {
      Navigator.of(context).pushNamed("home/all");
    });
    toggleLoadingState();
  }

  void toggleLoadingState() {
    setState(() {
      loading = !loading;
    });
  }

  void delete(id) async {
    toggleLoadingState();
    await deleteNote(id);
    toggleLoadingState();
    Navigator.of(context).pushNamed("home/all");
  }

  Future<void> _showDialog(String id) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete note'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Do you want to delete the note?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Yes',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
              style: ButtonStyle(
                backgroundColor: MaterialStatePropertyAll<Color>(
                  Theme.of(context).colorScheme.secondary,
                ),
              ),
              onPressed: () {
                delete(id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
