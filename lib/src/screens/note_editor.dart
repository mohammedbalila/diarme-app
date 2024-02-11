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
  bool isStarred = false;
  bool hasUnSavedChanges = true;
  bool servedFromCache = false;
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
      getNote(noteId: id).then((response) {
        Note note = response["note"];
        setState(() {
          hasUnSavedChanges = false;
          servedFromCache = response["servedFromCache"];
          loading = false;
          _titleFieldController.text = note.title;
          _contentFieldController.text = note.body;
          isStarred = note.isStarred;
        });
      });
    }
  }

  @override
  void dispose() async {
    super.dispose();

    if (hasUnSavedChanges) {
      await _submit();
    }
    _titleFieldController.dispose();
    _contentFieldController.dispose();
    _scrollController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(
          onPressed: () {
            saveNote(context);
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
              ListTile(
                leading: Icon(Icons.edit),
                title: Text(
                  "Title",
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              TextField(
                controller: _titleFieldController,
                maxLength: 150,
                focusNode: _titleFocus,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(158, 229, 178, 133),
                  errorText: _invalidTitle ? _invalidTitleText : null,
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.7),
                  )),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text(
                  "Content",
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              SizedBox(
                height: mediaQueryData.size.height * 0.50, // 50%
                child: TextField(
                  focusNode: _contentFocus,
                  controller: _contentFieldController,
                  keyboardType: TextInputType.multiline,
                  expands: true, // and this
                  maxLines: null,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.secondary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color.fromARGB(158, 229, 178, 133),
                    errorText: _invalidContent ? _invalidContentText : null,
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.7),
                    )),
                  ),
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
                    saveNote(context);
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

  void saveNote(BuildContext context) async {
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
    await _createOrUpdate();
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

      bool isAdd = note['id'] == "add";
      if (isAdd) {
        await createNote(note: note);
        return true;
      } else {
        await updateNote(note: note);
        return true;
      }
    } catch (e) {
      return false;
    } finally {
      toggleLoadingState();
    }
  }

  void _goBack(BuildContext context) {
    Navigator.pushReplacementNamed(context, "home");
  }

  void toggleLoadingState() {
    setState(() {
      loading = !loading;
    });
  }
}
