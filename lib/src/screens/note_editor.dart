import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
import '../ui/loading.dart';

class NoteEditorScreen extends StatefulWidget {
  final String id;
  NoteEditorScreen(this.id);
  @override
  _NoteEditorScreenState createState() => _NoteEditorScreenState(id);
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final String id;
  final _titleFieldController = TextEditingController();
  final _contentFieldController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _invalidTitle = false;
  String _invalidTitleText = "";
  bool _invalidContent = false;
  String _invalidContentText = "";
  bool loading = false;
  bool hasUnSavedChanges = true;
  bool isStarred = false;
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();
  _NoteEditorScreenState(this.id);
  @override
  void initState() {
    super.initState();
    if (id != "add") {
      setState(() {
        loading = true;
      });
      getNote(noteId: id).then((note) {
        setState(() {
          hasUnSavedChanges = false;
          loading = false;
          _titleFieldController.text = note!.title;
          _contentFieldController.text = note.body;
          isStarred = note.isStarred;
        });
      });
    } else {
      checkIfHadPreviousState();
    }
  }

  @override
  void dispose() async {
    super.dispose();

    if (hasUnSavedChanges) {
      await _saveToTempDB();
    }
    _titleFieldController.dispose();
    _contentFieldController.dispose();
    _scrollController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(
          onPressed: () {
            _goBack(context);
          },
        ),
        title: Text('Note editor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
            controller: _scrollController,
            scrollDirection: Axis.vertical,
            children: [
              TextField(
                controller: _titleFieldController,
                maxLength: 20,
                focusNode: _titleFocus,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
                decoration: InputDecoration(
                  icon: Icon(Icons.edit),
                  labelText: 'Title',
                  errorText: _invalidTitle ? _invalidTitleText : null,
                  labelStyle: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.7),
                  )),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                focusNode: _contentFocus,
                controller: _contentFieldController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 40.0),
                  icon: Icon(Icons.edit),
                  labelText: 'Content',
                  errorText: _invalidContent ? _invalidContentText : null,
                  labelStyle: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.7),
                  )),
                ),
              ),
              Container(
                child: Padding(
                  padding: EdgeInsets.all(10),
                ),
              ),
              Container(
                height: 40.0,
                margin: EdgeInsets.fromLTRB(15, 10, 15, 0),
                child: InkWell(
                  onTap: () {
                    onTab(context);
                  },
                  child: Material(
                    borderRadius: BorderRadius.circular(20.0),
                    shadowColor: Colors.white70,
                    color: Theme.of(context).colorScheme.secondary,
                    elevation: 7.0,
                    child: Center(
                      child: loading
                          ? Loading()
                          : Text(
                              'Done',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.tertiary,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Montserrat'),
                            ),
                    ),
                  ),
                ),
              ),
            ]),
      ),
    );
  }

  void onTab(BuildContext context) async {
    await _submit();
    _goBack(context);
  }

  bool _validate() {
    var textField = _titleFieldController.text.trim();
    var contentField = _contentFieldController.text;
    if (textField.isEmpty) {
      setState(() {
        _invalidTitleText = "Please enter a valid title.";
        _invalidTitle = true;
      });
      return false;
    }
    if (contentField.isEmpty || contentField.length < 5) {
      setState(() {
        _invalidContentText = "Content must be 5 at least characters long.";
        _invalidContent = true;
      });
      return false;
    }
    return true;
  }

  Future _submit() async {
    if (!_validate()) {
      return;
    }
    await saveOrUpdate();
    setState(() {
      hasUnSavedChanges = false;
    });
  }

  Future saveOrUpdate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool saveToWeb = prefs.getBool("saveToWeb") ?? true;
    if (saveToWeb) {
      await _createOrUpdate();
    } else {
      return _saveNoteLocal();
    }
    prefs.setBool("hasUnSavedChanges", false);
  }

  Future<bool> _createOrUpdate() async {
    toggleLoadingState();
    try {
      Map<String, dynamic> note = {
        'id': id,
        'title': _titleFieldController.text.trim(),
        'body': _contentFieldController.text,
        'date': DateTime.now().toString().split(" ").first,
        'isStarred': isStarred,
      };

      bool isMongoID = note['id'].length == 24;
      if (isMongoID) {
        await updateNote(
          note: note,
        );
        return true;
      } else {
        await createNote(
          note: note,
        );
        return true;
      }
    } catch (e) {
      return false;
    } finally {
      toggleLoadingState();
    }
  }

  Future _saveNoteLocal() async {
    var db = NotesDBProvider();
    await db.openTemp();
    await db.clearTemp();

    var note = {
      'id': id,
      'title': _titleFieldController.text.trim(),
      'body': _contentFieldController.text,
      'date': DateTime.now().toString().split(" ").first,
      'isStarred': isStarred ? 1 : 0,
    };

    debugPrint("note: $note");
    await db.open();
    if (note['id'] != "add") {
      await db.update(note);
    } else {
      note.remove('id');
      await db.insert(note);
    }
    await db.close();
  }

  void _goBack(BuildContext context) {
    Navigator.pushReplacementNamed(context, "home");
  }

  _saveToTempDB() async {
    var db = NotesDBProvider();
    await db.openTemp();
    await db.clearTemp();

    var title = _titleFieldController.text.trim();
    var content = _contentFieldController.text;

    // if the fields are empty abort
    if (title.isEmpty && content.isEmpty) {
      return;
    }
    var note = {
      'title': title,
      'body': content,
      'date': DateTime.now().toString().split(" ").first
    };
    await db.saveTemp(note);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("hasUnSavedChanges", true);
  }

  Future checkIfHadPreviousState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var db = NotesDBProvider();
    bool hasUnSavedChanges = prefs.getBool("hasUnSavedChanges") ?? false;

    if (hasUnSavedChanges) {
      await db.openTemp();
      var note = await db.getTemp();

      setState(() {
        _titleFieldController.text = note['title'];
        _contentFieldController.text = note['body'];
      });
    }
  }

  void toggleLoadingState() {
    setState(() {
      loading = !loading;
    });
  }
}
