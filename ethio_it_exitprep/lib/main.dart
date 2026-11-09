// lib/main.dart
// EthioIT ExitPrep — Application entry point.
// Offline-first Flutter app preparing Ethiopian BSc IT students for national exit exams.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethio_it_exitprep/core/providers/repository_providers.dart';
import 'package:ethio_it_exitprep/data/local/database.dart';
import 'package:ethio_it_exitprep/data/local/seed_data.dart';
import 'package:ethio_it_exitprep/presentation/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.getInstance();

  // Seed baseline curriculum if first launch
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ],
  );

  final seeder = SeedDataLoader(
    themeRepo: container.read(programThemeRepositoryProvider),
    courseRepo: container.read(courseRepositoryProvider),
    chapterRepo: container.read(chapterRepositoryProvider),
    questionRepo: container.read(questionRepositoryProvider),
    optionRepo: container.read(questionOptionRepositoryProvider),
  );
  await seeder.loadIfEmpty();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const EthioExitPrepApp(),
    ),
  );
}

class EthioExitPrepApp extends StatelessWidget {
  const EthioExitPrepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EthioIT ExitPrep',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F5132), // Academic Emerald
          secondary: const Color(0xFFD97706), // Academic Amber
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
    );
  }
}
