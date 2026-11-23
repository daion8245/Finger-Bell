import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('won groups thousands', () {
    expect(won(0), '0원');
    expect(won(2350000), '2,350,000원');
    expect(won(-12400), '-12,400원');
  });

  test('formatWhen uses relative Korean labels', () {
    final now = DateTime(2026, 10, 26, 14, 0);
    expect(formatWhen(now.subtract(const Duration(seconds: 20)), now), '방금 전');
    expect(formatWhen(DateTime(2026, 10, 26, 9, 5), now), '오늘 09:05');
    expect(formatWhen(DateTime(2026, 10, 25, 22, 30), now), '어제 22:30');
    expect(formatWhen(DateTime(2026, 10, 3, 8), now), '10월 3일');
  });

  test('countdowns never go negative', () {
    expect(formatCountdown(const Duration(hours: 23, minutes: 59, seconds: 58)), '23:59:58');
    expect(formatCountdown(const Duration(seconds: -5)), '00:00:00');
    expect(formatMinSec(const Duration(seconds: 161)), '2:41');
  });

  test('formatHourMin reads like Figma "23시간 58분"', () {
    expect(formatHourMin(const Duration(hours: 23, minutes: 58, seconds: 40)), '23시간 58분');
    expect(formatHourMin(const Duration(hours: 2)), '2시간');
    expect(formatHourMin(const Duration(minutes: 41)), '41분');
    expect(formatHourMin(const Duration(seconds: 30)), '1분 미만');
    expect(formatHourMin(const Duration(seconds: -5)), '1분 미만');
  });

  testWidgets('CountdownRing and RiskLevelMeter expose readable semantics', (tester) async {
    final now = DateTime(2026, 1, 1, 10);
    await tester.pumpWidget(
      MaterialApp(
        theme: FbTheme.build(),
        home: Scaffold(
          body: Column(
            children: [
              CountdownRing(until: now.add(const Duration(minutes: 29, seconds: 12)), now: () => now, caption: '보류 남은 시간'),
              const RiskLevelMeter(level: 2),
            ],
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('보류 남은 시간, 남은 시간 29:12'), findsOneWidget);
    expect(find.bySemanticsLabel('위험 단계 위험'), findsOneWidget);
  });

  test('ThousandsFormatter keeps only digits', () {
    const f = ThousandsFormatter();
    final v = f.formatEditUpdate(TextEditingValue.empty, const TextEditingValue(text: '50a0000'));
    expect(v.text, '500,000');
  });

  testWidgets('FbSplit stacks children in the mobile order', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FbTheme.build(),
        home: const Scaffold(
          body: FbSplit(main: [Text('A')], side: [Text('B')], mobile: [Text('B'), Text('A')]),
        ),
      ),
    );
    final b = tester.getTopLeft(find.text('B'));
    final a = tester.getTopLeft(find.text('A'));
    expect(b.dy, lessThan(a.dy));
  });
}
