import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/notification_service.dart';
import 'core/theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';
import 'features/monetization/loading_ad_screen.dart';
import 'core/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  String supabaseUrl = AppConstants.supabaseUrl;
  String supabaseAnonKey = '';
  String? initError;

  try {
    // Correct path for asset-bundled .env
    await dotenv.load(fileName: ".env");
    supabaseUrl = dotenv.env['SUPABASE_URL'] ?? supabaseUrl;
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  } catch (e) {
    debugPrint('Config load failed: $e');
  }

  try {
    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    } else {
      initError = 'Missing Supabase configuration. Please check your .env file.';
    }

    await Firebase.initializeApp();
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Initialization failed: $e');
    initError ??= e.toString();
  }

  runApp(ChessTrainerApp(error: initError));
}

class ChessTrainerApp extends StatefulWidget {
  final String? error;
  const ChessTrainerApp({super.key, this.error});

  @override
  State<ChessTrainerApp> createState() => _ChessTrainerAppState();
}

class _ChessTrainerAppState extends State<ChessTrainerApp> {
  bool _showAd = true;

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (widget.error != null) {
      body = _BootstrapErrorScreen(error: widget.error!);
    } else if (_showAd) {
      body = LoadingAdScreen(onAdComplete: () => setState(() => _showAd = false));
    } else {
      body = StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = snapshot.data?.session;
          if (session != null) {
            return const HomeScreen();
          }
          return const AuthScreen();
        },
      );
    }

    return MaterialApp(
      title: 'Chess FR',
      theme: AppTheme.dark,
      home: body,
    );
  }
}

class _BootstrapErrorScreen extends StatelessWidget {
  final String error;
  const _BootstrapErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 80, color: Colors.redAccent),
            const SizedBox(height: 24),
            Text(
              'Initialization Failed',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ChessTrainerApp()),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
