import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/gateway.dart';
import '../../data/repository.dart';
import '../../domain/clinic_time.dart';
import '../../domain/models.dart';
import '../../presentation/common.dart';

class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  static const pageSize = 25;

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  final events = <ClinicAuditEvent>[];
  bool loading = true;
  bool loadingOlder = false;
  bool hasOlder = false;
  String? error;

  bool _canReview(ClinicRepository repository) {
    final session = repository.session;
    return session.isDoctor &&
        session.isAdmin &&
        !session.isDemo &&
        repository.gateway is ClinicAuditGateway;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(load(reset: true));
    });
  }

  Future<void> load({required bool reset}) async {
    final repository = ref.read(repositoryProvider);
    if (!_canReview(repository)) return;
    setState(() {
      if (reset) {
        loading = true;
      } else {
        loadingOlder = true;
      }
      error = null;
    });
    try {
      final rows = await repository.auditGateway.auditEvents(
        repository.session.clinicId,
        offset: reset ? 0 : events.length,
        limit: AuditScreen.pageSize,
      );
      if (!mounted) return;
      setState(() {
        if (reset) events.clear();
        events.addAll(rows);
        hasOlder = rows.length == AuditScreen.pageSize;
      });
    } catch (caught) {
      if (!mounted) return;
      setState(() => error = safeError(caught));
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          loadingOlder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(repositoryProvider);
    final canReview = _canReview(repository);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit and access'),
        actions: [
          if (canReview)
            IconButton(
              tooltip: 'Refresh audit history',
              onPressed: loading || loadingOlder
                  ? null
                  : () => load(reset: true),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: !canReview
          ? const EmptyPanel(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Online doctor administrator access required',
              message:
                  'Sign into a real development clinic as its doctor administrator to review audit history. Saved offline access and preview mode cannot open it.',
            )
          : RefreshIndicator(
              onRefresh: () => load(reset: true),
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SectionCard(
                    title: 'Privacy-safe event history',
                    child: Text(
                      'This view shows who acted, what changed, the affected record identifier, and when it happened. Raw clinical before/after values are intentionally excluded.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (error != null && events.isEmpty)
                    EmptyPanel(
                      icon: Icons.error_outline,
                      title: 'Unable to load audit history',
                      message: error!,
                      action: FilledButton.tonal(
                        onPressed: () => load(reset: true),
                        child: const Text('Retry'),
                      ),
                    )
                  else if (events.isEmpty)
                    const EmptyPanel(
                      icon: Icons.history_toggle_off,
                      title: 'No audit events yet',
                      message:
                          'Events will appear here after protected clinic actions are recorded.',
                    )
                  else ...[
                    for (final event in events) AuditEventCard(event: event),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(error!, textAlign: TextAlign.center),
                      ),
                    if (hasOlder)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: FilledButton.tonalIcon(
                          onPressed: loadingOlder
                              ? null
                              : () => load(reset: false),
                          icon: loadingOlder
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more),
                          label: Text(
                            loadingOlder ? 'Loading…' : 'Load older events',
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class AuditEventCard extends StatelessWidget {
  const AuditEventCard({super.key, required this.event});

  final ClinicAuditEvent event;

  @override
  Widget build(BuildContext context) {
    final cairoTime = ClinicTime.local(event.occurredAt);
    final actor = compactAuditIdentifier(event.actorId);
    final object = compactAuditIdentifier(event.objectId);
    return Card(
      key: Key('audit-event-${event.id}'),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.policy_outlined)),
        title: Text(event.action),
        subtitle: Text(
          '${event.actorRole} · Actor $actor\n'
          '${event.objectType} · $object\n'
          '${DateFormat('d MMM y, HH:mm').format(cairoTime)} Cairo',
        ),
        isThreeLine: true,
      ),
    );
  }
}
