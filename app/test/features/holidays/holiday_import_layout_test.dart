import 'package:cuadrante/core/bootstrap/bootstrap.dart';
import 'package:cuadrante/features/calendar_export/domain/device_calendar_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_device_calendar.dart';
import '../../support/real_font.dart';
import '../../support/text_lines.dart';
import 'holiday_import_ui_support.dart';

void _checkText(WidgetTester tester, String step) {
  expect(tester.takeException(), isNull, reason: step);
  for (final element in find.byType(RichText).evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    // A line break at a written hyphen (English "Read-only") is a normal
    // break opportunity. Still reject a break inside any other word.
    final words = paragraph.text.toPlainText().trim().split(RegExp(r'\s+'));
    final lines = paragraphLines(paragraph);
    final fragments = lines
        .join(' ')
        .replaceAll(RegExp(r'-\s+'), '-')
        .trim()
        .split(RegExp(r'\s+'));
    expect(
      wrapsOnlyBetweenWords(paragraph) || fragments.length == words.length,
      isTrue,
      reason: '$step: ${lines.join(' | ')}',
    );
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: '$step: ${paragraph.text.toPlainText()}',
    );
  }
  final appBar = find.byType(AppBar).last;
  final bounds = tester.getRect(appBar);
  for (final element
      in find
          .descendant(of: appBar, matching: find.byType(RichText))
          .evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    final rect = paragraph.localToGlobal(Offset.zero) & paragraph.size;
    expect(
      rect.top,
      greaterThanOrEqualTo(bounds.top - 0.5),
      reason: '$step toolbar top: ${paragraph.text.toPlainText()}',
    );
    expect(
      rect.bottom,
      lessThanOrEqualTo(bounds.bottom + 0.5),
      reason: '$step toolbar bottom: ${paragraph.text.toPlainText()}',
    );
  }
}

/// Check the top and bottom of the scrollable body: short screens at large
/// text sizes can put the permission actions or preview status below the fold.
Future<void> _checkScrollable(WidgetTester tester, String step) async {
  _checkText(tester, step);
  final list = find.byType(ListView).last;
  await tester.drag(list, const Offset(0, -1200));
  await tester.pumpAndSettle();
  _checkText(tester, '$step bottom');
  await tester.drag(list, const Offset(0, 1200));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeLocale();
    expect(await loadRoboto(), isTrue, reason: 'Roboto from the Flutter SDK');
  });

  testWidgets('a 60-character external name stays whole and can be read '
      'from start to end by scrolling horizontally', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    final name = 'Abcdefghij' * 6;
    final phone = FakeDeviceCalendar();
    final id = phone.addCalendar('Festivos');
    phone.addSimpleEvent(
      id,
      name,
      DateTime(2026, 10, 21),
      DateTime(2026, 10, 22),
      allDay: true,
    );
    await openHolidayImport(tester, phone, size: const Size(320, 900));
    await holidayPreview(tester, [id]);
    final horizontal = find.descendant(
      of: importKey('holiday-import-row-0'),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      ),
    );
    expect(horizontal, findsOneWidget);
    await tester.ensureVisible(horizontal);
    await tester.pumpAndSettle();
    final state = tester.state<ScrollableState>(
      find.descendant(of: horizontal, matching: find.byType(Scrollable)),
    );
    final text = find.descendant(of: horizontal, matching: find.text(name));
    expect(text, findsOneWidget, reason: 'the complete source name is present');
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: text, matching: find.byType(RichText)),
    );
    expect(paragraphLines(paragraph), [name], reason: 'no split or ellipsis');
    expect(paragraph.didExceedMaxLines, isFalse);
    final viewport = tester.getRect(horizontal);
    expect(state.position.maxScrollExtent, greaterThan(0));
    expect(state.position.pixels, closeTo(0, 0.5));
    expect(
      tester.getRect(text).left,
      closeTo(viewport.left, 0.5),
      reason: 'the first character is reachable',
    );
    await tester.drag(horizontal, const Offset(-5000, 0));
    await tester.pumpAndSettle();
    expect(state.position.pixels, closeTo(state.position.maxScrollExtent, 0.5));
    expect(
      tester.getRect(text).right,
      closeTo(viewport.right, 0.5),
      reason: 'the final character is reachable',
    );
    _checkText(tester, 'long external name at 320dp and text 2');
  });

  for (final language in ['es', 'ca', 'gl', 'eu', 'en']) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final variant = '$language ${brightness.name}, 320dp and text 2';

      testWidgets('all three holiday import steps fit: $variant', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        final phone = FakeDeviceCalendar();
        final id = phone.addCalendar(
          'Festivos del trabajo',
          account: 'Calendario de empresa',
          readOnly: true,
        );
        phone.addSimpleEvent(
          id,
          'Fiesta local del barrio',
          DateTime(2026, 10, 21),
          DateTime(2026, 10, 22),
          allDay: true,
        );
        phone.addSimpleEvent(
          id,
          'Cita con hora',
          DateTime(2026, 10, 22, 9),
          DateTime(2026, 10, 22, 10),
        );
        await openHolidayImport(
          tester,
          phone,
          size: const Size(320, 900),
          brightness: brightness,
          beforeImport: () async {
            tester.platformDispatcher.localesTestValue = [Locale(language)];
            await tester.pumpAndSettle();
            final action = importKey('holidays-import');
            await tester.ensureVisible(action);
            await tester.pumpAndSettle();
            for (final element
                in find
                    .descendant(of: action, matching: find.byType(RichText))
                    .evaluate()) {
              final paragraph = element.renderObject! as RenderParagraph;
              expect(
                wrapsOnlyBetweenWords(paragraph),
                isTrue,
                reason: '$variant settings action',
              );
              expect(
                paragraph.didExceedMaxLines,
                isFalse,
                reason: '$variant settings action',
              );
            }
            expect(tester.takeException(), isNull);
          },
        );
        await _checkScrollable(tester, '$variant calendars');
        await importTap(tester, 'holiday-import-calendar-$id');
        await importTap(tester, 'holiday-import-next');
        await _checkScrollable(tester, '$variant range');
        await importTap(tester, 'holiday-import-next');
        await _checkScrollable(tester, '$variant preview');
        expect(importKey('holiday-import-row-0'), findsOneWidget);
        // Footer remains usable at each step even when labels stack.
        expect(importNextEnabled(tester), isTrue);
      });

      for (final access in [
        CalendarAccess.notDetermined,
        CalendarAccess.denied,
        CalendarAccess.restricted,
        CalendarAccess.writeOnly,
      ]) {
        testWidgets('permission ${access.name} fits: $variant', (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          final phone = FakeDeviceCalendar(access: access);
          await openHolidayImport(
            tester,
            phone,
            size: const Size(320, 900),
            brightness: brightness,
          );
          tester.platformDispatcher.localesTestValue = [Locale(language)];
          await tester.pumpAndSettle();
          await _checkScrollable(tester, '$variant ${access.name}');
          expect(phone.requests, 0);
          expect(importNextEnabled(tester), isFalse);
        });
      }
    }
  }
}
