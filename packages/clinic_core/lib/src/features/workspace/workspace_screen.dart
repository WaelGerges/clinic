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
              doctor ? 'Clinic Doctor' : 'Clinic Assistant',
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
            tooltip: 'Refresh and synchronize',
            onPressed: () => runAction(
              context,
              () async {
                await repo.synchronize();
                await repo.refresh();
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
                child: const Text(
                  'LOCAL PREVIEW · Fictional data · Not shared · Resets when closed',
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
                  repo.connectionWarning!,
                  semanticsLabel: repo.connectionWarning,
                ),
              ),
            LoadView<SyncSummary>(
              load: (r) => r.syncSummary(),
              builder: (s) => s.clean
                  ? const SizedBox.shrink()
                  : MaterialBanner(
                      content: Text(
                        '${s.pending} pending · ${s.conflicts} conflicts · ${s.failed} need attention. Saved on this device.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              setState(() => selected = labels.length - 1),
                          child: const Text('Review'),
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
                          label: Text(labels[i]),
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
                  label: labels[i],
                ),
              ),
            ),
    );
  }

  Widget settings(ClinicRepository repo) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      if (repo.session.isDoctor && repo.session.isAdmin)
        ListTile(
          leading: const Icon(Icons.people_outline),
          title: const Text('Clinic team'),
          subtitle: const Text('Invite assistants and manage access'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/staff'),
        ),
      if (repo.session.isDoctor && repo.session.isAdmin)
        ListTile(
          leading: const Icon(Icons.policy_outlined),
          title: const Text('Audit and access'),
          subtitle: const Text('Review protected clinic activity'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/audit'),
        ),
      SectionCard(
        title: 'Appearance',
        child: DropdownButtonFormField<ThemeMode>(
          initialValue: widget.mode,
          decoration: const InputDecoration(labelText: 'Theme'),
          items: ThemeMode.values
              .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
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
              repo.gateway == null
                  ? 'Offline preview. No changes are sent to a server.'
                  : 'Local changes are queued and retried. Hosted integration is not yet validated.',
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => runAction(context, repo.synchronize),
              child: const Text('Retry pending changes'),
            ),
            TextButton.icon(
              onPressed: () => context.push('/sync/history'),
              icon: const Icon(Icons.history),
              label: const Text('Recovery history'),
            ),
            LoadView<List<Map<String, dynamic>>>(
              load: (r) => r.pendingOperations(),
              builder: (rows) => Column(
                children: [
                  for (final row in rows)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cloud_upload_outlined),
                      title: Text('${row['entity_type']} · ${row['action']}'),
                      subtitle: Text(
                        '${row['state']}\n${row['error'] ?? 'Waiting for server confirmation'}',
                      ),
                      trailing:
                          row['state'] == 'conflict' &&
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
                    const Text(
                      'Tap a patient conflict to compare versions. Appointment and clinical conflict recovery still require further implementation; those requests remain retained and blocked.',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SectionCard(
        title: 'Foundation build',
        child: Text(
          'Document staging/preview, completed-visit amendments, a privacy-safe administrator audit review, and an eight-hour verified offline access lease are implemented. Device controls, full access logging, and full delta synchronization are not finished. Use fictional data only.',
        ),
      ),
      if (widget.onLogout != null)
        OutlinedButton.icon(
          onPressed: () => runAction(context, widget.onLogout!),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out and lock local records'),
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
        'A clear view of your day',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      Text(DateFormat('EEEE, d MMMM').format(ClinicTime.now())),
      const SizedBox(height: 20),
      FilledButton.tonalIcon(
        onPressed: onPatients,
        icon: const Icon(Icons.search),
        label: const Text('Search patient by name, phone or ID'),
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
                      '${rows.length}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
                Expanded(
                  child: SectionCard(
                    title: 'Waiting',
                    child: Text(
                      '${rows.where((a) => a.status == AppointmentStatus.waiting).length}',
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
                child: const Text('Queue'),
              ),
              child: Column(
                children: [
                  if (rows.isEmpty)
                    const EmptyPanel(
                      icon: Icons.calendar_today_outlined,
                      title: 'No appointments today',
                      message: 'Create an appointment or register a walk-in.',
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
        label: const Text('Register patient'),
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
      Text('Appointments', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: () => selectDay(ClinicTime.now()),
            child: const Text('Today'),
          ),
          OutlinedButton(
            onPressed: () => selectDay(
              DateTime(
                ClinicTime.now().year,
                ClinicTime.now().month,
                ClinicTime.now().day + 1,
              ),
            ),
            child: const Text('Tomorrow'),
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
            label: const Text('Calendar'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(DateFormat.yMMMMEEEEd().format(day)),
      const Text('Showing appointments currently cached on this device.'),
      const SizedBox(height: 12),
      LoadView<List<Appointment>>(
        load: (r) => r.appointments(day: day),
        builder: (rows) => Column(
          children: [
            if (rows.isEmpty)
              const EmptyPanel(
                icon: Icons.event_available,
                title: 'No appointments for this date',
                message: 'Create a new appointment below.',
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
        label: const Text('New appointment'),
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
      Text('Today’s queue', style: Theme.of(context).textTheme.headlineSmall),
      const Text(
        'One active patient per doctor. Handoffs require server confirmation.',
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
                      !data.delivery.serviceAvailable
                          ? 'Live device status is unavailable in offline preview.'
                          : data.delivery.doctorOnline
                          ? 'Doctor app is online for a server-confirmed handoff.'
                          : 'Doctor app presence is absent or expired. Do not send a patient.',
                    ),
                  ),
                ],
              ),
            ),
            SectionCard(
              title: 'With doctor',
              child: data.active == null
                  ? const Text('No patient currently assigned.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppointmentTile(data.active!, actions: false),
                        Text(
                          data.delivery.acknowledged
                              ? 'Doctor receipt confirmed at ${DateFormat.Hm().format(ClinicTime.local(data.delivery.acknowledgedAt!))} Cairo.'
                              : 'Awaiting explicit Doctor-device receipt. The assignment is reserved, but receipt must not be assumed.',
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
                    const Text('Nobody is waiting.'),
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
                    const Text('Completed visits will appear here.'),
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
      Text('Current patient', style: Theme.of(context).textTheme.headlineSmall),
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
            return const EmptyPanel(
              icon: Icons.meeting_room_outlined,
              title: 'No patient currently assigned.',
              message:
                  'The current patient appears here after the assistant’s handoff is confirmed.',
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
                      '${DateFormat.Hm().format(ClinicTime.local(a.startsAt))} · ${a.type} · Cairo',
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
                  'Receipt confirmed at ${DateFormat.Hm().format(ClinicTime.local(data.delivery.acknowledgedAt!))} Cairo.',
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => context.push('/consultation/${a.id}'),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Open consultation'),
                ),
              ] else ...[
                const Text(
                  'The server assigned this patient, but no Doctor device has acknowledged receipt. Confirm receipt before opening the consultation.',
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
                  label: const Text('Acknowledge patient received'),
                ),
              ],
              TextButton.icon(
                onPressed: () => context.push('/patients/${p.id}'),
                icon: const Icon(Icons.history),
                label: const Text('Medical history and patient record'),
              ),
              SectionCard(
                title: 'Previous visits',
                child: LoadView<List<Visit>>(
                  load: (r) => r.visits(p.id),
                  builder: (visits) => visits.isEmpty
                      ? const Text(
                          'No previous medical history on this device.',
                        )
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
              title: Text(data.patient?.name ?? 'Patient unavailable'),
              subtitle: Text(
                '${DateFormat.Hm().format(ClinicTime.local(a.startsAt))} · ${data.patient?.number ?? ''}',
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
                      child: const Text('Mark arrived'),
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
                      child: const Text('Confirm'),
                    ),
                  if (a.status == AppointmentStatus.arrived)
                    FilledButton.tonal(
                      onPressed: busy
                          ? null
                          : () => act(
                              () =>
                                  r.changeStatus(a, AppointmentStatus.waiting),
                            ),
                      child: const Text('Add to queue'),
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
                                  title: const Text('Send to doctor?'),
                                  content: Text(
                                    'Assign ${data.patient?.name ?? 'this patient'}? The server will reserve the assignment, but the Doctor device must acknowledge receipt separately.',
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
                                      child: const Text('Send to Doctor'),
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
                        widget.doctorBusy
                            ? 'Doctor is busy'
                            : !widget.doctorAvailable
                            ? 'Doctor device offline'
                            : 'Send to Doctor',
                      ),
                    ),
                  if (a.status != AppointmentStatus.withDoctor)
                    PopupMenuButton<String>(
                      enabled: !busy,
                      tooltip: 'Appointment actions',
                      onSelected: (action) {
                        if (action == 'reschedule') {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  AppointmentFormScreen(existing: a),
                            ),
                          );
                        } else {
                          act(
                            () => r.changeStatus(
                              a,
                              action == 'cancel'
                                  ? AppointmentStatus.cancelled
                                  : AppointmentStatus.noShow,
                            ),
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        if (a.status == AppointmentStatus.scheduled ||
                            a.status == AppointmentStatus.confirmed) ...[
                          const PopupMenuItem(
                            value: 'reschedule',
                            child: Text('Reschedule'),
                          ),
                          const PopupMenuItem(
                            value: 'noShow',
                            child: Text('No Show'),
                          ),
                        ],
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Text('Cancel appointment'),
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
