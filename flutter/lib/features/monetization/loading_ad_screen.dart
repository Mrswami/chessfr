import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoadingAdScreen extends StatefulWidget {
  final VoidCallback onAdComplete;

  const LoadingAdScreen({super.key, required this.onAdComplete});

  @override
  State<LoadingAdScreen> createState() => _LoadingAdScreenState();
}

class _LoadingAdScreenState extends State<LoadingAdScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate ad duration
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onAdComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image (Placeholder)
          Container(
            color: const Color(0xFF1A1A1A),
            child: const Center(
              child: Icon(Icons.gamepad, size: 100, color: Colors.white24),
            ),
          ),
          
          // Wisdom Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.tips_and_updates_rounded, size: 60, color: Colors.amber),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  '"Not being afraid isn\'t the same as being confident. You have to be both."',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn().moveY(begin: 10, end: 0),
              const SizedBox(height: 16),
              const Text(
                '— Magnus Carlsen',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),

          // Loading Indicator / Skip
          Positioned(
            bottom: 40,
            left: 0, 
            right: 0,
            child: Center(
              child: const CircularProgressIndicator(color: Colors.white)
                  .animate()
                  .fadeIn(),
            ),
          ),
        ],
      ),
    );
  }
}
