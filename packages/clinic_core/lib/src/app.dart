import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/database.dart';
import 'data/access_lease.dart';
import 'data/device_presence.dart';
import 'data/demo.dart';
import 'data/repository.dart';
import 'data/supabase_gateway.dart';
import 'domain/models.dart';
import 'presentation/common.dart';
import 'features/auth/auth_screen.dart';
import 'features/workspace/workspace_screen.dart';
import 'features/patients/patient_screens.dart';
import 'features/visits/consultation_screen.dart';
import 'features/staff/staff_screen.dart';
import 'features/audit/audit_screen.dart';
import 'features/sync/patient_sync_screen.dart';

Future<void> launchClinicApp(AppKind kind) async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL'),
      key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  SupabaseClient? client;
  final passwordRecovery = PasswordRecoveryController();
  final accessLease = ClinicAccessLeaseStore(
    projectRef: 'geikkygtnsgbtajyqdvc',
    kind: kind,
  );
  final doctorDeviceIdentity = DoctorDeviceIdentityStore(
    projectRef: 'geikkygtnsgbtajyqdvc',
  );
  String? error;
  if (url.isNotEmpty || key.isNotEmpty) {
    final uri = Uri.tryParse(url);
    if (uri?.scheme != 'https' ||
        uri?.host != 'geikkygtnsgbtajyqdvc.supabase.co' ||
        !key.startsWith('sb_publishable_')) {
      error =
          'Invalid development configuration. This build only permits clinic-chatgpt-dev with a publishable key.';
    } else {
      try {
        final initialization = Supabase.initialize(
          url: url,
          publishableKey: key,
          authOptions: FlutterAuthClientOptions(
            localStorage: const SecureSessionStorage('geikkygtnsgbtajyqdvc'),
            detectSessionInUriPredicate: (uri) =>
                isPasswordRecoveryCallback(kind, uri),
          ),
        );
        passwordRecovery.bind(Supabase.instance.client);
        await initialization;
        client = Supabase.instance.client;
      } catch (_) {
        error =
            'Secure sign-in could not initialize. Check the device’s secure storage.';
      }
    }
  }
  runApp(
    ClinicBootstrap(
      kind: kind,
      client: client,
      passwordRecovery: passwordRecovery,
      accessLease: accessLease,
      doctorDeviceIdentity: doctorDeviceIdentity,
      configurationError: error,
    ),
  );
}

class ClinicBootstrap extends StatefulWidget {
  const ClinicBootstrap({
    super.key,
    required this.kind,
    required this.passwordRecovery,
    required this.accessLease,
    required this.doctorDeviceIdentity,
    this.client,
    this.configurationError,
  });
  final AppKind kind;
  final PasswordRecoveryController passwordRecovery;
  final ClinicAccessLeaseStore accessLease;
  final DoctorDeviceIdentityStore doctorDeviceIdentity;
  final SupabaseClient? client;
  final String? configurationError;
  @override
  State<ClinicBootstrap> createState() => _ClinicBootstrapState();
}

class _ClinicBootstrapState extends State<ClinicBootstrap> {
  ClinicRepository? repository;
  Timer? accessTimer;
  bool busy = false;
  @override
  void dispose() {
    unawaited(repository?.close());
    accessTimer?.cancel();
    widget.passwordRecovery.dispose();
    super.dispose();
  }

  Future<void> open(ClinicSession session) async {
    if (!session.isDemo &&
        (session.accessExpiresAt == null ||
            !DateTime.now().toUtc().isBefore(
              session.accessExpiresAt!.toUtc(),
            ))) {
      throw const ClinicFailure(
        'offline_access_expired',
        'Reconnect to verify clinic access before opening saved records.',
      );
    }
    String? deviceId;
    if (session.isDoctor) {
      try {
        deviceId = await widget.doctorDeviceIdentity.readOrCreate();
      } catch (_) {
        // The clinic may still open, but delivery presence and acknowledgement
        // stay unavailable until protected device identity storage recovers.
      }
    }
    final next = ClinicRepository(
      db: await openProtectedCache(session),
      session: session,
      gateway: SupabaseClinicGateway(
        widget.client!,
        onSessionVerified: renewAccess,
      ),
      deviceId: deviceId,
      onAccessRevoked: () {
        if (mounted) unawaited(logout());
      },
    );
    await repository?.close();
    if (!mounted) {
      await next.close();
      return;
    }
    setState(() => repository = next);
    scheduleAccessExpiry(session);
    unawaited(
      next.startSync().catchError((Object _) => next.reportConnectionFailure()),
    );
    unawaited(
      next.refresh().catchError((Object _) => next.reportConnectionFailure()),
    );
  }

  Future<void> renewAccess(ClinicSession session) async {
    final lease = await widget.accessLease.issue(session);
    if (mounted &&
        repository?.session.userId == session.userId &&
        repository?.session.clinicId == session.clinicId) {
      scheduleAccessExpiry(lease.session);
    }
  }

  void scheduleAccessExpiry(ClinicSession session) {
    accessTimer?.cancel();
    if (session.isDemo || session.accessExpiresAt == null) return;
    final remaining = session.accessExpiresAt!.toUtc().difference(
      DateTime.now().toUtc(),
    );
    if (remaining <= Duration.zero) {
      unawaited(expireAccess());
      return;
    }
    accessTimer = Timer(remaining, () => unawaited(expireAccess()));
  }

  Future<void> expireAccess() async {
    accessTimer?.cancel();
    await widget.accessLease.clear();
    final old = repository;
    await old?.close();
    if (mounted && identical(repository, old)) {
      setState(() => repository = null);
    }
  }

  Future<void> demo() async {
    setState(() => busy = true);
    try {
      final next = await createDemoRepository(widget.kind);
      if (!mounted) {
        await next.close();
        return;
      }
      setState(() => repository = next);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> logout() async {
    accessTimer?.cancel();
    await widget.accessLease.clear();
    final old = repository;
    await old?.close();
    if (mounted) setState(() => repository = null);
    if (old?.session.isDemo != true) await widget.client?.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (repository != null) {
      return ClinicApp(
        kind: widget.kind,
        repository: repository!,
        onLogout: logout,
      );
    }
    return MaterialApp(
      title: widget.kind == AppKind.doctor
          ? 'Clinic Doctor'
          : 'Clinic Assistant',
      debugShowCheckedModeBanner: false,
      theme: clinicTheme(Brightness.light),
      darkTheme: clinicTheme(Brightness.dark),
      home: widget.client != null
          ? AuthScreen(
              kind: widget.kind,
              client: widget.client!,
              passwordRecovery: widget.passwordRecovery,
              accessLease: widget.accessLease,
              onSession: open,
              onDemo: kDebugMode ? demo : null,
            )
          : Scaffold(
              body: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: EmptyPanel(
                      icon: Icons.health_and_safety_outlined,
                      title: widget.kind == AppKind.doctor
                          ? 'Clinic Doctor'
                          : 'Clinic Assistant',
                      message:
                          widget.configurationError ??
                          'This build has no Supabase development configuration. Connect it to clinic-chatgpt-dev or use the protected fictional local preview.',
                      action: kDebugMode
                          ? FilledButton(
                              onPressed: busy ? null : demo,
                              child: Text(
                                busy
                                    ? 'Opening…'
                                    : 'Open fictional local preview',
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class ClinicApp extends StatefulWidget {
  const ClinicApp({
    super.key,
    required this.kind,
    required this.repository,
    this.onLogout,
  });
  final AppKind kind;
  final ClinicRepository repository;
  final Future<void> Function()? onLogout;
  @override
  State<ClinicApp> createState() => _ClinicAppState();
}

class _ClinicAppState extends State<ClinicApp> with WidgetsBindingObserver {
  ThemeMode mode = ThemeMode.system;
  Timer? presenceTimer;
  late final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/sync/history',
        builder: (context, state) => const PatientRecoveryHistoryScreen(),
      ),
      GoRoute(
        path: '/sync/patients/:operation',
        builder: (context, state) => PatientSyncReviewScreen(
          operationId: state.pathParameters['operation']!,
        ),
      ),
      GoRoute(path: '/staff', builder: (context, state) => const StaffScreen()),
      GoRoute(path: '/audit', builder: (context, state) => const AuditScreen()),
      GoRoute(
        path: '/',
        builder: (context, state) => WorkspaceScreen(
          kind: widget.kind,
          mode: mode,
          onTheme: (value) => setState(() => mode = value),
          onLogout: widget.onLogout,
        ),
      ),
      GoRoute(
        path: '/patients/new',
        builder: (context, state) => const PatientFormScreen(),
      ),
      GoRoute(
        path: '/patients/:id',
        builder: (context, state) =>
            PatientProfileScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/patients/:id/edit',
        builder: (context, state) =>
            PatientFormScreen(id: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/consultation/:appointment',
        builder: (context, state) => ConsultationScreen(
          appointmentId: state.pathParameters['appointment']!,
        ),
      ),
      GoRoute(
        path: '/patients/:patient/visits/:visit/amend',
        builder: (context, state) => ConsultationScreen.amendment(
          patientId: state.pathParameters['patient']!,
          visitId: state.pathParameters['visit']!,
        ),
      ),
    ],
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    startPresence();
  }

  void startPresence() {
    presenceTimer?.cancel();
    final repository = widget.repository;
    if (!repository.session.isDoctor ||
        repository.session.isDemo ||
        repository.deviceId == null) {
      return;
    }
    unawaited(repository.renewDoctorPresence().catchError((Object _) {}));
    presenceTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(repository.renewDoctorPresence().catchError((Object _) {}));
    });
  }

  @override
  void dispose() {
    presenceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    router.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      startPresence();
      unawaited(widget.repository.synchronize());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      presenceTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [repositoryProvider.overrideWithValue(widget.repository)],
    child: MaterialApp.router(
      title: widget.kind == AppKind.doctor
          ? 'Clinic Doctor'
          : 'Clinic Assistant',
      debugShowCheckedModeBanner: false,
      theme: clinicTheme(Brightness.light),
      darkTheme: clinicTheme(Brightness.dark),
      themeMode: mode,
      routerConfig: router,
    ),
  );
}
