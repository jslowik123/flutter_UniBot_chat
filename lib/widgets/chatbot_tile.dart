import 'package:flutter/material.dart';

class ProjectTile extends StatelessWidget {
  final Map<String, dynamic> project;
  final Function viewProjectFunc;
  final Function deleteProjectFunc;
  final Function editProjectFunc;

  const ProjectTile({
    super.key,
    required this.project,
    required this.viewProjectFunc,
    required this.deleteProjectFunc,
    required this.editProjectFunc,
  });

  @override
  Widget build(BuildContext context) {
    // Datum aus den Projekt-Daten holen
    final String? date = project['data']?['date'];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      child: ListTile(
        onTap: () => viewProjectFunc(context, project),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.work, color: Colors.blueAccent),
        ),
        title: Text(
          project['name'],
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        // Ersetze den Text 'Projekt Details' mit dem Datum
        subtitle: Text(
          date ??
              'Kein Datum verfügbar', // Falls kein Datum vorhanden ist, wird dieser Text angezeigt
          style: TextStyle(color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                editProjectFunc(project['name']); // Projekt umbenennen
              },
              tooltip: 'Projekt bearbeiten',
            ),

            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => deleteProjectFunc(project["name"]),
              tooltip: 'Projekt löschen',
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
      ),
    );
  }
}
