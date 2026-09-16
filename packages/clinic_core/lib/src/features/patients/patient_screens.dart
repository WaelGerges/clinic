import 'package:clinic_core/src/presentation/language.dart';
import '../visits/visit_documents.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models.dart';
import '../../domain/clinic_time.dart';
import '../../data/repository.dart';
import '../../presentation/common.dart';
import '../appointments/appointment_screen.dart';
import '../documents/document_screen.dart';

class PatientSearchPage extends ConsumerStatefulWidget {
  const PatientSearchPage({super.key});
  @override
  ConsumerState<PatientSearchPage> createState() => _PatientSearchPageState();
}

class _PatientSearchPageState extends ConsumerState<PatientSearchPage> {
  final search = TextEditingController();
  Timer? debounce;
  String term = '';
  bool archived = false;
  int offset = 0;
  String? remoteError;
  @override
  void initState() {
    super.initState();
    unawaited(refreshPage());
  }

  Future<void> refreshPage() async {
    try {
      await ref
          .read(repositoryProvider)
          .refresh(search: term, offset: offset, archived: archived);
      if (mounted) setState(() => remoteError = null);
    } catch (_) {
      if (mounted) {
        setState(
          () => remoteError =
              'Online search unavailable. Showing cached matches only.',
        );
      }
    }
  }

  void page(int value) {
    setState(() => offset = value);
    unawaited(refreshPage());
  }

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  void changed(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      setState(() {
        term = value;
        offset = 0;
        remoteError = null;
      });
      try {
        await ref
            .read(repositoryProvider)
            .refresh(search: value, archived: archived);
      } catch (_) {
        if (mounted) {
          setState(
            () => remoteError =
                'Online search unavailable. Showing cached matches only.',
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          children: [
            TextField(
              controller: search,
              onChanged: changed,
              decoration: InputDecoration(
                labelText: tr('Name, mobile or patient ID'),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilterChip(
                  label: Text(tr('Archived')),
                  selected: archived,
                  onSelected: (value) {
                    setState(() {
                      archived = value;
                      offset = 0;
                    });
                    unawaited(refreshPage());
                  },
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.push('/patients/new'),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(tr('New patient')),
                ),
              ],
            ),
            if (remoteError != null) Text(tr(remoteError!)),
          ],
        ),
      ),
      Expanded(
        child: LoadView<List<Patient>>(
          load: (r) =>
              r.patients(search: term, archived: archived, offset: offset),
          builder: (patients) => patients.isEmpty
              ? EmptyPanel(
                  icon: Icons.person_search_outlined,
                  title: 'No patients found',
                  message: tr(
                    archived
                        ? 'No matching archived records are cached. Online search may have additional results.'
                        : 'No matching records are cached. Online search may have additional results.',
                  ),
                  action: offset > 0
                      ? TextButton(
                          onPressed: () => page((offset - 50).clamp(0, offset)),
                          child: Text(tr('Previous page')),
                        )
                      : null,
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final p in patients)
                      Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(p.name),
                          subtitle: Text(
                            tr("{0} years · {1} · {2}\n{3}", [
                              p.ageAt(DateTime.now()),
                              tr(p.gender),
                              p.number,
                              p.mobile,
                            ]),
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/patients/${p.id}'),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: offset == 0
                              ? null
                              : () => page(offset - 50),
                          child: Text(tr('Previous')),
                        ),
                        Text(tr("Page {0}", [offset ~/ 50 + 1])),
                        TextButton(
                          onPressed: patients.length < 50
                              ? null
                              : () => page(offset + 50),
                          child: Text(tr('Next')),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    ],
  );
}

class PatientFormScreen extends ConsumerStatefulWidget {
  const PatientFormScreen({super.key, this.id});
  final String? id;
  @override
  ConsumerState<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends ConsumerState<PatientFormScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      dob = TextEditingController(),
      mobile = TextEditingController(),
      secondary = TextEditingController(),
      address = TextEditingController(),
      notes = TextEditingController(),
      alerts = TextEditingController();
  String gender = 'Not specified';
  Patient? original;
  bool loading = false, busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      loading = true;
      load();
    }
  }

  Future<void> load() async {
    try {
      final p = await ref.read(repositoryProvider).patient(widget.id!);
      if (p == null) {
        throw const ClinicFailure(
          'not_found',
          'This patient is not available in this clinic cache.',
        );
      }
      if (!mounted) return;
      original = p;
      name.text = p.name;
      dob.text = p.birthDate.toIso8601String().substring(0, 10);
      mobile.text = p.mobile;
      secondary.text = p.secondaryMobile;
      address.text = p.address;
      notes.text = p.notes;
      alerts.text = p.alerts;
      gender = p.gender;
    } catch (e) {
      error = safeError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [name, dob, mobile, secondary, address, notes, alerts]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(widget.id == null ? 'Register patient' : 'Edit patient'),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? EmptyPanel(
              icon: Icons.error_outline,
              title: 'Patient unavailable',
              message: tr(error!),
            )
          : Form(
              key: form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    original?.number ??
                        tr(
                          'Patient ID is assigned automatically after synchronization.',
                        ),
                  ),
                  const SizedBox(height: 16),
                  field(
                    name,
                    tr('Full name'),
                    validator: (v) => (v?.trim().length ?? 0) < 2
                        ? 'Enter the full name'
                        : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: gender,
                    decoration: InputDecoration(labelText: tr('Gender')),
                    items: ['Female', 'Male', 'Other', 'Not specified']
                        .map(
                          (s) => DropdownMenuItem(value: s, child: Text(tr(s))),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => gender = v!),
                  ),
                  const SizedBox(height: 16),
                  field(
                    dob,
                    tr('Date of birth · YYYY-MM-DD'),
                    validator: (v) => parseBirthDate(v ?? '') == null
                        ? 'Use a valid date: YYYY-MM-DD'
                        : null,
                  ),
                  field(
                    mobile,
                    tr('Mobile number'),
                    keyboard: TextInputType.phone,
                    validator: (v) => normalizePhone(v ?? '').length < 7
                        ? 'Enter a valid mobile number'
                        : null,
                  ),
                  field(
                    secondary,
                    tr('Secondary mobile'),
                    keyboard: TextInputType.phone,
                  ),
                  field(address, tr('Address'), lines: 2),
                  field(notes, tr('General notes'), lines: 4),
                  if (repo.session.isDoctor)
                    field(alerts, tr('Important medical alerts'), lines: 3),
                  Text(
                    tr(
                      'Saving on this device does not mean the server has received the change.',
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () async {
                            if (!form.currentState!.validate()) return;
                            setState(() => busy = true);
                            final now = DateTime.now();
                            final p = Patient(
                              id: original?.id ?? const Uuid().v4(),
                              clinicId: repo.session.clinicId,
                              name: name.text.trim(),
                              gender: gender,
                              birthDate: parseBirthDate(dob.text)!,
                              mobile: normalizePhone(mobile.text),
                              secondaryMobile: normalizePhone(secondary.text),
                              address: address.text,
                              notes: notes.text,
                              alerts: alerts.text,
                              number: original?.number ?? 'Pending ID',
                              createdAt: original?.createdAt ?? now,
                              updatedAt: now,
                              version: original?.version ?? 0,
                              archived: original?.archived ?? false,
                            );
                            final saved = await runAction(context, () async {
                              await repo.savePatient(p);
                            }, success: 'Patient saved on this device.');
                            if (mounted) {
                              setState(() => busy = false);
                              if (saved && context.mounted) context.pop();
                            }
                          },
                    child: Text(tr(busy ? 'Saving…' : 'Save patient')),
                  ),
                ],
              ),
            ),
    );
  }

  Widget field(
    TextEditingController controller,
    String label, {
    int lines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      minLines: lines,
      maxLines: lines > 1 ? lines + 2 : 1,
      keyboardType: keyboard,
      validator: (value) {
        final error = validator?.call(value);
        return error == null ? null : tr(error);
      },
      decoration: InputDecoration(labelText: tr(label)),
    ),
  );
}

class PatientProfileScreen extends ConsumerWidget {
  const PatientProfileScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('Patient record')),
          actions: [
            IconButton(
              tooltip: tr('Edit patient'),
              onPressed: () => context.push('/patients/$id/edit'),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        body: LoadView<Patient>(
          load: (r) async {
            final p = await r.patient(id);
            if (p == null) {
              throw const ClinicFailure(
                'not_found',
                'Patient is not available in this clinic cache.',
              );
            }
            return p;
          },
          builder: (p) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: PatientIdentity(p),
              ),
              if (p.archived)
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(tr('Archived patient · Records are retained')),
                ),
              TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: tr('Overview')),
                  Tab(text: tr('Visits')),
                  Tab(text: tr('Prescriptions')),
                  Tab(text: tr('Attachments')),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        if (p.alerts.isNotEmpty)
                          SectionCard(
                            title: 'Important alerts',
                            child: Text(p.alerts),
                          ),
                        SectionCard(
                          title: 'Patient details',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr("Date of birth: {0}", [
                                  DateFormat.yMMMd().format(p.birthDate),
                                ]),
                              ),
                              Text(tr("Mobile: {0}", [p.mobile])),
                              if (p.secondaryMobile.isNotEmpty)
                                Text(tr("Secondary: {0}", [p.secondaryMobile])),
                              Text(
                                tr("Address: {0}", [
                                  p.address.isEmpty
                                      ? 'Not recorded'
                                      : p.address,
                                ]),
                              ),
                              Text(
                                tr("Created: {0}", [
                                  DateFormat.yMMMd().format(
                                    ClinicTime.local(p.createdAt),
                                  ),
                                ]),
                              ),
                              Text(
                                tr("Updated: {0}", [
                                  DateFormat.yMMMd().format(
                                    ClinicTime.local(p.updatedAt),
                                  ),
                                ]),
                              ),
                            ],
                          ),
                        ),
                        SectionCard(
                          title: 'General notes',
                          child: Text(
                            tr(p.notes.isEmpty ? 'No general notes.' : p.notes),
                          ),
                        ),
                        if (!p.archived)
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    AppointmentFormScreen(patientId: p.id),
                              ),
                            ),
                            icon: const Icon(Icons.event_available),
                            label: Text(tr('Book appointment')),
                          ),
                        TextButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  tr(
                                    p.archived
                                        ? 'Restore patient?'
                                        : 'Archive patient?',
                                  ),
                                ),
                                content: Text(
                                  tr(
                                    'Medical history is retained. Active queue patients cannot be archived.',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(tr('Back')),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      tr(p.archived ? 'Restore' : 'Archive'),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true && context.mounted) {
                              await runAction(
                                context,
                                () => repo.archivePatient(p, !p.archived),
                              );
                            }
                          },
                          child: Text(
                            tr(
                              p.archived
                                  ? 'Restore archived patient'
                                  : 'Archive patient',
                            ),
                          ),
                        ),
                      ],
                    ),
                    ClinicalHistory(patientId: id),
                    ClinicalHistory(patientId: id, prescriptionsOnly: true),
                    ClinicDocumentsPanel(patientId: id),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClinicalHistory extends ConsumerStatefulWidget {
  const ClinicalHistory({
    super.key,
    required this.patientId,
    this.prescriptionsOnly = false,
  });
  final String patientId;
  final bool prescriptionsOnly;
  @override
  ConsumerState<ClinicalHistory> createState() => _ClinicalHistoryState();
}

class _ClinicalHistoryState extends ConsumerState<ClinicalHistory> {
  int offset = 0;
  bool refreshing = false;
  String? warning;
  late final ClinicRepository repo;
  @override
  void initState() {
    super.initState();
    repo = ref.read(repositoryProvider);
    if (repo.session.clinicalRead) {
      repo.watchPatientHistory(widget.patientId);
      unawaited(refreshPage());
    }
  }

  @override
  void dispose() {
    if (repo.session.clinicalRead) repo.unwatchPatientHistory(widget.patientId);
    super.dispose();
  }

  Future<void> refreshPage() async {
    if (mounted) setState(() => refreshing = true);
    try {
      await repo.refreshVisits(widget.patientId, offset: offset);
      if (mounted) setState(() => warning = null);
    } catch (_) {
      if (mounted) {
        setState(
          () => warning = 'History refresh failed. Showing saved visits only.',
        );
      }
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  void page(int value) {
    setState(() => offset = value);
    unawaited(refreshPage());
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(repositoryProvider).session.clinicalRead) {
      return SingleChildScrollView(
        child: EmptyPanel(
          icon: Icons.lock_outline,
          title: 'Clinical access restricted',
          message: tr(
            'The doctor must grant access to medical history and prescriptions.',
          ),
        ),
      );
    }
    return LoadView<List<Visit>>(
      load: (r) => r.visits(widget.patientId, offset: offset),
      builder: (visits) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(tr("Saved visits · Page {0}", [offset ~/ 50 + 1])),
              ),
              IconButton(
                tooltip: tr('Refresh history'),
                onPressed: refreshing ? null : refreshPage,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (warning != null) Text(tr(warning!)),
          if (refreshing) const LinearProgressIndicator(),
          if (visits.isEmpty)
            EmptyPanel(
              icon: Icons.history,
              title: 'No medical history on this device',
              message: tr(
                'Previous visits will appear after they have been synchronized.',
              ),
            ),
          for (final v in visits)
            Card(
              child: ExpansionTile(
                title: Text(
                  DateFormat.yMMMd().format(ClinicTime.local(v.createdAt)),
                ),
                subtitle: Text(
                  tr("{0} · revision {1}\n{2}", [
                    tr(v.completed ? 'Completed' : 'Draft'),
                    v.currentRevision,
                    v.diagnoses.join(' · '),
                  ]),
                ),
                childrenPadding: const EdgeInsets.all(16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.prescriptionsOnly) ...[
                    Text(v.notes),
                    if (v.followUp.isNotEmpty)
                      Text(tr("Follow-up: {0}", [v.followUp])),
                  ],
                  for (final m in v.medications)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr("{0} {1}", [m.name, m.strength])),
                      subtitle: Text(
                        [
                          m.dose,
                          m.frequency,
                          m.duration,
                          m.instructions,
                          m.notes,
                        ].where((s) => s.isNotEmpty).join(' · '),
                      ),
                    ),
                  Text(
                    tr("Last changed: {0} Cairo", [
                      DateFormat.yMMMd().add_Hm().format(
                        ClinicTime.local(v.updatedAt),
                      ),
                    ]),
                  ),
                  if (v.completed)
                    Text(
                      v.amendmentReason.isEmpty
                          ? tr(
                              'Historical changes require an amendment. Originals are retained.',
                            )
                          : tr('Amendment reason: {0}', [v.amendmentReason]),
                    ),
                  if (v.completed &&
                      ref.watch(repositoryProvider).session.clinicalRead)
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => VisitDocumentsScreen(
                            patientId: widget.patientId,
                            visitId: v.id,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.print_outlined),
                      label: Text(tr('Print visit documents')),
                    ),
                  if (v.completed &&
                      !widget.prescriptionsOnly &&
                      ref.watch(repositoryProvider).session.isDoctor)
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonalIcon(
                        onPressed: () async {
                          await context.push(
                            '/patients/${widget.patientId}/visits/${v.id}/amend',
                          );
                          if (mounted) await refreshPage();
                        },
                        icon: const Icon(Icons.edit_note),
                        label: Text(tr('Amend visit')),
                      ),
                    ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: offset == 0 ? null : () => page(offset - 50),
                child: Text(tr('Previous')),
              ),
              TextButton(
                onPressed: visits.length < 50 ? null : () => page(offset + 50),
                child: Text(tr('Next')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
