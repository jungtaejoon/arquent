import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_client/app/app.dart';

void main() {
  const channel = MethodChannel('arquent.runtime.bridge');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('dashboard shows quick run entry', (tester) async {
    await tester.pumpWidget(const AutomationApp());

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Quick Run: Daily Focus Setup'), findsOneWidget);
  });

  testWidgets('permission review requires consent before approval', (tester) async {
    await tester.pumpWidget(const AutomationApp());

    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();

    expect(find.text('Permission Review'), findsOneWidget);
    expect(find.text('Sensitive'), findsOneWidget);

    await tester.tap(find.text('Approve Sensitive Run'));
    await tester.pumpAndSettle();

    expect(find.text('Status: Consent required'), findsOneWidget);
  });

  testWidgets('permission review sends runtime proof when consent accepted', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'submitSensitiveRuntimeProof') {
        return 'ok';
      }
      return null;
    });

    await tester.pumpWidget(const AutomationApp());

    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Approve Sensitive Run'));
    await tester.pumpAndSettle();

    expect(find.text('Status: Approved and proof sent'), findsOneWidget);
  });

  testWidgets('marketplace shows publish and refresh controls', (tester) async {
    await tester.pumpWidget(const AutomationApp());

    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.pushNamed(AppRoutes.marketplace);
    await tester.pumpAndSettle();

    expect(find.text('Publish Demo Recipe'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
  });
}
