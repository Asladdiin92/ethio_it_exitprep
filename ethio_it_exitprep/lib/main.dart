// lib/main.dart
// EthioIT ExitPrep — Application entry point.
// Offline-first Flutter app preparing Ethiopian BSc IT students for national exit exams.

import 'dart:async';

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
    overrides: [appDatabaseProvider.overrideWithValue(db)],
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

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (container.read(syncEnabledProvider)) {
      unawaited(
        container.read(syncServiceProvider).runSyncCycle('LOCAL_STUDENT'),
      );
    }
  });
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
        scaffoldBackgroundColor: const Color(0xFFF4F7F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F5132), // Academic Emerald
          secondary: const Color(0xFFD97706), // Academic Amber
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        dividerTheme: const DividerThemeData(
          space: 1,
          thickness: 1,
          color: Color(0xFFE2E9E5),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF17211D),
          ),
          titleLarge: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF17211D),
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF17211D),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Color(0xFF53615B),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Color(0xFFF4F7F5),
          surfaceTintColor: Colors.transparent,
        ),
      ),
    );
  }
}
