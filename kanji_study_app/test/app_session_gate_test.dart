import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konnakanji/widgets/app_session_gate.dart';

void main() {
  testWidgets('shows unauthenticated child when there is no session', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppSessionGate(
          isInitialized: true,
          hasSession: false,
          sessionStream: Stream<bool>.empty(),
          authenticatedChild: Text('main-screen'),
          unauthenticatedChild: Text('login-screen'),
        ),
      ),
    );

    expect(find.text('login-screen'), findsOneWidget);
    expect(find.text('main-screen'), findsNothing);
  });

  testWidgets('switches to authenticated child when session stream updates', (
    tester,
  ) async {
    final controller = StreamController<bool>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      MaterialApp(
        home: AppSessionGate(
          isInitialized: true,
          hasSession: false,
          sessionStream: controller.stream,
          authenticatedChild: const Text('main-screen'),
          unauthenticatedChild: const Text('login-screen'),
        ),
      ),
    );

    controller.add(true);
    await tester.pump();

    expect(find.text('main-screen'), findsOneWidget);
    expect(find.text('login-screen'), findsNothing);
  });
}
