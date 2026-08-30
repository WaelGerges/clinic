import '../domain/models.dart';

/// A review of a rejected save and all later, never-sent saves of this patient.
/// Repository checks the snapshot again before committing a resolution.
class PatientSyncReview {
  PatientSyncReview({
    required this.operationId,
    required this.local,
    required this.remote,
    required this.operationsSnapshot,
    required this.operationCount,
  });

  final String operationId, operationsSnapshot;
  final Patient local, remote;
  final int operationCount;
}

const patientMergeFields = <String, String>{
  'full_name': 'Full name',
  'gender': 'Gender',
  'birth_date': 'Date of birth',
  'mobile': 'Mobile',
  'secondary_mobile': 'Secondary mobile',
  'address': 'Address',
  'notes': 'General notes',
  'alerts': 'Medical alerts',
  'archived': 'Archived',
};

class PatientSyncResolution {
  const PatientSyncResolution({
    required this.id,
    required this.resolvedAt,
    required this.choice,
    required this.local,
    required this.remote,
    required this.resolved,
    required this.operationCount,
  });
  final String id, choice;
  final DateTime resolvedAt;
  final Patient local, remote, resolved;
  final int operationCount;
}
