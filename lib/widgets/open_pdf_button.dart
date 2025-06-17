import 'package:flutter/material.dart';

class OpenPdfButton extends StatelessWidget {
  final String? documentId;
  final String? projectName;
  final String? documentName;

  const OpenPdfButton({super.key, this.documentId, this.projectName, this.documentName});
  
  void _openPDF(BuildContext context, Map<String, dynamic> project) {
    final arguments = {
      'name': projectName,  // Projektname für Database-Lookup
      'id': documentId,     // Document ID für Database-Lookup
      'documentName': documentName, // Optional: Document Name falls bereits bekannt
    };
    
    Navigator.of(
      context,
    ).pushNamed('/pdfViewer', arguments: arguments);
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        _openPDF(context, {'name': projectName, 'id': documentId});
      },
      child: const Text('PDF öffnen'),
    );
  }
}