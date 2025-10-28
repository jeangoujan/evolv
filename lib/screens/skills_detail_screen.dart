import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/hive_boxes.dart';
import '../data/models/session.dart';
import '../theme/app_theme.dart';

class SkillDetailScreen extends StatelessWidget {
  final String skillName;
  final double hoursDone;
  final double goalHours;
  final int skillId;

  const SkillDetailScreen({
    super.key,
    required this.skillName,
    required this.hoursDone,
    required this.goalHours,
    required this.skillId,
  });

  @override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final sessionBox = Hive.box<Session>('sessions');

  return Scaffold(
    appBar: AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: true,
      title: Text(
        skillName,
        style: theme.textTheme.titleLarge?.copyWith(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          color: isDark ? textLight : textDark,
        ),
      ),
    ),
    body: ValueListenableBuilder(
      valueListenable: sessionBox.listenable(),
      builder: (context, Box<Session> box, _) {
        final sessions = box.values
            .where((s) => s.skillId == skillId)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        if (sessions.isEmpty) {
          return Center(
            child: Text(
              'No sessions yet.\nStart training!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final s = sessions[i];
            return GestureDetector(
              onLongPress: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor:
                        isDark ? const Color(0xFF1C201C) : Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: Text(
                      'Delete this session?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    content: const Text(
                      'This action cannot be undone.',
                      style: TextStyle(fontFamily: 'Inter'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await s.delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Session deleted',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: Colors.redAccent,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 60, vertical: 40),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  );
                }
              },
              child: _AnimatedTap(
                borderRadius: 20,
                onTap: () {}, // визуальный эффект
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color:
                        isDark ? const Color(0xFF181C18) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDuration(s.durationMinutes),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              color: isDark ? textLight : textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(s.date),
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : Colors.black.withOpacity(0.6),
                              fontFamily: 'Inter',
                            ),
                          ),
                          if (s.note?.isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                s.note!,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black
                                          .withOpacity(0.55),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}



  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  String _formatDuration(double minutes) {
    if (minutes < 1) {
      final secs = (minutes * 60).round().clamp(1, 59);
      return '$secs ${secs == 1 ? "second" : "seconds"}';
    }

    final totalMin = minutes.round();
    final h = totalMin ~/ 60;
    final m = totalMin % 60;

    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
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