import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chessup_board_service.dart';
import 'game_projection_screen.dart';

class BoardConnectionScreen extends StatelessWidget {
  const BoardConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: ChessUpBoardService(),
      child: const _BoardConnectionContent(),
    );
  }
}

class _BoardConnectionContent extends StatelessWidget {
  const _BoardConnectionContent();

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ChessUpBoardService>();

    if (service.isConnected) {
      return GameProjectionScreen(
        fen: service.currentFen,
        logs: service.logs,
        liftedSquare: service.liftedSquare,
        onDisconnect: service.disconnect,
        onBack: () => Navigator.pop(context),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Connect Hardware'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(Icons.bluetooth_searching, size: 64, color: Colors.cyanAccent),
                const SizedBox(height: 16),
                const Text(
                  "Scanning for ChessUp Board",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  "Turn on your board to begin pairing.",
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
              ],
            ),
          ),

          // Scan Results
          Expanded(
            child: ListView.builder(
              itemCount: service.scanResults.length,
              itemBuilder: (context, index) {
                final result = service.scanResults[index];
                return ListTile(
                  leading: const Icon(Icons.check_box_outline_blank, color: Colors.cyanAccent),
                  title: Text(result.device.platformName, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(result.device.remoteId.toString(), style: const TextStyle(color: Colors.white54)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                  onTap: () => service.connect(result.device),
                );
              },
            ),
          ),

          // Scan Action
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: service.isScanning ? null : service.startScan,
                icon: service.isScanning 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
                label: Text(service.isScanning ? "SCANNING..." : "START SCAN"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.withOpacity(0.2),
                  foregroundColor: Colors.cyanAccent,
                  side: const BorderSide(color: Colors.cyanAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
