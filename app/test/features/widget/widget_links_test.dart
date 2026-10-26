import 'package:cuadrante/features/schedule/domain/schedule_domain.dart';
import 'package:cuadrante/features/widget/domain/widget_links.dart';
import 'package:flutter_test/flutter_test.dart';

const _today = CivilDate(2026, 10, 20);

WidgetTarget? _target(Uri? uri) => widgetLinkTarget(uri, today: _today);

void main() {
  test('a day link round-trips', () {
    const day = CivilDate(2026, 10, 19);
    final link = widgetDayLink(day);
    expect(link.toString(), 'cuadrante://widget/day/2026-10-19');
    expect(_target(link)?.day, day);
  });

  test('a month link round-trips and names a month, not a day', () {
    final link = widgetMonthLink(const CivilDate(2026, 11, 17));
    expect(link.toString(), 'cuadrante://widget/month/2026-11');
    final target = _target(link)!;
    expect(target.day, isNull);
    expect(target.month, const CivilDate(2026, 11, 1));
    // Not a month: the app just opens.
    for (final bad in ['2026-13', '2026-00', '2026', 'x-y', '2026-1']) {
      final t = _target(Uri.parse('cuadrante://widget/month/$bad'))!;
      expect(t.month, isNull, reason: bad);
      expect(t.day, isNull, reason: bad);
    }
    // A day link never carries a month.
    expect(_target(widgetDayLink(const CivilDate(2026, 11, 4)))?.month, isNull);
  });

  test('the iOS form of the links (with ?homeWidget) reads the same', () {
    // home_widget on iOS only passes on URLs that carry the `homeWidget` query
    // item; the Swift widget has to add it (docs/widget-contrato.md).
    final day = _target(
      Uri.parse('cuadrante://widget/day/2026-10-19?homeWidget'),
    );
    expect(day?.day, const CivilDate(2026, 10, 19));
    final month = _target(
      Uri.parse('cuadrante://widget/month/2026-11?homeWidget'),
    );
    expect(month?.month, const CivilDate(2026, 11, 1));
    expect(_target(Uri.parse('cuadrante://widget?homeWidget'))?.day, isNull);
  });

  test('a bare widget link opens the app without a day', () {
    final target = _target(Uri.parse('cuadrante://widget'));
    expect(target, isNotNull);
    expect(target!.day, isNull);
    expect(
      _target(Uri.parse('cuadrante://widget/day/not-a-date'))?.day,
      isNull,
    );
  });

  test('links that are not ours are ignored', () {
    expect(_target(null), isNull);
    expect(_target(Uri.parse('')), isNull);
    expect(_target(Uri.parse('https://widget/day/2026-10-19')), isNull);
    expect(_target(Uri.parse('cuadrante://other/day/2026-10-19')), isNull);
  });

  test('a day or month more than 50 years from today is ignored: the app just '
      'opens', () {
    for (final bad in [
      'cuadrante://widget/day/0000-01-01',
      'cuadrante://widget/day/9999-12-31',
      'cuadrante://widget/day/1975-10-20',
      'cuadrante://widget/day/2077-01-01',
      'cuadrante://widget/month/0000-01',
      'cuadrante://widget/month/9999-12',
      'cuadrante://widget/month/2077-01',
    ]) {
      final t = _target(Uri.parse(bad))!;
      expect(t.day, isNull, reason: bad);
      expect(t.month, isNull, reason: bad);
    }
  });

  test('the edges of the range (today plus or minus 50 years) still open', () {
    expect(
      _target(Uri.parse('cuadrante://widget/day/2076-12-31'))?.day,
      const CivilDate(2076, 12, 31),
    );
    expect(
      _target(Uri.parse('cuadrante://widget/day/1976-01-01'))?.day,
      const CivilDate(1976, 1, 1),
    );
    expect(
      _target(Uri.parse('cuadrante://widget/month/1976-05'))?.month,
      const CivilDate(1976, 5, 1),
    );
  });
}
