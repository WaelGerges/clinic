import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/common.dart';

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});
  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  final email = TextEditingController();
  bool clinicalRead = false, busy = false;
  List<Map<String, dynamic>> members = [];
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final repo = ref.read(repositoryProvider);
    if (!repo.session.isAdmin || repo.session.isDemo) return;
    try {
      final rows = await repo.administration.staff(repo.session.clinicId);
      if (mounted) {
        setState(() {
          members = rows;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Staff access could not be loaded. Check connectivity and the staff migration deployment.',
        );
      }
    }
  }

  Future<void> invite() async {
    if (!email.text.contains('@')) {
      setState(() => error = 'Enter the assistant’s email address.');
      return;
    }
    setState(() => busy = true);
    final repo = ref.read(repositoryProvider);
    await runAction(context, () async {
      final result = await repo.administration.inviteAssistant(
        repo.session.clinicId,
        email.text.trim(),
        clinicalRead,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invitation created'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'For ${result['email']} only. The assistant must verify that email and sign in with their own account.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'This code expires in 24 hours and can be used once. Share it privately with this assistant.',
                ),
                const SizedBox(height: 12),
                SelectableText(result['code'] as String),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Clipboard.setData(
                ClipboardData(text: result['code'] as String),
              ),
              child: const Text('Copy code'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    });
    if (mounted) setState(() => busy = false);
  }

  Future<void> changeAccess(
    Map<String, dynamic> member, {
    required bool active,
    required bool clinical,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          active ? 'Change assistant access?' : 'Revoke assistant access?',
        ),
        content: Text(
          '${member['email']}\n\nServer permissions change immediately. Disconnected devices cannot receive revocation until they reconnect; offline access controls still require release validation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => busy = true);
    final repo = ref.read(repositoryProvider);
    await runAction(context, () async {
      await repo.administration.setStaffAccess(
        repo.session.clinicId,
        member['user_id'] as String,
        active,
        clinical,
      );
      await load();
    });
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(repositoryProvider).session;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinic team'),
        actions: [
          IconButton(
            tooltip: 'Refresh team',
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: !session.isAdmin || session.isDemo
          ? const EmptyPanel(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Online administrator access required',
              message:
                  'Sign into a real development clinic as its doctor administrator to invite staff. Preview mode never issues invitations.',
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SectionCard(
                  title: 'Invite an assistant',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Each staff member uses their own account. A clinic name is not an access code.',
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Assistant email',
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Allow clinical history access'),
                        subtitle: const Text(
                          'Read visits and prescriptions. Assistants cannot author clinical records.',
                        ),
                        value: clinicalRead,
                        onChanged: busy
                            ? null
                            : (v) => setState(() => clinicalRead = v),
                      ),
                      FilledButton.icon(
                        onPressed: busy ? null : invite,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Create private invitation'),
                      ),
                    ],
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(error!),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Team members',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final member in members)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member['email'] as String? ?? 'Clinic member',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${member['role']} · ${member['active'] == true ? 'Active' : 'Access revoked'}',
                          ),
                          if (member['role'] == 'assistant') ...[
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Clinical read access'),
                              value: member['clinical_read'] == true,
                              onChanged: busy
                                  ? null
                                  : (v) => changeAccess(
                                      member,
                                      active: member['active'] == true,
                                      clinical: v,
                                    ),
                            ),
                            TextButton(
                              onPressed: busy
                                  ? null
                                  : () => changeAccess(
                                      member,
                                      active: member['active'] != true,
                                      clinical: member['clinical_read'] == true,
                                    ),
                              child: Text(
                                member['active'] == true
                                    ? 'Revoke access'
                                    : 'Restore access',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
