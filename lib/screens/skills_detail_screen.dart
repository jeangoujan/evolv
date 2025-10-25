import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'all_sessions_screen.dart';

class SkillDetailScreen extends StatelessWidget {
  final String skillName;
  final double hoursDone;
  final double goalHours;

  const SkillDetailScreen({
    super.key,
    required this.skillName,
    required this.hoursDone,
    required this.goalHours,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = (hoursDone / goalHours).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? textLight : textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Statistics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: isDark ? textLight : textDark,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSkillProgress(context, progress, isDark),
          const SizedBox(height: 24),
          _buildWeeklyProgress(context, isDark),
          const SizedBox(height: 24),
          _buildRecentSessions(context, isDark),
        ],
      ),
    );
  }

  // --- Skill Progress Block ---
  Widget _buildSkillProgress(
      BuildContext context, double progress, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141814) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.08),
            offset: const Offset(3, 3),
            blurRadius: 10,
          ),
          BoxShadow(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.8),
            offset: const Offset(-3, -3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                skillName,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                '${hoursDone.toStringAsFixed(0)} h',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor:
                  isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(mintPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Goal: ${hoursDone.toStringAsFixed(0)} / ${goalHours.toStringAsFixed(0)} h',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // --- Weekly Progress Block ---
  Widget _buildWeeklyProgress(BuildContext context, bool isDark) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final progressValues = [0.4, 0.2, 0.0, 0.3, 0.5, 0.1, 0.8]; // mock data

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141814) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.08),
            offset: const Offset(3, 3),
            blurRadius: 10,
          ),
          BoxShadow(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.8),
            offset: const Offset(-3, -3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "This Week",
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Oct 22 – Oct 28   +15%",
            style: TextStyle(
              fontFamily: 'Inter',
              color: mintPrimary.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(days.length, (i) {
              final isToday = i == 6;
              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26 + progressValues[i] * 30,
                    height: 26 + progressValues[i] * 30,
                    decoration: BoxDecoration(
                      color: isToday
                          ? mintPrimary
                          : mintPrimary.withOpacity(progressValues[i]),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    days[i],
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight:
                          isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isDark
                          ? (isToday ? Colors.white : Colors.white70)
                          : (isToday ? Colors.black : Colors.black87),
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

  // --- Recent Sessions Block ---
  Widget _buildRecentSessions(BuildContext context, bool isDark) {
    final recent = [
      {"time": "1h 30m", "date": "Oct 22, 2025", "note": "Learned a new chord progression ✨"},
      {"time": "45m", "date": "Oct 21, 2025", "note": "Scales and arpeggios practice."},
      {"time": "2h 15m", "date": "Oct 19, 2025", "note": "Worked on improvisation."},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Sessions",
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ...recent.map((s) => _buildSessionCard(s, isDark)).toList(),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AllSessionsScreen()),
              );
            },
            child: Text(
              "Show all sessions",
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: mintPrimary,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(Map<String, String> s, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141814) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.08),
            offset: const Offset(3, 3),
            blurRadius: 10,
          ),
          BoxShadow(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.8),
            offset: const Offset(-3, -3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s["time"]!,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s["date"]!,
            style: TextStyle(
              fontFamily: 'Inter',
              color: isDark ? Colors.white70 : Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s["note"]!,
            style: TextStyle(
              fontFamily: 'Inter',
              color: isDark ? Colors.white.withOpacity(0.85) : Colors.black87,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}