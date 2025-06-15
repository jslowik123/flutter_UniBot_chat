import 'package:flutter/material.dart';

class OpenPdfButton extends StatelessWidget {
  final String? documentId;
  final String? projectName;
  final String? documentName;

  const OpenPdfButton({super.key, this.documentId, this.projectName, this.documentName});
  
  void _openPDF(BuildContext context, Map<String, dynamic> project) {
    print('🔗 _openPDF wurde aufgerufen');
    print('🔗 Project Name: "$projectName"');
    print('🔗 Document ID: "$documentId"');
    print('🔗 Document Name: "$documentName"');
    
    final arguments = {
      'name': projectName,  // Projektname für Database-Lookup
      'id': documentId,     // Document ID für Database-Lookup
      'documentName': documentName, // Optional: Document Name falls bereits bekannt
    };
    
    print('🔗 Arguments: $arguments');
    
    Navigator.of(
      context,
    ).pushNamed('/pdfViewer', arguments: arguments);
    
    print('🔗 Navigation zu /pdfViewer gestartet');
  }

  @override
  Widget build(BuildContext context) {
    print('🔗 OpenPdfButton build() - projectName: "$projectName", documentId: "$documentId"');
    return TextButton(
      onPressed: () {
        print('🔗 PDF öffnen Button gedrückt');
        _openPDF(context, {'name': projectName, 'id': documentId});
      },
      child: const Text('PDF öffnen'),
    );
  }
}