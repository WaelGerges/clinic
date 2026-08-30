import 'dart:typed_data';

import '../domain/models.dart';

class PendingCommand {
  const PendingCommand({
    required this.operationId,
    required this.clinicId,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payload,
    required this.expectedVersion,
  });
  final String operationId, clinicId, entityType, entityId, action;
  final Map<String, dynamic> payload;
  final int expectedVersion;
}

class CommandReceipt {
  const CommandReceipt(this.entity, this.version, {this.appointment});
  final Map<String, dynamic> entity;
  final int version;
  final Map<String, dynamic>? appointment;
}

class SyncConflict extends ClinicFailure {
  const SyncConflict(this.remote)
    : super(
        'conflict',
        'This record changed on another device. Both versions are retained for review.',
      );
  final Map<String, dynamic> remote;
}

abstract interface class ClinicGateway {
  Future<void> verifySession(ClinicSession session);
  Future<CommandReceipt> apply(PendingCommand command);
  Future<List<Patient>> patients({
    required String clinicId,
    String search = '',
    int offset = 0,
    bool archived = false,
  });
  Future<List<Patient>> patientsByIds(String clinicId, List<String> ids);
  Future<List<Appointment>> appointmentsByIds(
    String clinicId,
    List<String> ids,
  );
  Future<Appointment?> activeAppointment(String clinicId, String doctorId);
  Future<List<Appointment>> appointments(
    String clinicId,
    DateTime from,
    DateTime to,
  );
  Future<List<Visit>> visits(
    String clinicId,
    String patientId, {
    int offset = 0,
  });
  Stream<void> changes(String clinicId);
}

abstract interface class ClinicAdministration {
  Future<Map<String, dynamic>> inviteAssistant(
    String clinicId,
    String email,
    bool clinicalRead,
  );
  Future<List<Map<String, dynamic>>> staff(String clinicId);
  Future<void> setStaffAccess(
    String clinicId,
    String userId,
    bool active,
    bool clinicalRead,
  );
}

/// This explicit allowlist is the mobile privacy boundary for audit history.
/// Clinical before/after payloads are intentionally never selected.
const clinicAuditSafeColumns =
    'id,clinic_id,actor_id,actor_role,action,object_type,object_id,occurred_at';

abstract interface class ClinicAuditGateway {
  Future<List<ClinicAuditEvent>> auditEvents(
    String clinicId, {
    int offset = 0,
    int limit = 25,
  });
}

abstract interface class ClinicDeliveryGateway {
  Future<DoctorDeliveryState> doctorHeartbeat(String clinicId, String deviceId);
  Future<DoctorDeliveryState> doctorDeliveryState(
    String clinicId,
    String doctorId, {
    String? appointmentId,
  });
  Future<DoctorDeliveryState> acknowledgeAppointment(
    String clinicId,
    String appointmentId,
    String deviceId,
    String operationId,
    int expectedVersion,
  );
}

abstract interface class ClinicDocumentGateway {
  Future<ClinicDocument> beginDocument(ClinicDocument document);
  Future<ClinicDocument> finalizeDocument(String id);
  Future<void> failDocument(String id);
  Future<List<ClinicDocument>> documents(
    String clinicId,
    String patientId, {
    int offset = 0,
  });
  Future<Map<String, dynamic>> authorizeDocument(String id, String purpose);
  Future<void> uploadDocument(
    String objectPath,
    Uint8List bytes,
    String contentType,
  );
  Future<Uint8List> downloadDocument(String objectPath);
  Future<ClinicDocument> setDocumentArchived(String id, bool archived);
}
