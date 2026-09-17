import '../../presentation/language.dart';
import '../appointments/scheduling_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/repository.dart';
import '../../domain/models.dart';
import '../../domain/clinic_time.dart';
import '../../presentation/common.dart';
import '../patients/patient_screens.dart';
import '../appointments/appointment_screen.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({
    super.key,
    required this.kind,
    required this.mode,
    required this.onTheme,
    this.onLogout,
  });
  final AppKind kind;
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onTheme;
  final Future<void> Function()? onLogout;
  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  int selected = 0;
  @override
  Widget build(BuildContext context) {
    ref.watch(changesProvider);
    final repo = ref.watch(repositoryProvider),
        doctor = widget.kind == AppKind.doctor;
    final labels = doctor
        ? ['Current', 'Records', 'More']
        : ['Home', 'Patients', 'Schedule', 'Queue', 'More'];
    final icons = doctor
        ? [
            Icons.medical_services_outlined,
            Icons.folder_shared_outlined,
            Icons.more_horiz,
          ]
        : [
            Icons.home_outlined,
            Icons.people_outline,
            Icons.calendar_month_outlined,
            Icons.groups_outlined,
            Icons.more_horiz,
          ];
    final pages = doctor
        ? <Widget>[
            const CurrentPatientPage(),
            const PatientSearchPage(),
            settings(repo),
          ]
        : <Widget>[
            DashboardPage(
              onPatients: () => setState(() => selected = 1),
              onQueue: () => setState(() => selected = 3),
            ),
            const PatientSearchPage(),
            const SchedulePage(),
            const QueuePage(),
            settings(repo),
          ];
    final wide = MediaQuery.sizeOf(context).width >= 800;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(
          context,
        ).scale(56).clamp(64, 120),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(doctor ? 'Clinic Doctor' : 'Clinic Assistant'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              repo.session.clinicName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: tr('Refresh and synchronize'),
            onPressed: () => runAction(
              context,
              () async {
                await repo.synchronize();
                await repo.refresh(full: true);
              },
              success: repo.gateway == null
                  ? 'Offline workspace: changes remain on this device.'
                  : 'Refresh finished.',
            ),
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (repo.session.isDemo)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: Text(
                  tr(
                    'LOCAL PREVIEW · Fictional data · Not shared · Resets when closed',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (repo.connectionWarning != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  tr(repo.connectionWarning!),
                  semanticsLabel: tr(repo.connectionWarning!),
                ),
              ),
            LoadView<SyncSummary>(
              load: (r) => r.syncSummary(),
              builder: (s) => s.clean
                  ? const SizedBox.shrink()
                  : MaterialBanner(
                      content: Text(
                        tr(
                          "{0} pending · {1} conflicts · {2} need attention. Saved on this device.",
                          [s.pending, s.conflicts, s.failed],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              setState(() => selected = labels.length - 1),
                          child: Text(tr('Review')),
                        ),
                      ],
                    ),
            ),
            Expanded(
              child: Row(
                children: [
                  if (wide)
                    NavigationRail(
                      selectedIndex: selected,
                      onDestinationSelected: (i) =>
                          setState(() => selected = i),
                      labelType: NavigationRailLabelType.all,
                      destinations: List.generate(
                        labels.length,
                        (i) => NavigationRailDestination(
                          icon: Icon(icons[i]),
                          label: Text(tr(labels[i])),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: pages[selected],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (i) => setState(() => selected = i),
              destinations: List.generate(
                labels.length,
                (i) => NavigationDestination(
                  icon: Icon(icons[i]),
                  label: tr(labels[i]),
                ),
              ),
            ),
    );
  }

  Future<void> discardRejected(
    BuildContext context,
    ClinicRepository repo,
    String operationId, {
    bool conflict = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          tr(
            conflict
                ? 'Discard this conflicting request?'
                : 'Discard this rejected request?',
          ),
        ),
        content: Text(
          tr(
            conflict
                ? 'Another device changed this record first, so the server did not apply this request. Discarding removes it from the queue, keeps its content in recovery history, and refreshes the saved record from the server. Re-enter any edit that is still needed.'
                : 'The server rejected this request and did not apply it. Discarding removes it from the queue so the remaining changes can synchronize, and refreshes the saved record from the server. Any edit it contained will need to be made again.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('Discard')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await runAction(
      context,
      () => repo.discardRejectedOperation(operationId),
      success: 'The rejected request was discarded. Synchronization resumed.',
    );
  }

  Widget settings(ClinicRepository repo) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      ListTile(
        leading: const Icon(Icons.edit_calendar),
        title: Text(tr('Working hours and waitlist')),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const SchedulingScreen()),
        ),
      ),
      if (repo.session.isDoctor && repo.session.isAdmin)
        ListTile(
          leading: const Icon(Icons.people_outline),
          title: Text(tr('Clinic team')),
          subtitle: Text(tr('Invite assistants and manage access')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/staff'),
        ),
      if (repo.session.isDoctor && repo.session.isAdmin)
        ListTile(
          leading: const Icon(Icons.policy_outlined),
          title: Text(tr('Audit and access')),
          subtitle: Text(tr('Review protected clinic activity')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/audit'),
        ),
      const LanguagePicker(),
      const SizedBox(height: 16),
      SectionCard(
        title: 'Appearance',
        child: DropdownButtonFormField<ThemeMode>(
          initialValue: widget.mode,
          decoration: InputDecoration(labelText: tr('Theme')),
          items: ThemeMode.values
              .map((m) => DropdownMenuItem(value: m, child: Text(tr(m.name))))
              .toList(),
          onChanged: (m) {
            if (m != null) widget.onTheme(m);
          },
        ),
      ),
      SectionCard(
        title: 'Synchronization',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(
                repo.gateway == null
                    ? 'Offline preview. No changes are sent to a server.'
                    : 'Local changes are queued and retried. Hosted integration is not yet validated.',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => runAction(context, repo.synchronize),
              child: Text(tr('Retry pending changes')),
            ),
            TextButton.icon(
              onPressed: () => context.push('/sync/history'),
              icon: const Icon(Icons.history),
              label: Text(tr('Recovery history')),
            ),
            LoadView<List<Map<String, dynamic>>>(
              load: (r) => r.pendingOperations(),
              builder: (rows) => Column(
                children: [
                  for (final row in rows)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cloud_upload_outlined),
                      title: Text(
                        tr("{0} · {1}", [
                          tr(row['entity_type'] as String),
                          tr(row['action'] as String),
                        ]),
                      ),
                      subtitle: Text(
                        tr("{0}\n{1}", [
                          tr(row['state'] as String),
                          tr(
                            (row['error'] as String?) ??
                                'Waiting for server confirmation',
                          ),
                        ]),
                      ),
                      trailing: ClinicRepository.isDiscardable(row)
                          ? TextButton(
                              onPressed: () => discardRejected(
                                context,
                                repo,
                                row['operation_id'] as String,
                                conflict: row['state'] == 'conflict',
                              ),
                              child: Text(tr('Discard')),
                            )
                          : row['state'] == 'conflict' &&
                                row['entity_type'] == 'patient' &&
                                row['action'] == 'save'
                          ? const Icon(Icons.chevron_right)
                          : null,
                      onTap:
                          row['state'] == 'conflict' &&
                              row['entity_type'] == 'patient' &&
                              row['action'] == 'save'
                          ? () => context.push(
                              '/sync/patients/${row['operation_id']}',
                            )
                          : null,
                    ),
                  if (rows.any((r) => r['state'] == 'conflict'))
                    Text(
                      tr(
                        'Tap a patient conflict to compare and merge versions. An appointment or clinical conflict can be discarded: its content is kept in recovery history and the saved record is refreshed from the server.',
                      ),
                    ),
                  if (rows.any((r) => r['state'] == 'failed'))
                    Text(
                      tr(
                        'A rejected request blocks everything queued after it, including document uploads and shared queue actions. The server did not apply it. Discard it to resume synchronization; the saved record is then refreshed from the server.',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      SectionCard(
        title: 'Foundation build',
        child: Text(
          tr(
            'Document staging/preview, completed-visit amendments, a privacy-safe administrator audit review, and an eight-hour verified offline access lease are implemented. Device controls, full access logging, and full delta synchronization are not finished. Use fictional data only.',
          ),
        ),
      ),
      if (widget.onLogout != null)
        OutlinedButton.icon(
          onPressed: () => runAction(context, widget.onLogout!),
          icon: const Icon(Icons.logout),
          label: Text(tr('Sign out and lock local records')),
        ),
    ],
  );
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.onPatients,
    required this.onQueue,
  });
  final VoidCallback onPatients, onQueue;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        tr('A clear view of your day'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      Text(DateFormat('EEEE, d MMMM').format(ClinicTime.now())),
      const SizedBox(height: 20),
      FilledButton.tonalIcon(
        onPressed: onPatients,
        icon: const Icon(Icons.search),
        label: Text(tr('Search patient by name, phone or ID')),
      ),
      const SizedBox(height: 16),
      LoadView<List<Appointment>>(
        load: (r) => r.appointments(),
        builder: (rows) => Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SectionCard(
                    title: 'Today',
                    child: Text(
                      tr("{0}", [rows.length]),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
                Expanded(
                  child: SectionCard(
                    title: 'Waiting',
                    child: Text(
                      tr("{0}", [
                        rows
                            .where((a) => a.status == AppointmentStatus.waiting)
                            .length,
                      ]),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
              ],
            ),
            SectionCard(
              title: 'Today’s appointments',
              trailing: TextButton(
                onPressed: onQueue,
                child: Text(tr('Queue')),
              ),
              child: Column(
                children: [
                  if (rows.isEmpty)
                    EmptyPanel(
                      icon: Icons.calendar_today_outlined,
                      title: 'No appointments today',
                      message: tr(
                        'Create an appointment or register a walk-in.',
                      ),
                    ),
                  for (final a in rows.take(6)) AppointmentTile(a),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: () => context.push('/patients/new'),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(tr('Register patient')),
      ),
    ],
  );
}

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});
  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  DateTime day = ClinicTime.now();
  @override
  void initState() {
    super.initState();
    unawaited(refreshDay());
  }

  Future<void> refreshDay() async {
    final repo = ref.read(repositoryProvider);
    try {
      await repo.refreshAppointments(day: day);
    } catch (_) {
      repo.reportConnectionFailure();
    }
  }

  void selectDay(DateTime value) {
    setState(() => day = value);
    unawaited(refreshDay());
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        tr('Appointments'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: () => selectDay(ClinicTime.now()),
            child: Text(tr('Today')),
          ),
          OutlinedButton(
            onPressed: () => selectDay(
              DateTime(
                ClinicTime.now().year,
                ClinicTime.now().month,
                ClinicTime.now().day + 1,
              ),
            ),
            child: Text(tr('Tomorrow')),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final chosen = await showDatePicker(
                context: context,
                initialDate: day,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (chosen != null && mounted) selectDay(chosen);
            },
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(tr('Calendar')),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(DateFormat.yMMMMEEEEd().format(day)),
      Text(tr('Showing appointments currently cached on this device.')),
      const SizedBox(height: 12),
      LoadView<List<Appointment>>(
        load: (r) => r.appointments(day: day),
        builder: (rows) => Column(
          children: [
            if (rows.isEmpty)
              EmptyPanel(
                icon: Icons.event_available,
                title: 'No appointments for this date',
                message: tr('Create a new appointment below.'),
              ),
            for (final a in rows) AppointmentTile(a),
          ],
        ),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AppointmentFormScreen(initialDate: day),
          ),
        ),
        icon: const Icon(Icons.add),
        label: Text(tr('New appointment')),
      ),
    ],
  );
}

class QueuePage extends StatelessWidget {
  const QueuePage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        tr('Today’s queue'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      Text(
        tr(
          'One active patient per doctor. Handoffs require server confirmation.',
        ),
      ),
      const SizedBox(height: 16),
      LoadView<
        ({
          Appointment? active,
          List<Appointment> today,
          DoctorDeliveryState delivery,
        })
      >(
        load: (r) async {
          final active = await r.activeAppointment();
          return (
            active: active,
            today: await r.appointments(),
            delivery: await r.deliveryState(appointmentId: active?.id),
          );
        },
        builder: (data) => Column(
          children: [
            SectionCard(
              title: 'Doctor device',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    data.delivery.doctorOnline
                        ? Icons.wifi_tethering
                        : Icons.portable_wifi_off,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr(
                        !data.delivery.serviceAvailable
                            ? 'Live device status is unavailable in offline preview.'
                            : data.delivery.doctorOnline
                            ? 'Doctor app is online for a server-confirmed handoff.'
                            : 'Doctor app presence is absent or expired. Do not send a patient.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SectionCard(
              title: 'With doctor',
              child: data.active == null
                  ? Text(tr('No patient currently assigned.'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppointmentTile(data.active!, actions: false),
                        Text(
                          data.delivery.acknowledged
                              ? tr('Doctor receipt confirmed at {0} Cairo.', [
                                  DateFormat.Hm().format(
                                    ClinicTime.local(
                                      data.delivery.acknowledgedAt!,
                                    ),
                                  ),
                                ])
                              : tr(
                                  'Awaiting explicit Doctor-device receipt. The assignment is reserved, but receipt must not be assumed.',
                                ),
                        ),
                      ],
                    ),
            ),
            SectionCard(
              title: 'Waiting',
              child: Column(
                children: [
                  if (!data.today.any(
                    (a) => a.status == AppointmentStatus.waiting,
                  ))
                    Text(tr('Nobody is waiting.')),
                  for (final a in data.today.where(
                    (a) => a.status == AppointmentStatus.waiting,
                  ))
                    AppointmentTile(
                      a,
                      doctorBusy: data.active != null,
                      doctorAvailable:
                          data.delivery.serviceAvailable &&
                          data.delivery.doctorOnline,
                    ),
                ],
              ),
            ),
            SectionCard(
              title: 'Completed',
              child: Column(
                children: [
                  if (!data.today.any(
                    (a) => a.status == AppointmentStatus.completed,
                  ))
                    Text(tr('Completed visits will appear here.')),
                  for (final a in data.today.where(
                    (a) => a.status == AppointmentStatus.completed,
                  ))
                    AppointmentTile(a, actions: false),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class CurrentPatientPage extends ConsumerWidget {
  const CurrentPatientPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        tr('Current patient'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 16),
      LoadView<
        ({
          Appointment? appointment,
          Patient? patient,
          DoctorDeliveryState delivery,
        })
      >(
        load: (r) async {
          final a = await r.activeAppointment();
          return (
            appointment: a,
            patient: a == null ? null : await r.patient(a.patientId),
            delivery: await r.deliveryState(appointmentId: a?.id),
          );
        },
        builder: (data) {
          if (data.patient == null) {
            return EmptyPanel(
              icon: Icons.meeting_room_outlined,
              title: 'No patient currently assigned.',
              message: tr(
                'The current patient appears here after the assistant’s handoff is confirmed.',
              ),
            );
          }
          final p = data.patient!, a = data.appointment!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(
                title: 'In consultation',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PatientIdentity(p),
                    const SizedBox(height: 16),
                    StatusChip(a.status),
                    Text(
                      tr("{0} · {1} · Cairo", [
                        DateFormat.Hm().format(ClinicTime.local(a.startsAt)),
                        a.type,
                      ]),
                    ),
                    if (p.alerts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: MedicalAlert(p.alerts),
                      ),
                    if (p.notes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(p.notes),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (data.delivery.acknowledged) ...[
                Text(
                  tr("Receipt confirmed at {0} Cairo.", [
                    DateFormat.Hm().format(
                      ClinicTime.local(data.delivery.acknowledgedAt!),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => context.push('/consultation/${a.id}'),
                  icon: const Icon(Icons.edit_note),
                  label: Text(tr('Open consultation')),
                ),
              ] else ...[
                Text(
                  tr(
                    'The server assigned this patient, but no Doctor device has acknowledged receipt. Confirm receipt before opening the consultation.',
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => runAction(
                    context,
                    () =>
                        ref.read(repositoryProvider).acknowledgeAppointment(a),
                    success: 'Patient receipt confirmed.',
                  ),
                  icon: const Icon(Icons.mark_email_read_outlined),
                  label: Text(tr('Acknowledge patient received')),
                ),
              ],
              TextButton.icon(
                onPressed: () => context.push('/patients/${p.id}'),
                icon: const Icon(Icons.history),
                label: Text(tr('Medical history and patient record')),
              ),
              SectionCard(
                title: 'Previous visits',
                child: LoadView<List<Visit>>(
                  load: (r) => r.visits(p.id),
                  builder: (visits) => visits.isEmpty
                      ? Text(tr('No previous medical history on this device.'))
                      : Column(
                          children: [
                            for (final v in visits.take(3))
                              ListTile(
                                title: Text(
                                  DateFormat.yMMMd().format(
                                    ClinicTime.local(v.createdAt),
                                  ),
                                ),
                                subtitle: Text(v.diagnoses.join(' · ')),
                              ),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    ],
  );
}

class AppointmentTile extends ConsumerStatefulWidget {
  const AppointmentTile(
    this.appointment, {
    super.key,
    this.actions = true,
    this.doctorBusy = false,
    this.doctorAvailable = true,
  });
  final Appointment appointment;
  final bool actions, doctorBusy, doctorAvailable;
  @override
  ConsumerState<AppointmentTile> createState() => _AppointmentTileState();
}

class _AppointmentTileState extends ConsumerState<AppointmentTile> {
  bool busy = false;
  Future<void> act(Future<void> Function() operation) async {
    setState(() => busy = true);
    await runAction(context, operation);
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment, r = ref.watch(repositoryProvider);
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    return LoadView<({Patient? patient})>(
      load: (repo) async => (patient: await repo.patient(a.patientId)),
      builder: (data) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(data.patient?.name ?? tr('Patient unavailable')),
              subtitle: Text(
                tr("{0} · {1} min · {2}", [
                  DateFormat.Hm().format(ClinicTime.local(a.startsAt)),
                  a.durationMinutes,
                  data.patient?.number ?? '',
                ]),
              ),
              trailing: largeText ? null : StatusChip(a.status),
              onTap: data.patient == null
                  ? null
                  : () => context.push('/patients/${a.patientId}'),
            ),
            if (largeText) StatusChip(a.status),
            if (widget.actions && !a.status.terminal)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (a.status == AppointmentStatus.scheduled ||
                      a.status == AppointmentStatus.confirmed)
                    OutlinedButton(
                      onPressed: busy
                          ? null
                          : () => act(
                              () =>
                                  r.changeStatus(a, AppointmentStatus.arrived),
                            ),
                      child: Text(tr('Mark arrived')),
                    ),
                  if (a.status == AppointmentStatus.scheduled)
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => act(
                              () => r.changeStatus(
                                a,
                                AppointmentStatus.confirmed,
                              ),
                            ),
                      child: Text(tr('Confirm')),
                    ),
                  if (a.status == AppointmentStatus.arrived)
                    FilledButton.tonal(
                      onPressed: busy
                          ? null
                          : () => act(
                              () =>
                                  r.changeStatus(a, AppointmentStatus.waiting),
                            ),
                      child: Text(tr('Add to queue')),
                    ),
                  if (a.status == AppointmentStatus.waiting)
                    FilledButton.icon(
                      onPressed:
                          busy || widget.doctorBusy || !widget.doctorAvailable
                          ? null
                          : () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(tr('Send to doctor?')),
                                  content: Text(
                                    tr(
                                      "Assign {0}? The server will reserve the assignment, but the Doctor device must acknowledge receipt separately.",
                                      [data.patient?.name ?? 'this patient'],
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
                                      child: Text(tr('Send to Doctor')),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && mounted) {
                                await act(() => r.sendToDoctor(a));
                              }
                            },
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(
                        tr(
                          widget.doctorBusy
                              ? 'Doctor is busy'
                              : !widget.doctorAvailable
                              ? 'Doctor device offline'
                              : 'Send to Doctor',
                        ),
                      ),
                    ),
                  // Also shown while the patient is with the doctor, so a
                  // mis-sent patient or a walkout can be released instead of
                  // holding the doctor's only active slot.
                  PopupMenuButton<String>(
                    enabled: !busy,
                    tooltip: tr('Appointment actions'),
                    onSelected: (action) {
                      if (action == 'reschedule') {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AppointmentFormScreen(existing: a),
                          ),
                        );
                      } else {
                        act(
                          () => r.changeStatus(a, switch (action) {
                            'cancel' => AppointmentStatus.cancelled,
                            'return' => AppointmentStatus.waiting,
                            _ => AppointmentStatus.noShow,
                          }),
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      if (a.status == AppointmentStatus.scheduled ||
                          a.status == AppointmentStatus.confirmed) ...[
                        PopupMenuItem(
                          value: 'reschedule',
                          child: Text(tr('Reschedule')),
                        ),
                        PopupMenuItem(
                          value: 'noShow',
                          child: Text(tr('No Show')),
                        ),
                      ],
                      if (a.status == AppointmentStatus.withDoctor)
                        PopupMenuItem(
                          value: 'return',
                          child: Text(tr('Return to queue')),
                        ),
                      PopupMenuItem(
                        value: 'cancel',
                        child: Text(tr('Cancel appointment')),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
