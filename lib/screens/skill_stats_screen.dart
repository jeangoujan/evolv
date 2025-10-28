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

    final skillBox = HiveBoxes.skillBox();
    final sessionBox = Hive.box<Session>('sessions');

    return ValueListenableBuilder(
      valueListenable: skillBox.listenable(),
      builder: (context, _, __) {
        final liveSkill = skillBox.get(skill.id) ?? skill;

        return ValueListenableBuilder(
          valueListenable: sessionBox.listenable(),
          builder: (context, __, ___) {
            final sessions = sessionBox.values
                .where((s) => s.skillId == liveSkill.id)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            final totalMinutes =
                sessions.fold<double>(0, (sum, s) => sum + s.durationMinutes);
            final goalProgress =
                liveSkill.goalHours == 0 ? 0.0 : (totalMinutes / 60) / liveSkill.goalHours;

            final formattedTotal = _formatDuration(totalMinutes);
            final weekStats = _calculateWeeklyStats(sessions);
            final last5 = sessions.take(5).toList();

            final now = DateTime.now();
            final weekStart = _mondayOf(now);
            final weekEnd = _sundayOf(now);

            return Scaffold(
              backgroundColor: isDark ? const Color(0xFF0F120F) : Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  '${liveSkill.name} Practice',
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
                    // --- Top stats ---
                    Row(
                      children: [
                        Expanded(
                          child: _NeuroStatCard(
                            label: 'Total Time',
                            value: formattedTotal,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _NeuroStatCard(
                            label: 'Current Streak',
                            value: '${liveSkill.currentStreak} days',
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // --- Goal Progress ---
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
                      label:
                          '${(totalMinutes / 60).toStringAsFixed(1)} / ${liveSkill.goalHours} h',
                      isDark: isDark,
                    ),

                    const SizedBox(height: 24),

                    // --- Weekly Progress ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Weekly Progress',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: isDark ? textLight : textDark,
                          ),
                        ),
                        Text(
                          '${_fmtDM(weekStart)} – ${_fmtDM(weekEnd)}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _WeeklySummary(
                      totalMinutes: weekStats['thisWeek'],
                      percentChange: weekStats['percentChange'],
                      daysActive: weekStats['daysActive'],
                      isDark: isDark,
                    ),

                    const SizedBox(height: 30),

                    // --- Recent Sessions ---
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

                    // --- All Sessions button ---
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
                                skillName: liveSkill.name,
                                hoursDone: liveSkill.totalHours,
                                goalHours: liveSkill.goalHours,
                                skillId: liveSkill.id,
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
          },
        );
      },
    );
  }

  // ---------- Helpers ----------
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
    final startOfWeek = _mondayOf(now);
    final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));

    double thisWeek = 0;
    double lastWeek = 0;
    final activeDays = <int>{};

    for (final s in sessions) {
      if (!s.date.isBefore(startOfWeek)) {
        thisWeek += s.durationMinutes;
        activeDays.add(s.date.weekday);
      } else if (!s.date.isBefore(startOfLastWeek) &&
          s.date.isBefore(startOfWeek)) {
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

// ---------- Supporting Components ----------

class _DetailedSessionCard extends StatelessWidget {
  final Session s;
  final bool isDark;
  const _DetailedSessionCard({required this.s, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
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
          Text(
            _formatDuration(s.durationMinutes),
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: isDark ? textLight : textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(s.date),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          if (s.note?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                s.note!,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color:
                      isDark ? Colors.white70 : Colors.black.withOpacity(0.65),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

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
}

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

// Progress bar
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

// Weekly summary
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
                  ? (isDark ? Colors.white38 : Colors.black26)
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
                    color: active
                        ? mintPrimary
                        : (isDark ? Colors.white24 : Colors.black12),
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
}

// ---------- Helpers ----------
DateTime _mondayOf(DateTime d) {
  final delta = (d.weekday + 6) % 7;
  return DateTime(d.year, d.month, d.day).subtract(Duration(days: delta));
}

DateTime _sundayOf(DateTime d) => _mondayOf(d).add(const Duration(days: 6));

String _fmtDM(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';