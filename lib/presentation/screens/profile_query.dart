// presentation/screens/name_query.dart
import 'package:flutter/material.dart';
import 'package:fyp_latest/presentation/screens/personalization_query.dart';
import '../../widgets/gradient_background.dart';
import '../../services/auth_service.dart';
import '../../controllers/profile_controller.dart';
import '../../main.dart';
import 'login.dart';

class NameQuery extends StatefulWidget {
  const NameQuery({super.key});

  @override
  State<NameQuery> createState() => _NameQueryState();
}

class _NameQueryState extends State<NameQuery>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final ProfileController _profileController = ProfileController();

  final TextEditingController _nameController = TextEditingController();

  int _step = 0; // 0 = name, 1 = gender, 2 = dob
  String? _selectedGender;
  DateTime? _selectedDob;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

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
    _nameController.dispose();
    super.dispose();
  }

  void _nextStep() async {
    // Validate current step
    if (_step == 0 && _nameController.text.trim().isEmpty) {
      _showError("Please enter your name.");
      return;
    }
    if (_step == 1 && _selectedGender == null) {
      _showError("Please select your gender.");
      return;
    }

    if (_step == 2) {
      // Final step — save and navigate
      if (_selectedDob == null) {
        _showError("Please select your date of birth.");
        return;
      }
      setState(() => _isLoading = true);
      try {
        await _profileController.saveProfile(
          name: _nameController.text.trim(),
          gender: _selectedGender!,
          dob: _selectedDob!,
        );
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                PersonalizationQuery(userName: _nameController.text.trim()),
          ),
        );
      } catch (e) {
        _showError("Failed to save. Please try again.");
      } finally {
        setState(() => _isLoading = false);
      }
      return;
    }

    // Animate to next step
    await _animController.reverse();
    setState(() => _step++);
    _animController.forward();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 5, now.month, now.day),
      builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  String _formatDate(DateTime dt) =>
      "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Image.asset('assets/images/back.png', height: 24, width: 24),
            onPressed: () async {
              if (_step > 0) {
                // Go back a step
                await _animController.reverse();
                setState(() => _step--);
                _animController.forward();
              } else {
                await _authService.signOut();
                navigatorKey.currentState?.pushReplacement(
                  MaterialPageRoute(builder: (_) => LoginPage()),
                );
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/dog.png', height: 120),
                const SizedBox(height: 12),

                // Step indicator dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
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
                const SizedBox(height: 40),

                // Animated question content
                FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: _buildStep(),
                  ),
                ),

                const SizedBox(height: 36),

                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _step == 2 ? "Let's go!" : "Continue",
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildGenderStep();
      case 2:
        return _buildDobStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildNameStep() {
    return Column(
      children: [
        const Text(
          "What's your name?",
          style: TextStyle(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter your name",
            hintStyle: const TextStyle(color: Colors.white60),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderStep() {
    final genders = [
      ('male', '👨', 'Male'),
      ('female', '👩', 'Female'),
      ('other', '🧑', 'Other'),
    ];
    return Column(
      children: [
        const Text(
          "What's your gender?",
          style: TextStyle(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        ...genders.map((g) {
          final isSelected = _selectedGender == g.$1;
          return GestureDetector(
            onTap: () => setState(() => _selectedGender = g.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Text(g.$2, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 16),
                  Text(
                    g.$3,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Colors.white),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDobStep() {
    return Column(
      children: [
        const Text(
          "When's your birthday?",
          style: TextStyle(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _pickDob,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration: BoxDecoration(
              color: _selectedDob != null
                  ? Colors.white.withOpacity(0.25)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedDob != null ? Colors.white : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined, color: Colors.white70),
                const SizedBox(width: 16),
                Text(
                  _selectedDob != null
                      ? _formatDate(_selectedDob!)
                      : "Select your date of birth",
                  style: TextStyle(
                    color: _selectedDob != null ? Colors.white : Colors.white60,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
