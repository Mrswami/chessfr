import 'package:flutter/material.dart';
import 'widgets/carlsbad_matrix_visualizer.dart';

class GeographicKingSafetyScreen extends StatefulWidget {
  const GeographicKingSafetyScreen({super.key});

  @override
  State<GeographicKingSafetyScreen> createState() => _GeographicKingSafetyScreenState();
}

class _GeographicKingSafetyScreenState extends State<GeographicKingSafetyScreen> {
  CarlsbadModality _selectedModality = CarlsbadModality.artificialFortress;
  bool _showGeologicalConstraints = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070E),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Text(
              "GEOGRAPHIC KING SAFETY MATRIX",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
            Text(
              "Carlsbad Tabiya Field Analysis Unit",
              style: TextStyle(
                fontSize: 10,
                color: Colors.cyanAccent,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black.withOpacity(0.3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 950) {
              return _buildDesktopLayout();
            } else {
              return _buildMobileLayout();
            }
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Visualizer Column
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderPanel(),
                const SizedBox(height: 16),
                Expanded(
                  child: CarlsbadMatrixVisualizer(
                    modality: _selectedModality,
                    showGeologicalConstraints: _showGeologicalConstraints,
                  ),
                ),
                const SizedBox(height: 16),
                _buildControlsBar(),
              ],
            ),
          ),
        ),
        // Sidebar Directory Column
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            border: const Border(
              left: BorderSide(color: Colors.white12, width: 1),
            ),
          ),
          child: _buildSidebarDirectory(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderPanel(),
            const SizedBox(height: 16),
            SizedBox(
              height: 350,
              child: CarlsbadMatrixVisualizer(
                modality: _selectedModality,
                showGeologicalConstraints: _showGeologicalConstraints,
              ),
            ),
            const SizedBox(height: 16),
            _buildControlsBar(),
            const SizedBox(height: 24),
            _buildSidebarDirectory(isNested: true),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  "CHIHUAHUAN DESERT SURVEY SECTOR: LONESOME RIDGE",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                ),
                child: const Text(
                  "85.24% ACCURACY SHIELD",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Bureau of Land Management (BLM) Topographical Overlay mapping Split Estates, checkerboard ownership boundaries, and Area of Critical Environmental Concern (ACEC) shielding onto king safety defensive pathways.",
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Modality Toggles
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildModalityBtn("Modality A: Fortress", CarlsbadModality.artificialFortress, Colors.cyanAccent),
                _buildModalityBtn("Modality B: Bait Hook", CarlsbadModality.hPawnBaitHook, Colors.redAccent),
                _buildModalityBtn("Modality C: Evacuation", CarlsbadModality.preEmptiveEvacuation, Colors.greenAccent),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Geological vs Tactics switch
          Row(
            children: [
              const Text("BLM Estates Grid", style: TextStyle(color: Colors.white70, fontSize: 11)),
              Switch(
                value: _showGeologicalConstraints,
                onChanged: (val) => setState(() => _showGeologicalConstraints = val),
                activeColor: Colors.cyanAccent,
                activeTrackColor: Colors.cyan.withOpacity(0.3),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildModalityBtn(String label, CarlsbadModality modality, Color accent) {
    final isSelected = _selectedModality == modality;
    return InkWell(
      onTap: () => setState(() => _selectedModality = modality),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accent : Colors.white12,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white38,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarDirectory({bool isNested = false}) {
    final childrenList = [
      const Text(
        "RESEARCH & OPERATIONS",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.2,
        ),
      ),
      const Text(
        "Carlsbad Field Station Directory",
        style: TextStyle(color: Colors.white54, fontSize: 11),
      ),
      const Divider(color: Colors.white24, height: 24),

      _buildContactTile(
        "Dawn Jones",
        "Carlsbad Field Station Manager",
        "Office Contact: (575) 234-5972\nEmail: djones@blm.gov\nCoord: 32.1245° N, 104.2234° W",
      ),
      const SizedBox(height: 20),

      const Text(
        "MODALITY PROTOCOLS",
        style: TextStyle(
          color: Colors.cyanAccent,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),
      const SizedBox(height: 12),
      _buildProtocolDesc(
        "Modality A (Lonesome Ridge ACEC)",
        "Elevates the King to the Lonesome Ridge plateau. Uses the Area of Critical Environmental Concern (ACEC) designation as an absolute regulatory barrier to restrict opponent piece approaches.",
      ),
      const SizedBox(height: 12),
      _buildProtocolDesc(
        "Modality B (H-Pawn Bait Hook)",
        "Fractures the h-file into a geological canyon fault line. Intentionally weakens the files to bait opponent attacks, drawing them into a spatial tactical trap.",
      ),
      const SizedBox(height: 12),
      _buildProtocolDesc(
        "Modality C (Pre-Emptive Evacuation)",
        "Leverages access easements across the checkerboard split-estate land pattern, securing a clear lane for the King to traverse before hostile lines open.",
      ),
    ];

    if (isNested) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: childrenList,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: childrenList,
      ),
    );
  }

  Widget _buildContactTile(String name, String title, String details) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge, color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.w600),
          ),
          const Divider(color: Colors.white12, height: 16),
          Text(
            details,
            style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolDesc(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
        ),
      ],
    );
  }
}
