import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/patterns_provider.dart';

class PatternsLibraryScreen extends StatefulWidget {
  const PatternsLibraryScreen({super.key});

  @override
  State<PatternsLibraryScreen> createState() => _PatternsLibraryScreenState();
}

class _PatternsLibraryScreenState extends State<PatternsLibraryScreen> {
  final PatternsProvider _provider = PatternsProvider();
  String _selectedCategory = 'Tactics and Techniques';
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _provider.loadPatterns();
    if (mounted) {
      setState(() {
        final categories = _provider.getCategories();
        if (categories.isNotEmpty) {
           // Find a good default category if 'Tactics' doesn't exist
           if (!categories.contains(_selectedCategory)) {
             _selectedCategory = categories.first;
           }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "PATTERN ORACLE",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0B1E), // Deep Obsidian Purple
              Color(0xFF1A1230),
              Color(0xFF0D0221), // Black hole depth
            ],
          ),
        ),
        child: _provider.isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C22F5)))
            : Column(
                children: [
                  const SizedBox(height: 100),
                  _buildCategoryScroller(),
                  Expanded(
                    child: _buildPatternGrid(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCategoryScroller() {
    final categories = _provider.getCategories();
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6C22F5).withOpacity(0.8) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected ? const Color(0xFFBC9AFF) : Colors.white10,
                  width: 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: const Color(0xFF6C22F5).withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ] : [],
              ),
              child: Center(
                child: Text(
                  cat.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected ? Colors.white : Colors.white60,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPatternGrid() {
    final patterns = _provider.getByCategory(_selectedCategory);
    if (patterns.isEmpty) {
      return Center(
        child: Text(
          "The Oracle is silent in this realm...",
          style: GoogleFonts.outfit(color: Colors.white38),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: patterns.length,
      itemBuilder: (context, index) {
        final p = patterns[index];
        return _buildPatternCard(p);
      },
    );
  }

  Widget _buildPatternCard(ChessPattern p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPatternDetail(p),
          child: Stack(
            children: [
              // Subtle Glow in background
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6C22F5).withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Placeholder (In a real app, use the actual icons)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C22F5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.AutoAwesome, // Placeholder for the unique pattern icons
                        color: Color(0xFFBC9AFF),
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      p.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.description,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white38,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (p.fen.isNotEmpty)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "FEN",
                      style: GoogleFonts.outfit(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF00E5FF),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPatternDetail(ChessPattern p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PatternDetailSheet(pattern: p),
    );
  }
}

class _PatternDetailSheet extends StatelessWidget {
  final ChessPattern pattern;
  const _PatternDetailSheet({required this.pattern});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E1435),
            Color(0xFF121212),
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(32),
              children: [
                Text(
                  pattern.category.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFBC9AFF),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pattern.name,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 24),
                // Simulated Board Preview
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.grid_4x4, color: Colors.white10, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            pattern.fen.isNotEmpty ? "POSITION READY" : "SETUP REQUIRED",
                            style: GoogleFonts.outfit(color: Colors.white24),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "INSIGHT",
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  pattern.description,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 18,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () {
                    // Logic to project to board would go here
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C22F5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    "PROJECT TO BOARD",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
