import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' show ClientException;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/access_lease.dart';
import '../../domain/models.dart';
import '../../presentation/common.dart';

String authRedirect(AppKind kind) => switch (kind) {
  AppKind.assistant => 'dev.homeversion.clinic.assistant://auth-callback/',
  AppKind.doctor => 'dev.homeversion.clinic.doctor://auth-callback/',
};

bool isPasswordRecoveryCallback(AppKind kind, Uri uri) {
  bool hasAuthParameter(String name) {
    if (uri.queryParameters.containsKey(name)) return true;
    try {
      return Uri.splitQueryString(uri.fragment).containsKey(name);
    } on FormatException {
      return false;
    }
  }

  final hasAuthParameters = const [
    'access_token',
    'code',
    'error',
    'error_code',
    'error_description',
  ].any(hasAuthParameter);
  if (!hasAuthParameters) return false;
  if (kIsWeb) return true;
  final expected = Uri.parse(authRedirect(kind));
  return uri.scheme == expected.scheme &&
      uri.host == expected.host &&
      uri.path == expected.path;
}

class PasswordRecoveryController extends ChangeNotifier {
  StreamSubscription<AuthState>? _subscription;
  bool _active = false;

  bool get active => _active;

  void bind(SupabaseClient client) {
    unawaited(_subscription?.cancel());
    _subscription = client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery && !_active) {
        _active = true;
        notifyListeners();
      }
    });
  }

  void complete() {
    if (!_active) return;
    _active = false;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.kind,
    required this.client,
    required this.passwordRecovery,
    required this.accessLease,
    required this.onSession,
    this.onDemo,
  });
  final AppKind kind;
  final SupabaseClient client;
  final PasswordRecoveryController passwordRecovery;
  final ClinicAccessLeaseStore accessLease;
  final Future<void> Function(ClinicSession) onSession;
  final Future<void> Function()? onDemo;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController(),
      password = TextEditingController(),
      clinicName = TextEditingController();
  final invitation = TextEditingController();
  bool busy = false, register = false;
  String? message;
  List<Map<String, dynamic>> memberships = [];
  ClinicAccessLease? offlineLease;
  bool get signedIn => widget.client.auth.currentUser != null;
  @override
  void initState() {
    super.initState();
    widget.passwordRecovery.addListener(onPasswordRecoveryChanged);
    if (signedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        act(loadClinicsForEntry);
      });
    }
  }

  @override
  void dispose() {
    widget.passwordRecovery.removeListener(onPasswordRecoveryChanged);
    email.dispose();
    password.dispose();
    clinicName.dispose();
    invitation.dispose();
    super.dispose();
  }

  void onPasswordRecoveryChanged() {
    if (!mounted) return;
    if (widget.passwordRecovery.active) memberships = [];
    setState(() {});
  }

  Future<void> act(
    Future<void> Function() operation, {
    String authFailureMessage =
        'Sign-in failed. Check your credentials and email verification.',
  }) async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await operation();
    } on AuthException {
      if (mounted) {
        setState(() => message = authFailureMessage);
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(
          () => message = e.code == 'PGRST205' || e.code == 'PGRST202'
              ? 'The clinic access service is unavailable or incompatible. Contact the administrator.'
              : 'Clinic access could not be verified. Contact the administrator.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => message = safeError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> loadClinics() async {
    final user = widget.client.auth.currentUser;
    if (user == null) return;
    final rows = await widget.client
        .from('clinic_memberships')
        .select('clinic_id,user_id,role,is_admin,clinical_read,clinics(name)')
        .eq('user_id', user.id)
        .eq('active', true);
    final saved = await widget.accessLease.readValid(user.id);
    if (saved != null) {
      final stillAuthorized = rows.any(
        (row) =>
            row['clinic_id'] == saved.session.clinicId &&
            row['role'] == saved.session.role.name &&
            row['is_admin'] == saved.session.isAdmin &&
            row['clinical_read'] == saved.session.canReadClinical,
      );
      if (!stillAuthorized) await widget.accessLease.clear();
    }
    if (mounted) {
      setState(() {
        memberships = rows;
        offlineLease = null;
      });
    }
  }

  Future<void> loadClinicsForEntry() async {
    try {
      await loadClinics();
    } catch (error) {
      final networkFailure =
          error is SocketException ||
          error is TimeoutException ||
          error is ClientException;
      if (!networkFailure) rethrow;
      final user = widget.client.auth.currentUser;
      final saved = user == null
          ? null
          : await widget.accessLease.readValid(user.id);
      if (saved == null) {
        throw const ClinicFailure(
          'offline_access_unavailable',
          'Connection unavailable and there is no recent verified clinic access on this device.',
        );
      }
      if (mounted) {
        setState(() {
          memberships = [];
          offlineLease = saved;
          message =
              'Connection unavailable. Saved access can open this clinic until ${DateFormat('d MMM, HH:mm').format(saved.expiresAt.toLocal())}. Shared queue actions, amendments, and remote documents still require a connection.';
        });
      }
    }
  }

  Future<void> selectClinic(Map<String, dynamic> row) async {
    final user = widget.client.auth.currentUser!,
        role = ClinicRole.values.byName(row['role'] as String);
    if (widget.kind == AppKind.doctor && role != ClinicRole.doctor) {
      throw const ClinicFailure(
        'forbidden',
        'Use the Assistant App for this clinic role.',
      );
    }
    if (widget.kind == AppKind.assistant && role != ClinicRole.assistant) {
      throw const ClinicFailure(
        'forbidden',
        'Use the Doctor App for this clinic role.',
      );
    }
    final doctors = await widget.client
        .from('clinic_memberships')
        .select('user_id')
        .eq('clinic_id', row['clinic_id'])
        .eq('role', 'doctor')
        .eq('active', true);
    if (doctors.isEmpty) {
      throw const ClinicFailure(
        'no_doctor',
        'No active doctor is configured for this clinic.',
      );
    }
    final lease = await widget.accessLease.issue(
      ClinicSession(
        userId: user.id,
        clinicId: row['clinic_id'] as String,
        clinicName: (row['clinics'] as Map)['name'] as String,
        role: role,
        doctorId: role == ClinicRole.doctor
            ? user.id
            : doctors.first['user_id'] as String,
        canReadClinical: row['clinical_read'] == true,
        isAdmin: row['is_admin'] == true,
      ),
    );
    await widget.onSession(lease.session);
  }

  Future<void> updateRecoveredPassword(String nextPassword) => act(() async {
    try {
      await widget.client.auth.updateUser(
        UserAttributes(password: nextPassword),
      );
    } on AuthException {
      throw const ClinicFailure(
        'password_recovery_failed',
        'The recovery link is invalid or expired. Request a new link and try again.',
      );
    }
    var revokedEverywhere = true;
    try {
      await widget.client.auth.signOut(scope: SignOutScope.global);
    } catch (_) {
      revokedEverywhere = false;
      await widget.client.auth.signOut(scope: SignOutScope.local);
    }
    widget.passwordRecovery.complete();
    await widget.accessLease.clear();
    if (mounted) {
      setState(
        () => message = revokedEverywhere
            ? 'Password updated. Sign in with your new password.'
            : 'Password updated and this device was signed out. Other device sessions could not be revoked; contact the clinic administrator.',
      );
    }
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.health_and_safety_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  widget.kind == AppKind.doctor
                      ? 'Clinic Doctor'
                      : 'Clinic Assistant',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your clinic. One connected patient record.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                if (widget.passwordRecovery.active)
                  PasswordRecoveryPanel(
                    busy: busy,
                    onSubmit: updateRecoveredPassword,
                  )
                else if (!signedIn) ...[
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () => act(() async {
                            if (register) {
                              if (password.text.length < 12 ||
                                  password.text.length > 72) {
                                throw const ClinicFailure(
                                  'validation',
                                  'Use a password between 12 and 72 characters.',
                                );
                              }
                              await widget.client.auth.signUp(
                                email: email.text.trim(),
                                password: password.text,
                                emailRedirectTo: kIsWeb
                                    ? null
                                    : authRedirect(widget.kind),
                              );
                              if (mounted) {
                                setState(
                                  () => message =
                                      'Check your email to verify your account, then sign in.',
                                );
                              }
                            } else {
                              await widget.client.auth.signInWithPassword(
                                email: email.text.trim(),
                                password: password.text,
                              );
                              await loadClinics();
                            }
                            password.clear();
                          }),
                    child: Text(
                      busy
                          ? 'Please wait…'
                          : register
                          ? 'Create account'
                          : 'Sign in',
                    ),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() => register = !register),
                    child: Text(
                      register
                          ? 'Already registered? Sign in'
                          : 'Create an account',
                    ),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => act(
                            () async {
                              if (!email.text.contains('@')) {
                                throw const ClinicFailure(
                                  'validation',
                                  'Enter your email first.',
                                );
                              }
                              await widget.client.auth.resetPasswordForEmail(
                                email.text.trim(),
                                redirectTo: kIsWeb
                                    ? null
                                    : authRedirect(widget.kind),
                              );
                              if (mounted) {
                                setState(
                                  () => message =
                                      'If registered, recovery instructions will be sent.',
                                );
                              }
                            },
                            authFailureMessage:
                                'Password recovery could not be requested. Check the address and try again.',
                          ),
                    child: const Text('Forgot password?'),
                  ),
                ] else ...[
                  Text(
                    'Choose your clinic',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  for (final row in memberships)
                    Card(
                      child: ListTile(
                        title: Text((row['clinics'] as Map)['name'] as String),
                        subtitle: Text(row['role'] as String),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: busy ? null : () => act(() => selectClinic(row)),
                      ),
                    ),
                  if (offlineLease != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.offline_bolt_outlined),
                        title: Text(offlineLease!.session.clinicName),
                        subtitle: Text(
                          'Saved offline access · expires ${DateFormat('d MMM, HH:mm').format(offlineLease!.expiresAt.toLocal())}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: busy
                            ? null
                            : () => act(
                                () => widget.onSession(offlineLease!.session),
                              ),
                      ),
                    ),
                  if (memberships.isEmpty && offlineLease == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No clinic membership yet. Create your clinic or enter an invitation from the doctor.',
                      ),
                    ),
                  if (widget.kind == AppKind.doctor) ...[
                    const SizedBox(height: 20),
                    TextField(
                      controller: clinicName,
                      decoration: const InputDecoration(
                        labelText: 'New clinic name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: busy
                          ? null
                          : () => act(() async {
                              await widget.client.rpc(
                                'clinic_create',
                                params: {'p_name': clinicName.text.trim()},
                              );
                              await loadClinics();
                            }),
                      child: const Text('Create private clinic'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextField(
                    controller: invitation,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Doctor’s invitation code',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => act(() async {
                            await widget.client.rpc(
                              'clinic_join',
                              params: {'p_code': invitation.text.trim()},
                            );
                            invitation.clear();
                            await loadClinics();
                          }),
                    child: const Text('Join private clinic'),
                  ),
                  TextButton(
                    onPressed: busy ? null : () => act(loadClinicsForEntry),
                    child: const Text('Refresh clinic access'),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => act(() async {
                            await widget.accessLease.clear();
                            await widget.client.auth.signOut();
                            memberships = [];
                          }),
                    child: const Text('Sign out'),
                  ),
                ],
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(message!, textAlign: TextAlign.center),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Development only · Use fictional patient data.',
                  textAlign: TextAlign.center,
                ),
                if (widget.onDemo != null)
                  TextButton(
                    onPressed: busy ? null : widget.onDemo,
                    child: const Text('Open fictional local preview'),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class PasswordRecoveryPanel extends StatefulWidget {
  const PasswordRecoveryPanel({
    super.key,
    required this.busy,
    required this.onSubmit,
  });

  final bool busy;
  final Future<void> Function(String password) onSubmit;

  @override
  State<PasswordRecoveryPanel> createState() => _PasswordRecoveryPanelState();
}

class _PasswordRecoveryPanelState extends State<PasswordRecoveryPanel> {
  final password = TextEditingController();
  final confirmation = TextEditingController();
  String? error;

  @override
  void dispose() {
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final value = password.text;
    String? nextError;
    if (value.length < 12 || value.length > 72) {
      nextError = 'Use a password between 12 and 72 characters.';
    } else if (value != confirmation.text) {
      nextError = 'The passwords do not match.';
    }
    setState(() => error = nextError);
    if (nextError != null) return;
    await widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Choose a new password',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      const Text(
        'This recovery link is single-purpose. After the password changes, sign in again.',
      ),
      const SizedBox(height: 20),
      TextField(
        key: const Key('recovery-password'),
        controller: password,
        obscureText: true,
        autofillHints: const [AutofillHints.newPassword],
        decoration: const InputDecoration(labelText: 'New password'),
      ),
      const SizedBox(height: 16),
      TextField(
        key: const Key('recovery-confirmation'),
        controller: confirmation,
        obscureText: true,
        autofillHints: const [AutofillHints.newPassword],
        onSubmitted: widget.busy ? null : (_) => submit(),
        decoration: const InputDecoration(labelText: 'Confirm new password'),
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: widget.busy ? null : submit,
        child: Text(widget.busy ? 'Updating…' : 'Update password'),
      ),
    ],
  );
}
