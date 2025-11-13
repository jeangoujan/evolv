import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../data/models/skill.dart';
import '../theme/app_theme.dart';

class AddExistingSkillScreen extends StatefulWidget {
  const AddExistingSkillScreen({super.key});

  @override
  State<AddExistingSkillScreen> createState() => _AddExistingSkillScreenState();
}

class _AddExistingSkillScreenState extends State<AddExistingSkillScreen> {
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  double _totalHours = 10; // начальное значение

  int? _selectedIconIndex;
  int? _selectedColorIndex;

  final List<IconData> _icons = [
    Icons.music_note,
    Icons.code,
    Icons.psychology,
    Icons.fitness_center,
    Icons.brush,
    Icons.menu_book,
    Icons.language,
    Icons.self_improvement,
  ];

  final List<Color> _colors = const [
    Color(0xFFFAC7C3),
    Color(0xFFB5D8FA),
    Color(0xFFFBE49E),
    Color(0xFFCBC7FA),
    Color(0xFFA3F1D0),
    Color(0xFF81C784),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? textLight : textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Add Existing Skill",
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: isDark ? textLight : textDark,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildLabel("Skill Name", isDark),
          _buildTextField(_nameController, "e.g., Piano Practice", isDark),
          const SizedBox(height: 28),

          _buildLabel("Total Time (hours, approx.)", isDark),
          const SizedBox(height: 8),
          _buildSlider(isDark),
          const SizedBox(height: 28),

          _buildLabel("Goal Hours", isDark),
          _buildTextField(_goalController, "e.g., 100", isDark,
              keyboardType: TextInputType.number),
          const SizedBox(height: 32),

          _buildLabel("Select an Icon", isDark),
          const SizedBox(height: 12),
          _buildIconGrid(isDark),
          const SizedBox(height: 28),

          _buildLabel("Choose a Color", isDark),
          const SizedBox(height: 12),
          _buildColorRow(isDark),
          const SizedBox(height: 40),

          _buildSaveButton(context),
        ],
      ),
    );
  }

  // ---------------- UI BUILDERS ----------------
  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: isDark ? Colors.white.withOpacity(0.9) : textDark,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      bool isDark,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F1A) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  offset: const Offset(3, 3),
                  blurRadius: 10,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.07),
                  offset: const Offset(-3, -3),
                  blurRadius: 10,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  offset: const Offset(4, 4),
                  blurRadius: 10,
                ),
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-4, -4),
                  blurRadius: 10,
                ),
              ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontFamily: 'Inter',
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Inter',
            color: isDark ? Colors.white54 : Colors.grey[500],
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSlider(bool isDark) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: mintPrimary,
            inactiveTrackColor:
                isDark ? Colors.white12 : Colors.grey.shade300,
            thumbColor: mintPrimary,
            overlayColor: mintPrimary.withOpacity(0.2),
          ),
          child: Slider(
            min: 0,
            max: 500,
            divisions: 100,
            value: _totalHours,
            label: "${_totalHours.toStringAsFixed(0)} h",
            onChanged: (v) => setState(() => _totalHours = v),
          ),
        ),
        Text(
          "You've practiced ~${_totalHours.toStringAsFixed(0)} hours",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildIconGrid(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _icons.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemBuilder: (context, index) {
        final selected = _selectedIconIndex == index;
        final icon = _icons[index];

        return GestureDetector(
          onTap: () => setState(() => _selectedIconIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1F241F) : Colors.white,
              border: Border.all(
                color: selected
                    ? mintPrimary
                    : (isDark
                        ? const Color(0xFF232823)
                        : const Color(0xFFE7ECE7)),
                width: selected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.55)
                      : Colors.black.withOpacity(0.08),
                  offset: const Offset(4, 4),
                  blurRadius: 10,
                ),
                BoxShadow(
                  color:
                      isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                  offset: const Offset(-4, -4),
                  blurRadius: 8,
                ),
                if (selected)
                  BoxShadow(
                    color: mintPrimary.withOpacity(0.35),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Icon(
              icon,
              size: selected ? 30 : 26,
              color: selected
                  ? mintPrimary
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(_colors.length, (index) {
        final selected = _selectedColorIndex == index;
        final color = _colors[index];

        return GestureDetector(
          onTap: () => setState(() => _selectedColorIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: selected ? 44 : 40,
            height: selected ? 44 : 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border:
                  selected ? Border.all(color: mintPrimary, width: 2.5) : null,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.6)
                      : Colors.black.withOpacity(0.06),
                  offset: const Offset(3, 3),
                  blurRadius: 8,
                ),
                BoxShadow(
                  color:
                      isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  offset: const Offset(-3, -3),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: mintPrimary,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: () async {
        final name = _nameController.text.trim();
        if (name.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Center(
                child: Text(
                  "Please enter a skill name",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              backgroundColor: Colors.black87,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        final goal = int.tryParse(_goalController.text.trim()) ?? 0;
        final icon = _icons[_selectedIconIndex ?? 0];
        final color = _colors[_selectedColorIndex ?? 0];

        final newSkill = Skill(
          id: DateTime.now().millisecondsSinceEpoch,
          name: name,
          goalHours: goal.toDouble(),
          totalHours: _totalHours,
          currentStreak: 1,
          colorValue: color.value,
          iconCode: icon.codePoint,
        );

        final box = Hive.box<Skill>('skills');
        await box.add(newSkill);

        if (context.mounted) Navigator.pop(context, newSkill);
      },
      child: const Text(
        "Save Skill",
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}