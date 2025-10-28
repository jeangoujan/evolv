import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'data/hive_boxes.dart';
import 'package:hive_flutter/hive_flutter.dart'; // ⬅️ добавь это


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Инициализируем Hive, чтобы можно было удалять боксы
  await Hive.initFlutter();

  // --- TEMP: очистка старых данных после смены типов (удали после первого удачного запуска) ---
  // try {
  //   if (await Hive.boxExists('skills'))   await Hive.deleteBoxFromDisk('skills');
  //   if (await Hive.boxExists('sessions')) await Hive.deleteBoxFromDisk('sessions');
  // } catch (_) {}

  await HiveBoxes.init();
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