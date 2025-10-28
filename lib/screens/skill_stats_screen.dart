import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/skill.dart';
import '../data/models/session.dart';
import '../theme/app_theme.dart';
import '../data/hive_boxes.dart';
import 'skills_detail_screen.dart';

class SkillStatsScreen extends StatelessWidget {
  final Skill skill;

  const SkillStatsScreen({super.key, required this.skill});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionBox = Hive.box<Session>('sessions');
    final sessions = sessionBox.values
        .where((s) => s.skillId == skill.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalMinutes = sessions.fold<double>(0, (sum, s) => sum + s.durationMinutes);
    final goalProgress = (totalMinutes / 60) / skill.goalHours;
    final formattedTotal = _formatDuration(totalMinutes);

    final weekStats = _calculateWeeklyStats(sessions);
    final last5 = sessions.take(5).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F120F) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '${skill.name} Practice',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: isDark ? textLight : textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _NeuroStatCard(
                    label: 'Total Hours',
                    value: formattedTotal,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _NeuroStatCard(
                    label: 'Current Streak',
                    value: '${skill.currentStreak} days',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Goal Progress',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: isDark ? textLight : textDark,
              ),
            ),
            const SizedBox(height: 10),
            _NeuroProgressBar(
              progress: goalProgress.clamp(0, 1),
              label: '${(totalMinutes / 60).toStringAsFixed(1)} / ${skill.goalHours} h',
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            Text(
              'Weekly Progress',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: isDark ? textLight : textDark,
              ),
            ),
            const SizedBox(height: 10),
            _WeeklySummary(
              totalMinutes: weekStats['thisWeek'],
              percentChange: weekStats['percentChange'],
              daysActive: weekStats['daysActive'],
              isDark: isDark,
            ),
            const SizedBox(height: 30),
            Text(
              'Recent Sessions',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: isDark ? textLight : textDark,
              ),
            ),
            const SizedBox(height: 12),
            if (last5.isEmpty)
              Text(
                'No sessions yet.',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ...last5.map((s) => _DetailedSessionCard(s: s, isDark: isDark)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mintPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 8,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SkillDetailScreen(
                        skillName: skill.name,
                        hoursDone: skill.totalHours,
                        goalHours: skill.goalHours,
                        skillId: skill.id,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'All Sessions →',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

String _formatDuration(double minutes) {
  if (minutes < 1) {
    final secs = (minutes * 60).round();
    return '$secs sec';
  } else if (minutes < 60) {
    return '${minutes.floor()} min';
  } else {
    final h = minutes ~/ 60;
    final m = (minutes % 60).round();
    return '${h}h ${m}min';
  }
}

  Map<String, dynamic> _calculateWeeklyStats(List<Session> sessions) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));

    double thisWeek = 0;
    double lastWeek = 0;
    final activeDays = <int>{};

    for (final s in sessions) {
      if (s.date.isAfter(startOfWeek)) {
        thisWeek += s.durationMinutes;
        activeDays.add(s.date.weekday);
      } else if (s.date.isAfter(startOfLastWeek) && s.date.isBefore(startOfWeek)) {
        lastWeek += s.durationMinutes;
      }
    }

    double? percentChange;
    if (lastWeek > 0) {
      percentChange = ((thisWeek - lastWeek) / lastWeek) * 100;
    }

    return {
      'thisWeek': thisWeek,
      'percentChange': percentChange,
      'daysActive': activeDays,
    };
  }
}

// Карточка для Recent Sessions (подробная)
class _DetailedSessionCard extends StatelessWidget {
  final Session s;
  final bool isDark;

  const _DetailedSessionCard({required this.s, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181C18) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.55 : 0.1),
            offset: const Offset(6, 6),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(isDark ? 0.08 : 0.9),
            offset: const Offset(-6, -6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Длительность ----
          Text(
            _formatDuration(s.durationMinutes),
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: isDark ? textLight : textDark,
            ),
          ),

          const SizedBox(height: 4),

          // ---- Дата ----
          Text(
            _formatDate(s.date),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),

          // ---- Заметка ----
          if (s.note?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  s.note!,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: isDark
                        ? Colors.white70
                        : Colors.black.withOpacity(0.65),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ---------- Форматирование ----------

String _formatDuration(double minutes) {
  if (minutes < 1) {
    final secs = (minutes * 60).round();
    return '$secs sec';
  } else if (minutes < 60) {
    return '${minutes.floor()} min';
  } else {
    final h = minutes ~/ 60;
    final m = (minutes % 60).round();
    return '${h}h ${m}min';
  }
}

String _formatDate(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}




// ---------- COMPONENTS ----------

class _NeuroStatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _NeuroStatCard({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181C18) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.55),
                  offset: const Offset(6, 6),
                  blurRadius: 14,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.08),
                  offset: const Offset(-6, -6),
                  blurRadius: 14,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(6, 6),
                  blurRadius: 14,
                ),
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-6, -6),
                  blurRadius: 14,
                ),
              ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: isDark ? textLight : textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeuroProgressBar extends StatelessWidget {
  final double progress;
  final String label;
  final bool isDark;

  const _NeuroProgressBar({
    required this.progress,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181C18) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.55 : 0.1),
            offset: const Offset(5, 5),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(isDark ? 0.08 : 0.9),
            offset: const Offset(-5, -5),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: progress,
            color: mintPrimary,
            backgroundColor: isDark ? Colors.white12 : Colors.black12,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklySummary extends StatelessWidget {
  final double totalMinutes;
  final double? percentChange;
  final Set<int> daysActive;
  final bool isDark;

  const _WeeklySummary({
    required this.totalMinutes,
    required this.percentChange,
    required this.daysActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = _formatDuration(totalMinutes);
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181C18) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.55 : 0.1),
            offset: const Offset(6, 6),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(isDark ? 0.08 : 0.9),
            offset: const Offset(-6, -6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: TextStyle(
              fontFamily: 'Inter',
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatted,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: isDark ? textLight : textDark,
            ),
          ),
          Text(
            percentChange == null
                ? '—'
                : '${percentChange! >= 0 ? '+' : ''}${percentChange!.toStringAsFixed(1)}%',
            style: TextStyle(
              color: percentChange == null
                  ? Colors.white38
                  : (percentChange! >= 0 ? mintPrimary : Colors.redAccent),
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final active = daysActive.contains(i + 1);
              return Column(
                children: [
                  Icon(
                    active ? Icons.check_circle : Icons.circle_outlined,
                    color: active ? mintPrimary : Colors.white24,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weekDays[i],
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  String _formatDuration(double minutes) {
    final h = (minutes / 60).floor();
    final m = (minutes % 60).round();
    if (h == 0 && m == 0) return '0 min';
    if (h == 0) return '$m min';
    return '${h}h ${m}min';
  }
}

class _RecentSessionCard extends StatelessWidget {
  final Session s;
  final bool isDark;

  const _RecentSessionCard({required this.s, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181C18) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.55 : 0.1),
            offset: const Offset(6, 6),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(isDark ? 0.08 : 0.9),
            offset: const Offset(-6, -6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatDate(s.date),
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              color: isDark ? textLight : textDark,
            ),
          ),
          Text(
            _formatDuration(s.durationMinutes),
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) return 'Today';
    if (d.year == now.year &&
        d.month == now.month &&
        d.day == now.day - 1) return 'Yesterday';
    return '${d.day}.${d.month}.${d.year}';
  }

  String _formatDuration(double minutes) {
    final h = (minutes / 60).floor();
    final m = (minutes % 60).round();
    if (h == 0 && m == 0) return '0 min';
    if (h == 0) return '$m min';
    return '${h}h ${m}min';
  }
}