import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import 'backup_screen.dart';
import 'tip_jar_screen.dart';
import 'timer_sound_settings_screen.dart'; // 👈 НОВЫЙ ИМПОРТ

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Duration _defaultDuration = const Duration(hours: 1, minutes: 30);

  // 👇 подпись для пункта "Timer Sound"
  String _timerSoundLabel = 'Default sound';

  @override
  void initState() {
    super.initState();
    _loadDuration();
  }

  Future<void> _loadDuration() async {
    final box = await Hive.openBox('settings');
    final minutes = box.get('defaultDurationMinutes', defaultValue: 90);

    final customPath = box.get('customTimerSoundPath') as String?;
  

    setState(() {
      _defaultDuration = Duration(minutes: minutes);
      _timerSoundLabel = customPath != null ? 'Custom' : 'Default';
    });
  }

  Future<void> _saveDuration(Duration duration) async {
    final box = await Hive.openBox('settings');
    await box.put('defaultDurationMinutes', duration.inMinutes);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }

  Future<void> _pickDuration() async {
    Duration temp = _defaultDuration;
    final result = await showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SizedBox(
        height: 280,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              'Select Default Duration',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Theme.of(context).brightness == Brightness.dark
                    ? textLight
                    : textDark,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: CupertinoTimerPicker(
                mode: CupertinoTimerPickerMode.hm,
                initialTimerDuration: _defaultDuration,
                onTimerDurationChanged: (v) => temp = v,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx, temp),
              child: Text(
                'Save',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: mintPrimary,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _defaultDuration = result);
      _saveDuration(result);
    }
  }

  // 👇 отдельный метод для открытия экрана настроек звука,
  // чтобы после возврата обновлять подпись
  Future<void> _openTimerSoundSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TimerSoundSettingsScreen()),
    );
    // после возврата обновляем подпись (Default / Custom)
    await _loadDuration();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: isDark ? textLight : textDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        minimum: const EdgeInsets.only(top: 8, bottom: 12),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NeuroCard(
                child: Column(
                  children: [
                    _SettingSwitchTile(
                      icon: Icons.brightness_6_rounded,
                      title: 'Light / Dark Mode',
                      value: isDarkMode,
                      onChanged: (v) {
                        themeProvider.setTheme(
                          v ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                    ),
                    _SettingDivider(),
                    _SettingButtonTile(
                      icon: Icons.timer_outlined,
                      title: 'Default Session Duration',
                      subtitle: _formatDuration(_defaultDuration),
                      onTap: _pickDuration,
                    ),

                    // 👇 НОВЫЙ ПУНКТ "Timer Sound"
                    _SettingDivider(),
                    _SettingButtonTile(
                      icon: Icons.music_note_rounded,
                      title: 'Timer Sound',
                      subtitle: _timerSoundLabel,
                      onTap: _openTimerSoundSettings,
                    ),

                    _SettingDivider(),
                    _SettingButtonTile(
                      icon: Icons.favorite_outline_rounded,
                      title: 'Support Evolv 💚',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TipJarScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _NeuroCard(
                child: Column(
                  children: [
                    _SettingButtonTile(
                      icon: Icons.cloud_outlined,
                      title: 'Data & Backup',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BackupScreen()),
                        );
                      },
                    ),
                    _SettingDivider(),
                    _SettingButtonTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy',
                      onTap: _openPrivacyPolicy,
                    ),
                    _SettingDivider(),
                    _SettingButtonTile(
                      icon: Icons.info_outline_rounded,
                      title: 'About',
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Column(
                children: [
                  Text(
                    'Evolv v1.0.0',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _contactSupport,
                    child: Text(
                      'Contact Support',
                      style: TextStyle(
                        color: mintPrimary,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _contactSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@evolvapp.site',
      queryParameters: {'subject': 'Evolv App Support'},
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final Uri url = Uri.parse('https://evolvapp.site/privacy');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Privacy Policy'),
        ),
      );
    }
  }

  void _showAboutDialog(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        backgroundColor: isDark ? const Color(0xFF1C201C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: isDark ? const Color(0xFF181C18) : Colors.white,
            boxShadow: isDark
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
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // small Evolv icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: mintPrimary, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: mintPrimary.withOpacity(0.35),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Text(
                "About Evolv",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: isDark ? textLight : textDark,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "Evolv helps you grow through\nconsistent skill practice.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  height: 1.4,
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Version: 1.0.0\nBuilt with ❤️ for lifelong learners",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  height: 1.4,
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Made by Jeangoujan",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? textLight : textDark,
                ),
              ),

              const SizedBox(height: 28),

              // neumorphic close button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 26, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: isDark ? const Color(0xFF1D211D) : Colors.white,
                    border: Border.all(
                      color:
                          isDark ? const Color(0xFF232823) : const Color(0xFFE7ECE7),
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
                    "Close",
                    style: TextStyle(
                      color: mintPrimary,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
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
}
}

// остальной низ файла (_NeuroCard, _SettingButtonTile, _AnimatedTap и т.д.)
// остаётся без изменений

// ---------------------------------------------------------------------------
// ОСТАЛЬНЫЕ КОМПОНЕНТЫ (без изменений, только добавлен subtitle)
// ---------------------------------------------------------------------------

class _NeuroCard extends StatelessWidget {
  final Widget child;
  const _NeuroCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181C18) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF232823) : const Color(0xFFE7ECE7),
          width: 1,
        ),
        boxShadow: isDark
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
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: child,
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _AnimatedTap(
      onTap: () => onChanged(!value),
      borderRadius: 28,
      child: ListTile(
        leading: Icon(icon, color: mintPrimary, size: 26),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? textLight
                : textDark,
          ),
        ),
        trailing: Switch(
          value: value,
          activeColor: mintPrimary,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SettingButtonTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingButtonTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _AnimatedTap(
      onTap: onTap,
      borderRadius: 28,
      child: ListTile(
        leading: Icon(icon, color: mintPrimary, size: 24),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            color: isDark ? textLight : textDark,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              )
            : null,
        trailing: const Icon(Icons.chevron_right_rounded,
            color: Colors.grey, size: 20),
      ),
    );
  }
}

class _SettingDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      color: isDark ? Colors.white10 : Colors.black12,
      indent: 56,
      endIndent: 16,
    );
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