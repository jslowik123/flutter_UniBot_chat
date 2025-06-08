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

  Future<void> _fetchProjects() async {
    try {
      final snapshot = await _db.once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      setState(() {
        _projects.clear();
        if (data != null) {
          data.forEach((key, value) {
            _projects.add({'name': key.toString(), 'data': value});
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
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    }
  }

  void _openChatbot(BuildContext context, Map<String, dynamic> project) {
    Navigator.of(
      context,
    ).pushNamed('/llmInterface', arguments: {'name': project['name']});
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text('Chatbots'), actions: []),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child:
              _isLoading
                  ? Center(
                    child: CircularProgressIndicator(
                    ),
                  )
                  : _projects.isEmpty
                  ? Center(
                    child: Text(
                      'Keine Projekte vorhanden',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _projects.length,
                    itemBuilder: (context, index) {
                      return ChatbotTile(
                        chatbot: _projects[index],
                        openChatFunc: _openChatbot,
                      );
                    },
                  ),
        ),
      ),
    );
  }
}
