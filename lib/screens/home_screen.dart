import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/app_theme.dart';
import '../data/hive_boxes.dart';
import '../data/models/skill.dart';
import 'add_skill_screen.dart';
import 'session_timer_screen.dart';
import 'skill_stats_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Box<Skill> skillBox;
  final Map<int, double> _previousHours = {}; // для анимации пульса

  Duration _defaultSessionDuration = const Duration(hours: 1, minutes: 30);

  @override
  void initState() {
    super.initState();
    skillBox = HiveBoxes.skillBox();
    _loadDefaultDuration();
  }

  Future<void> _loadDefaultDuration() async {
    final box = await Hive.openBox('settings');
    final minutes = box.get('defaultDurationMinutes', defaultValue: 90);
    setState(() {
      _defaultSessionDuration = Duration(minutes: minutes);
    });
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) => _loadDefaultDuration());
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1F241F) : Colors.white,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF232823)
                      : const Color(0xFFE7ECE7),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.55)
                        : Colors.black.withOpacity(0.10),
                    offset: const Offset(4, 4),
                    blurRadius: 10,
                  ),
                  BoxShadow(
                    color: isDark
                        ? Colors.white.withOpacity(0.07)
                        : Colors.white,
                    offset: const Offset(-3, -3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                Icons.settings_rounded,
                size: 22,
                color: mintPrimary,
              ),
            ),
          ),
        ),
      ],
    ),
      
      body: ValueListenableBuilder(
        valueListenable: skillBox.listenable(),
        builder: (context, Box<Skill> box, _) {
          final skills = box.values.toList();
          print('📦 Skills from Hive:');
          for (final s in skills) {
            print('   ${s.name}: ${s.totalHours.toStringAsFixed(2)} h');
          }

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

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: ListView.separated(
              key: ValueKey(skills.length),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
              itemCount: skills.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final s = skills[i];

                // 🔄 Проверяем, выросло ли количество часов
                final prev = _previousHours[s.id] ?? s.totalHours;
                final increased = s.totalHours > prev;
                _previousHours[s.id] = s.totalHours;

                // 🧮 Формируем красивый текст для часов
                // 🧠 Теперь считаем реальное время по всем сессиям из Hive
                final sessionBox = HiveBoxes.sessionBox();
                final sessionsForSkill =
                    sessionBox.values.where((sess) => sess.skillId == s.id).toList();

                final totalMinutes = sessionsForSkill.fold<double>(
                  0,
                  (sum, sess) => sum + sess.durationMinutes,
                );
                final totalHours = totalMinutes / 60.0;

                // Округляем вниз до целого числа
                final displayHours = totalHours < 1 ? 0 : totalHours.floor();
                final hoursLabel =
                    '$displayHours ${displayHours == 1 ? "hour" : "hours"}';

                return _AnimatedPulse(
                  active: increased,
                  child: GestureDetector(
                    onLongPress: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor:
                              isDark ? const Color(0xFF1C201C) : Colors.white,
                          title: Text(
                            'Delete "${s.name}"?',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          content: Text(
                            'This will remove the skill and all its sessions.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color:
                                  isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.black87,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await skillBox.deleteAt(i);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                              elevation: 8,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              content: Center(
                                child: Text(
                                  '"${s.name}" deleted',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    child: _SkillCard(
                      name: s.name,
                      hoursLabel: hoursLabel,
                      icon: IconData(s.iconCode,
                          fontFamily: 'MaterialIcons'),
                      color: Color(s.colorValue),
                      onCardTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SkillStatsScreen(skill: s),
                          ),
                        );
                      },
                      onStartTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            fullscreenDialog: false,
                            builder: (_) => SessionTimerScreen(
                              skillName: s.name,
                              skillId: s.id,
                              targetDuration: _defaultSessionDuration, // тест
                            ),
                          ),
                        );
                        setState(() {}); // обновим при возврате
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
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

// ---------------------------------------------------------------------------
// Skill Card UI
// ---------------------------------------------------------------------------

class _SkillCard extends StatelessWidget {
  final String name;
  final String hoursLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onCardTap;
  final VoidCallback onStartTap;

  const _SkillCard({
    required this.name,
    required this.hoursLabel,
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
          color:
              isDark ? const Color(0xFF232823) : const Color(0xFFE7ECE7),
          width: 1,
        ),
        boxShadow: neuShadows,
      ),
      child: _AnimatedTap(
        onTap: onCardTap,
        borderRadius: 28,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.85),
                  border: Border.all(
                    color:
                        isDark ? Colors.white12 : const Color(0xFFE7ECE7),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: isDark
                      ? Color.lerp(Colors.black,
                          theme.colorScheme.primary, 0.3)!
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
                      hoursLabel,
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

// ---------------------------------------------------------------------------
// Pulse Animation
// ---------------------------------------------------------------------------

class _AnimatedPulse extends StatefulWidget {
  final Widget child;
  final bool active;
  const _AnimatedPulse({required this.child, required this.active});

  @override
  State<_AnimatedPulse> createState() => _AnimatedPulseState();
}

class _AnimatedPulseState extends State<_AnimatedPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  }

  @override
  void didUpdateWidget(covariant _AnimatedPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_ctrl.isAnimating) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final glow = (1 - _ctrl.value) * 0.35;
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: mintPrimary.withOpacity(glow),
                blurRadius: 30 * (1 - _ctrl.value),
                spreadRadius: 2 * (1 - _ctrl.value),
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// Остальные вспомогательные классы (_StartPill, _AddSkillFab, _AnimatedTap)
// ---------------------------------------------------------------------------
// оставлены без изменений из твоей версии.
// ---------------------------------------------------------------------------
// Start button
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Floating Button
// ---------------------------------------------------------------------------

class _AddSkillFab extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddSkillFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.35),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: primary,
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

// ---------------------------------------------------------------------------
// Tap Animation
// ---------------------------------------------------------------------------

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