import 'package:uuid/uuid.dart';

import 'access_lease.dart';

class DoctorDeviceIdentityStore {
  DoctorDeviceIdentityStore({
    required this.projectRef,
    ClinicSecureValueStore? storage,
  }) : storage = storage ?? const FlutterClinicSecureValueStore();

  final String projectRef;
  final ClinicSecureValueStore storage;
  static const _uuid = Uuid();

  String get _key => 'clinic_doctor_device_$projectRef';

  Future<String> readOrCreate() async {
    final current = (await storage.read(_key))?.trim();
    if (current != null && _canonicalUuid.hasMatch(current)) return current;
    final created = _uuid.v4();
    await storage.write(_key, created);
    return created;
  }

  static final _canonicalUuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
}
