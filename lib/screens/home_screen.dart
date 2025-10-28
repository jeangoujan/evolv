import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/app_theme.dart';
import '../data/hive_boxes.dart';
import '../data/models/skill.dart';
import 'add_skill_screen.dart';
import 'session_timer_screen.dart';
import 'skills_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Box<Skill> skillBox;

  @override
  void initState() {
    super.initState();
    skillBox = HiveBoxes.skillBox();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Skills',
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: isDark ? textLight : textDark,
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: skillBox.listenable(),
        builder: (context, Box<Skill> box, _) {
          final skills = box.values.toList();

          if (skills.isEmpty) {
            return Center(
              child: Text(
                'No skills yet.\nTap "Add Skill" to start!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            itemCount: skills.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final s = skills[i];
              return _SkillCard(
                name: s.name,
                hours: s.totalHours.toStringAsFixed(0),
                icon: IconData(s.iconCode, fontFamily: 'MaterialIcons'),
                color: Color(s.colorValue),
                onCardTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SkillDetailScreen(
                        skillName: s.name,
                        hoursDone: s.totalHours,
                        goalHours: s.goalHours,
                      ),
                    ),
                  );
                },
                onStartTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionTimerScreen(
                        skillName: s.name,
                        skillId: s.id,
                        targetDuration: const Duration(seconds: 10), // тест
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _AddSkillFab(
        onPressed: () async {
          final newSkill = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSkillScreen()),
          );
          if (newSkill != null && newSkill is Skill) {
            skillBox.put(newSkill.id, newSkill);
          }
        },
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  final String name;
  final String hours;
  final IconData icon;
  final Color color;
  final VoidCallback onCardTap;
  final VoidCallback onStartTap;

  const _SkillCard({
    required this.name,
    required this.hours,
    required this.icon,
    required this.color,
    required this.onCardTap,
    required this.onStartTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF181C18) : Colors.white;
    final neuShadows = isDark
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.55),
              offset: const Offset(8, 8),
              blurRadius: 18,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.07),
              offset: const Offset(-6, -6),
              blurRadius: 14,
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              offset: const Offset(8, 8),
              blurRadius: 18,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-6, -6),
              blurRadius: 12,
            ),
          ];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF232823) : const Color(0xFFE7ECE7),
          width: 1,
        ),
        boxShadow: neuShadows,
      ),
      child: _AnimatedTap(
        onTap: onCardTap,
        borderRadius: 28,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.85),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE7ECE7),
                    width: 1,
                  ),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            offset: const Offset(2, 2),
                            blurRadius: 6,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            offset: const Offset(2, 2),
                            blurRadius: 6,
                          ),
                        ],
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: isDark
                      ? Color.lerp(Colors.black, theme.colorScheme.primary, 0.3)!
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: isDark ? textLight : textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$hours h',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Inter',
                        color: isDark
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _AnimatedTap(
                onTap: onStartTap,
                borderRadius: 30,
                isButton: true,
                child: const _StartPill(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartPill extends StatelessWidget {
  const _StartPill();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F241F) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.45 : 0.08),
            offset: const Offset(3, 3),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(isDark ? 0.08 : 1),
            offset: const Offset(-3, -3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Text(
        'Start',
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 17,
          color: theme.colorScheme.secondary,
        ),
      ),
    );
  }
}

class _AddSkillFab extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddSkillFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: (isDark ? mintSecondary : mintPrimary).withOpacity(0.35),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: isDark ? mintSecondary : mintPrimary,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add, size: 22),
        label: const Text(
          'Add Skill',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _AnimatedTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;
  final bool isButton;

  const _AnimatedTap({
    required this.child,
    required this.onTap,
    this.borderRadius = 20,
    this.isButton = false,
  });

  @override
  State<_AnimatedTap> createState() => _AnimatedTapState();
}

class _AnimatedTapState extends State<_AnimatedTap> {
  bool _pressed = false;

  void _down(TapDownDetails _) => setState(() => _pressed = true);
  void _up(TapUpDetails _) => setState(() => _pressed = false);
  void _cancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final shadowUp = isDark
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.55),
              offset: const Offset(5, 5),
              blurRadius: 10,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.07),
              offset: const Offset(-4, -4),
              blurRadius: 10,
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              offset: const Offset(6, 6),
              blurRadius: 12,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.95),
              offset: const Offset(-4, -4),
              blurRadius: 10,
            ),
          ];

    final shadowDown = isDark
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.75),
              offset: const Offset(2, 2),
              blurRadius: 5,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.04),
              offset: const Offset(-2, -2),
              blurRadius: 6,
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              offset: const Offset(2, 2),
              blurRadius: 6,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              offset: const Offset(-2, -2),
              blurRadius: 6,
            ),
          ];

    final applied = _pressed
        ? (widget.isButton ? _boost(shadowDown, 1.2) : shadowDown)
        : (widget.isButton ? _boost(shadowUp, 1.1) : shadowUp);

    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.translucent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: applied,
        ),
        child: widget.child,
      ),
    );
  }

  List<BoxShadow> _boost(List<BoxShadow> src, double k) =>
      src.map((s) => s.copyWith(blurRadius: s.blurRadius * k)).toList();
}