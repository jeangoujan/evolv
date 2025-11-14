import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:hive_flutter/hive_flutter.dart';
import '../data/skill_repo.dart';
import '../theme/app_theme.dart';

class SessionTimerScreen extends StatefulWidget {
  final int skillId;
  final String skillName;
  final Duration targetDuration;

  const SessionTimerScreen({
    super.key,
    required this.skillId,
    required this.skillName,
    this.targetDuration = const Duration(hours: 1, minutes: 30),
  });

  @override
  State<SessionTimerScreen> createState() => _SessionTimerScreenState();
}

class _SessionTimerScreenState extends State<SessionTimerScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  bool _running = false;
  bool _completed = false;

  final _noteCtrl = TextEditingController();
  final _audioPlayer = AudioPlayer();
  final _notifications = FlutterLocalNotificationsPlugin();

  static const _boxName = 'activeTimer';
  static const _key = 'session';

  double get _progress {
    final total = widget.targetDuration.inMilliseconds;
    if (total == 0) return 0;
    return (_elapsed.inMilliseconds / total).clamp(0, 1).toDouble();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initNotifications();
    _restoreState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _noteCtrl.dispose();
    _cancelNotification();
    super.dispose();
  }

  // -------------------- NOTIFICATIONS --------------------
  Future<void> _initNotifications() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _notifications.initialize(settings);
  }

  Future<void> _scheduleNotification(Duration remain) async {
    await _cancelNotification();
    final scheduled = tz.TZDateTime.now(tz.local).add(remain);

    const android = AndroidNotificationDetails(
      'session_end_channel',
      'Session End',
      channelDescription: 'Notify when session ends',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification_2_269292'),
      playSound: true,
    );
    const ios = DarwinNotificationDetails(presentAlert: true, presentSound: true);

    await _notifications.zonedSchedule(
      1,
      'Session Complete 🎉',
      '${widget.skillName} finished!',
      scheduled,
      const NotificationDetails(android: android, iOS: ios),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> _cancelNotification() async {
    await _notifications.cancel(1);
  }

  // -------------------- HIVE STATE --------------------
  Future<void> _saveState() async {
    final box = await Hive.openBox(_boxName);
    await box.put(_key, {
      'skillId': widget.skillId,
      'skillName': widget.skillName,
      'startTime': _startTime?.toIso8601String(),
      'elapsed': _elapsed.inMilliseconds,
      'running': _running,
      'completed': _completed,
      'targetMs': widget.targetDuration.inMilliseconds,
    });
  }

  Future<void> _clearState() async {
    final box = await Hive.openBox(_boxName);
    await box.delete(_key);
    _ticker?.cancel();
    _running = false;
    _completed = false;
    _startTime = null;
    _elapsed = Duration.zero;
    _cancelNotification();
    if (mounted) setState(() {});
  }

Future<void> _restoreState() async {
  final box = await Hive.openBox(_boxName);
  final data = box.get(_key);
  if (data == null || data is! Map || data['skillId'] != widget.skillId) return;

  final bool running   = (data['running'] ?? false) == true;
  final bool completed = (data['completed'] ?? false) == true;
  final int  elapsedMs = (data['elapsed'] ?? 0) as int;
  final String? startIso = data['startTime'] as String?;
  final DateTime? start  = startIso != null ? DateTime.tryParse(startIso) : null;

  // базовое восстановление
  _elapsed   = Duration(milliseconds: elapsedMs);
  _running   = running;
  _startTime = start;
  _completed = completed;

  // если уже завершена — показываем финальный экран и ждём Save & Exit
  if (_completed) {
    _running = false;
    _ticker?.cancel();
    await _cancelNotification();

    // гарантируем, что прогресс = 100%
    if (_elapsed < widget.targetDuration) {
      _elapsed = widget.targetDuration;
    }

    if (mounted) setState(() {});
    return;
  }

  // если шёл таймер и есть старт — пересчитываем с учётом прошедшего времени
  if (_running && _startTime != null) {
    final diff = DateTime.now().difference(_startTime!);

    // если цель уже достигнута в фоне — корректно завершаем без очистки state
    if (diff >= widget.targetDuration) {
      _elapsed = widget.targetDuration;
      _onComplete(); // отмечает как завершённую, но НЕ чистит и НЕ закрывает экран
    } else {
      _elapsed = diff;
      _startTicker();
    }
  }

  if (mounted) setState(() {});
}

  // -------------------- TIMER LOGIC --------------------
  void _start() {
    if (_running) return;

    _startTime = DateTime.now().subtract(_elapsed);
    _running = true;
    _completed = false;

    _startTicker();
    final remain = widget.targetDuration - _elapsed;
    if (remain.isNegative) {
      _onComplete();
    } else {
      _scheduleNotification(remain);
    }

    _saveState();
    setState(() {});
  }

  void _pause() {
    if (!_running) return;
    _running = false;
    _ticker?.cancel();
    _cancelNotification();

    if (_startTime != null) {
      _elapsed = DateTime.now().difference(_startTime!);
    }
    _saveState();
    setState(() {});
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_running || _startTime == null) return;
      final diff = DateTime.now().difference(_startTime!);
      if (diff >= widget.targetDuration) {
        _onComplete();
      } else {
        setState(() => _elapsed = diff);
      }
    });
  }

  void _onComplete() async {
    if (_completed) return;
    _completed = true;
    _running = false;
    _ticker?.cancel();
    await _cancelNotification();
    _elapsed = widget.targetDuration;
    HapticFeedback.mediumImpact();
    await _playSound();
    await _saveState();
    if (mounted) setState(() {});
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notification-2-269292.mp3'));
    } catch (e) {
      debugPrint('Sound error: $e');
    }
  }

  // -------------------- END SESSION --------------------
  Future<void> _endSession({required bool fromCompletion}) async {
    _pause();
    final result = await _openNoteSheet(fromCompletion: fromCompletion);
    if (!mounted || result == null) return;

    try {
      final duration = _elapsed;
      final durationMinutes = duration.inSeconds < 60
          ? duration.inSeconds / 60.0
          : duration.inMinutes.toDouble();

      await SkillRepo.addSession(
        skillId: widget.skillId,
        durationMinutes: durationMinutes,
        note: _noteCtrl.text.trim(),
      );

      await _clearState();

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop(true);
      }
    } catch (e, st) {
      debugPrint('❌ Error saving session: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Error while saving session'),
          ),
        );
      }
    }
  }

  // -------------------- NOTE SHEET --------------------
  Future<Map<String, dynamic>?> _openNoteSheet(
      {required bool fromCompletion}) {
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
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1F1A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _neuShadows(isDark),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF232823)
                        : const Color(0xFFE7ECE7),
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    Navigator.of(ctx).pop({
                      'note': _noteCtrl.text.trim(),
                      'timestamp': DateTime.now().toIso8601String(),
                    });
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
            ],
          ),
        );
      },
    );
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        if (_running) {
          _pause();
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Exit session?'),
              content: const Text('Your progress for this session will be lost.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Exit', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          );
          if (shouldExit == true) {
            await _clearState();
          }
          return shouldExit ?? false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Row(
                  children: [
                    _BackButton(onPressed: () async {
                      if (_running) {
                        _pause();
                        final shouldExit = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Exit session?'),
                            content: const Text(
                                'Your progress for this session will be lost.'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text(
                                  'Exit',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (shouldExit == true && context.mounted) {
                          await _clearState();
                          Navigator.pop(context);
                        }
                      } else {
                        Navigator.pop(context);
                      }
                    }),
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
                    const SizedBox(width: 48),
                  ],
                ),
              ),
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
              const SizedBox(height: 6),
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
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "You're done! 🎉",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: _completed
                    ? _NeuroPillButton(
                        label: 'Session Complete',
                        onTap: () => _endSession(fromCompletion: true),
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
                            icon: _running
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
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

  String _format(Duration d) =>
      '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  List<BoxShadow> _neuShadows(bool isDark) => isDark
      ? [
          BoxShadow(color: Colors.black.withOpacity(0.55), offset: const Offset(6, 6), blurRadius: 14),
          BoxShadow(color: Colors.white.withOpacity(0.07), offset: const Offset(-6, -6), blurRadius: 12),
        ]
      : [
          BoxShadow(color: Colors.black.withOpacity(0.10), offset: const Offset(6, 6), blurRadius: 14),
          const BoxShadow(color: Colors.white, offset: Offset(-6, -6), blurRadius: 12),
        ];
}

// -------------------- Widgets --------------------

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: Icon(Icons.arrow_back_ios_new,
          size: 22, color: isDark ? textLight : textDark),
      onPressed: onPressed,
    );
  }
}

class _RingTimer extends StatefulWidget {
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
  State<_RingTimer> createState() => _RingTimerState();
}

class _RingTimerState extends State<_RingTimer>
    with TickerProviderStateMixin {
  bool _pressed = false;

  late final AnimationController _orbitCtrl;
  late final AnimationController _breathCtrl;

  @override
  void initState() {
    super.initState();

    // Вращающаяся подсветка (10 секунд полный круг)
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // "Breathing" эффект
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
      lowerBound: 0.85,
      upperBound: 1.05,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
      },
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onCenterTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: Listenable.merge([_orbitCtrl, _breathCtrl]),
          builder: (context, child) {
            final orbitAngle = _orbitCtrl.value * 6.28318; // 2π

            final breatheScale = _pressed
                ? 1.0
                : _breathCtrl.value; // не дышит в режиме прожатия

            return Transform.scale(
              scale: breatheScale,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = (constraints.biggest.shortestSide * 0.70)
                      .clamp(180.0, 420.0);

                  final ringSize = size * 0.82;
                  final stroke =
                      (size * 0.06).clamp(8.0, 18.0);
                  final fontSize =
                      (size * 0.16).clamp(28.0, 48.0);

                  return SizedBox(
                    width: size,
                    height: size,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // -----------------------------------------
                        // 🔵 1. Вращающаяся подсветка вокруг круга
                        // -----------------------------------------
                        Transform.rotate(
                          angle: orbitAngle,
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                startAngle: 0,
                                endAngle: 6.28318,
                                colors: [
                                  mintPrimary.withOpacity(0.05),
                                  Colors.transparent,
                                  mintPrimary.withOpacity(0.05),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // -----------------------------------------
                        // 🔆 2. Неоморфная основа круга
                        // -----------------------------------------
                        Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF181C18)
                                : Colors.white,
                            boxShadow: _pressed
                                ? _pressedShadow(isDark)
                                : _normalShadow(isDark),
                          ),
                        ),

                        // -----------------------------------------
                        // ⚪ 3. Бэкграунд кольца
                        // -----------------------------------------
                        SizedBox(
                          width: ringSize,
                          height: ringSize,
                          child: CircularProgressIndicator(
                            value: 1,
                            strokeWidth: stroke,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : const Color(0xFFE5EBE5),
                            ),
                          ),
                        ),

                        // -----------------------------------------
                        // 🟢 4. Прогресс кольца (анимированный)
                        // -----------------------------------------
                        SizedBox(
                          width: ringSize,
                          height: ringSize,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                                begin: 0, end: widget.progress),
                            duration:
                                const Duration(milliseconds: 300),
                            builder: (_, v, __) =>
                                CircularProgressIndicator(
                              value: v,
                              strokeWidth: stroke,
                              backgroundColor: Colors.transparent,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                      mintPrimary),
                            ),
                          ),
                        ),

                        // -----------------------------------------
                        // 📝 5. Текст времени
                        // -----------------------------------------
                        Text(
                          widget.timeText,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w800,
                            fontSize: fontSize,
                            color:
                                isDark ? textLight : textDark,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // ☁️ Неоморфные тени
  // -------------------------------------------------------

  List<BoxShadow> _normalShadow(bool isDark) => isDark
      ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            offset: const Offset(10, 10),
            blurRadius: 26,
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
            blurRadius: 26,
          ),
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-10, -10),
            blurRadius: 18,
          ),
        ];

  List<BoxShadow> _pressedShadow(bool isDark) => isDark
      ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.75),
            offset: const Offset(4, 4),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            offset: const Offset(-4, -4),
            blurRadius: 14,
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            offset: const Offset(4, 4),
            blurRadius: 14,
          ),
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-4, -4),
            blurRadius: 14,
          ),
        ];
}


class _NeuroPillButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _NeuroPillButton({required this.label, required this.onTap});

  @override
  State<_NeuroPillButton> createState() => _NeuroPillButtonState();
}

class _NeuroPillButtonState extends State<_NeuroPillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F241F) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color:
                  isDark ? const Color(0xFF232823) : const Color(0xFFE7ECE7),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.55)
                    : Colors.black.withOpacity(0.1),
                offset: const Offset(6, 6),
                blurRadius: 14,
              ),
              BoxShadow(
                color: isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.white.withOpacity(0.9),
                offset: const Offset(-6, -6),
                blurRadius: 12,
              ),
            ],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: isDark ? textLight : textDark,
            ),
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