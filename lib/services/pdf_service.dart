import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class PdfService {
  Future<Uint8List?> downloadPdfFromFirebase(String projectName, String documentID) async {
  try {
    // Referenz zum Firebase Storage Pfad
    final storageRef = FirebaseStorage.instance.ref().child("files/${projectName}/${documentID}");
    
    // Lade das PDF als Bytes herunter (max. 10 MB, anpassbar)
    final Uint8List? pdfBytes = await storageRef.getData(10 * 1024 * 1024);
    
    if (pdfBytes == null) {
      print('Keine Daten empfangen');
      return null;
    }
    
    return pdfBytes;
  } catch (e) {
    print('Fehler beim Herunterladen des PDFs: $e');
    return null;
  }
}
}