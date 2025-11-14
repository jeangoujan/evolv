import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TipJarScreen extends StatelessWidget {
  const TipJarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Support Evolv',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: isDark ? textLight : textDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 40),

            /// ⭐ КРУГЛЫЙ ЭЛЕМЕНТ КАК НА "NO SKILLS YET"
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1A1D1A) : const Color(0xFFF3F6F3),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.5)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 30,
                    spreadRadius: 4,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Center(
                child: Text(
                  '💚',
                  style: TextStyle(fontSize: 44),
                ),
              ),
            ),

            const SizedBox(height: 26),

            /// Основной текст
            Text(
              'The Tip Jar feature is coming soon!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? textLight : textDark,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Thank you for supporting Evolv 💚',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                height: 1.4,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),

            const Spacer(),

            /// Нижний текст
            Text(
              'Evolv will stay ad-free.\nYour support means a lot.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.3,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}