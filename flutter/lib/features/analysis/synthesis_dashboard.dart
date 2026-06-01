import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/opening_curve_chart.dart';
import 'widgets/tabiya_visualizer_board.dart';
import 'widgets/psychosis_gears.dart';
import 'geographic_king_safety_screen.dart';

class SynthesisDashboard extends StatefulWidget {
  const SynthesisDashboard({Key? key}) : super(key: key);

  @override
  State<SynthesisDashboard> createState() => _SynthesisDashboardState();
}

class _SynthesisDashboardState extends State<SynthesisDashboard> {
  final List<String> _demoOpenings = ["London", "Sicilian", "French", "King's Indian"];
  String _selectedOpening = "London";
  TabiyaState _tabiyaState = TabiyaState.Actual;
  
  // Val.exe terminology controllers
  final _triggerConditionCtrl = TextEditingController();
  final _behavioralHeuristicCtrl = TextEditingController();
  final _spatialMovementCtrl = TextEditingController();
  final _blackjackRuleCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _triggerConditionCtrl.dispose();
    _behavioralHeuristicCtrl.dispose();
    _spatialMovementCtrl.dispose();
    _blackjackRuleCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveMutation() async {
    if (_blackjackRuleCtrl.text.isEmpty) return;
    
    setState(() => _isSaving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Find profile id
        final profileRes = await Supabase.instance.client
            .from('profiles')
            .select('id')
            .eq('user_id', user.id)
            .single();
            
        final profileId = profileRes['id'];

        await Supabase.instance.client.from('synthesis_mutations').insert({
          'anomaly_id': 'CHESS-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
          'profile_id': profileId,
          'agent_target': 'Opponent',
          'map_name': _selectedOpening,
          'trigger_condition': _triggerConditionCtrl.text,
          'behavioral_heuristic': _behavioralHeuristicCtrl.text,
          'spatial_movement_target': _spatialMovementCtrl.text,
          'blackjack_rule_of_thumb': _blackjackRuleCtrl.text,
          'manual_grade': 'Unassessed',
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mutation Anomaly Logged Successfully!', style: TextStyle(color: Colors.greenAccent))),
        );
        
        _triggerConditionCtrl.clear();
        _behavioralHeuristicCtrl.clear();
        _spatialMovementCtrl.clear();
        _blackjackRuleCtrl.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving mutation: $e', style: TextStyle(color: Colors.redAccent))),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F1A), // Dark glassmorphism background
      appBar: AppBar(
        title: Text("Cognitive Synthesis", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_outlined, color: Colors.cyanAccent),
            tooltip: "Geographic King Safety Matrix",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GeographicKingSafetyScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: OpeningCurveChart(
                    openings: _demoOpenings,
                    selectedOpening: _selectedOpening,
                    onOpeningSelected: (op) => setState(() => _selectedOpening = op),
                    totalGames: 12, // Above the 5 game threshold
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: _buildWorkshopCard(),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: TabiyaVisualizerBoard(
              openingName: _selectedOpening,
              currentState: _tabiyaState,
              onStateChanged: (st) => setState(() => _tabiyaState = st),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 300,
            child: OpeningCurveChart(
              openings: _demoOpenings,
              selectedOpening: _selectedOpening,
              onOpeningSelected: (op) => setState(() => _selectedOpening = op),
              totalGames: 12,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 400,
            child: TabiyaVisualizerBoard(
              openingName: _selectedOpening,
              currentState: _tabiyaState,
              onStateChanged: (st) => setState(() => _tabiyaState = st),
            ),
          ),
          SizedBox(height: 16),
          _buildWorkshopCard(),
        ],
      ),
    );
  }

  Widget _buildWorkshopCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      padding: EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Text("Analysis Engine", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                Expanded(child: PsychosisGears()),
              ],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Log Tabiya Mutation (Val.exe Schema)", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_triggerConditionCtrl, "Trigger Condition (e.g., Bishop_Pin)")),
                    SizedBox(width: 8),
                    Expanded(child: _buildTextField(_behavioralHeuristicCtrl, "Heuristic (e.g., Survival_Fold)")),
                  ],
                ),
                SizedBox(height: 8),
                _buildTextField(_spatialMovementCtrl, "Spatial Target (e.g., King_To_Safety)"),
                SizedBox(height: 8),
                _buildTextField(_blackjackRuleCtrl, "Blackjack Rule of Thumb (Required)", maxLines: 2),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent.withOpacity(0.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isSaving ? null : _saveMutation,
                    child: _isSaving 
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                      : Text("Synthesize & Save", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: Colors.white, fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
