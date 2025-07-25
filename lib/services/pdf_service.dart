import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

/// Container für PDF-Informationen
class PdfInfo {
  final String storageUrl;
  final String? name;

  PdfInfo({required this.storageUrl, this.name});
}

class PdfService {
  /// Lädt ein PDF basierend auf der Document ID
  /// Sucht erst in der Firebase Database nach der storageURL
  /// und lädt dann das PDF direkt von dieser URL
  Future<Uint8List?> downloadPdfByDocumentId(String projectName, String documentId) async {
    try {
      // 1. Erst in der Database nach den PDF-Informationen suchen
      final pdfInfo = await _getPdfInfoFromDatabase(projectName, documentId);
      
      if (pdfInfo == null) {
        return null;
      }
      
      // 2. PDF direkt von der storageURL herunterladen
      return await _downloadPdfFromUrl(pdfInfo.storageUrl);
      
    } catch (e) {
      return null;
    }
  }

  /// Holt PDF-Informationen (URL + Name) für eine Document ID
  Future<PdfInfo?> getPdfInfoByDocumentId(String projectName, String documentId) async {
    try {
      return await _getPdfInfoFromDatabase(projectName, documentId);
    } catch (e) {
      return null;
    }
  }

  /// Lädt PDF von der Firebase Storage URL herunter
  Future<Uint8List?> _downloadPdfFromUrl(String url) async {
    try {
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        return bytes;
      } else {
        return null;
      }
      
    } catch (e) {
      return null;
    }
  }

  /// Sucht die PDF-Informationen (storageURL + Name) für ein Dokument in der Database
  Future<PdfInfo?> _getPdfInfoFromDatabase(String projectName, String documentId) async {
    try {
      final DatabaseReference dbRef = FirebaseDatabase.instance
          .ref()
          .child('files')
          .child(projectName)
          .child(documentId);
      
      final snapshot = await dbRef.once();
      final data = snapshot.snapshot.value;
      
      if (data == null) {
        return null;
      }
      
      // Nach storageURL und PDF-Name suchen
      String? storageUrl;
      String? pdfName;
      
      if (data is Map) {
        storageUrl = data['storageURL']?.toString();
        // Verschiedene mögliche Felder für den PDF-Namen prüfen
        pdfName = data['name']?.toString() ?? 
                  data['filename']?.toString() ?? 
                  data['pdfName']?.toString() ?? 
                  data['originalName']?.toString();
      }
      
      if (storageUrl == null) {
        return null;
      }
      
      return PdfInfo(storageUrl: storageUrl, name: pdfName);
      
    } catch (e) {
      return null;
    }
  }

  /// Legacy-Methode: Lädt PDF direkt über project/document Pfad (für Rückwärtskompatibilität)
  Future<Uint8List?> downloadPdfFromFirebase(String projectName, String documentID) async {
    try {
      // Referenz zum Firebase Storage Pfad
      final storagePath = "files/$projectName/$documentID";
      
      return await _downloadPdfFromStorage(storagePath);
      
    } catch (e) {
      return null;
    }
  }

  /// Lädt das PDF direkt aus Firebase Storage über den Storage-Pfad (Legacy)
  Future<Uint8List?> _downloadPdfFromStorage(String storagePath) async {
    try {
      
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
      
      final Uint8List? pdfBytes = await storageRef.getData(10 * 1024 * 1024);
      
      if (pdfBytes == null) {
        return null;
      }
      
      return pdfBytes;
      
    } catch (e) {
      return null;
    }
  }
}