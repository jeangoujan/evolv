import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../theme/app_theme.dart';
import '../data/hive_boxes.dart';
import '../data/models/skill.dart';
import '../data/models/session.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isLoading = false;

  // ----------------- EXPORT -----------------

  Future<void> _exportBackup() async {
    setState(() => _isLoading = true);
    try {
      final skillsBox = HiveBoxes.skillBox();
      final sessionsBox = HiveBoxes.sessionBox();

      final skills = skillsBox.values.toList();
      final sessions = sessionsBox.values.toList();

      final data = {
        'skills': skills.map(_skillToJson).toList(),
        'sessions': sessions.map(_sessionToJson).toList(),
      };

      final jsonStr = jsonEncode(data);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/evolv_backup.json');
      await file.writeAsString(jsonStr);

      final shareResult = await Share.shareXFiles(
        [XFile(file.path)],
        text: '📦 Here is your Evolv backup file.',
        // фикс для iOS: non-zero rect
        sharePositionOrigin: Rect.fromCenter(
          center: MediaQuery.of(context).size.center(Offset.zero),
          width: 10,
          height: 10,
        ),
      );

      if (shareResult.status == ShareResultStatus.success) {
        _showSnack('Backup exported successfully!');
      } else {
        // отменили — молчим
        debugPrint('ℹ️ Share canceled / not completed');
      }
    } catch (e) {
      debugPrint('❌ Export error: $e');
      _showSnack('Failed to export backup.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ----------------- IMPORT -----------------

  Future<void> _importBackup() async {
  try {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (picked == null || picked.files.single.path == null) {
      debugPrint('ℹ️ Import canceled by user');
      return;
    }

    setState(() => _isLoading = true);

    final file = File(picked.files.single.path!);
    final jsonStr = await file.readAsString();
    final data = jsonDecode(jsonStr);

    if (data is! Map ||
        data['skills'] == null ||
        data['sessions'] == null) {
      _showSnack('Invalid backup file.');
      return;
    }

    final skillsJson = (data['skills'] as List).cast<dynamic>();
    final sessionsJson = (data['sessions'] as List).cast<dynamic>();

    final skillBox = HiveBoxes.skillBox();
    final sessionBox = HiveBoxes.sessionBox();

    int addedSkills = 0;
    int addedSessions = 0;

    // --- Добавляем новые навыки ---
    for (final raw in skillsJson) {
      if (raw is! Map) continue;
      final id = raw['id'];

      // Проверяем, есть ли уже такой навык
      final exists = skillBox.values.any((s) => s.id == id);
      if (exists) continue;

      final s = Skill(
        id: id,
        name: raw['name'] ?? 'Skill',
        goalHours: (raw['goalHours'] ?? 0).toDouble(),
        totalHours: (raw['totalHours'] ?? 0).toDouble(),
        currentStreak: raw['currentStreak'] ?? 1,
        colorValue: raw['colorValue'] ?? 0xFF81C784,
        iconCode: raw['iconCode'] ?? 0xe04e
      );
      await skillBox.put(s.id, s);
      addedSkills++;
    }

    // --- Добавляем новые сессии ---
    for (final raw in sessionsJson) {
      if (raw is! Map) continue;
      final id = raw['id'];

      final exists = sessionBox.values.any((sess) => sess.id == id);
      if (exists) continue;

      final sess = Session(
        id: id,
        skillId: raw['skillId'],
        durationMinutes: (raw['durationMinutes'] ?? 0).toDouble(),
        date: DateTime.tryParse(raw['date'] ?? '') ?? DateTime.now(),
        note: raw['note'],
      );
      await sessionBox.put(sess.id, sess);
      addedSessions++;
    }

    _showSnack('✅ Imported $addedSkills skill(s) and $addedSessions session(s)');
  } catch (e) {
    debugPrint('❌ Import error: $e');
    _showSnack('Failed to import backup.');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  // ----------------- UI -----------------

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: mintPrimary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin:
            const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Data & Backup',
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: isDark ? textLight : textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.cloud_rounded,
                size: 72,
                color: mintPrimary.withOpacity(0.9),
              ),
              const SizedBox(height: 16),
              Text(
                'Export or restore your Evolv data',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFamily: 'Inter',
                  color: isDark
                      ? Colors.white70
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 60),

              // Export
              _AnimatedTap(
                onTap: _isLoading ? () {} : _exportBackup,
                borderRadius: 28,
                isButton: true,
                child: _NeumorphicButton(
                  text: _isLoading
                      ? 'Loading...'
                      : 'Export Backup',
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 20),

              // Import
              _AnimatedTap(
                onTap: _isLoading ? () {} : _importBackup,
                borderRadius: 28,
                isButton: true,
                child: _NeumorphicButton(
                  text: _isLoading
                      ? 'Loading...'
                      : 'Import Backup',
                  isDark: isDark,
                ),
              ),

              const Spacer(),
              Text(
                'Your data is stored locally\nand only leaves device when you export it.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: isDark
                      ? Colors.white54
                      : Colors.black54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------- Neumorphic button -----------------

class _NeumorphicButton extends StatelessWidget {
  final String text;
  final bool isDark;
  const _NeumorphicButton({
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 40, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F241F) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.45 : 0.10),
            offset: const Offset(4, 4),
            blurRadius: 12,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(isDark ? 0.08 : 1),
            offset: const Offset(-3, -3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: theme.colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}

// ----------------- Tap animation (как в HomeScreen) -----------------

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

  void _down(TapDownDetails _) =>
      setState(() => _pressed = true);
  void _up(TapUpDetails _) =>
      setState(() => _pressed = false);
  void _cancel() =>
      setState(() => _pressed = false);

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
          borderRadius:
              BorderRadius.circular(widget.borderRadius),
          boxShadow: applied,
        ),
        child: widget.child,
      ),
    );
  }

  List<BoxShadow> _boost(List<BoxShadow> src, double k) =>
      src
          .map((s) => s.copyWith(
                blurRadius: s.blurRadius * k,
              ))
          .toList();
}

// ----------------- JSON helpers -----------------

Map<String, dynamic> _skillToJson(Skill s) => {
      'id': s.id,
      'name': s.name,
      'goalHours': s.goalHours,
      'totalHours': s.totalHours,
      'currentStreak': s.currentStreak,
      'colorValue': s.colorValue,
      'iconCode': s.iconCode,
    };

Map<String, dynamic> _sessionToJson(Session s) => {
      'id': s.id,
      'skillId': s.skillId,
      'durationMinutes': s.durationMinutes,
      'date': s.date.toIso8601String(),
      'note': s.note,
    };