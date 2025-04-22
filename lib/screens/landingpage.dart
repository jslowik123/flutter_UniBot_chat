import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/chatbot_tile.dart';
import 'package:intl/intl.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  LandingPageState createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref().child("files");
  final List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  String getFormattedDate() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('dd.MM.yyyy');
    return formatter.format(now);
  }

  // Projekte und ihre Dateien aus der Realtime Database laden
  Future<void> _fetchProjects() async {
    try {
      final snapshot = await _db.once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      setState(() {
        _projects.clear();
        if (data != null) {
          data.forEach((key, value) {
            _projects.add({
              'name': key.toString(),
              'data':
                  value, // Speichert die Daten des Projekts (falls vorhanden)
            });
          });
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Laden der Projekte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Neues Projekt zur Realtime Database hinzufügen
  Future<void> _addProject(String projectName) async {
    try {
      final newProjectRef = _db.child(projectName);
      await newProjectRef.set({"date": getFormattedDate()});
      await _fetchProjects();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Projekt "$projectName" erstellt'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Erstellen des Projekts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Projekt und alle zugehörigen Dateien löschen
  Future<void> _deleteProject(String projectName) async {
    try {
      await _db.child(projectName).remove();
      await _fetchProjects(); // Projekte neu laden nach dem Löschen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Projekt gelöscht'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Löschen des Projekts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Zu FileScreen navigieren
  void _viewProject(BuildContext context, Map<String, dynamic> project) {
    Navigator.of(
      context,
    ).pushNamed('/projectView', arguments: {'name': project['name']});
  }

  // Dialog zum Hinzufügen eines neuen Projekts
  void _showAddProjectDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Neues Projekt erstellen'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Projektname eingeben',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    await _addProject(name);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bitte einen Projektname eingeben'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Erstellen'),
              ),
            ],
          ),
    );
  }

  // Funktion zum Ändern des Projektnamens in Firebase
  Future<void> _updateProjectName(String oldName, String newName) async {
    try {
      final oldProjectRef = _db.child(oldName);
      final newProjectRef = _db.child(newName);

      // Kopiere die Daten von alt nach neu
      final snapshot = await oldProjectRef.once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;

      // Setze die neuen Projekt-Daten unter dem neuen Namen
      await newProjectRef.set(data);

      // Lösche das alte Projekt
      await oldProjectRef.remove();

      await _fetchProjects(); // Projekte neu laden nach dem Umbenennen

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Projekt "$newName" wurde umbenannt'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Umbenennen des Projekts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editProject(String projectName) async {
    final TextEditingController controller = TextEditingController();
    controller.text =
        projectName; // Setzt den aktuellen Projektnamen als Standard

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Projekt bearbeiten'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Neuen Projektnamen eingeben',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty && newName != projectName) {
                    await _updateProjectName(projectName, newName);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Bitte einen neuen Projektnamen eingeben',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Ändern'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projekte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddProjectDialog,
            tooltip: 'Neues Projekt hinzufügen',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _projects.isEmpty
                  ? const Center(child: Text('Keine Projekte vorhanden'))
                  : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _projects.length,
                    itemBuilder: (context, index) {
                      return ProjectTile(
                        project: _projects[index],
                        viewProjectFunc: _viewProject,
                        deleteProjectFunc: _deleteProject,
                        editProjectFunc: _editProject,
                      );
                    },
                  ),
        ),
      ),
    );
  }
}
