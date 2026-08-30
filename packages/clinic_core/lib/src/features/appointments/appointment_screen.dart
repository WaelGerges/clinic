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
        widget.existing == null ? 'New appointment' : 'Reschedule appointment',
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (widget.existing == null) ...[
          TextField(
            controller: search,
            decoration: const InputDecoration(
              labelText: 'Find patient',
              prefixIcon: Icon(Icons.search),
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
                      subtitle: Text('${p.number} · ${p.mobile}'),
                    ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            final result = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (result != null && mounted) setState(() => date = result);
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
          decoration: const InputDecoration(labelText: 'Appointment type'),
          items: [
            'Consultation',
            'Follow-up',
            'Procedure',
          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => type = v!),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: notes,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(labelText: 'Appointment notes'),
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
                        type: type,
                        notes: notes.text,
                        version: widget.existing?.version ?? 0,
                      );
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
          child: Text(busy ? 'Saving…' : 'Save appointment'),
        ),
      ],
    ),
  );
}
