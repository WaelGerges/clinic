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
              decoration: const InputDecoration(
                labelText: 'Name, mobile or patient ID',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilterChip(
                  label: const Text('Archived'),
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
                  label: const Text('New patient'),
                ),
              ],
            ),
            if (remoteError != null) Text(remoteError!),
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
                  message:
                      'No matching ${archived ? 'archived ' : ''}records are cached. Online search may have additional results.',
                  action: offset > 0
                      ? TextButton(
                          onPressed: () => page((offset - 50).clamp(0, offset)),
                          child: const Text('Previous page'),
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
                            '${p.ageAt(DateTime.now())} years · ${p.gender} · ${p.number}\n${p.mobile}',
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
                          child: const Text('Previous'),
                        ),
                        Text('Page ${offset ~/ 50 + 1}'),
                        TextButton(
                          onPressed: patients.length < 50
                              ? null
                              : () => page(offset + 50),
                          child: const Text('Next'),
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
        title: Text(widget.id == null ? 'Register patient' : 'Edit patient'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? EmptyPanel(
              icon: Icons.error_outline,
              title: 'Patient unavailable',
              message: error!,
            )
          : Form(
              key: form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    original?.number ??
                        'Patient ID is assigned automatically after synchronization.',
                  ),
                  const SizedBox(height: 16),
                  field(
                    name,
                    'Full name',
                    validator: (v) => (v?.trim().length ?? 0) < 2
                        ? 'Enter the full name'
                        : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: ['Female', 'Male', 'Other', 'Not specified']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => gender = v!),
                  ),
                  const SizedBox(height: 16),
                  field(
                    dob,
                    'Date of birth · YYYY-MM-DD',
                    validator: (v) => parseBirthDate(v ?? '') == null
                        ? 'Use a valid date: YYYY-MM-DD'
                        : null,
                  ),
                  field(
                    mobile,
                    'Mobile number',
                    keyboard: TextInputType.phone,
                    validator: (v) => normalizePhone(v ?? '').length < 7
                        ? 'Enter a valid mobile number'
                        : null,
                  ),
                  field(
                    secondary,
                    'Secondary mobile',
                    keyboard: TextInputType.phone,
                  ),
                  field(address, 'Address', lines: 2),
                  field(notes, 'General notes', lines: 4),
                  if (repo.session.isDoctor)
                    field(alerts, 'Important medical alerts', lines: 3),
                  const Text(
                    'Saving on this device does not mean the server has received the change.',
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
                    child: Text(busy ? 'Saving…' : 'Save patient'),
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
      validator: validator,
      decoration: InputDecoration(labelText: label),
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
          title: const Text('Patient record'),
          actions: [
            IconButton(
              tooltip: 'Edit patient',
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
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Archived patient · Records are retained'),
                ),
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Visits'),
                  Tab(text: 'Prescriptions'),
                  Tab(text: 'Attachments'),
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
                                'Date of birth: ${DateFormat.yMMMd().format(p.birthDate)}',
                              ),
                              Text('Mobile: ${p.mobile}'),
                              if (p.secondaryMobile.isNotEmpty)
                                Text('Secondary: ${p.secondaryMobile}'),
                              Text(
                                'Address: ${p.address.isEmpty ? 'Not recorded' : p.address}',
                              ),
                              Text(
                                'Created: ${DateFormat.yMMMd().format(ClinicTime.local(p.createdAt))}',
                              ),
                              Text(
                                'Updated: ${DateFormat.yMMMd().format(ClinicTime.local(p.updatedAt))}',
                              ),
                            ],
                          ),
                        ),
                        SectionCard(
                          title: 'General notes',
                          child: Text(
                            p.notes.isEmpty ? 'No general notes.' : p.notes,
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
                            label: const Text('Book appointment'),
                          ),
                        TextButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  p.archived
                                      ? 'Restore patient?'
                                      : 'Archive patient?',
                                ),
                                content: const Text(
                                  'Medical history is retained. Active queue patients cannot be archived.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Back'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      p.archived ? 'Restore' : 'Archive',
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
                            p.archived
                                ? 'Restore archived patient'
                                : 'Archive patient',
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
      return const SingleChildScrollView(
        child: EmptyPanel(
          icon: Icons.lock_outline,
          title: 'Clinical access restricted',
          message:
              'The doctor must grant access to medical history and prescriptions.',
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
              Expanded(child: Text('Saved visits · Page ${offset ~/ 50 + 1}')),
              IconButton(
                tooltip: 'Refresh history',
                onPressed: refreshing ? null : refreshPage,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (warning != null) Text(warning!),
          if (refreshing) const LinearProgressIndicator(),
          if (visits.isEmpty)
            const EmptyPanel(
              icon: Icons.history,
              title: 'No medical history on this device',
              message:
                  'Previous visits will appear after they have been synchronized.',
            ),
          for (final v in visits)
            Card(
              child: ExpansionTile(
                title: Text(
                  DateFormat.yMMMd().format(ClinicTime.local(v.createdAt)),
                ),
                subtitle: Text(
                  '${v.completed ? 'Completed' : 'Draft'} · revision ${v.currentRevision}\n${v.diagnoses.join(' · ')}',
                ),
                childrenPadding: const EdgeInsets.all(16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.prescriptionsOnly) ...[
                    Text(v.notes),
                    if (v.followUp.isNotEmpty) Text('Follow-up: ${v.followUp}'),
                  ],
                  for (final m in v.medications)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${m.name} ${m.strength}'),
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
                    'Last changed: ${DateFormat.yMMMd().add_Hm().format(ClinicTime.local(v.updatedAt))} Cairo',
                  ),
                  if (v.completed)
                    Text(
                      v.amendmentReason.isEmpty
                          ? 'Historical changes require an amendment. Originals are retained.'
                          : 'Amendment reason: ${v.amendmentReason}',
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
                        label: const Text('Amend visit'),
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
                child: const Text('Previous'),
              ),
              TextButton(
                onPressed: visits.length < 50 ? null : () => page(offset + 50),
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
