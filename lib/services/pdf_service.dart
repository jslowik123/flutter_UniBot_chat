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
      print('🔍 Suche PDF-Informationen in Firebase Database...');
      final pdfInfo = await _getPdfInfoFromDatabase(projectName, documentId);
      
      if (pdfInfo == null) {
        print('❌ Keine PDF-Informationen für Document ID "$documentId" gefunden');
        return null;
      }
      
      print('✅ PDF-Informationen gefunden:');
      print('   - StorageURL: "${pdfInfo.storageUrl}"');
      print('   - Name: "${pdfInfo.name ?? 'Unbekannt'}"');
      
      // 2. PDF direkt von der storageURL herunterladen
      return await _downloadPdfFromUrl(pdfInfo.storageUrl);
      
    } catch (e) {
      print('❌ Fehler beim Laden des PDFs: $e');
      return null;
    }
  }

  /// Holt PDF-Informationen (URL + Name) für eine Document ID
  Future<PdfInfo?> getPdfInfoByDocumentId(String projectName, String documentId) async {
    try {
      print('🔍 Hole PDF-Informationen für Document ID "$documentId"...');
      return await _getPdfInfoFromDatabase(projectName, documentId);
    } catch (e) {
      print('❌ Fehler beim Abrufen der PDF-Informationen: $e');
      return null;
    }
  }

  /// Lädt PDF von der Firebase Storage URL herunter
  Future<Uint8List?> _downloadPdfFromUrl(String url) async {
    try {
      print('🌐 Lade PDF von storageURL: "$url"');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        print('✅ PDF erfolgreich heruntergeladen - Größe: ${bytes.length} bytes');
        return bytes;
      } else {
        print('❌ HTTP Fehler beim Download: ${response.statusCode}');
        return null;
      }
      
    } catch (e) {
      print('❌ Fehler beim Herunterladen des PDFs: $e');
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
      
      print('🔍 Database Query Path: files/$projectName/$documentId');
      
      final snapshot = await dbRef.once();
      final data = snapshot.snapshot.value;
      
      print('🔍 Database Response: $data');
      
      if (data == null) {
        print('❌ Kein Dokument mit ID "$documentId" in der Database gefunden');
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
        print('❌ Keine storageURL im Dokument gefunden. Verfügbare Felder: ${data is Map ? data.keys.toList() : 'N/A'}');
        return null;
      }
      
      return PdfInfo(storageUrl: storageUrl, name: pdfName);
      
    } catch (e) {
      print('❌ Fehler beim Abrufen der PDF-Informationen aus der Database: $e');
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
      print('❌ Fehler in Legacy-Methode: $e');
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