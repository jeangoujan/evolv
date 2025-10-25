import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const EvolvApp());
}

class EvolvApp extends StatelessWidget {
  const EvolvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Evolv',
      debugShowCheckedModeBanner: false,
      theme: evolvLightTheme(),
      darkTheme: evolvDarkTheme(),
      themeMode: ThemeMode.system, // автоматически по системе
      home: const HomeScreen(),
    );
  }
}

class EvolvHome extends StatelessWidget {
  const EvolvHome({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Evolv')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to Evolv 👋',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Text(
              'Track your growth.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Start'),
        icon: const Icon(Icons.play_arrow),
      ),
    );
  }
}