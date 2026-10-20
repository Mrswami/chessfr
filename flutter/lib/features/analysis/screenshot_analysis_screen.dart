import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../logic/gemini_chess_service.dart';
import '../../core/theme.dart';

/// Screen for submitting chess position screenshots to DankFish (Gemini)
/// for grounded psychological and tactical analysis.
class ScreenshotAnalysisScreen extends StatefulWidget {
  final GeminiChessService geminiService;

  const ScreenshotAnalysisScreen({super.key, required this.geminiService});

  @override
  State<ScreenshotAnalysisScreen> createState() =>
      _ScreenshotAnalysisScreenState();
}

class _ScreenshotAnalysisScreenState extends State<ScreenshotAnalysisScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  ChessAnalysisResult? _result;
  bool _isAnalyzing = false;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (picked == null) return;
      setState(() {
        _selectedImage = File(picked.path);
        _result = null;
        _errorMessage = null;
      });
      await _analyze();
    } catch (e) {
      setState(() => _errorMessage = 'Could not pick image: $e');
    }
  }

  Future<void> _analyze() async {
    if (_selectedImage == null) return;
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });
    try {
      final result = await widget.geminiService.analyzeScreenshot(_selectedImage!);
      setState(() {
        _result = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = 'Analysis failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        title: Text(
          '🧠 DankFish Analysis',
          style: GoogleFonts.outfit(
            color: AppTheme.primaryTeal,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildImagePickerCard(),
            const SizedBox(height: 16),
            if (_isAnalyzing) _buildAnalyzingIndicator(),
            if (_errorMessage != null) _buildErrorCard(),
            if (_result != null && !_isAnalyzing) _buildResultsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryTeal.withOpacity(0.15),
            Colors.transparent,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submit a Chess Screenshot',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Grounded in your ChessLessons knowledge base. DankFish will identify openings, psychological patterns, blindspot lineages, and opponent archetypes.',
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildImagePickerCard() {
    return Column(
      children: [
        if (_selectedImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _selectedImage!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: () => _pickImage(ImageSource.gallery),
                color: AppTheme.primaryTeal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                onTap: () => _pickImage(ImageSource.camera),
                color: AppTheme.accentGold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyzingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'DankFish is scanning the matrix...',
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    ).animate().fadeIn().shimmer(duration: 1200.ms);
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPanel() {
    final r = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Vibe Header
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.suggestedName.replaceAll('_', ' '),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (r.cavernDetected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orangeAccent),
                      ),
                      child: Text(
                        '⚠ CAVERN',
                        style: GoogleFonts.outfit(
                          color: Colors.orangeAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _InfoRow('Opening', r.openingDetected),
              _InfoRow('Side to Move', r.sideToMove),
              _InfoRow('Psychological Vibe', r.psychologicalVibe),
              _InfoRow('Opponent Archetype', r.opponentArchetype),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // C.O.R.E. Score
        _SectionCard(
          title: '⚙️ C.O.R.E. Score',
          child: Column(
            children: [
              _CoreRow('Center Dynamics', r.coreScore.centerDynamics),
              _CoreRow('Operational Space', r.coreScore.operationalSpace),
              _CoreRow('Red-Mist Trigger', r.coreScore.redMistTrigger,
                  highlight: r.coreScore.redMistTrigger == 'High'),
              _CoreRow('Endgame Integrity', r.coreScore.endgameIntegrity),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Patterns & Blindspots
        if (r.patternsDetected.isNotEmpty || r.blindspotFlags.isNotEmpty)
          _SectionCard(
            title: '🎯 Detected Patterns & Blindspots',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (r.patternsDetected.isNotEmpty) ...[
                  Text(
                    'Patterns',
                    style: GoogleFonts.outfit(
                      color: AppTheme.primaryTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: r.patternsDetected
                        .map((p) => _TagChip(p, AppTheme.primaryTeal))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                ],
                if (r.blindspotFlags.isNotEmpty) ...[
                  Text(
                    'Blindspot Lineage',
                    style: GoogleFonts.outfit(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: r.blindspotFlags
                        .map((b) => _TagChip(b, Colors.orangeAccent))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 12),
        // Coaching Priority
        _SectionCard(
          title: '📌 Coaching Priority',
          child: Text(
            r.coachingPriority,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
          ),
        ),
        const SizedBox(height: 12),
        // Structural Lesson
        _SectionCard(
          title: '📚 Structural Lesson',
          child: Text(
            r.structuralLesson,
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Tags
        if (r.tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: r.tags
                .map((t) => _TagChip(t, Colors.white30))
                .toList(),
          ),
        const SizedBox(height: 30),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

// ── Reusable Sub-Widgets ──────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;

  const _SectionCard({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: GoogleFonts.outfit(
                color: AppTheme.primaryTeal,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoreRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _CoreRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final color = highlight ? Colors.redAccent : Colors.white70;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text(
              value,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TagChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label.replaceAll('_', ' '),
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
