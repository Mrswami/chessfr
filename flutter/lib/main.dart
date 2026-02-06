import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';
import 'features/monetization/loading_ad_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    // TODO: Move to .env or --dart-define in production
    url: 'https://jcrkoclchttokwzeddlr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpjcmtvY2xjaHR0b2t3emVkZGxyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAzMDIyNzEsImV4cCI6MjA4NTg3ODI3MX0.9atZ2PCTdXjC862CqRYo5WAsOtyBFanITy-iwVfEiPA',
  );

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
      title: 'Chess Trainer',
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
