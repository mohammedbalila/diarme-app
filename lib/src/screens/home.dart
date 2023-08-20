import 'dart:async';
import 'package:diarme/src/models/note.dart';
import 'package:diarme/src/models/user.dart';
import 'package:diarme/src/ui/loading.dart';
import 'package:diarme/src/ui/note_list.dart';
import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:provider/provider.dart';
import '../providers/shared_prefs.dart';

class HomeScreen extends StatefulWidget {
  final String type;
  HomeScreen(this.type);
  @override
  State<StatefulWidget> createState() => _HomePageState(type);
}

class _HomePageState extends State<HomeScreen> {
  _HomePageState(this.type);

  late final String type;
  bool loading = false;
  List<Note> notes = [];
  String title = 'Home';

  @override
  void initState() {
    super.initState();
    fetchNotes(type);
  }

  void toggleLoadingState() {
    setState(() {
      loading = !loading;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        onPressed: () {
          Navigator.of(context).pushReplacementNamed("notes/add");
        },
        child: const Icon(Icons.add),
      ),
      drawer: Consumer<SharedPrefsProvider>(
        builder: (context, provider, child) {
          provider.loadPrefs(context);
          return HomeDrawer();
        },
      ),
      body: LiquidPullToRefresh(
        onRefresh: () {
          fetchNotes(type);
          return Future(() => null);
        },
        showChildOpacityTransition: true,
        child: loading
            ? Center(
                child: Loading(),
              )
            : NoteList(notes: notes),
      ),
    );
  }

  Future<void> fetchNotes(String type) async {
    toggleLoadingState();
    if (type == 'local') {
      List notes = await getLocalNotes();
      setState(() {
        title = 'Local';
        notes = notes;
      });
    } else {
      bool isFavorite = type == 'favorite' ? true : false;
      List<Note> _notes = await getNotes(isStarred: isFavorite);
      setState(() {
        title = isFavorite ? 'Favorite' : 'Home';
        notes = _notes;
      });
    }
    toggleLoadingState();
  }

  Future<List<Note>> getLocalNotes() async {
    var db = NotesDBProvider();
    await db.open();
    List<Note> notes = await db.getNotes();
    return notes;
  }
}

class HomeDrawer extends StatefulWidget {
  HomeDrawer({
    super.key,
  });

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  String greeting = 'Good morning';

  String bgImage = 'day.png';

  @override
  void initState() {
    super.initState();
    int hour = DateTime.now().hour;
    checkTime(hour);
    Timer.periodic(Duration(hours: 1), (Timer t) {
      hour = DateTime.now().hour;
      checkTime(hour);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // backgroundColor: Theme.of(context).colorScheme.s,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                image: AssetImage('assets/$bgImage'),
                fit: BoxFit.cover,
              ),
            ),
            child: ListView(
              children: [
                Text(
                  'Diarme',
                  style: TextStyle(
                      fontFamily: 'Satisfy',
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 30),
                ),
                const SizedBox(height: 40.0),
                Text(
                  greeting,
                  style: const TextStyle(
                      fontFamily: 'Pangolin',
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      fontSize: 20),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.home,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: const Text('Home'),
            onTap: () => goHome(context),
          ),
          ListTile(
            leading: Icon(
              Icons.star,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: const Text('Starred notes'),
            onTap: () => getFavoriteNotes(context),
          ),
          ListTile(
            leading: Icon(
              Icons.phonelink_lock,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: const Text('Local notes'),
            onTap: () => getLocalNotes(context),
          ),
          ListTile(
            leading: Icon(
              Icons.settings,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pushReplacementNamed(context, "settings");
              // ));
            },
          ),
        ],
      ),
    );
  }

  void getFavoriteNotes(context) {
    Navigator.pushReplacementNamed(context, "home/favorite");
  }

  void getLocalNotes(context) {
    Navigator.pushReplacementNamed(context, "home/local");
  }

  void goHome(context) {
    Navigator.pushReplacementNamed(context, "home/all");
  }

  void checkTime(int hour) async {
    var db = UserDBProvider();
    await db.open();
    User? user = await db.getUser();
    String username =
        '${user?.username[0].toUpperCase()}${user?.username.substring(1).toLowerCase()}';

    String greetingText = '';
    String image = '';
    if (hour > 3 && hour <= 10) {
      greetingText = 'Good morning';
      image = 'day.png';
    }
    if (hour > 10 && hour <= 16) {
      greetingText = 'Good afternoon';
      image = 'afternoon.png';
    }
    if (hour > 16 && hour <= 18) {
      greetingText = 'Good evening';
      image = 'evening.png';
    }
    if (hour > 17 || hour <= 3) {
      greetingText = 'Good night';
      image = 'night.png';
    }

    setState(() {
      greeting = '$greetingText, $username';
      bgImage = image;
    });
  }
}
