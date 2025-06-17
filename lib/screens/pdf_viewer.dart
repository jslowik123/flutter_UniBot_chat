import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/pdf_service.dart';

class PdfViewer extends StatefulWidget {
  const PdfViewer({super.key});

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  Uint8List? pdfBytes;
  String? pdfPath;
  bool isLoading = true;
  String? errorMessage;
  String? documentName;
  PDFViewController? _pdfViewController;
  final PdfService _pdfService = PdfService();
  int currentPage = 0;
  int totalPages = 0;
  bool isPdfReady = false; // Neuer State für PDF-Bereitschaft

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPdfData();
  }

  Future<void> _loadPdfData() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args != null && args['name'] != null && args['id'] != null) {
      final projectName = args['name'] as String;
      final documentId = args['id'] as String;
      final startPage = args['page'] as int? ?? 0; // Optional: Startseite
    
      setState(() {
        currentPage = startPage;
        isLoading = true;
        errorMessage = null;
        documentName = 'PDF wird geladen...'; // Temporärer Titel während des Ladens
        isPdfReady = false;
      });

      try {
        
        // 1. Erst PDF-Informationen (inkl. Name) laden
        final pdfInfo = await _pdfService.getPdfInfoByDocumentId(projectName, documentId);
        
        if (pdfInfo == null) {
          print('❌ Keine PDF-Informationen gefunden');
          setState(() {
            errorMessage = 'PDF konnte nicht gefunden werden';
            isLoading = false;
            documentName = 'PDF nicht gefunden';
          });
          return;
        }
        
        // 2. PDF-Namen aus der Database setzen
        setState(() {
          documentName = pdfInfo.name ?? 'Unbenanntes PDF';
        });
        
        // 3. PDF-Bytes herunterladen
        final bytes = await _pdfService.downloadPdfByDocumentId(projectName, documentId);
        
        if (bytes != null) {
          // Save bytes to temporary file for flutter_pdfview
          final tempDir = await getTemporaryDirectory();
          
          final file = File('${tempDir.path}/$documentId.pdf');
          
          await file.writeAsBytes(bytes);
          
          setState(() {
            pdfBytes = bytes;
            pdfPath = file.path;
            isLoading = false;
          });
        } else {
          print('❌ Keine PDF-Bytes empfangen');
          setState(() {
            errorMessage = 'PDF konnte nicht geladen werden';
            isLoading = false;
            documentName = 'Fehler beim Laden';
          });
        }
      } catch (e) {
        print('❌ Fehler beim Laden des PDFs: $e');
        setState(() {
          errorMessage = 'Fehler beim Laden des PDFs: $e';
          isLoading = false;
          documentName = 'Fehler';
        });
      }
    } else {
      print('❌ Ungültige oder fehlende Route-Parameter');
      print('❌ args: $args');
      setState(() {
        errorMessage = 'Ungültige Parameter';
        isLoading = false;
        documentName = 'Ungültige Parameter';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(documentName ?? 'PDF Viewer'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
      bottomNavigationBar: pdfPath != null && isPdfReady ? _buildBottomNavigationBar() : null,
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('PDF wird geladen...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPdfData,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (pdfPath != null) {
      return Container(
        color: Colors.grey[200],
        child: PDFView(
          filePath: pdfPath!,
          enableSwipe: true,
          swipeHorizontal: true,
          autoSpacing: false,
          pageFling: true,
          pageSnap: true,
          defaultPage: currentPage,
          fitPolicy: FitPolicy.BOTH,
          preventLinkNavigation: false,
          onRender: (pages) {
            setState(() {
              totalPages = pages!;
              // Initial currentPage korrekt setzen (1-basiert für Anzeige)
              if (currentPage == 0) {
                currentPage = 1;
              }
              isPdfReady = true; // PDF ist jetzt bereit für Navigation
            });
          },
          onError: (error) {
            print('❌ PDF Render-Fehler: $error');
            setState(() {
              errorMessage = 'PDF Anzeigefehler: $error';
            });
          },
          onPageError: (page, error) {
            print('❌ PDF Seiten-Fehler - Seite $page: $error');
            setState(() {
              errorMessage = 'Seite $page Fehler: $error';
            });
          },
          onViewCreated: (PDFViewController pdfViewController) {  
            _pdfViewController = pdfViewController;
            
            // Kleine Verzögerung, um sicherzustellen, dass alles initialisiert ist
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                setState(() {
                  // Zusätzliche Bereitschaftsprüfung
                });
              }
            });
          },
          onLinkHandler: (String? uri) {
            // Handle link clicks
          },
          onPageChanged: (int? page, int? total) {
          print('📄 Seite geändert: ${page! + 1} von $total');
            setState(() {
              currentPage = page + 1;
              totalPages = total!;
            });
          },
        ),
      );
    }

    return const Center(
      child: Text('Kein PDF verfügbar'),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 60,
      color: Colors.blue[600],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.first_page, color: Colors.white),
            onPressed: isPdfReady && _pdfViewController != null ? () async {
              print('📄 Springe zur ersten Seite');
              await _pdfViewController!.setPage(0);
            } : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: isPdfReady && _pdfViewController != null && currentPage > 1 ? () async {
              print('📄 Springe zur vorherigen Seite (${currentPage - 1})');
              await _pdfViewController!.setPage(currentPage - 2);
            } : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Seite $currentPage / $totalPages',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: isPdfReady && _pdfViewController != null && currentPage < totalPages ? () async {
              print('📄 Springe zur nächsten Seite (${currentPage + 1})');
              await _pdfViewController!.setPage(currentPage);
            } : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page, color: Colors.white),
            onPressed: isPdfReady && _pdfViewController != null && totalPages > 0 ? () async {
              print('📄 Springe zur letzten Seite ($totalPages)');
              await _pdfViewController!.setPage(totalPages - 1);
            } : null,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    print('📄 PDF Viewer wird disposed');
    // Clean up temporary PDF file
    if (pdfPath != null) {
      print('📄 Lösche temporäre PDF-Datei: $pdfPath');
      final file = File(pdfPath!);
      if (file.existsSync()) {
        file.deleteSync();
        print('📄 Temporäre PDF-Datei erfolgreich gelöscht');
      } else {
        print('📄 Temporäre PDF-Datei existiert nicht mehr');
      }
    }
    super.dispose();
  }
}