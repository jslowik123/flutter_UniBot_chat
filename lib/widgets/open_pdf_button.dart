import 'package:flutter/material.dart';

class OpenPdfButton extends StatelessWidget {
  final String? documentId;
  final String? projectName;

  const OpenPdfButton({super.key, this.documentId, this.projectName});
  
  void _openPDF(BuildContext context, Map<String, dynamic> project) {
    Navigator.of(
      context,
    ).pushNamed('/pdfViewer', arguments: {'name': projectName, 'id': documentId});
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _openPDF(context, {'name': projectName, 'id': documentId});
      },
      child: const Text('PDF öffnen'),
    );
  }
}