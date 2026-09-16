import '../../presentation/language.dart';
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

/// Why a membership with [role] cannot be opened by [kind], or null when this
/// is the right app for it.
///
/// Both apps list every membership the signed-in account has, because hiding
/// the others would look like the clinic had disappeared. A doctor account
/// opened in the Assistant App therefore reaches this, and the row says which
/// app to use instead of the tap failing with nothing visible on screen.
String? clinicRoleMismatch(AppKind kind, String role) => switch (kind) {
  AppKind.doctor when role != ClinicRole.doctor.name =>
    'Use the Assistant App for this clinic role.',
  AppKind.assistant when role != ClinicRole.assistant.name =>
    'Use the Doctor App for this clinic role.',
  _ => null,
};

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

  /// Shows a failure both inline and as a snack bar.
  ///
  /// The inline notice alone sat below the clinic list, the invitation field
  /// and four buttons, so on a phone the reason a clinic refused to open was
  /// off-screen and the tap looked like it had done nothing at all.
  void report(String text) {
    if (!mounted) return;
    final translated = tr(text);
    setState(() => message = translated);
    ScaffoldMessenger.maybeOf(context)
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(translated),
          duration: const Duration(seconds: 8),
        ),
      );
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
      report(authFailureMessage);
    } on PostgrestException catch (e) {
      report(
        e.code == 'PGRST205' || e.code == 'PGRST202'
            ? 'The clinic access service is unavailable or incompatible. Contact the administrator.'
            : 'Clinic access could not be verified. Contact the administrator.',
      );
    } catch (e) {
      report(safeError(e));
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
          message = tr(
            'Connection unavailable. Saved access can open this clinic until {0}. Shared queue actions, amendments, and remote documents still require a connection.',
            [DateFormat('d MMM, HH:mm').format(saved.expiresAt.toLocal())],
          );
        });
      }
    }
  }

  Future<void> selectClinic(Map<String, dynamic> row) async {
    final mismatch = clinicRoleMismatch(widget.kind, row['role'] as String);
    if (mismatch != null) throw ClinicFailure('forbidden', mismatch);
    final user = widget.client.auth.currentUser!,
        role = ClinicRole.values.byName(row['role'] as String);
    // Ordered so an assistant binds to the same doctor on every device and
    // every sign-in. An unordered read picked an arbitrary row, which changed
    // which doctor's queue and presence the assistant saw.
    final doctors = await widget.client
        .from('clinic_memberships')
        .select('user_id,created_at')
        .eq('clinic_id', row['clinic_id'])
        .eq('role', 'doctor')
        .eq('active', true)
        .order('created_at')
        .order('user_id');
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
        () => message = tr(
          revokedEverywhere
              ? 'Password updated. Sign in with your new password.'
              : 'Password updated and this device was signed out. Other device sessions could not be revoked; contact the clinic administrator.',
        ),
      );
    }
  });

  Widget clinicTile(Map<String, dynamic> row) {
    final role = row['role'] as String;
    final mismatch = clinicRoleMismatch(widget.kind, role);
    return Card(
      child: ListTile(
        enabled: mismatch == null,
        title: Text((row['clinics'] as Map)['name'] as String),
        subtitle: Text(tr(mismatch ?? role)),
        trailing: Icon(
          mismatch == null
              ? Icons.chevron_right
              : Icons.phonelink_off_outlined,
        ),
        onTap: busy || mismatch != null
            ? null
            : () => act(() => selectClinic(row)),
      ),
    );
  }

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
                const LanguagePicker(),
                const SizedBox(height: 20),
                Icon(
                  Icons.health_and_safety_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  tr(
                    widget.kind == AppKind.doctor
                        ? 'Clinic Doctor'
                        : 'Clinic Assistant',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  tr('Your clinic. One connected patient record.'),
                  textAlign: TextAlign.center,
                ),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(message!, textAlign: TextAlign.center),
                      ),
                    ),
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
                    decoration: InputDecoration(labelText: tr('Email')),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(labelText: tr('Password')),
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
                                  () => message = tr(
                                    'Check your email to verify your account, then sign in.',
                                  ),
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
                      tr(
                        busy
                            ? 'Please wait…'
                            : register
                            ? 'Create account'
                            : 'Sign in',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() => register = !register),
                    child: Text(
                      tr(
                        register
                            ? 'Already registered? Sign in'
                            : 'Create an account',
                      ),
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
                                  () => message = tr(
                                    'If registered, recovery instructions will be sent.',
                                  ),
                                );
                              }
                            },
                            authFailureMessage:
                                'Password recovery could not be requested. Check the address and try again.',
                          ),
                    child: Text(tr('Forgot password?')),
                  ),
                ] else ...[
                  Text(
                    tr('Choose your clinic'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  for (final row in memberships) clinicTile(row),
                  if (offlineLease != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.offline_bolt_outlined),
                        title: Text(offlineLease!.session.clinicName),
                        subtitle: Text(
                          tr("Saved offline access · expires {0}", [
                            DateFormat(
                              'd MMM, HH:mm',
                            ).format(offlineLease!.expiresAt.toLocal()),
                          ]),
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
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        tr(
                          'No clinic membership yet. Create your clinic or enter an invitation from the doctor.',
                        ),
                      ),
                    ),
                  if (widget.kind == AppKind.doctor) ...[
                    const SizedBox(height: 20),
                    TextField(
                      controller: clinicName,
                      decoration: InputDecoration(
                        labelText: tr('New clinic name'),
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
                      child: Text(tr('Create private clinic')),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextField(
                    controller: invitation,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: tr('Doctor’s invitation code'),
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
                    child: Text(tr('Join private clinic')),
                  ),
                  TextButton(
                    onPressed: busy ? null : () => act(loadClinicsForEntry),
                    child: Text(tr('Refresh clinic access')),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => act(() async {
                            await widget.accessLease.clear();
                            await widget.client.auth.signOut();
                            memberships = [];
                          }),
                    child: Text(tr('Sign out')),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  tr('Development only · Use fictional patient data.'),
                  textAlign: TextAlign.center,
                ),
                if (widget.onDemo != null)
                  TextButton(
                    onPressed: busy ? null : widget.onDemo,
                    child: Text(tr('Open fictional local preview')),
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
        tr('Choose a new password'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      Text(
        tr(
          'This recovery link is single-purpose. After the password changes, sign in again.',
        ),
      ),
      const SizedBox(height: 20),
      TextField(
        key: const Key('recovery-password'),
        controller: password,
        obscureText: true,
        autofillHints: const [AutofillHints.newPassword],
        decoration: InputDecoration(labelText: tr('New password')),
      ),
      const SizedBox(height: 16),
      TextField(
        key: const Key('recovery-confirmation'),
        controller: confirmation,
        obscureText: true,
        autofillHints: const [AutofillHints.newPassword],
        onSubmitted: widget.busy ? null : (_) => submit(),
        decoration: InputDecoration(labelText: tr('Confirm new password')),
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            tr(error!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: widget.busy ? null : submit,
        child: Text(tr(widget.busy ? 'Updating…' : 'Update password')),
      ),
    ],
  );
}
