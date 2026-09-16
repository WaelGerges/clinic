import 'package:clinic_core/src/presentation/language.dart';
import '../../domain/scheduling.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models.dart';
import '../../domain/clinic_time.dart';
import '../../presentation/common.dart';

class AppointmentFormScreen extends ConsumerStatefulWidget {
  const AppointmentFormScreen({
    super.key,
    this.patientId,
    this.initialDate,
    this.existing,
  });
  final String? patientId;
  final DateTime? initialDate;
  final Appointment? existing;
  @override
  ConsumerState<AppointmentFormScreen> createState() =>
      _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends ConsumerState<AppointmentFormScreen> {
  final notes = TextEditingController(), search = TextEditingController();
  late DateTime date;
  late TimeOfDay time;
  String? patientId;
  String type = 'Consultation';
  bool busy = false;
  int duration = 30;
  ScheduleSettings settings = const ScheduleSettings();
  List<Appointment> booked = [];
  String? slotError;
  bool loadingSlots = true;
  Future<void> loadSlots() async {
    if (mounted) setState(() => loadingSlots = true);
    final requestedDay = date;
    final repo = ref.read(repositoryProvider);
    try {
      final nextSettings = await repo.schedulingSettings();
      await repo.refreshAppointments(day: requestedDay);
      final rows = await repo.appointments(day: requestedDay);
      if (mounted && requestedDay == date) {
        setState(() {
          settings = nextSettings;
          booked = rows;
          slotError = null;
        });
      }
    } catch (e) {
      if (mounted && requestedDay == date) {
        setState(() => slotError = safeError(e));
      }
    } finally {
      if (mounted && requestedDay == date) setState(() => loadingSlots = false);
    }
  }

  @override
  void initState() {
    super.initState();
    date = widget.existing == null
        ? widget.initialDate ?? ClinicTime.now()
        : ClinicTime.local(widget.existing!.startsAt);
    time = widget.existing == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay.fromDateTime(date);
    patientId = widget.existing?.patientId ?? widget.patientId;
    type = widget.existing?.type ?? type;
    notes.text = widget.existing?.notes ?? '';
    duration = widget.existing?.durationMinutes ?? 30;
    loadSlots();
  }

  @override
  void dispose() {
    notes.dispose();
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        tr(
          widget.existing == null
              ? 'New appointment'
              : 'Reschedule appointment',
        ),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // The search and the patient list are only for choosing. Once a
        // patient is chosen - here, or before arriving from a patient record
        // or the waitlist - only that patient is shown.
        if (widget.existing == null && patientId == null) ...[
          TextField(
            key: const Key('appointment-patient-search'),
            controller: search,
            decoration: InputDecoration(
              labelText: tr('Find patient'),
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          LoadView<List<Patient>>(
            load: (r) => r.patients(search: search.text),
            builder: (patients) => RadioGroup<String>(
              groupValue: patientId,
              onChanged: (value) => setState(() => patientId = value),
              child: Column(
                children: [
                  for (final p in patients.take(20))
                    RadioListTile<String>(
                      value: p.id,
                      title: Text(p.name),
                      subtitle: Text(tr("{0} · {1}", [p.number, p.mobile])),
                    ),
                ],
              ),
            ),
          ),
        ] else if (widget.existing == null)
          LoadView<Patient?>(
            key: ValueKey(patientId),
            load: (r) => r.patientOrFetch(patientId!),
            builder: (p) => Card(
              key: const Key('appointment-selected-patient'),
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(p?.name ?? tr('Patient unavailable')),
                subtitle: p == null
                    ? null
                    : Text(tr("{0} · {1}", [p.number, p.mobile])),
                trailing: TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          patientId = null;
                          search.clear();
                        }),
                  child: Text(tr('Change patient')),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            final result = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (result != null && mounted) {
              setState(() => date = result);
              await loadSlots();
            }
          },
          icon: const Icon(Icons.calendar_month),
          label: Text(DateFormat.yMMMMd().format(date)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final result = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (result != null && mounted) setState(() => time = result);
          },
          icon: const Icon(Icons.schedule),
          label: Text(time.format(context)),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: type,
          decoration: InputDecoration(labelText: tr('Appointment type')),
          items: [
            'Consultation',
            'Follow-up',
            'Procedure',
          ].map((s) => DropdownMenuItem(value: s, child: Text(tr(s)))).toList(),
          onChanged: (v) => setState(() => type = v!),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: duration,
          decoration: InputDecoration(labelText: tr('Duration (minutes)')),
          items:
              ({
                    ...[15, 30, 45, 60, 90, 120],
                    duration,
                  }.toList()..sort())
                  .map(
                    (d) =>
                        DropdownMenuItem(value: d, child: Text(tr("{0}", [d]))),
                  )
                  .toList(),
          onChanged: (v) => setState(() => duration = v!),
        ),
        const SizedBox(height: 16),
        Text(tr('Available slots · Cairo time')),
        if (loadingSlots)
          const LinearProgressIndicator()
        else if (slotError != null) ...[
          Text(tr(slotError!)),
          TextButton(onPressed: loadSlots, child: Text(tr('Retry'))),
        ] else ...[
          if (!settings.configured)
            Text(
              tr(
                'Working hours are not configured. Suggested times are 09:00–17:00.',
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final slot in availableSlots(
                date,
                duration,
                settings,
                booked,
                ref.read(repositoryProvider).session.doctorId,
                excludeId: widget.existing?.id,
              ))
                ChoiceChip(
                  label: Text(
                    TimeOfDay.fromDateTime(
                      ClinicTime.local(slot),
                    ).format(context),
                  ),
                  selected:
                      time == TimeOfDay.fromDateTime(ClinicTime.local(slot)),
                  onSelected: (_) => setState(
                    () => time = TimeOfDay.fromDateTime(ClinicTime.local(slot)),
                  ),
                ),
            ],
          ),
          if (availableSlots(
            date,
            duration,
            settings,
            booked,
            ref.read(repositoryProvider).session.doctorId,
            excludeId: widget.existing?.id,
          ).isEmpty)
            Text(tr('No available slots for this date and duration.')),
        ],
        if (widget.existing == null)
          TextButton.icon(
            onPressed: patientId == null || busy
                ? null
                : () async {
                    await runAction(context, () async {
                      await ref.read(repositoryProvider).scheduleAction(
                        'waitlist_add',
                        {'patient_id': patientId, 'notes': notes.text},
                      );
                    }, success: 'Patient added to the cancellation waitlist.');
                  },
            icon: const Icon(Icons.playlist_add),
            label: Text(tr('Add to cancellation waitlist')),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: notes,
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(labelText: tr('Appointment notes')),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: busy || patientId == null
              ? null
              : () async {
                  setState(() => busy = true);
                  final repo = ref.read(repositoryProvider);
                  final saved = await runAction(
                    context,
                    () async {
                      final value = Appointment(
                        id: widget.existing?.id ?? const Uuid().v4(),
                        clinicId: repo.session.clinicId,
                        patientId: patientId!,
                        doctorId:
                            widget.existing?.doctorId ?? repo.session.doctorId,
                        startsAt: ClinicTime.at(date, time.hour, time.minute),
                        status:
                            widget.existing?.status ??
                            AppointmentStatus.scheduled,
                        durationMinutes: duration,
                        type: type,
                        notes: notes.text,
                        version: widget.existing?.version ?? 0,
                      );
                      if (!settings.allows(value.startsAt, duration)) {
                        throw const ClinicFailure(
                          'validation',
                          'Choose a time within the doctor’s working hours and outside breaks.',
                        );
                      }
                      if (value.startsAt.isBefore(DateTime.now())) {
                        throw const ClinicFailure(
                          'validation',
                          'Choose a future appointment time.',
                        );
                      }
                      await repo.saveAppointment(value);
                    },
                    success:
                        'Saved on this device. Server synchronization is separate.',
                  );
                  if (mounted) {
                    setState(() => busy = false);
                    if (saved && context.mounted) Navigator.pop(context);
                  }
                },
          child: Text(tr(busy ? 'Saving…' : 'Save appointment')),
        ),
      ],
    ),
  );
}
