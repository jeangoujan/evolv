// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'data/hive_boxes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Инициализируем Hive
  await Hive.initFlutter();

  // 2) Открываем все боксы
  await HiveBoxes.init();

  // 3) Создаём themeProvider (он внутри читает Hive 'settings')
  final themeProvider = ThemeProvider();

  // 4) Стартуем приложение
  runApp(
    ChangeNotifierProvider<ThemeProvider>.value(
      value: themeProvider,
      child: const EvolvApp(),
    ),
  );
}

class EvolvApp extends StatelessWidget {
  const EvolvApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Nexlo',
      debugShowCheckedModeBanner: false,
      theme: evolvLightTheme(),
      darkTheme: evolvDarkTheme(),
      themeMode: themeProvider.themeMode,
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
      appBar: AppBar(title: const Text('Nexlo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to Nexlo 👋', style: theme.textTheme.titleMedium),
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


// Future<void> clearHiveDebug() async {
//   if (Hive.isBoxOpen('skills')) await Hive.box('skills').clear();
//   if (Hive.isBoxOpen('sessions')) await Hive.box('sessions').clear();
//   if (Hive.isBoxOpen('activeTimer')) await Hive.box('activeTimer').clear();

//   await Hive.deleteBoxFromDisk('skills');
//   await Hive.deleteBoxFromDisk('sessions');
//   await Hive.deleteBoxFromDisk('activeTimer');
// }