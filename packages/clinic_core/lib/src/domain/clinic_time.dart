import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;
import 'models.dart';

/// Clinic calendar time is independent of the phone's current time zone.
abstract final class ClinicTime {
  static final tz.Location _location = _initialize();
  static tz.Location _initialize() {
    data.initializeTimeZones();
    return tz.getLocation('Africa/Cairo');
  }

  static DateTime local(DateTime instant) =>
      tz.TZDateTime.from(instant, _location);
  static DateTime now() => local(DateTime.now());
  static DateTime at(DateTime date, int hour, int minute) {
    final value = tz.TZDateTime(
      _location,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
    bool matches(DateTime v) =>
        v.year == date.year &&
        v.month == date.month &&
        v.day == date.day &&
        v.hour == hour &&
        v.minute == minute;
    if (!matches(value)) {
      throw const ClinicFailure(
        'invalid_time',
        'This Cairo time does not exist because of a clock change. Choose another time.',
      );
    }
    if (matches(local(value.add(const Duration(hours: 1)))) ||
        matches(local(value.subtract(const Duration(hours: 1))))) {
      throw const ClinicFailure(
        'ambiguous_time',
        'This Cairo time occurs twice during a clock change. Choose a time outside the repeated hour.',
      );
    }
    return value.toUtc();
  }

  static ({DateTime from, DateTime to}) dayBounds(DateTime date) => (
    from: tz.TZDateTime(_location, date.year, date.month, date.day).toUtc(),
    to: tz.TZDateTime(_location, date.year, date.month, date.day + 1).toUtc(),
  );
}
