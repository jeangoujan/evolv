import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:hive_flutter/hive_flutter.dart';
import '../data/hive_boxes.dart';
import '../data/models/session.dart';
import '../data/models/skill.dart';
import '../theme/app_theme.dart';

class SessionTimerScreen extends StatefulWidget {
  final int skillId;
  final String skillName;
  final Duration targetDuration;

  const SessionTimerScreen({
    super.key,
    required this.skillName,
    required this.skillId,
    this.targetDuration = const Duration(seconds: 15),
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

  final TextEditingController _noteCtrl = TextEditingController();
  final _audioPlayer = AudioPlayer();
  final _notifications = FlutterLocalNotificationsPlugin();

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
  }

  Future<void> _initNotifications() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _notifications.initialize(settings);
  }

  Future<void> _scheduleEndNotification() async {
    final scheduledTime = tz.TZDateTime.now(tz.local).add(widget.targetDuration);

    const androidDetails = AndroidNotificationDetails(
      'session_end_channel',
      'Session End Alert',
      channelDescription: 'Alerts when your practice session finishes',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification_2_269292'),
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
    );

    await _notifications.zonedSchedule(
      1,
      'Session Complete 🎉',
      '${widget.skillName} session finished!',
      scheduledTime,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _cancelScheduledNotification() async {
    await _notifications.cancel(1);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _noteCtrl.dispose();
    _cancelScheduledNotification();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_startTime == null) return;

    if (state == AppLifecycleState.resumed && _running) {
      final diff = DateTime.now().difference(_startTime!);
      if (diff >= widget.targetDuration) {
        _onCompleted();
      } else {
        setState(() => _elapsed = diff);
      }
    }
  }

  void _start() {
    if (_running) return;
    _startTime ??= DateTime.now().subtract(_elapsed);
    _running = true;
    _playFinishSound();
    _scheduleEndNotification(); // планируем уведомление

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_running || _startTime == null) return;
      final diff = DateTime.now().difference(_startTime!);

      if (diff >= widget.targetDuration) {
        _onCompleted();
      } else {
        setState(() => _elapsed = diff);
      }
    });
    setState(() {});
  }

  void _pause() {
    _running = false;
    _ticker?.cancel();
    _cancelScheduledNotification(); // отменяем уведомление
    setState(() {});
  }

  void _onCompleted() {
    if (_completed) return;
    _completed = true;
    _running = false;
    _ticker?.cancel();
    _cancelScheduledNotification();
    _elapsed = widget.targetDuration;
    HapticFeedback.mediumImpact();
    _playFinishSound();
    setState(() {});
  }

  Future<void> _playFinishSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notification-2-269292.mp3'));
    } catch (e) {
      debugPrint('Sound error: $e');
    }
  }

  Future<void> _endSession({required bool fromCompletion}) async {
    _pause();
    final result = await _openNoteSheet(fromCompletion: fromCompletion);
    if (!mounted || result == null) return;

    try {
      final now = DateTime.now();
      final duration = _elapsed;
      final durationMinutes = duration.inSeconds < 60
          ? duration.inSeconds / 60.0
          : duration.inMinutes.toDouble();

      final sessionBox = Hive.box<Session>('sessions');
      final skillBox = HiveBoxes.skillBox();

      final safeId = now.microsecondsSinceEpoch % 0xFFFFFFFF;
      final session = Session(
        id: safeId,
        skillId: widget.skillId,
        durationMinutes: durationMinutes,
        date: now,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      await sessionBox.put(session.id, session);

      final skill = skillBox.get(widget.skillId);
      if (skill != null) {
        skill.totalHours += durationMinutes / 60.0;
        await skill.save();
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e, st) {
      debugPrint('❌ Error saving session: $e\n$st');
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Row(
                children: [
                  _BackNeuroButton(
                    onPressed: () async {
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
                          Navigator.pop(context);
                        }
                      } else {
                        Navigator.pop(context);
                      }
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
                    ? StatefulBuilder(
                        builder: (context, setState) {
                          bool pressed = false;
                          return GestureDetector(
                            onTapDown: (_) {
                              setState(() => pressed = true);
                              HapticFeedback.lightImpact();
                            },
                            onTapUp: (_) {
                              setState(() => pressed = false);
                              _endSession(fromCompletion: true);
                            },
                            onTapCancel: () => setState(() => pressed = false),
                            child: AnimatedScale(
                              scale: pressed ? 0.96 : 1.0,
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeOut,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: mintPrimary, // ✅ всегда зелёная
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: [
                                    BoxShadow(
                                      color: mintPrimary.withOpacity(0.35),
                                      blurRadius: 22,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                alignment: Alignment.center,
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
                            ),
                          );
                        },
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
    );
  }

  String _format(Duration d) =>
      '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: Icon(Icons.arrow_back_ios_new,
          size: 22, color: isDark ? textLight : textDark),
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
      onTap: onCenterTap,
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
                builder: (_, v, __) => CircularProgressIndicator(
                  value: v,
                  strokeWidth: 16,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(mintPrimary),
                ),
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

class _NeuroPillButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _NeuroPillButton({
    required this.label,
    required this.onTap,
  });

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
        HapticFeedback.lightImpact(); // 🔸 добавили мягкую вибрацию
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