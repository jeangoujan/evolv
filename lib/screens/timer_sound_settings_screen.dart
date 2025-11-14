import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';

import '../theme/app_theme.dart';

class TimerSoundSettingsScreen extends StatefulWidget {
  const TimerSoundSettingsScreen({super.key});

  @override
  State<TimerSoundSettingsScreen> createState() =>
      _TimerSoundSettingsScreenState();
}

class _TimerSoundSettingsScreenState extends State<TimerSoundSettingsScreen> {
  String? _filePath;
  String? _fileName;
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadSound();
  }

  Future<void> _loadSound() async {
    final box = await Hive.openBox('settings');
    setState(() {
      _filePath = box.get('customTimerSoundPath');
      _fileName = box.get('customTimerSoundName');
    });
  }

  Future<void> _pickSound() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'aac', 'm4a'],
    );

    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    final file = File(path);

    // Проверим длительность
    final tempPlayer = AudioPlayer();
    await tempPlayer.setSource(DeviceFileSource(path));
    final duration = await tempPlayer.getDuration();

    if (duration == null || duration.inSeconds > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Sound must be 10 seconds or shorter.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter'),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      );
      return;
    }

    final box = await Hive.openBox('settings');
    await box.put('customTimerSoundPath', path);
    await box.put('customTimerSoundName', result.files.single.name);

    setState(() {
      _filePath = path;
      _fileName = result.files.single.name;
    });
  }

  Future<void> _playSound() async {
    if (_filePath == null) return;

    await _player.stop();
    await _player.play(DeviceFileSource(_filePath!));
  }

  Future<void> _resetSound() async {
    final box = await Hive.openBox('settings');
    await box.delete('customTimerSoundPath');
    await box.delete('customTimerSoundName');

    setState(() {
      _filePath = null;
      _fileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Timer Sound',
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: isDark ? textLight : textDark,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: SafeArea(
        minimum: const EdgeInsets.only(top: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _NeuroCard(
                child: Column(
                  children: [
                    _SettingTile(
                      icon: Icons.upload_rounded,
                      title: 'Select Custom Sound',
                      subtitle: 'Up to 10 seconds',
                      onTap: _pickSound,
                    ),
                    _SettingDivider(),
                    _SettingTile(
                      icon: Icons.play_arrow_rounded,
                      title: 'Preview',
                      subtitle: _filePath == null
                          ? 'No sound selected'
                          : _fileName ?? 'Custom sound',
                      onTap: _filePath == null ? null : _playSound,
                    ),
                    _SettingDivider(),
                    _SettingTile(
                      icon: Icons.refresh_rounded,
                      title: 'Reset to Default',
                      subtitle: 'Use built-in timer sound',
                      onTap: _filePath == null ? null : _resetSound,
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
}

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

class _SettingTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  State<_SettingTile> createState() => _SettingTileState();
}

class _SettingTileState extends State<_SettingTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = widget.onTap != null;

    return GestureDetector(
      onTapDown: enabled
          ? (_) {
              setState(() => _pressed = true);
            }
          : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onTap,
      behavior: HitTestBehavior.translucent,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : 0.45,
          child: ListTile(
            leading: Icon(widget.icon, color: mintPrimary, size: 26),
            title: Text(
              widget.title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: isDark ? textLight : textDark,
              ),
            ),
            subtitle: widget.subtitle != null
                ? Text(
                    widget.subtitle!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  )
                : null,
            trailing: enabled
                ? const Icon(Icons.chevron_right_rounded,
                    color: Colors.grey, size: 20)
                : null,
          ),
        ),
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