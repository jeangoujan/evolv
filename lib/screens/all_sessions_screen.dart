import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AllSessionsScreen extends StatelessWidget {
  const AllSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          'All Sessions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: isDark ? textLight : textDark,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          "All sessions list coming soon...",
          style: TextStyle(fontFamily: 'Inter'),
        ),
      ),
    );
  }
}