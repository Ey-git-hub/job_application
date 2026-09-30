import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:job_application/main.dart';

void main() {
  testWidgets('job search feed supports search, bookmarks, and navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: JobSearchApp()));
    await tester.pumpAndSettle();
    expect(find.text('Job Search'), findsOneWidget);
    expect(find.text('Senior Flutter Developer'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove bookmark').first);
    await tester.pump();
    expect(find.byTooltip('Save job'), findsWidgets);
    await tester.tap(find.text('Saved').last);
    await tester.pump();
    expect(find.text('Saved jobs'), findsOneWidget);
    await tester.tap(find.text('Home').last);
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Data Analyst');
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == 'Data Analyst',
      ),
      findsOneWidget,
    );
  });
}
