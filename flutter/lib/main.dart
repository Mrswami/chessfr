import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/notification_service.dart';
import 'core/theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';
import 'features/monetization/loading_ad_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    // TODO: Move to .env or --dart-define in production
    url: 'https://kticrtqrtnskgiqxewzd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt0aWNydHFydG5za2dpcXhld3pkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzNDQ4MTEsImV4cCI6MjA4NjkyMDgxMX0.cfwhQz5jzAW9gjWcGQQfLnoghcQrgqpicBdZ1u_ZBw0',
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
      title: 'ChessXL',
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
