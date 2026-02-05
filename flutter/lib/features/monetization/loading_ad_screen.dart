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
          
          // Ad Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Play "Last War: Survival Game"',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ).animate().fadeIn().moveY(begin: 10, end: 0),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                   // Open URL
                }, 
                style: FilledButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('INSTALL NOW'),
              ).animate().scale(delay: 500.ms),
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
