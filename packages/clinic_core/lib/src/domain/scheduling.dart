import 'models.dart';
import 'clinic_time.dart';

/// A recurring Cairo-time working day. An empty list means the day is closed.
class WorkingPeriod {
  const WorkingPeriod(this.weekday, this.start, this.end);
  final int weekday, start, end;
  Map<String, dynamic> toMap() => {
    'weekday': weekday,
    'start': start,
    'end': end,
  };
  factory WorkingPeriod.fromMap(Map<String, dynamic> m) => WorkingPeriod(
    (m['weekday'] as num).toInt(),
    (m['start'] as num).toInt(),
    (m['end'] as num).toInt(),
  );
}

class ScheduleSettings {
  const ScheduleSettings({this.periods = const [], this.configured = false});
  final List<WorkingPeriod> periods;
  final bool configured;
  factory ScheduleSettings.fromMap(Map<String, dynamic> m) => ScheduleSettings(
    configured: m['configured'] == true,
    periods: (m['periods'] as List? ?? [])
        .map((v) => WorkingPeriod.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList(),
  );
  Map<String, dynamic> toMap() => {
    'configured': configured,
    'periods': periods.map((p) => p.toMap()).toList(),
  };
  bool allows(DateTime start, int duration) {
    if (!configured) return true;
    final date = ClinicTime.local(start);
    final minute = date.hour * 60 + date.minute;
    return periods.any(
      (p) =>
          p.weekday == date.weekday &&
          minute >= p.start &&
          minute + duration <= p.end,
    );
  }
}

bool appointmentOverlaps(
  Appointment proposed,
  Iterable<Appointment> appointments,
) => appointments.any(
  (a) =>
      a.id != proposed.id &&
      a.doctorId == proposed.doctorId &&
      a.clinicId == proposed.clinicId &&
      a.status != AppointmentStatus.cancelled &&
      a.status != AppointmentStatus.noShow &&
      a.status != AppointmentStatus.completed &&
      proposed.startsAt.isBefore(a.endsAt) &&
      proposed.endsAt.isAfter(a.startsAt),
);

List<DateTime> availableSlots(
  DateTime day,
  int duration,
  ScheduleSettings settings,
  List<Appointment> appointments,
  String doctorId, {
  String? excludeId,
  DateTime? now,
}) {
  final periods = settings.configured
      ? settings.periods.where((p) => p.weekday == day.weekday)
      : [WorkingPeriod(day.weekday, 9 * 60, 17 * 60)];
  final result = <DateTime>[];
  for (final period in periods) {
    for (
      var minute = period.start;
      minute + duration <= period.end;
      minute += 15
    ) {
      DateTime start;
      try {
        start = ClinicTime.at(day, minute ~/ 60, minute % 60);
      } on ClinicFailure {
        continue;
      }
      if (start.isBefore(now ?? DateTime.now())) {
        continue;
      }
      final end = start.add(Duration(minutes: duration));
      if (appointments.any(
        (a) =>
            a.id != excludeId &&
            a.doctorId == doctorId &&
            a.status != AppointmentStatus.cancelled &&
            a.status != AppointmentStatus.noShow &&
            a.status != AppointmentStatus.completed &&
            start.isBefore(a.endsAt) &&
            end.isAfter(a.startsAt),
      )) {
        continue;
      }
      result.add(start);
    }
  }
  return result.toSet().toList()..sort();
}
