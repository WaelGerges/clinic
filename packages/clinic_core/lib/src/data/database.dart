import 'dart:io';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/models.dart';

part 'database.g.dart';

@DriftDatabase(include: {'cache.drift'})
class ClinicDatabase extends _$ClinicDatabase {
  ClinicDatabase(super.executor);
  factory ClinicDatabase.memory() => ClinicDatabase(NativeDatabase.memory());
  factory ClinicDatabase.encrypted(File file, String encryptionKey) {
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(encryptionKey)) {
      throw const ClinicFailure(
        'cache_locked',
        'Invalid local encryption key.',
      );
    }
    return ClinicDatabase(
      NativeDatabase.createInBackground(
        file,
        setup: (db) {
          // Fail closed in release builds too; an assert is not sufficient.
          if (db.select('PRAGMA cipher').isEmpty) {
            throw StateError(
              'Encrypted SQLite is unavailable. Refusing to open medical data.',
            );
          }
          db.execute("PRAGMA key = '$encryptionKey'");
          db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
  }
  @override
  int get schemaVersion => 5;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 5) {
        await m.addColumn(
          cachedAppointments,
          cachedAppointments.durationMinutes,
        );
      }
      if (from < 2) {
        await m.createTable(syncResolutions);
        await customStatement(
          'CREATE INDEX sync_resolution_clinic_idx ON sync_resolutions(clinic_id, resolved_at)',
        );
      }
      if (from < 3) {
        await m.createTable(cachedDocuments);
        await m.createTable(documentBlobs);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS cached_document_patient_idx ON cached_documents(clinic_id, patient_id, created_at, id)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS cached_document_visit_idx ON cached_documents(clinic_id, visit_id, created_at, id)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS document_blob_state_idx ON document_blobs(clinic_id, user_id, transfer_state, created_at)',
        );
      }
      if (from < 4) {
        await m.addColumn(cachedVisits, cachedVisits.currentRevision);
        await customStatement(
          'UPDATE cached_visits SET current_revision=CASE WHEN completed=1 THEN max(version-1,1) ELSE version END',
        );
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

Future<ClinicDatabase> openProtectedCache(ClinicSession session) async {
  if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(session.userId) ||
      !RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(session.clinicId)) {
    throw const ClinicFailure(
      'invalid_session',
      'Invalid cache identity. Sign in again.',
    );
  }
  const secure = FlutterSecureStorage();
  final directory = await getApplicationSupportDirectory();
  final identity = '${session.userId}_${session.clinicId}';
  final file = File(p.join(directory.path, 'clinic_$identity.sqlite'));
  final keyName = 'clinic_cache_key_$identity';
  var key = await secure.read(key: keyName);
  if (key == null && await file.exists()) {
    throw const ClinicFailure(
      'cache_locked',
      'The local database key is unavailable. Existing data was preserved. Contact support.',
    );
  }
  if (key == null) {
    final random = Random.secure();
    key = List.generate(
      32,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await secure.write(key: keyName, value: key);
  }
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(key)) {
    throw const ClinicFailure(
      'cache_locked',
      'The local encryption key is invalid. Data was preserved.',
    );
  }
  return ClinicDatabase.encrypted(file, key);
}
