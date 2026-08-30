import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/patient_sync_review.dart';
import '../../domain/clinic_time.dart';
import '../../presentation/common.dart';

String _display(Object? value) => switch (value) {
  true => 'Yes',
  false => 'No',
  null || '' => 'Not entered',
  _ => value.toString(),
};

class PatientSyncReviewScreen extends ConsumerStatefulWidget {
  const PatientSyncReviewScreen({super.key, required this.operationId});
  final String operationId;

  @override
  ConsumerState<PatientSyncReviewScreen> createState() =>
      _PatientSyncReviewScreenState();
}

class _PatientSyncReviewScreenState
    extends ConsumerState<PatientSyncReviewScreen> {
  PatientSyncReview? review;
  String? error;
  bool busy = false;
  final localFields = <String>{};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
      review = null;
      localFields.clear();
    });
    try {
      final value = await ref
          .read(repositoryProvider)
          .reviewPatientConflict(widget.operationId);
      if (mounted) setState(() => review = value);
    } catch (e) {
      if (mounted) setState(() => error = safeError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resolve({required bool useServer}) async {
    final current = review;
    if (busy || current == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          useServer ? 'Keep the server version?' : 'Queue this reviewed merge?',
        ),
        content: Text(
          useServer
              ? 'The server patient will replace the local record. All ${current.operationCount} queued saves and both versions will remain in encrypted recovery history.'
              : 'Only the selected fields will come from this device. Other fields stay as shown on the server. The merged save can conflict again if another device edits first. Original changes remain in encrypted recovery history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(useServer ? 'Keep server version' : 'Queue merge'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    final success = await runAction(
      context,
      () => ref
          .read(repositoryProvider)
          .resolvePatientConflict(
            current,
            localFields: useServer ? {} : Set.of(localFields),
          ),
      success: useServer
          ? 'Server version kept. Original local changes remain in recovery history.'
          : 'Reviewed merge queued. Check synchronization for server confirmation.',
    );
    if (!mounted) return;
    setState(() => busy = false);
    if (success) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final current = review;
    final doctor = ref.watch(repositoryProvider).session.isDoctor;
    final differentFields = current == null
        ? <MapEntry<String, String>>[]
        : patientMergeFields.entries
              .where(
                (field) =>
                    current.local.toMap()[field.key] !=
                    current.remote.toMap()[field.key],
              )
              .toList();
    final unchangedFields = patientMergeFields.entries
        .where(
          (field) =>
              !differentFields.any((changed) => changed.key == field.key),
        )
        .toList();
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Patient changes'),
          actions: [
            IconButton(
              onPressed: busy ? null : load,
              tooltip: 'Reload latest versions',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: busy
              ? const Center(child: CircularProgressIndicator())
              : current == null
              ? SingleChildScrollView(
                  child: EmptyPanel(
                    icon: Icons.cloud_off_outlined,
                    title: 'Review unavailable',
                    message:
                        error ?? 'Connect to load the latest server record.',
                    action: FilledButton(
                      onPressed: load,
                      child: const Text('Try again'),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      current.local.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${current.operationCount} local ${current.operationCount == 1 ? 'save' : 'saves'} retained · Server version ${current.remote.version}',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Compare each field. Server values are selected by default. Choose any device values you want to keep in the merged save.',
                    ),
                    const SizedBox(height: 12),
                    for (final field in differentFields)
                      _field(field.key, field.value, current, doctor),
                    if (unchangedFields.isNotEmpty)
                      ExpansionTile(
                        title: Text(
                          'Unchanged fields (${unchangedFields.length})',
                        ),
                        children: [
                          for (final field in unchangedFields)
                            _field(field.key, field.value, current, doctor),
                        ],
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: localFields.isEmpty
                          ? null
                          : () => resolve(useServer: false),
                      child: const Text('Queue reviewed merge'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => resolve(useServer: true),
                      child: const Text('Keep server version'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Neither choice deletes your original changes. Review them later in More → Recovery history.',
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _field(
    String key,
    String label,
    PatientSyncReview current,
    bool doctor,
  ) {
    final local = current.local.toMap()[key],
        remote = current.remote.toMap()[key];
    final different = local != remote;
    final editable = key != 'alerts' || doctor;
    return SectionCard(
      title: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (different) ...[
            Text('This device: ${_display(local)}'),
            const SizedBox(height: 8),
            Text('Server: ${_display(remote)}'),
            if (editable)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text('Use this device’s ${label.toLowerCase()}'),
                value: localFields.contains(key),
                onChanged: (selected) => setState(() {
                  if (selected == true) {
                    localFields.add(key);
                  } else {
                    localFields.remove(key);
                  }
                }),
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'The doctor controls medical alerts. The server value will be kept.',
                ),
              ),
          ] else
            Text('${_display(remote)} · Same on both'),
        ],
      ),
    );
  }
}

class PatientRecoveryHistoryScreen extends ConsumerStatefulWidget {
  const PatientRecoveryHistoryScreen({super.key});
  @override
  ConsumerState<PatientRecoveryHistoryScreen> createState() =>
      _PatientRecoveryHistoryScreenState();
}

class _PatientRecoveryHistoryScreenState
    extends ConsumerState<PatientRecoveryHistoryScreen> {
  int offset = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recovery history')),
    body: SafeArea(
      child: LoadView<List<PatientSyncResolution>>(
        load: (repo) => repo.patientRecoveryHistory(offset: offset),
        builder: (entries) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Encrypted history on this device. Original requests and both versions are retained. A queued merge is not proof of server acceptance.',
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const Text('No reviewed conflicts on this page.'),
            for (final entry in entries)
              Card(
                child: ListTile(
                  title: Text(entry.local.name),
                  subtitle: Text(
                    '${entry.choice == 'server' ? 'Kept server version' : 'Queued reviewed merge'}\n'
                    '${DateFormat('d MMM yyyy, HH:mm').format(ClinicTime.local(entry.resolvedAt))} · ${entry.operationCount} original saves',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    useSafeArea: true,
                    builder: (context) => FractionallySizedBox(
                      heightFactor: .9,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Text(
                            entry.local.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          for (final field in patientMergeFields.entries)
                            SectionCard(
                              title: field.value,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Original device: ${_display(entry.local.toMap()[field.key])}',
                                  ),
                                  Text(
                                    'Server at review: ${_display(entry.remote.toMap()[field.key])}',
                                  ),
                                  Text(
                                    'Selected result: ${_display(entry.resolved.toMap()[field.key])}',
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Wrap(
              spacing: 12,
              children: [
                TextButton(
                  onPressed: offset == 0
                      ? null
                      : () => setState(() => offset -= 50),
                  child: const Text('Previous'),
                ),
                TextButton(
                  onPressed: entries.length < 50
                      ? null
                      : () => setState(() => offset += 50),
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
