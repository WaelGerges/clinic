import 'dart:typed_data';

enum AppKind { assistant, doctor }

enum ClinicRole { assistant, doctor }

enum AppointmentStatus {
  scheduled('Scheduled'),
  confirmed('Confirmed'),
  arrived('Arrived'),
  waiting('Waiting'),
  withDoctor('With Doctor'),
  completed('Completed'),
  cancelled('Cancelled'),
  noShow('No Show');

  const AppointmentStatus(this.label);
  final String label;
  bool get terminal => this == completed || this == cancelled || this == noShow;
}

class ClinicFailure implements Exception {
  const ClinicFailure(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => message;
}

class ClinicSession {
  const ClinicSession({
    required this.userId,
    required this.clinicId,
    required this.clinicName,
    required this.role,
    required this.doctorId,
    this.canReadClinical = false,
    this.isDemo = false,
    this.isAdmin = false,
    this.accessExpiresAt,
  });
  final String userId, clinicId, clinicName, doctorId;
  final ClinicRole role;
  final bool canReadClinical, isDemo, isAdmin;
  final DateTime? accessExpiresAt;
  bool get isDoctor => role == ClinicRole.doctor;
  bool get clinicalRead => isDoctor || canReadClinical;

  ClinicSession copyWith({DateTime? accessExpiresAt}) => ClinicSession(
    userId: userId,
    clinicId: clinicId,
    clinicName: clinicName,
    role: role,
    doctorId: doctorId,
    canReadClinical: canReadClinical,
    isDemo: isDemo,
    isAdmin: isAdmin,
    accessExpiresAt: accessExpiresAt ?? this.accessExpiresAt,
  );
}

class ClinicAuditEvent {
  const ClinicAuditEvent({
    required this.id,
    required this.clinicId,
    required this.actorId,
    required this.actorRole,
    required this.action,
    required this.objectType,
    required this.objectId,
    required this.occurredAt,
  });

  final int id;
  final String clinicId;
  final String actorId;
  final String actorRole;
  final String action;
  final String objectType;
  final String objectId;
  final DateTime occurredAt;

  factory ClinicAuditEvent.fromMap(Map<String, dynamic> value) {
    final id = value['id'];
    final occurredAt = DateTime.tryParse(value['occurred_at'] as String? ?? '');
    final strings = [
      value['clinic_id'],
      value['actor_id'],
      value['actor_role'],
      value['action'],
      value['object_type'],
      value['object_id'],
    ];
    if (id is! num ||
        occurredAt == null ||
        strings.any((item) => item is! String || item.trim().isEmpty)) {
      throw const FormatException('Invalid clinic audit event');
    }
    return ClinicAuditEvent(
      id: id.toInt(),
      clinicId: value['clinic_id'] as String,
      actorId: value['actor_id'] as String,
      actorRole: value['actor_role'] as String,
      action: value['action'] as String,
      objectType: value['object_type'] as String,
      objectId: value['object_id'] as String,
      occurredAt: occurredAt.toUtc(),
    );
  }
}

class DoctorDeliveryState {
  const DoctorDeliveryState({
    required this.serverNow,
    required this.doctorOnline,
    required this.serviceAvailable,
    this.presenceExpiresAt,
    this.acknowledgedAt,
    this.appointmentVersion,
  });

  final DateTime serverNow;
  final bool doctorOnline;
  final bool serviceAvailable;
  final DateTime? presenceExpiresAt;
  final DateTime? acknowledgedAt;
  final int? appointmentVersion;
  bool get acknowledged => acknowledgedAt != null;

  factory DoctorDeliveryState.fromMap(Map<String, dynamic> value) {
    final serverNow = DateTime.tryParse(value['server_now'] as String? ?? '');
    final online = value['doctor_online'];
    final presence = value['presence_expires_at'] == null
        ? null
        : DateTime.tryParse(value['presence_expires_at'] as String? ?? '');
    final acknowledged = value['acknowledged_at'] == null
        ? null
        : DateTime.tryParse(value['acknowledged_at'] as String? ?? '');
    final version = value['appointment_version'];
    if (serverNow == null ||
        online is! bool ||
        (value['presence_expires_at'] != null && presence == null) ||
        (value['acknowledged_at'] != null && acknowledged == null) ||
        (version != null && version is! num)) {
      throw const FormatException('Invalid doctor delivery state');
    }
    return DoctorDeliveryState(
      serverNow: serverNow.toUtc(),
      doctorOnline: online,
      serviceAvailable: true,
      presenceExpiresAt: presence?.toUtc(),
      acknowledgedAt: acknowledged?.toUtc(),
      appointmentVersion: (version as num?)?.toInt(),
    );
  }

  factory DoctorDeliveryState.unavailable(DateTime now) => DoctorDeliveryState(
    serverNow: now.toUtc(),
    doctorOnline: false,
    serviceAvailable: false,
  );
}

String compactAuditIdentifier(String value) {
  final normalized = value.trim();
  if (normalized.length <= 13) return normalized;
  return '${normalized.substring(0, 8)}…${normalized.substring(normalized.length - 4)}';
}

String normalizePhone(String value) {
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final converted = value.split('').map((c) {
    final a = eastern.indexOf(c);
    final b = persian.indexOf(c);
    return a >= 0
        ? '$a'
        : b >= 0
        ? '$b'
        : c;
  }).join();
  return converted.replaceAll(RegExp('[^0-9]'), '');
}

DateTime? parseBirthDate(String input) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(input)) return null;
  final date = DateTime.tryParse(input);
  if (date == null || date.toIso8601String().substring(0, 10) != input) {
    return null;
  }
  return DateTime.utc(date.year, date.month, date.day);
}

class Patient {
  const Patient({
    required this.id,
    required this.clinicId,
    required this.name,
    required this.gender,
    required this.birthDate,
    required this.mobile,
    required this.createdAt,
    required this.updatedAt,
    this.number = 'Pending ID',
    this.secondaryMobile = '',
    this.address = '',
    this.notes = '',
    this.alerts = '',
    this.archived = false,
    this.version = 0,
  });
  final String id, clinicId, name, gender, mobile, secondaryMobile;
  final String number, address, notes, alerts;
  final DateTime birthDate, createdAt, updatedAt;
  final bool archived;
  final int version;

  int ageAt(DateTime today) {
    var age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void validate(DateTime today) {
    if (name.trim().length < 2) {
      throw const ClinicFailure('validation', 'Enter the patient’s full name.');
    }
    if (birthDate.isAfter(DateTime.utc(today.year, today.month, today.day))) {
      throw const ClinicFailure(
        'validation',
        'Date of birth cannot be in the future.',
      );
    }
    if (normalizePhone(mobile).length < 7) {
      throw const ClinicFailure('validation', 'Enter a valid mobile number.');
    }
    if (!['Female', 'Male', 'Other', 'Not specified'].contains(gender)) {
      throw const ClinicFailure('validation', 'Choose a gender value.');
    }
  }

  Patient copyWith({
    String? name,
    String? gender,
    DateTime? birthDate,
    String? mobile,
    String? secondaryMobile,
    String? address,
    String? notes,
    String? alerts,
    bool? archived,
    DateTime? updatedAt,
    int? version,
    String? number,
  }) => Patient(
    id: id,
    clinicId: clinicId,
    name: name ?? this.name,
    gender: gender ?? this.gender,
    birthDate: birthDate ?? this.birthDate,
    mobile: mobile ?? this.mobile,
    secondaryMobile: secondaryMobile ?? this.secondaryMobile,
    address: address ?? this.address,
    notes: notes ?? this.notes,
    alerts: alerts ?? this.alerts,
    archived: archived ?? this.archived,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    number: number ?? this.number,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'clinic_id': clinicId,
    'full_name': name,
    'gender': gender,
    'birth_date': birthDate.toIso8601String().substring(0, 10),
    'mobile': mobile,
    'secondary_mobile': secondaryMobile,
    'patient_number': number,
    'address': address,
    'notes': notes,
    'alerts': alerts,
    'archived': archived,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'version': version,
  };

  factory Patient.fromMap(Map<String, dynamic> row) => Patient(
    id: row['id'] as String,
    clinicId: row['clinic_id'] as String,
    name: row['full_name'] as String,
    gender: row['gender'] as String,
    birthDate: DateTime.parse(row['birth_date'] as String),
    mobile: row['mobile'] as String,
    secondaryMobile: row['secondary_mobile'] as String? ?? '',
    number: row['patient_number']?.toString() ?? 'Pending ID',
    address: row['address'] as String? ?? '',
    notes: row['notes'] as String? ?? '',
    alerts: row['alerts'] as String? ?? '',
    archived: row['archived'] == true,
    createdAt: DateTime.parse(row['created_at'] as String),
    updatedAt: DateTime.parse(row['updated_at'] as String),
    version: (row['version'] as num?)?.toInt() ?? 0,
  );
}

class Appointment {
  const Appointment({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.doctorId,
    required this.startsAt,
    this.status = AppointmentStatus.scheduled,
    this.type = 'Consultation',
    this.notes = '',
    this.version = 0,
  });
  final String id, clinicId, patientId, doctorId, type, notes;
  final DateTime startsAt;
  final AppointmentStatus status;
  final int version;
  Appointment copyWith({
    AppointmentStatus? status,
    DateTime? startsAt,
    int? version,
  }) => Appointment(
    id: id,
    clinicId: clinicId,
    patientId: patientId,
    doctorId: doctorId,
    startsAt: startsAt ?? this.startsAt,
    status: status ?? this.status,
    type: type,
    notes: notes,
    version: version ?? this.version,
  );
  Map<String, Object?> toMap() => {
    'id': id,
    'clinic_id': clinicId,
    'patient_id': patientId,
    'doctor_id': doctorId,
    'starts_at': startsAt.toUtc().toIso8601String(),
    'status': status.name,
    'appointment_type': type,
    'notes': notes,
    'version': version,
  };
  factory Appointment.fromMap(Map<String, dynamic> row) => Appointment(
    id: row['id'] as String,
    clinicId: row['clinic_id'] as String,
    patientId: row['patient_id'] as String,
    doctorId: row['doctor_id'] as String,
    startsAt: DateTime.parse(row['starts_at'] as String),
    status: AppointmentStatus.values.byName(row['status'] as String),
    type: row['appointment_type'] as String? ?? 'Consultation',
    notes: row['notes'] as String? ?? '',
    version: (row['version'] as num?)?.toInt() ?? 0,
  );
}

class Medication {
  const Medication({
    required this.id,
    required this.name,
    this.strength = '',
    this.dose = '',
    this.frequency = '',
    this.duration = '',
    this.instructions = '',
    this.notes = '',
  });
  final String id,
      name,
      strength,
      dose,
      frequency,
      duration,
      instructions,
      notes;
  void validate() {
    if (name.trim().isEmpty || name.trim().length > 300) {
      throw const ClinicFailure('validation', 'Each medication needs a name.');
    }
    if (strength.length > 200 ||
        dose.length > 200 ||
        frequency.length > 200 ||
        duration.length > 200 ||
        instructions.length > 5000 ||
        notes.length > 5000) {
      throw const ClinicFailure(
        'validation',
        'A medication field is too long. Shorten it before saving.',
      );
    }
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'strength': strength,
    'dose': dose,
    'frequency': frequency,
    'duration': duration,
    'instructions': instructions,
    'notes': notes,
  };
  factory Medication.fromMap(Map<String, dynamic> row) => Medication(
    id: row['id'] as String,
    name: row['name'] as String,
    strength: row['strength'] as String? ?? '',
    dose: row['dose'] as String? ?? '',
    frequency: row['frequency'] as String? ?? '',
    duration: row['duration'] as String? ?? '',
    instructions: row['instructions'] as String? ?? '',
    notes: row['notes'] as String? ?? '',
  );
}

class Visit {
  Visit({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.appointmentId,
    required this.doctorId,
    required this.createdAt,
    required this.updatedAt,
    List<String> diagnoses = const [],
    List<Medication> medications = const [],
    this.notes = '',
    this.followUp = '',
    this.completed = false,
    this.version = 0,
    this.currentRevision = 0,
    this.amendmentReason = '',
  }) : diagnoses = List.unmodifiable(diagnoses),
       medications = List.unmodifiable(medications);
  final String id,
      clinicId,
      patientId,
      appointmentId,
      doctorId,
      notes,
      followUp,
      amendmentReason;
  final DateTime createdAt, updatedAt;
  final List<String> diagnoses;
  final List<Medication> medications;
  final bool completed;
  final int version, currentRevision;
  Visit copyWith({
    List<String>? diagnoses,
    List<Medication>? medications,
    String? notes,
    String? followUp,
    bool? completed,
    int? version,
    int? currentRevision,
    DateTime? updatedAt,
    String? amendmentReason,
  }) => Visit(
    id: id,
    clinicId: clinicId,
    patientId: patientId,
    appointmentId: appointmentId,
    doctorId: doctorId,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    diagnoses: diagnoses ?? this.diagnoses,
    medications: medications ?? this.medications,
    notes: notes ?? this.notes,
    followUp: followUp ?? this.followUp,
    completed: completed ?? this.completed,
    version: version ?? this.version,
    currentRevision: currentRevision ?? this.currentRevision,
    amendmentReason: amendmentReason ?? this.amendmentReason,
  );
  void validateForCompletion() {
    if (diagnoses.every((s) => s.trim().isEmpty)) {
      throw const ClinicFailure(
        'validation',
        'Add at least one diagnosis before completing.',
      );
    }
    if (diagnoses.length > 50 ||
        diagnoses.any((value) => value.trim().length > 1000) ||
        medications.length > 100 ||
        notes.length > 20000 ||
        followUp.length > 5000) {
      throw const ClinicFailure(
        'validation',
        'The clinical entry is too large. Shorten it before saving.',
      );
    }
    for (final item in medications) {
      item.validate();
    }
  }

  void validateAmendment(String reason) {
    if (!completed) {
      throw const ClinicFailure(
        'validation',
        'Only a completed visit can be amended.',
      );
    }
    validateForCompletion();
    if (reason.trim().length < 10 || reason.trim().length > 1000) {
      throw const ClinicFailure(
        'validation',
        'Explain the amendment in 10 to 1000 characters.',
      );
    }
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'clinic_id': clinicId,
    'patient_id': patientId,
    'appointment_id': appointmentId,
    'doctor_id': doctorId,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'diagnoses': diagnoses,
    'medications': medications.map((e) => e.toMap()).toList(),
    'notes': notes,
    'follow_up': followUp,
    'completed': completed,
    'version': version,
    'current_revision': currentRevision,
    'amendment_reason': amendmentReason,
  };
  factory Visit.fromMap(Map<String, dynamic> row) => Visit(
    id: row['id'] as String,
    clinicId: row['clinic_id'] as String,
    patientId: row['patient_id'] as String,
    appointmentId: row['appointment_id'] as String,
    doctorId: row['doctor_id'] as String,
    createdAt: DateTime.parse(row['created_at'] as String),
    updatedAt: DateTime.parse(row['updated_at'] as String),
    diagnoses: (row['diagnoses'] as List? ?? []).cast<String>(),
    medications: (row['medications'] as List? ?? [])
        .map((e) => Medication.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList(),
    notes: row['notes'] as String? ?? '',
    followUp: row['follow_up'] as String? ?? '',
    completed: row['completed'] == true,
    version: (row['version'] as num?)?.toInt() ?? 0,
    currentRevision: (row['current_revision'] as num?)?.toInt() ?? 0,
    amendmentReason: row['amendment_reason'] as String? ?? '',
  );
}

enum ClinicDocumentCategory {
  lab('Lab'),
  radiology('Radiology'),
  referral('Referral'),
  consent('Consent'),
  other('Other');

  const ClinicDocumentCategory(this.label);
  final String label;
  static ClinicDocumentCategory parse(String value) =>
      values.firstWhere((item) => item.label == value, orElse: () => other);
}

class ClinicDocument {
  const ClinicDocument({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.fileName,
    required this.contentType,
    required this.category,
    required this.objectPath,
    required this.bytes,
    required this.sha256Hex,
    required this.clinical,
    required this.state,
    required this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
    this.visitId,
    this.notes = '',
    this.version = 0,
  });

  static const maxBytes = 20 * 1024 * 1024;
  static const contentTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf',
  };
  final String id, clinicId, patientId, fileName, contentType, objectPath;
  final String sha256Hex, state, uploadedBy, notes;
  final String? visitId;
  final ClinicDocumentCategory category;
  final int bytes, version;
  final bool clinical;
  final DateTime createdAt, updatedAt;

  bool get isReady => state == 'ready';
  bool get isArchived => state == 'archived';
  bool get isImage => contentType.startsWith('image/');
  bool get isPdf => contentType == 'application/pdf';

  static String? detectContentType(Uint8List data) {
    bool starts(List<int> signature) {
      if (data.length < signature.length) return false;
      for (var i = 0; i < signature.length; i++) {
        if (data[i] != signature[i]) return false;
      }
      return true;
    }

    if (data.length >= 3 &&
        data[0] == 0xff &&
        data[1] == 0xd8 &&
        data[2] == 0xff) {
      return 'image/jpeg';
    }
    if (data.length >= 8 &&
        starts(const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) {
      return 'image/png';
    }
    if (data.length >= 12 &&
        String.fromCharCodes(data.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(data.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    if (data.length >= 5 &&
        String.fromCharCodes(data.sublist(0, 5)) == '%PDF-') {
      return 'application/pdf';
    }
    return null;
  }

  void validate() {
    if (id.isEmpty || clinicId.isEmpty || patientId.isEmpty) {
      throw const ClinicFailure(
        'invalid_document',
        'Invalid document identity.',
      );
    }
    if (fileName.trim().isEmpty ||
        fileName.trim().length > 180 ||
        fileName.contains(RegExp(r'[\x00-\x1f/\\]'))) {
      throw const ClinicFailure(
        'invalid_document',
        'Use a file name without folders or control characters.',
      );
    }
    if (!contentTypes.contains(contentType)) {
      throw const ClinicFailure(
        'invalid_document',
        'Choose a JPEG, PNG, WebP image, or PDF document.',
      );
    }
    if (bytes < 1 || bytes > maxBytes) {
      throw const ClinicFailure(
        'invalid_document',
        'Documents must be between 1 byte and 20 MB.',
      );
    }
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sha256Hex)) {
      throw const ClinicFailure(
        'invalid_document',
        'The document integrity digest is invalid.',
      );
    }
  }

  ClinicDocument copyWith({String? state, DateTime? updatedAt, int? version}) =>
      ClinicDocument(
        id: id,
        clinicId: clinicId,
        patientId: patientId,
        visitId: visitId,
        fileName: fileName,
        contentType: contentType,
        category: category,
        notes: notes,
        objectPath: objectPath,
        bytes: bytes,
        sha256Hex: sha256Hex,
        clinical: clinical,
        state: state ?? this.state,
        uploadedBy: uploadedBy,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        version: version ?? this.version,
      );

  Map<String, Object?> toMap() => {
    'id': id,
    'clinic_id': clinicId,
    'patient_id': patientId,
    'visit_id': visitId,
    'file_name': fileName,
    'content_type': contentType,
    'category': category.label,
    'notes': notes,
    'object_path': objectPath,
    'bytes': bytes,
    'sha256_hex': sha256Hex,
    'clinical': clinical,
    'state': state,
    'uploaded_by': uploadedBy,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'version': version,
  };

  factory ClinicDocument.fromMap(Map<String, dynamic> row) {
    var digest = (row['sha256_hex'] ?? row['sha256']) as String;
    if (digest.startsWith(r'\x')) digest = digest.substring(2);
    return ClinicDocument(
      id: row['id'] as String,
      clinicId: row['clinic_id'] as String,
      patientId: row['patient_id'] as String,
      visitId: row['visit_id'] as String?,
      fileName: row['file_name'] as String,
      contentType: row['content_type'] as String,
      category: ClinicDocumentCategory.parse(
        row['category'] as String? ?? 'Other',
      ),
      notes: row['notes'] as String? ?? '',
      objectPath: row['object_path'] as String,
      bytes: (row['bytes'] as num).toInt(),
      sha256Hex: digest,
      clinical: row['clinical'] == true || row['clinical'] == 1,
      state: row['state'] as String,
      uploadedBy: row['uploaded_by'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      version: (row['version'] as num?)?.toInt() ?? 0,
    );
  }
}

class ClinicDocumentContent {
  const ClinicDocumentContent(this.document, this.data);
  final ClinicDocument document;
  final Uint8List data;
}

void requireTransition(AppointmentStatus from, AppointmentStatus to) {
  const allowed = {
    AppointmentStatus.scheduled: {
      AppointmentStatus.confirmed,
      AppointmentStatus.arrived,
      AppointmentStatus.cancelled,
      AppointmentStatus.noShow,
    },
    AppointmentStatus.confirmed: {
      AppointmentStatus.arrived,
      AppointmentStatus.cancelled,
      AppointmentStatus.noShow,
    },
    AppointmentStatus.arrived: {
      AppointmentStatus.waiting,
      AppointmentStatus.cancelled,
    },
    AppointmentStatus.waiting: {
      AppointmentStatus.withDoctor,
      AppointmentStatus.cancelled,
    },
    AppointmentStatus.withDoctor: {
      AppointmentStatus.completed,
      AppointmentStatus.waiting,
    },
  };
  if (!(allowed[from]?.contains(to) ?? false)) {
    throw ClinicFailure(
      'invalid_transition',
      'Cannot change ${from.label} to ${to.label}.',
    );
  }
}
