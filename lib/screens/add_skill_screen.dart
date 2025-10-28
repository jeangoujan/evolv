import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../data/models/skill.dart';
import '../theme/app_theme.dart';

class AddSkillScreen extends StatefulWidget {
  const AddSkillScreen({super.key});

  @override
  State<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();

  int? _selectedIconIndex;
  int? _selectedColorIndex;

  final List<IconData> _icons = [
    Icons.music_note,
    Icons.laptop_mac,
    Icons.translate,
    Icons.edit_note,
    Icons.menu_book,
    Icons.fitness_center,
    Icons.code,
    Icons.brush,
  ];

  final List<Color> _colors = const [
    Color(0xFFFAC7C3),
    Color(0xFFB5D8FA),
    Color(0xFFFBE49E),
    Color(0xFFCBC7FA),
    Color(0xFFA3F1D0),
    Color(0xFFD6D8DB),
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
          "Add Skill",
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
          _buildTextField(_nameController, "e.g., Learn Piano", isDark),
          const SizedBox(height: 24),
          _buildLabel("Goal Hours (Optional)", isDark),
          _buildTextField(_goalController, "e.g., 100", isDark),
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

  // --- Components ---

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
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

  Widget _buildTextField(
      TextEditingController controller, String hint, bool isDark) {
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
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(4, 4),
                  blurRadius: 12,
                ),
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-4, -4),
                  blurRadius: 12,
                ),
              ],
      ),
      child: TextField(
        controller: controller,
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

  Widget _buildIconGrid(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _icons.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
      ),
      itemBuilder: (context, index) {
        final selected = _selectedIconIndex == index;

        return GestureDetector(
          onTap: () => setState(() => _selectedIconIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF202620)
                  : const Color(0xFFF9FBF9),
              shape: BoxShape.circle,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: mintPrimary.withOpacity(0.5),
                        blurRadius: 25,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                        offset: const Offset(3, 3),
                        blurRadius: 10,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(isDark ? 0.05 : 0.9),
                        offset: const Offset(-3, -3),
                        blurRadius: 8,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                        offset: const Offset(3, 3),
                        blurRadius: 10,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(isDark ? 0.05 : 0.9),
                        offset: const Offset(-3, -3),
                        blurRadius: 8,
                      ),
                    ],
            ),
            child: Icon(
              _icons[index],
              size: 26,
              color: selected
                  ? (isDark ? Colors.white : mintPrimary)
                  : (isDark ? Colors.white70 : Colors.black54),
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
            width: selected ? 54 : 48,
            height: selected ? 54 : 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.7),
                        offset: const Offset(3, 3),
                        blurRadius: 8,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        offset: const Offset(-3, -3),
                        blurRadius: 8,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(4, 4),
                        blurRadius: 10,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.9),
                        offset: const Offset(-4, -4),
                        blurRadius: 8,
                      ),
                    ],
              border:
                  selected ? Border.all(color: mintPrimary, width: 3) : null,
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: () async {
        if (_nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.black87,
              elevation: 6,
              behavior: SnackBarBehavior.floating,
              margin:
                  const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              content: const Center(
                child: Text(
                  "Please enter a skill name",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        final name = _nameController.text.trim();
        final goal = int.tryParse(_goalController.text.trim()) ?? 0;
        final icon = _icons[_selectedIconIndex ?? 0];
        final color = _colors[_selectedColorIndex ?? 0];

        final newSkill = Skill(
        id: DateTime.now().millisecondsSinceEpoch, // уникальный ID
        name: name,
        goalHours: goal.toDouble(), // double, а не int
        totalHours: 0,
        colorValue: color.value,
        iconCode: icon.codePoint, // ✅ соответствует модели
        sessions: const [],
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