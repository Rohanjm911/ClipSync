import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/services/state_service.dart';
import 'package:flutter_app/widgets/first_launch_dialog.dart';

void main() {
  testWidgets('ClipSync app smoke test on desktop viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ClipSyncApp());
    expect(find.text('ClipSync'), findsWidgets);
    expect(find.text('Real-Time Dashboard'), findsOneWidget);
    expect(find.text('Broadcast Clipboard Payload'), findsOneWidget);
  });

  testWidgets('ClipSync app smoke test on mobile viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ClipSyncApp());
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Broadcast Clipboard Payload'), findsOneWidget);
  });

  testWidgets(
    'First-launch device naming dialog renders presets and saves custom name',
    (WidgetTester tester) async {
      final state = ClipSyncState();
      String completedName = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FirstLaunchDialog(
              state: state,
              onCompleted: (name) {
                completedName = name;
              },
            ),
          ),
        ),
      );

      // Verify Title and Setup components
      expect(find.text('Welcome to ClipSync'), findsOneWidget);
      expect(find.text('Device Name'), findsOneWidget);
      expect(find.text('Save Name & Start Syncing'), findsOneWidget);

      // Enter a custom name
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'Rohan Work Laptop');
      await tester.tap(find.text('Save Name & Start Syncing'));
      await tester.pumpAndSettle();

      expect(completedName, equals('Rohan Work Laptop'));
      expect(state.localDevice.deviceName, equals('Rohan Work Laptop'));
      state.dispose();
    },
  );

  test('ClipSyncState syncViaBluetooth sets Bluetooth state and dispatches payload', () async {
    final state = ClipSyncState();
    state.updateCompanionIp('192.168.44.2');
    expect(state.settings.companionIp, equals('192.168.44.2'));

    final res = await state.syncViaBluetooth('Secret payload via Bluetooth');
    expect(res['transport'], equals('bluetooth_direct'));
    expect(state.settings.bluetoothEnabled, isTrue);
    expect(state.connectionStatus.transportMode.contains('Bluetooth'), isTrue);

    final recentLog = state.diagnosticLogs.first;
    expect(recentLog.eventType, equals('BLUETOOTH_DIRECT_SYNC'));
    state.dispose();
  });
}
