import 'package:flutter/material.dart';
import '../theme/app_theme.dart'; // mintPrimary, mintSecondary, textDark, textLight

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // временные данные
    final skills = const [
      {'name': 'Piano', 'hours': 45},
      {'name': 'Coding', 'hours': 20},
      {'name': 'Languages', 'hours': 12},
    ];

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
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        itemCount: skills.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final s = skills[i];
          return _SkillCard(
            name: s['name'] as String,
            hours: s['hours'] as int,
            onCardTap: () {
              // TODO: переход к деталям/статистике
            },
            onStartTap: () {
              // TODO: запуск таймера
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const _AddSkillFab(),
    );
  }
}

class _SkillCard extends StatelessWidget {
  final String name;
  final int hours;
  final VoidCallback onCardTap;
  final VoidCallback onStartTap;

  const _SkillCard({
    required this.name,
    required this.hours,
    required this.onCardTap,
    required this.onStartTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // более контрастная карточка + тени
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
        onTap: onCardTap, // клик по карточке отдельно
        borderRadius: 28,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // аватарка-иконка с контрастным фоном
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isDark ? const Color(0xFF252A25) : const Color(0xFFF2F5F2),
                  border: Border.all(
                    color:
                        isDark ? Colors.white12 : const Color(0xFFE7ECE7),
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
                  _iconForSkill(name),
                  size: 26,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              // текст
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
              // кнопка Start — независимая зона нажатия + анимация
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

  IconData _iconForSkill(String name) {
    final n = name.toLowerCase();
    if (n.contains('piano')) return Icons.music_note;
    if (n.contains('coding') || n.contains('code')) return Icons.laptop_mac;
    if (n.contains('lang')) return Icons.chat_bubble_outline;
    return Icons.auto_graph_rounded;
  }
}

// увеличенная и контрастная капсула Start
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
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  offset: const Offset(3, 3),
                  blurRadius: 10,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.08),
                  offset: const Offset(-3, -3),
                  blurRadius: 10,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  offset: const Offset(3, 3),
                  blurRadius: 10,
                ),
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-3, -3),
                  blurRadius: 10,
                ),
              ],
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1.2,
        ),
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

// мягкий “glow”-FAB по центру
class _AddSkillFab extends StatelessWidget {
  const _AddSkillFab();

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
        onPressed: () {
          // TODO: Navigator.pushNamed(context, '/add');
        },
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

/// Универсальный виджет лёгкого “scale”-эффекта при тапе

class _AnimatedTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;
  final bool isButton; // 👈 добавили флаг для “Start” кнопки

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

  void _onTapDown(TapDownDetails _) => setState(() => _pressed = true);
  void _onTapUp(TapUpDetails _) => setState(() => _pressed = false);
  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 🌗 усиливаем контраст светлой темы
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

    // если элемент — кнопка (например Start), делаем эффект чуть сильнее
    final appliedShadow = _pressed
        ? (widget.isButton ? shadowDown.map((s) => s.copyWith(blurRadius: 8)).toList() : shadowDown)
        : (widget.isButton ? shadowUp.map((s) => s.copyWith(blurRadius: 12)).toList() : shadowUp);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.translucent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: appliedShadow,
        ),
        child: widget.child,
      ),
    );
  }
}