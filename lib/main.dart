import 'package:flutter/material.dart';
import 'screens/landingpage.dart';
import 'screens/llm_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/pdf_viewer.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChatBots',
      theme: ThemeData(
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/llmInterface': (context) => const LLMInterface(),
        '/pdfViewer': (context) => const PdfViewer(),
      },
    );
  }
}
