import 'package:clinic_core/src/presentation/language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/common.dart';
import '../../domain/scheduling.dart';
import '../../domain/models.dart';
import 'appointment_screen.dart';

class SchedulingScreen extends ConsumerStatefulWidget {
  const SchedulingScreen({super.key});
  @override
  ConsumerState<SchedulingScreen> createState() => _SchedulingScreenState();
}

class _SchedulingScreenState extends ConsumerState<SchedulingScreen> {
  List<WorkingPeriod> periods = [];
  List<Map<String, dynamic>> waitlist = [];
  bool loading = true, busy = false, configured = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await ref.read(repositoryProvider).scheduleAction('read');
      if (!mounted) return;
      final settings = ScheduleSettings.fromMap(
        Map<String, dynamic>.from(data['settings'] as Map),
      );
      setState(() {
        configured = settings.configured;
        periods = settings.periods.toList();
        waitlist = (data['waitlist'] as List)
            .map((v) => Map<String, dynamic>.from(v as Map))
            .toList();
        error = null;
      });
    } catch (e) {
      if (mounted) setState(() => error = safeError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> addPeriod(int weekday) async {
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (start == null || !mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 0),
    );
    if (end == null || !mounted) return;
    final a = start.hour * 60 + start.minute, b = end.hour * 60 + end.minute;
    if (b <= a ||
        periods.any((p) => p.weekday == weekday && a < p.end && b > p.start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('Check working hours and breaks. Periods must not overlap.'),
          ),
        ),
      );
      return;
    }
    setState(() => periods.add(WorkingPeriod(weekday, a, b)));
  }

  String time(int minute) =>
      TimeOfDay(hour: minute ~/ 60, minute: minute % 60).format(context);
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Working hours and waitlist')),
        actions: [
          IconButton(
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh),
            tooltip: tr('Refresh'),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (error != null) ...[
                  Text(tr(error!)),
                  TextButton(onPressed: load, child: Text(tr('Retry'))),
                ],
                if (repo.session.isAdmin) ...[
                  Text(
                    tr('Recurring working hours'),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    tr(
                      'Times use Cairo. Add two periods to leave a break between them. A day with no period is closed once these hours are saved. Existing bookings are retained.',
                    ),
                  ),
                  if (!configured)
                    Text(
                      tr(
                        'No working hours are set, so any time can be booked. Saving hours starts restricting bookings to them.',
                      ),
                    ),
                  for (var day = 1; day <= 7; day++)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(tr(days[day - 1]))),
                                IconButton(
                                  tooltip: tr('Add working period'),
                                  onPressed: busy ? null : () => addPeriod(day),
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                            for (final p in periods.where(
                              (p) => p.weekday == day,
                            ))
                              ListTile(
                                title: Text(
                                  tr("{0} - {1}", [time(p.start), time(p.end)]),
                                ),
                                trailing: IconButton(
                                  tooltip: tr('Remove period'),
                                  onPressed: busy
                                      ? null
                                      : () => setState(() => periods.remove(p)),
                                  icon: const Icon(Icons.close),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  // Saving an empty list would leave the clinic configured with
                  // no open time, which refuses every booking. Removing the
                  // restriction entirely is a separate, explicit action.
                  FilledButton(
                    onPressed: busy || periods.isEmpty
                        ? null
                        : () async {
                            setState(() => busy = true);
                            await runAction(context, () async {
                              await repo.scheduleAction('settings', {
                                'periods': periods
                                    .map((p) => p.toMap())
                                    .toList(),
                              });
                            }, success: 'Working hours saved.');
                            if (mounted) {
                              setState(() => busy = false);
                              await load();
                            }
                          },
                    child: Text(tr('Save working hours')),
                  ),
                  if (periods.isEmpty)
                    Text(
                      tr(
                        'Add at least one working period to save, or clear the working hours so any time can be booked.',
                      ),
                    ),
                  if (configured)
                    OutlinedButton(
                      onPressed: busy
                          ? null
                          : () async {
                              setState(() => busy = true);
                              await runAction(
                                context,
                                () => repo.scheduleAction('settings_clear'),
                                success:
                                    'Working hours cleared. Any time can be booked.',
                              );
                              if (mounted) {
                                setState(() => busy = false);
                                await load();
                              }
                            },
                      child: Text(tr('Clear working hours')),
                    ),
                  const SizedBox(height: 24),
                ],
                Text(
                  tr('Cancellation waitlist'),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  tr(
                    'Patients waiting for an earlier opening. Book a slot, then remove the patient after the booking is synchronized.',
                  ),
                ),
                if (waitlist.isEmpty) Text(tr('No patients on the waitlist.')),
                for (final entry in waitlist)
                  LoadView<Patient?>(
                    load: (r) => r.patientOrFetch(entry['patient_id'] as String),
                    builder: (patient) => Card(
                      child: ListTile(
                        title: Text(patient?.name ?? tr('Patient unavailable')),
                        subtitle: Text(entry['notes'] as String? ?? ''),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              tooltip: tr('Book appointment'),
                              onPressed: patient == null
                                  ? null
                                  : () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => AppointmentFormScreen(
                                          patientId: patient.id,
                                        ),
                                      ),
                                    ),
                              icon: const Icon(Icons.event_available),
                            ),
                            IconButton(
                              tooltip: tr('Remove from waitlist'),
                              onPressed: busy
                                  ? null
                                  : () async {
                                      if (await runAction(context, () async {
                                        await repo.scheduleAction(
                                          'waitlist_remove',
                                          {'id': entry['id']},
                                        );
                                      })) {
                                        await load();
                                      }
                                    },
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
