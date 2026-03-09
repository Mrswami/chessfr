import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/notification_service.dart';
import 'core/theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';
import 'features/monetization/loading_ad_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: "flutter/.env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  try {
    await Firebase.initializeApp();
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase init failed (Missing config?): $e');
  }

  runApp(const ChessTrainerApp());
}

class ChessTrainerApp extends StatefulWidget {
  const ChessTrainerApp({super.key});

  @override
  State<ChessTrainerApp> createState() => _ChessTrainerAppState();
}

class _ChessTrainerAppState extends State<ChessTrainerApp> {
  bool _showAd = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess Personal Trainer',
      theme: AppTheme.dark,
      home: _showAd 
        ? LoadingAdScreen(onAdComplete: () => setState(() => _showAd = false))
        : StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, snapshot) {
              final session = snapshot.data?.session;
              if (session != null) {
                return const HomeScreen();
              }
              return const AuthScreen();
            },
          ),
    );
  }
}
