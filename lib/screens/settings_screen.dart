import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
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
                    onTap: () {},
                  ),
                  _SettingDivider(),
                  _SettingButtonTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy',
                    onTap: () {},
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
            const Spacer(),
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
    );
  }

  void _contactSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@evolvapp.com',
      queryParameters: {'subject': 'Evolv App Support'},
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C201C) : Colors.white,
        title: const Text(
          'About Evolv',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Evolv helps you grow through consistent skill practice.\n\n'
          'Version: 1.0.0\nDeveloped with ❤️ for lifelong learners.',
          style: TextStyle(fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Карточка в стиле HomeScreen (_SkillCard неоморфный стиль)
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

// ---------------------------------------------------------------------------
// Switch Tile (в стиле SkillCard + _AnimatedTap)
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// Кнопка (в стиле HomeScreen карточек)
// ---------------------------------------------------------------------------
class _SettingButtonTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingButtonTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            color: Theme.of(context).brightness == Brightness.dark
                ? textLight
                : textDark,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: Colors.grey, size: 20),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Divider между пунктами
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// Тот же _AnimatedTap, что и на HomeScreen
// ---------------------------------------------------------------------------
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