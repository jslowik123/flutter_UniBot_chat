import 'package:flutter/material.dart';

class CitationCard extends StatelessWidget {
  final String? source;
  final String? documentId;

  const CitationCard({
    super.key,
    this.source,
    this.documentId,
  });

  @override
  Widget build(BuildContext context) {
    // Falls beide null sind, verstecke die Card
    if (source == null && documentId == null) {
      return const SizedBox.shrink();
    }

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
          if (source != null) ...[
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
                Text(
                  'ID: $documentId',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}