import 'package:flutter/material.dart';
import 'open_pdf_button.dart';

class CitationCard extends StatelessWidget {
  final String? source;
  final String? documentId;
  final String? projectName;
  final String? documentName;

  const CitationCard({
    super.key,
    this.source,
    this.documentId,
    this.projectName,
    this.documentName,
  });


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_quote,
                size: 16,
                color: Colors.blue[600],
              ),
              const SizedBox(width: 6),
              Text(
                'Quelle',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          if (source != null && source!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              source!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.3,
              ),
            ),
          ],
          if (documentId != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Builder(
                  builder: (context) {
                    return OpenPdfButton(projectName: projectName, documentId: documentId, documentName: documentName,);
                  }
                )
              ],
            ),
          ],
        ],
      ),
    );
  }
}