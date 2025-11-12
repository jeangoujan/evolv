import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';

class TipJarScreen extends StatelessWidget {
  const TipJarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tips = [
      {'emoji': '☕', 'label': 'Buy me a coffee', 'amount': '\$0.99'},
      {'emoji': '🍩', 'label': 'Send some donuts', 'amount': '\$2.99'},
      {'emoji': '💎', 'label': 'Big supporter', 'amount': '\$4.99'},
    ];

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
            Text(
              'If Evolv helps you stay focused and grow,\nconsider leaving a small tip 💚',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            ...tips.map((t) => _TipCard(
              emoji: t['emoji']!,
              label: t['label']!,
              amount: t['amount']!,
              onTap: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Thanks for your support 🙏'),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 40),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    duration: const Duration(seconds: 2),
                  ),
                );
                // TODO: подключить in-app purchase
              },
            )),
            const Spacer(),
            Text(
              'Your support keeps Evolv ad-free and independent.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
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

class _TipCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String amount;
  final VoidCallback onTap;

  const _TipCard({
    required this.emoji,
    required this.label,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C201C) : Colors.white,
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
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: isDark ? textLight : textDark,
                ),
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: mintPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}