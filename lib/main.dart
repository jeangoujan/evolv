import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'screens/home_screen.dart';
import 'data/hive_boxes.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  await HiveBoxes.init();

  // ✅ Оборачиваем приложение в ChangeNotifierProvider
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const EvolvApp(),
    ),
  );
}

class EvolvApp extends StatelessWidget {
  const EvolvApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Теперь Provider доступен
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Evolv',
      debugShowCheckedModeBanner: false,
      theme: evolvLightTheme(),
      darkTheme: evolvDarkTheme(),
      themeMode: themeProvider.themeMode, // ← всё работает
      home: const SplashScreen(),
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
            Text('Welcome to Evolv 👋', style: theme.textTheme.titleMedium),
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


Future<void> clearHiveDebug() async {
  // Если боксы были открыты — чистим
  if (Hive.isBoxOpen('skills')) await Hive.box('skills').clear();
  if (Hive.isBoxOpen('sessions')) await Hive.box('sessions').clear();
  if (Hive.isBoxOpen('activeTimer')) await Hive.box('activeTimer').clear();

  // Полностью удаляем с диска
  await Hive.deleteBoxFromDisk('skills');
  await Hive.deleteBoxFromDisk('sessions');
  await Hive.deleteBoxFromDisk('activeTimer');

  print('🔥 Hive completely wiped (debug)');
}