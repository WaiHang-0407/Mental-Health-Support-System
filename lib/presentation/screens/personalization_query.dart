import 'package:flutter/material.dart';
import '../../widgets/gradient_background.dart';
import '../../controllers/profile_controller.dart';
import '../../main.dart';
import 'home_patient.dart';

class PersonalizationQuery extends StatefulWidget {
  final String userName;
  const PersonalizationQuery({super.key, required this.userName});

  @override
  State<PersonalizationQuery> createState() => _PersonalizationQueryState();
}

class _PersonalizationQueryState extends State<PersonalizationQuery>
    with SingleTickerProviderStateMixin {
  final ProfileController _profileController = ProfileController();

  int _step = 0;
  final List<String> _selectedConditions = [];
  String? _selectedAnimal;
  String? _selectedActivity;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Options
  final List<Map<String, String>> _conditions = [
    {'label': 'Depression', 'emoji': '😔'},
    {'label': 'Stress', 'emoji': '😤'},
    {'label': 'Anxiety', 'emoji': '😰'},
    {'label': 'Confidence', 'emoji': '💪'},
    {'label': 'Relationships', 'emoji': '💔'},
    {'label': 'Trauma', 'emoji': '🌧️'},
  ];

  final List<Map<String, String>> _animals = [
    {'label': 'Dog', 'asset': 'assets/images/dog.png'},
    {'label': 'Cat', 'asset': 'assets/images/cat.png'},
    {'label': 'Rabbit', 'asset': 'assets/images/rabbit.png'},
    {'label': 'Duck', 'asset': 'assets/images/duck.png'},
    {'label': 'Parrot', 'asset': 'assets/images/parrot.png'},
    {'label': 'Guinea Pig', 'asset': 'assets/images/guinea-pig.png'},
  ];

  final List<Map<String, String>> _activities = [
    {'label': 'Reading', 'emoji': '📚'},
    {'label': 'Music', 'emoji': '🎵'},
    {'label': 'Exercise', 'emoji': '🏃'},
    {'label': 'Gaming', 'emoji': '🎮'},
    {'label': 'Cooking', 'emoji': '🍳'},
    {'label': 'Art', 'emoji': '🎨'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    // Validate
    if (_step == 0 && _selectedConditions.isEmpty) {
      _showError("Please select at least one challenge.");
      return;
    }
    if (_step == 1 && _selectedAnimal == null) {
      _showError("Please select a favourite animal.");
      return;
    }
    if (_step == 2) {
      if (_selectedActivity == null) {
        _showError("Please select a favourite activity.");
        return;
      }
      // Save and navigate
      setState(() => _isLoading = true);
      try {
        await _profileController.savePersonalization(
          conditions: _selectedConditions,
          favAnimal: _selectedAnimal!.toLowerCase(),
          favActivity: _selectedActivity!.toLowerCase(),
        );
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePatientPage()),
        );
      } catch (e) {
        _showError("Failed to save. Please try again.");
        setState(() => _isLoading = false);
      }
      return;
    }

    // Animate to next
    await _animController.reverse();
    setState(() => _step++);
    _animController.forward();
  }

  Future<void> _prevStep() async {
    if (_step == 0) return;
    await _animController.reverse();
    setState(() => _step--);
    _animController.forward();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _step > 0
              ? IconButton(
                  icon: Image.asset(
                    'assets/images/back.png',
                    height: 24,
                    width: 24,
                  ),
                  onPressed: _prevStep,
                )
              : const SizedBox(),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Header
              Text(
                "Hi, ${widget.userName}!",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                "now let's build your space",
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 24),

              // Step dots
              Row(
                children: List.generate(
                  3,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 6),
                    width: _step == i ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _step == i
                          ? Colors.white
                          : Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Animated content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: _buildStep(),
                  ),
                ),
              ),

              // Bottom area
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _isLoading ? null : _nextStep,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black54,
                                  ),
                                )
                              : const Icon(
                                  Icons.chevron_right,
                                  color: Colors.black87,
                                  size: 28,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        "You can change or add later",
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildGridStep(
          question:
              "Any challenges you face that you would love to be helped with?",
          options: _conditions,
          selected: _selectedConditions,
          multiSelect: true,
        );
      case 1:
        return _buildGridStep(
          question: "What's your favourite animal?",
          options: _animals,
          selected: _selectedAnimal != null ? [_selectedAnimal!] : [],
          multiSelect: false,
          onSingleSelect: (val) => setState(() => _selectedAnimal = val),
        );
      case 2:
        return _buildGridStep(
          question: "What's your favourite activity?",
          options: _activities,
          selected: _selectedActivity != null ? [_selectedActivity!] : [],
          multiSelect: false,
          onSingleSelect: (val) => setState(() => _selectedActivity = val),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildGridStep({
    required String question,
    required List<Map<String, String>> options,
    required List<String> selected,
    required bool multiSelect,
    void Function(String)? onSingleSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: options.map((option) {
            final isSelected = selected.contains(option['label']);
            return GestureDetector(
              onTap: () {
                if (multiSelect) {
                  setState(() {
                    if (isSelected) {
                      _selectedConditions.remove(option['label']);
                    } else {
                      _selectedConditions.add(option['label']!);
                    }
                  });
                } else {
                  onSingleSelect?.call(option['label']!);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.25)
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 👇 handle both asset images and emoji
                      if (option['asset'] != null)
                        Image.asset(option['asset']!, height: 24, width: 24)
                      else
                        Text(
                          option['emoji'] ?? '',
                          style: const TextStyle(fontSize: 20),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        option['label']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
