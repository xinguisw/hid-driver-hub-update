import 'package:driver_hub/layer3_ui/screens/hub_landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fast save (<200ms) does not show loading overlay', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CommitOverlay(
            committing: true,
            consecutiveFailures: 0,
          ),
        ),
      ),
    );

    // At 100ms (before 200ms threshold), overlay is not shown
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Saving settings to device...'), findsNothing);

    // Fast ACK finishes committing before threshold
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CommitOverlay(
            committing: false,
            consecutiveFailures: 0,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Saving settings to device...'), findsNothing);
  });

  testWidgets('slow save (>200ms) displays loading overlay', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CommitOverlay(
            committing: true,
            consecutiveFailures: 0,
          ),
        ),
      ),
    );

    // At 100ms, overlay is not visible yet
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Saving settings to device...'), findsNothing);

    // Past 200ms threshold (100 + 110 = 210ms), overlay is displayed
    await tester.pump(const Duration(milliseconds: 110));
    expect(find.text('Saving settings to device...'), findsOneWidget);

    // Complete committing
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CommitOverlay(
            committing: false,
            consecutiveFailures: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saving settings to device...'), findsNothing);
  });

  testWidgets('consecutive failures > 0 displays retry text immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CommitOverlay(
            committing: true,
            consecutiveFailures: 1,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 10));

    expect(
      find.text('Re-attempting device write (Retry 1 of 3)...'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CommitOverlay(
            committing: false,
            consecutiveFailures: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Re-attempting device write (Retry 1 of 3)...'),
      findsNothing,
    );
  });
}
