import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models.dart';
import '../../presentation/common.dart';
import '../documents/document_screen.dart';

class ConsultationScreen extends ConsumerStatefulWidget {
  const ConsultationScreen({super.key, required this.appointmentId})
    : patientId = null,
      visitId = null,
      amendment = false;
  const ConsultationScreen.amendment({
    super.key,
    required this.patientId,
    required this.visitId,
  }) : appointmentId = null,
       amendment = true;
  final String? appointmentId, patientId, visitId;
  final bool amendment;
  @override
  ConsumerState<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends ConsumerState<ConsultationScreen> {
  final diagnoses = TextEditingController(),
      notes = TextEditingController(),
      followUp = TextEditingController(),
      reason = TextEditingController();
  final medications = <Medication>[];
  Visit? visit;
  Patient? patient;
  bool busy = false, dirty = false, loading = true;
  String? error, saved;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final repo = ref.read(repositoryProvider);
      if (!repo.session.isDoctor) {
        throw const ClinicFailure(
          'forbidden',
          'Only a doctor can open the consultation editor.',
        );
      }
      if (widget.amendment) {
        patient = await repo.patient(widget.patientId!);
        visit = (await repo.visits(
          widget.patientId!,
        )).where((item) => item.id == widget.visitId).firstOrNull;
        if (patient == null || visit == null || !visit!.completed) {
          throw const ClinicFailure(
            'not_found',
            'The completed visit is unavailable. Refresh the patient history.',
          );
        }
      } else {
        final a = await repo.appointment(widget.appointmentId!);
        if (a == null || a.status != AppointmentStatus.withDoctor) {
          throw const ClinicFailure(
            'assignment_changed',
            'This appointment is not currently with the doctor.',
          );
        }
        patient = await repo.patient(a.patientId);
        final history = await repo.visits(a.patientId);
        visit = history
            .where((v) => v.appointmentId == a.id && !v.completed)
            .firstOrNull;
        final now = DateTime.now();
        visit ??= Visit(
          id: const Uuid().v4(),
          clinicId: a.clinicId,
          patientId: a.patientId,
          appointmentId: a.id,
          doctorId: repo.session.userId,
          createdAt: now,
          updatedAt: now,
        );
      }
      diagnoses.text = visit!.diagnoses.join('\n');
      notes.text = visit!.notes;
      followUp.text = visit!.followUp;
      medications.addAll(visit!.medications);
    } catch (e) {
      error = safeError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    diagnoses.dispose();
    notes.dispose();
    followUp.dispose();
    reason.dispose();
    super.dispose();
  }

  Future<void> save({bool complete = false}) async {
    setState(() => busy = true);
    final repo = ref.read(repositoryProvider);
    final success = await runAction(context, () async {
      final draft = visit!.copyWith(
        diagnoses: diagnoses.text
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        medications: medications,
        notes: notes.text,
        followUp: followUp.text,
      );
      if (widget.amendment) {
        draft.validateAmendment(reason.text);
        visit = await repo.amendVisit(draft, reason.text);
        if (mounted) setState(() => dirty = false);
        return;
      }
      if (complete) draft.validateForCompletion();
      visit = await repo.saveVisit(draft);
      if (mounted) {
        setState(() {
          dirty = false;
          saved = 'Draft saved on this device. Check synchronization status.';
        });
      }
      if (complete) await repo.completeVisit(visit!);
    });
    if (mounted) {
      setState(() => busy = false);
      if (success && (complete || widget.amendment)) context.pop();
    }
  }

  Future<void> discard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave unsaved changes?'),
        content: const Text(
          'Save a draft to keep your latest notes. Changes since the last save will otherwise be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard unsaved changes'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => dirty = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty && !busy,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !busy) discard();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.amendment ? 'Amend completed visit' : 'Consultation',
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? EmptyPanel(
              icon: Icons.error_outline,
              title: 'Consultation unavailable',
              message: error!,
            )
          : Column(
              children: [
                if (patient != null)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: PatientIdentity(patient!),
                  ),
                if (patient?.alerts.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: MedicalAlert(patient!.alerts),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        widget.amendment
                            ? 'Revision ${visit!.currentRevision} is preserved. Submitting creates revision ${visit!.currentRevision + 1}.'
                            : dirty
                            ? 'Unsaved changes'
                            : saved ?? 'Draft visit · Not completed',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      if (widget.amendment)
                        SectionCard(
                          title: 'Reason for amendment',
                          child: TextField(
                            controller: reason,
                            minLines: 2,
                            maxLines: 5,
                            maxLength: 1000,
                            onChanged: (_) => setState(() => dirty = true),
                            decoration: const InputDecoration(
                              labelText: 'Required',
                              hintText:
                                  'Explain what is being corrected or clarified and why.',
                              alignLabelWithHint: true,
                            ),
                          ),
                        ),
                      TextButton.icon(
                        onPressed: () =>
                            context.push('/patients/${patient!.id}'),
                        icon: const Icon(Icons.history),
                        label: const Text('Review patient history'),
                      ),
                      SectionCard(
                        title: 'Diagnosis',
                        child: TextField(
                          controller: diagnoses,
                          minLines: 2,
                          maxLines: 6,
                          onChanged: (_) => setState(() => dirty = true),
                          decoration: const InputDecoration(
                            labelText: 'One diagnosis per line',
                          ),
                        ),
                      ),
                      SectionCard(
                        title: 'Prescription',
                        trailing: IconButton(
                          tooltip: 'Add medication',
                          icon: const Icon(Icons.add),
                          onPressed: () async {
                            final item = await showDialog<Medication>(
                              context: context,
                              builder: (_) => const MedicationDialog(),
                            );
                            if (item != null && mounted) {
                              setState(() {
                                medications.add(item);
                                dirty = true;
                              });
                            }
                          },
                        ),
                        child: Column(
                          children: [
                            if (medications.isEmpty)
                              const Text(
                                'No medication items. Add only what you intend to prescribe.',
                              ),
                            for (var i = 0; i < medications.length; i++)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  '${medications[i].name} ${medications[i].strength}',
                                ),
                                subtitle: Text(
                                  [
                                    medications[i].dose,
                                    medications[i].frequency,
                                    medications[i].duration,
                                  ].where((s) => s.isNotEmpty).join(' · '),
                                ),
                                onTap: () async {
                                  final item = await showDialog<Medication>(
                                    context: context,
                                    builder: (_) => MedicationDialog(
                                      existing: medications[i],
                                    ),
                                  );
                                  if (item != null && mounted) {
                                    setState(() {
                                      medications[i] = item;
                                      dirty = true;
                                    });
                                  }
                                },
                                trailing: IconButton(
                                  tooltip: 'Remove medication item',
                                  icon: const Icon(Icons.close),
                                  onPressed: () => setState(() {
                                    medications.removeAt(i);
                                    dirty = true;
                                  }),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SectionCard(
                        title: 'Doctor notes',
                        child: TextField(
                          controller: notes,
                          minLines: 7,
                          maxLines: 20,
                          onChanged: (_) => setState(() => dirty = true),
                          decoration: const InputDecoration(
                            labelText: 'Clinical notes',
                            hintText:
                                'Symptoms and examination\nAssessment and treatment plan',
                            hintMaxLines: 3,
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      SectionCard(
                        title: 'Follow-up',
                        child: TextField(
                          controller: followUp,
                          minLines: 2,
                          maxLines: 5,
                          onChanged: (_) => setState(() => dirty = true),
                          decoration: const InputDecoration(
                            labelText: 'Follow-up instructions',
                          ),
                        ),
                      ),
                      SectionCard(
                        title: 'Attachments',
                        child: SizedBox(
                          height: 420,
                          child: ClinicDocumentsPanel(
                            patientId: visit!.patientId,
                            visitId: visit!.id,
                            compact: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: busy
                                ? null
                                : widget.amendment
                                ? discard
                                : save,
                            child: Text(
                              widget.amendment ? 'Cancel' : 'Save draft',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: busy
                                ? null
                                : widget.amendment
                                ? save
                                : () => save(complete: true),
                            child: Text(
                              busy
                                  ? 'Saving…'
                                  : widget.amendment
                                  ? 'Submit amendment'
                                  : 'Complete visit',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    ),
  );
}

class MedicationDialog extends StatefulWidget {
  const MedicationDialog({super.key, this.existing});
  final Medication? existing;
  @override
  State<MedicationDialog> createState() => _MedicationDialogState();
}

class _MedicationDialogState extends State<MedicationDialog> {
  final form = GlobalKey<FormState>();
  late final fields = <String, TextEditingController>{
    for (final key in [
      'name',
      'strength',
      'dose',
      'frequency',
      'duration',
      'instructions',
      'notes',
    ])
      key: TextEditingController(
        text: widget.existing?.toMap()[key]?.toString() ?? '',
      ),
  };
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.existing == null ? 'Add medication' : 'Edit medication'),
    content: SingleChildScrollView(
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in fields.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: item.value,
                  validator: item.key == 'name'
                      ? (v) => v == null || v.trim().isEmpty
                            ? 'Medication name is required'
                            : null
                      : null,
                  decoration: InputDecoration(
                    labelText:
                        item.key[0].toUpperCase() + item.key.substring(1),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!form.currentState!.validate()) return;
          Navigator.pop(
            context,
            Medication.fromMap({
              'id': widget.existing?.id ?? const Uuid().v4(),
              for (final e in fields.entries) e.key: e.value.text.trim(),
            }),
          );
        },
        child: const Text('Save item'),
      ),
    ],
  );
}
