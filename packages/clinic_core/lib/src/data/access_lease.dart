import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/models.dart';

const clinicOfflineAccessDuration = Duration(hours: 8);
const _clockRollbackTolerance = Duration(minutes: 5);

abstract interface class ClinicSecureValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterClinicSecureValueStore implements ClinicSecureValueStore {
  const FlutterClinicSecureValueStore();

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class ClinicAccessLease {
  const ClinicAccessLease({
    required this.session,
    required this.issuedAt,
    required this.expiresAt,
  });

  final ClinicSession session;
  final DateTime issuedAt, expiresAt;
}

class ClinicAccessLeaseStore {
  ClinicAccessLeaseStore({
    required this.projectRef,
    required this.kind,
    ClinicSecureValueStore? storage,
    DateTime Function()? clock,
    this.duration = clinicOfflineAccessDuration,
  }) : storage = storage ?? const FlutterClinicSecureValueStore(),
       clock = clock ?? DateTime.now;

  final String projectRef;
  final AppKind kind;
  final ClinicSecureValueStore storage;
  final DateTime Function() clock;
  final Duration duration;

  String get _key => 'clinic_access_lease_${projectRef}_${kind.name}';

  Future<ClinicAccessLease> issue(ClinicSession session) async {
    _validateSession(session);
    final issuedAt = clock().toUtc();
    final expiresAt = issuedAt.add(duration);
    final lease = ClinicAccessLease(
      session: session.copyWith(accessExpiresAt: expiresAt),
      issuedAt: issuedAt,
      expiresAt: expiresAt,
    );
    await storage.write(
      _key,
      jsonEncode({
        'version': 1,
        'project_ref': projectRef,
        'app_kind': kind.name,
        'user_id': session.userId,
        'clinic_id': session.clinicId,
        'clinic_name': session.clinicName,
        'role': session.role.name,
        'doctor_id': session.doctorId,
        'clinical_read': session.canReadClinical,
        'is_admin': session.isAdmin,
        'issued_at': issuedAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'last_seen_at': issuedAt.toIso8601String(),
      }),
    );
    return lease;
  }

  Future<ClinicAccessLease?> readValid(String userId) async {
    final encoded = await storage.read(_key);
    if (encoded == null) return null;
    try {
      final value = jsonDecode(encoded);
      if (value is! Map<String, dynamic> ||
          value['version'] != 1 ||
          value['project_ref'] != projectRef ||
          value['app_kind'] != kind.name ||
          value['user_id'] != userId) {
        await clear();
        return null;
      }
      final issuedAt = DateTime.parse(value['issued_at'] as String).toUtc();
      final expiresAt = DateTime.parse(value['expires_at'] as String).toUtc();
      final lastSeenAt = DateTime.parse(
        value['last_seen_at'] as String,
      ).toUtc();
      final now = clock().toUtc();
      final lifetime = expiresAt.difference(issuedAt);
      if (lifetime <= Duration.zero ||
          lifetime > duration ||
          lastSeenAt.isBefore(issuedAt) ||
          !lastSeenAt.isBefore(expiresAt) ||
          now.isBefore(issuedAt.subtract(_clockRollbackTolerance)) ||
          now.isBefore(lastSeenAt.subtract(_clockRollbackTolerance)) ||
          !now.isBefore(expiresAt)) {
        await clear();
        return null;
      }
      final role = ClinicRole.values.byName(value['role'] as String);
      final session = ClinicSession(
        userId: value['user_id'] as String,
        clinicId: value['clinic_id'] as String,
        clinicName: value['clinic_name'] as String,
        role: role,
        doctorId: value['doctor_id'] as String,
        canReadClinical: value['clinical_read'] as bool,
        isAdmin: value['is_admin'] as bool,
        accessExpiresAt: expiresAt,
      );
      _validateSession(session);
      value['last_seen_at'] = (now.isAfter(lastSeenAt) ? now : lastSeenAt)
          .toIso8601String();
      await storage.write(_key, jsonEncode(value));
      return ClinicAccessLease(
        session: session,
        issuedAt: issuedAt,
        expiresAt: expiresAt,
      );
    } on Object {
      await clear();
      return null;
    }
  }

  Future<void> clear() => storage.delete(_key);

  void _validateSession(ClinicSession session) {
    final id = RegExp(r'^[a-zA-Z0-9-]{1,128}$');
    final correctRole = switch (kind) {
      AppKind.assistant => session.role == ClinicRole.assistant,
      AppKind.doctor => session.role == ClinicRole.doctor,
    };
    if (session.isDemo ||
        !correctRole ||
        !id.hasMatch(session.userId) ||
        !id.hasMatch(session.clinicId) ||
        !id.hasMatch(session.doctorId) ||
        session.clinicName.trim().length < 2 ||
        session.clinicName.trim().length > 160 ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(session.clinicName)) {
      throw const ClinicFailure(
        'invalid_session',
        'The saved clinic access record is invalid. Reconnect and sign in again.',
      );
    }
  }
}
