import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/auth/splash_screen.dart'; // Adjust path if needed

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    // Initialize with direct Web configuration keys from Firebase Console
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAknd8RBj-tdsR2241Bi9yUrDqQxKu52aA",
        appId: "1:392581525231:web:2ccc6eb384258ac191b51a",
        messagingSenderId: "392581525231",
        projectId: "tech-trader-3ee76",
        authDomain: "tech-trader-3ee76.firebaseapp.com",
        storageBucket: "tech-trader-3ee76.firebasestorage.app",
      ),
    );
  } else {
    // For Android/iOS (uses your google-services.json / GoogleService-Info.plist automatically)
    await Firebase.initializeApp();
  } // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Talent Bridge',
      home: const SplashScreen(),
    );
  }
}