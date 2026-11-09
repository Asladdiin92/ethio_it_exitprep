// test/widget_test.dart
// App smoke test for EthioExitPrepApp.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethio_it_exitprep/core/providers/repository_providers.dart';
import 'package:ethio_it_exitprep/data/local/database.dart';
import 'package:ethio_it_exitprep/main.dart';

void main() {
  testWidgets('App renders the exam hub with sync and mock exam actions', (
    WidgetTester tester,
  ) async {
    final db = await AppDatabase.createInMemory();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const EthioExitPrepApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BSc IT Exit Exam'), findsOneWidget);
    expect(find.text('Start a mock exam'), findsOneWidget);
    expect(find.byTooltip('Sync curriculum and attempts'), findsOneWidget);

    await db.close();
  });
}
