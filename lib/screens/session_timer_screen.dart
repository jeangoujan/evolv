import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class SessionTimerScreen extends StatefulWidget {
  final String skillName;

  /// Боевой дефолт будет 1h30m, но для теста можно передать 10s.
  final Duration targetDuration;

  const SessionTimerScreen({
    super.key,
    required this.skillName,
    this.targetDuration = const Duration(seconds: 10), // ← сейчас 10s для тестов
  });

  @override
  State<SessionTimerScreen> createState() => _SessionTimerScreenState();
}

class _SessionTimerScreenState extends State<SessionTimerScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _running = false;
  bool _completed = false;

  final TextEditingController _noteCtrl = TextEditingController();

  double get _progress {
    final total = widget.targetDuration.inMilliseconds;
    if (total == 0) return 0;
    return (_elapsed.inMilliseconds / total).clamp(0, 1).toDouble();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_running) return true;
    _pause();
    final shouldExit = await _confirmExitDialog();
    return shouldExit ?? false;
  }

  void _start() {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _elapsed += const Duration(seconds: 1);
        if (_elapsed >= widget.targetDuration) {
          _completed = true;
          _running = false;
          _timer?.cancel();
          HapticFeedback.mediumImpact(); // 📳 вибрация по завершении
        }
      });
    });
    setState(() {});
  }

  void _pause() {
    _running = false;
    _timer?.cancel();
    setState(() {});
  }

  Future<void> _endSession({required bool fromCompletion}) async {
    _pause();
    final result = await _openNoteSheet(fromCompletion: fromCompletion);
    if (!mounted) return;
    if (result == null) return;

    // Возвращаем данные на прошлый экран (Home/детали навыка)
    Navigator.pop(context, result);
  }

  Future<Map<String, dynamic>?> _openNoteSheet({required bool fromCompletion}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    _noteCtrl.clear();

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF181C18) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Text(
                fromCompletion ? 'Session complete 🎉' : 'End session',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: isDark ? textLight : textDark,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add a note (optional)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1F1A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _neuShadows(isDark),
                  border: Border.all(
                    color: isDark ? const Color(0xFF232823) : const Color(0xFFE7ECE7),
                  ),
                ),
                child: TextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mintPrimary,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    final payload = {
                      'skill': widget.skillName,
                      'seconds': _elapsed.inSeconds,
                      'note': _noteCtrl.text.trim(),
                      'completed': fromCompletion,
                      'timestamp': DateTime.now().toIso8601String(),
                    };
                    Navigator.pop(ctx, payload);
                  },
                  child: const Text(
                    'Save & Exit',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _confirmExitDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF181C18) : Colors.white,
        title: Text(
          'Exit session?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: isDark ? textLight : textDark,
          ),
        ),
        content: Text(
          'The timer is still running. Do you want to exit?',
          style: TextStyle(
            fontFamily: 'Inter',
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // ---- Top bar ----
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Row(
                  children: [
                    _BackNeuroButton(
                      onPressed: () async {
                        final shouldPop = await _onWillPop();
                        if (shouldPop && mounted) Navigator.pop(context);
                      },
                    ),
                    const Spacer(),
                    Text(
                      '${widget.skillName} Practice',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: isDark ? textLight : textDark,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // симметрия с кнопкой назад
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ---- Ring timer ----
              Expanded(
                child: Center(
                  child: _RingTimer(
                    progress: _progress,
                    timeText: _format(_elapsed),
                    isDark: isDark,
                    onCenterTap: () => _running ? _pause() : _start(),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Goal: ${_format(widget.targetDuration)}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
                if (_completed)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      "You're done! 🎉",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),

              const SizedBox(height: 18),

              // ---- Bottom controls ----
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: _completed
                    ? SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mintPrimary,
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () => _endSession(fromCompletion: true),
                          child: const Text(
                            'Session Complete',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _NeuroPillButton(
                              label: 'End Session',
                              onTap: () => _endSession(fromCompletion: false),
                            ),
                          ),
                          const SizedBox(width: 16),
                          _RoundMintButton(
                            icon: _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            onTap: () => _running ? _pause() : _start(),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _format(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  List<BoxShadow> _neuShadows(bool isDark) => isDark
      ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            offset: const Offset(6, 6),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.07),
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            offset: const Offset(6, 6),
            blurRadius: 14,
          ),
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-6, -6),
            blurRadius: 12,
          ),
        ];
}

/// ---------- Widgets ----------

class _BackNeuroButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BackNeuroButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IconButton(
      icon: Icon(
        Icons.arrow_back_ios_new,
        size: 22,
        color: isDark ? textLight : textDark,
      ),
      onPressed: onPressed,
    );
  }
}


class _RingTimer extends StatelessWidget {
  final double progress;
  final String timeText;
  final bool isDark;
  final VoidCallback onCenterTap;

  const _RingTimer({
    required this.progress,
    required this.timeText,
    required this.isDark,
    required this.onCenterTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgTrack = isDark ? Colors.white10 : const Color(0xFFE5EBE5);

    return GestureDetector(
      onTap: onCenterTap, // тап по кругу тоже старт/пауза
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF181C18) : Colors.white,
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.55),
                    offset: const Offset(10, 10),
                    blurRadius: 22,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.07),
                    offset: const Offset(-10, -10),
                    blurRadius: 18,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    offset: const Offset(10, 10),
                    blurRadius: 22,
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-10, -10),
                    blurRadius: 18,
                  ),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 230,
              height: 230,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 16,
                valueColor: AlwaysStoppedAnimation<Color>(bgTrack),
              ),
            ),
            SizedBox(
              width: 230,
              height: 230,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 300),
                builder: (_, v, __) {
                  return CircularProgressIndicator(
                    value: v,
                    strokeWidth: 16,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(mintPrimary),
                  );
                },
              ),
            ),
            Text(
              timeText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                fontSize: 40,
                color: isDark ? textLight : textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeuroPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NeuroPillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F241F) : Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isDark ? const Color(0xFF232823) : const Color(0xFFE7ECE7),
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.55),
                    offset: const Offset(6, 6),
                    blurRadius: 14,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.07),
                    offset: const Offset(-6, -6),
                    blurRadius: 12,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    offset: const Offset(6, 6),
                    blurRadius: 14,
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-6, -6),
                    blurRadius: 12,
                  ),
                ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: isDark ? textLight : textDark,
          ),
        ),
      ),
    );
  }
}

class _RoundMintButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundMintButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: mintPrimary,
          boxShadow: [
            BoxShadow(
              color: mintPrimary.withOpacity(0.35),
              blurRadius: 22,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, size: 34, color: Colors.white),
      ),
    );
  }
}