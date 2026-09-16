// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class CachedPatients extends Table
    with TableInfo<CachedPatients, CachedPatient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CachedPatients(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _clinicIdMeta = const VerificationMeta(
    'clinicId',
  );
  late final GeneratedColumn<String> clinicId = GeneratedColumn<String>(
    'clinic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _birthDateMeta = const VerificationMeta(
    'birthDate',
  );
  late final GeneratedColumn<String> birthDate = GeneratedColumn<String>(
    'birth_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _mobileMeta = const VerificationMeta('mobile');
  late final GeneratedColumn<String> mobile = GeneratedColumn<String>(
    'mobile',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _mobileDigitsMeta = const VerificationMeta(
    'mobileDigits',
  );
  late final GeneratedColumn<String> mobileDigits = GeneratedColumn<String>(
    'mobile_digits',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _secondaryMobileMeta = const VerificationMeta(
    'secondaryMobile',
  );
  late final GeneratedColumn<String> secondaryMobile = GeneratedColumn<String>(
    'secondary_mobile',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _patientNumberMeta = const VerificationMeta(
    'patientNumber',
  );
  late final GeneratedColumn<String> patientNumber = GeneratedColumn<String>(
    'patient_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _alertsMeta = const VerificationMeta('alerts');
  late final GeneratedColumn<String> alerts = GeneratedColumn<String>(
    'alerts',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  late final GeneratedColumn<int> archived = GeneratedColumn<int>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clinicId,
    fullName,
    gender,
    birthDate,
    mobile,
    mobileDigits,
    secondaryMobile,
    patientNumber,
    address,
    notes,
    alerts,
    archived,
    createdAt,
    updatedAt,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_patients';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPatient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('clinic_id')) {
      context.handle(
        _clinicIdMeta,
        clinicId.isAcceptableOrUnknown(data['clinic_id']!, _clinicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clinicIdMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    } else if (isInserting) {
      context.missing(_genderMeta);
    }
    if (data.containsKey('birth_date')) {
      context.handle(
        _birthDateMeta,
        birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta),
      );
    } else if (isInserting) {
      context.missing(_birthDateMeta);
    }
    if (data.containsKey('mobile')) {
      context.handle(
        _mobileMeta,
        mobile.isAcceptableOrUnknown(data['mobile']!, _mobileMeta),
      );
    } else if (isInserting) {
      context.missing(_mobileMeta);
    }
    if (data.containsKey('mobile_digits')) {
      context.handle(
        _mobileDigitsMeta,
        mobileDigits.isAcceptableOrUnknown(
          data['mobile_digits']!,
          _mobileDigitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mobileDigitsMeta);
    }
    if (data.containsKey('secondary_mobile')) {
      context.handle(
        _secondaryMobileMeta,
        secondaryMobile.isAcceptableOrUnknown(
          data['secondary_mobile']!,
          _secondaryMobileMeta,
        ),
      );
    }
    if (data.containsKey('patient_number')) {
      context.handle(
        _patientNumberMeta,
        patientNumber.isAcceptableOrUnknown(
          data['patient_number']!,
          _patientNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_patientNumberMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('alerts')) {
      context.handle(
        _alertsMeta,
        alerts.isAcceptableOrUnknown(data['alerts']!, _alertsMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedPatient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPatient(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clinicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clinic_id'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      )!,
      birthDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}birth_date'],
      )!,
      mobile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mobile'],
      )!,
      mobileDigits: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mobile_digits'],
      )!,
      secondaryMobile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secondary_mobile'],
      )!,
      patientNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_number'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      alerts: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alerts'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  CachedPatients createAlias(String alias) {
    return CachedPatients(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CachedPatient extends DataClass implements Insertable<CachedPatient> {
  final String id;
  final String clinicId;
  final String fullName;
  final String gender;
  final String birthDate;
  final String mobile;
  final String mobileDigits;
  final String secondaryMobile;
  final String patientNumber;
  final String address;
  final String notes;
  final String alerts;
  final int archived;
  final String createdAt;
  final String updatedAt;
  final int version;
  const CachedPatient({
    required this.id,
    required this.clinicId,
    required this.fullName,
    required this.gender,
    required this.birthDate,
    required this.mobile,
    required this.mobileDigits,
    required this.secondaryMobile,
    required this.patientNumber,
    required this.address,
    required this.notes,
    required this.alerts,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['clinic_id'] = Variable<String>(clinicId);
    map['full_name'] = Variable<String>(fullName);
    map['gender'] = Variable<String>(gender);
    map['birth_date'] = Variable<String>(birthDate);
    map['mobile'] = Variable<String>(mobile);
    map['mobile_digits'] = Variable<String>(mobileDigits);
    map['secondary_mobile'] = Variable<String>(secondaryMobile);
    map['patient_number'] = Variable<String>(patientNumber);
    map['address'] = Variable<String>(address);
    map['notes'] = Variable<String>(notes);
    map['alerts'] = Variable<String>(alerts);
    map['archived'] = Variable<int>(archived);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['version'] = Variable<int>(version);
    return map;
  }

  CachedPatientsCompanion toCompanion(bool nullToAbsent) {
    return CachedPatientsCompanion(
      id: Value(id),
      clinicId: Value(clinicId),
      fullName: Value(fullName),
      gender: Value(gender),
      birthDate: Value(birthDate),
      mobile: Value(mobile),
      mobileDigits: Value(mobileDigits),
      secondaryMobile: Value(secondaryMobile),
      patientNumber: Value(patientNumber),
      address: Value(address),
      notes: Value(notes),
      alerts: Value(alerts),
      archived: Value(archived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      version: Value(version),
    );
  }

  factory CachedPatient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPatient(
      id: serializer.fromJson<String>(json['id']),
      clinicId: serializer.fromJson<String>(json['clinic_id']),
      fullName: serializer.fromJson<String>(json['full_name']),
      gender: serializer.fromJson<String>(json['gender']),
      birthDate: serializer.fromJson<String>(json['birth_date']),
      mobile: serializer.fromJson<String>(json['mobile']),
      mobileDigits: serializer.fromJson<String>(json['mobile_digits']),
      secondaryMobile: serializer.fromJson<String>(json['secondary_mobile']),
      patientNumber: serializer.fromJson<String>(json['patient_number']),
      address: serializer.fromJson<String>(json['address']),
      notes: serializer.fromJson<String>(json['notes']),
      alerts: serializer.fromJson<String>(json['alerts']),
      archived: serializer.fromJson<int>(json['archived']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      updatedAt: serializer.fromJson<String>(json['updated_at']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clinic_id': serializer.toJson<String>(clinicId),
      'full_name': serializer.toJson<String>(fullName),
      'gender': serializer.toJson<String>(gender),
      'birth_date': serializer.toJson<String>(birthDate),
      'mobile': serializer.toJson<String>(mobile),
      'mobile_digits': serializer.toJson<String>(mobileDigits),
      'secondary_mobile': serializer.toJson<String>(secondaryMobile),
      'patient_number': serializer.toJson<String>(patientNumber),
      'address': serializer.toJson<String>(address),
      'notes': serializer.toJson<String>(notes),
      'alerts': serializer.toJson<String>(alerts),
      'archived': serializer.toJson<int>(archived),
      'created_at': serializer.toJson<String>(createdAt),
      'updated_at': serializer.toJson<String>(updatedAt),
      'version': serializer.toJson<int>(version),
    };
  }

  CachedPatient copyWith({
    String? id,
    String? clinicId,
    String? fullName,
    String? gender,
    String? birthDate,
    String? mobile,
    String? mobileDigits,
    String? secondaryMobile,
    String? patientNumber,
    String? address,
    String? notes,
    String? alerts,
    int? archived,
    String? createdAt,
    String? updatedAt,
    int? version,
  }) => CachedPatient(
    id: id ?? this.id,
    clinicId: clinicId ?? this.clinicId,
    fullName: fullName ?? this.fullName,
    gender: gender ?? this.gender,
    birthDate: birthDate ?? this.birthDate,
    mobile: mobile ?? this.mobile,
    mobileDigits: mobileDigits ?? this.mobileDigits,
    secondaryMobile: secondaryMobile ?? this.secondaryMobile,
    patientNumber: patientNumber ?? this.patientNumber,
    address: address ?? this.address,
    notes: notes ?? this.notes,
    alerts: alerts ?? this.alerts,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
  );
  CachedPatient copyWithCompanion(CachedPatientsCompanion data) {
    return CachedPatient(
      id: data.id.present ? data.id.value : this.id,
      clinicId: data.clinicId.present ? data.clinicId.value : this.clinicId,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      gender: data.gender.present ? data.gender.value : this.gender,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      mobile: data.mobile.present ? data.mobile.value : this.mobile,
      mobileDigits: data.mobileDigits.present
          ? data.mobileDigits.value
          : this.mobileDigits,
      secondaryMobile: data.secondaryMobile.present
          ? data.secondaryMobile.value
          : this.secondaryMobile,
      patientNumber: data.patientNumber.present
          ? data.patientNumber.value
          : this.patientNumber,
      address: data.address.present ? data.address.value : this.address,
      notes: data.notes.present ? data.notes.value : this.notes,
      alerts: data.alerts.present ? data.alerts.value : this.alerts,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPatient(')
          ..write('id: $id, ')
          ..write('clinicId: $clinicId, ')
          ..write('fullName: $fullName, ')
          ..write('gender: $gender, ')
          ..write('birthDate: $birthDate, ')
          ..write('mobile: $mobile, ')
          ..write('mobileDigits: $mobileDigits, ')
          ..write('secondaryMobile: $secondaryMobile, ')
          ..write('patientNumber: $patientNumber, ')
          ..write('address: $address, ')
          ..write('notes: $notes, ')
          ..write('alerts: $alerts, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clinicId,
    fullName,
    gender,
    birthDate,
    mobile,
    mobileDigits,
    secondaryMobile,
    patientNumber,
    address,
    notes,
    alerts,
    archived,
    createdAt,
    updatedAt,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPatient &&
          other.id == this.id &&
          other.clinicId == this.clinicId &&
          other.fullName == this.fullName &&
          other.gender == this.gender &&
          other.birthDate == this.birthDate &&
          other.mobile == this.mobile &&
          other.mobileDigits == this.mobileDigits &&
          other.secondaryMobile == this.secondaryMobile &&
          other.patientNumber == this.patientNumber &&
          other.address == this.address &&
          other.notes == this.notes &&
          other.alerts == this.alerts &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version);
}

class CachedPatientsCompanion extends UpdateCompanion<CachedPatient> {
  final Value<String> id;
  final Value<String> clinicId;
  final Value<String> fullName;
  final Value<String> gender;
  final Value<String> birthDate;
  final Value<String> mobile;
  final Value<String> mobileDigits;
  final Value<String> secondaryMobile;
  final Value<String> patientNumber;
  final Value<String> address;
  final Value<String> notes;
  final Value<String> alerts;
  final Value<int> archived;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> version;
  final Value<int> rowid;
  const CachedPatientsCompanion({
    this.id = const Value.absent(),
    this.clinicId = const Value.absent(),
    this.fullName = const Value.absent(),
    this.gender = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.mobile = const Value.absent(),
    this.mobileDigits = const Value.absent(),
    this.secondaryMobile = const Value.absent(),
    this.patientNumber = const Value.absent(),
    this.address = const Value.absent(),
    this.notes = const Value.absent(),
    this.alerts = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPatientsCompanion.insert({
    required String id,
    required String clinicId,
    required String fullName,
    required String gender,
    required String birthDate,
    required String mobile,
    required String mobileDigits,
    this.secondaryMobile = const Value.absent(),
    required String patientNumber,
    this.address = const Value.absent(),
    this.notes = const Value.absent(),
    this.alerts = const Value.absent(),
    this.archived = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    required int version,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clinicId = Value(clinicId),
       fullName = Value(fullName),
       gender = Value(gender),
       birthDate = Value(birthDate),
       mobile = Value(mobile),
       mobileDigits = Value(mobileDigits),
       patientNumber = Value(patientNumber),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       version = Value(version);
  static Insertable<CachedPatient> custom({
    Expression<String>? id,
    Expression<String>? clinicId,
    Expression<String>? fullName,
    Expression<String>? gender,
    Expression<String>? birthDate,
    Expression<String>? mobile,
    Expression<String>? mobileDigits,
    Expression<String>? secondaryMobile,
    Expression<String>? patientNumber,
    Expression<String>? address,
    Expression<String>? notes,
    Expression<String>? alerts,
    Expression<int>? archived,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clinicId != null) 'clinic_id': clinicId,
      if (fullName != null) 'full_name': fullName,
      if (gender != null) 'gender': gender,
      if (birthDate != null) 'birth_date': birthDate,
      if (mobile != null) 'mobile': mobile,
      if (mobileDigits != null) 'mobile_digits': mobileDigits,
      if (secondaryMobile != null) 'secondary_mobile': secondaryMobile,
      if (patientNumber != null) 'patient_number': patientNumber,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
      if (alerts != null) 'alerts': alerts,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPatientsCompanion copyWith({
    Value<String>? id,
    Value<String>? clinicId,
    Value<String>? fullName,
    Value<String>? gender,
    Value<String>? birthDate,
    Value<String>? mobile,
    Value<String>? mobileDigits,
    Value<String>? secondaryMobile,
    Value<String>? patientNumber,
    Value<String>? address,
    Value<String>? notes,
    Value<String>? alerts,
    Value<int>? archived,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return CachedPatientsCompanion(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      mobile: mobile ?? this.mobile,
      mobileDigits: mobileDigits ?? this.mobileDigits,
      secondaryMobile: secondaryMobile ?? this.secondaryMobile,
      patientNumber: patientNumber ?? this.patientNumber,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      alerts: alerts ?? this.alerts,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clinicId.present) {
      map['clinic_id'] = Variable<String>(clinicId.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<String>(birthDate.value);
    }
    if (mobile.present) {
      map['mobile'] = Variable<String>(mobile.value);
    }
    if (mobileDigits.present) {
      map['mobile_digits'] = Variable<String>(mobileDigits.value);
    }
    if (secondaryMobile.present) {
      map['secondary_mobile'] = Variable<String>(secondaryMobile.value);
    }
    if (patientNumber.present) {
      map['patient_number'] = Variable<String>(patientNumber.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (alerts.present) {
      map['alerts'] = Variable<String>(alerts.value);
    }
    if (archived.present) {
      map['archived'] = Variable<int>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPatientsCompanion(')
          ..write('id: $id, ')
          ..write('clinicId: $clinicId, ')
          ..write('fullName: $fullName, ')
          ..write('gender: $gender, ')
          ..write('birthDate: $birthDate, ')
          ..write('mobile: $mobile, ')
          ..write('mobileDigits: $mobileDigits, ')
          ..write('secondaryMobile: $secondaryMobile, ')
          ..write('patientNumber: $patientNumber, ')
          ..write('address: $address, ')
          ..write('notes: $notes, ')
          ..write('alerts: $alerts, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CachedAppointments extends Table
    with TableInfo<CachedAppointments, CachedAppointment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CachedAppointments(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _clinicIdMeta = const VerificationMeta(
    'clinicId',
  );
  late final GeneratedColumn<String> clinicId = GeneratedColumn<String>(
    'clinic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES cached_patients(id)',
  );
  static const VerificationMeta _doctorIdMeta = const VerificationMeta(
    'doctorId',
  );
  late final GeneratedColumn<String> doctorId = GeneratedColumn<String>(
    'doctor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _startsAtMeta = const VerificationMeta(
    'startsAt',
  );
  late final GeneratedColumn<String> startsAt = GeneratedColumn<String>(
    'starts_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 30',
    defaultValue: const CustomExpression('30'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _appointmentTypeMeta = const VerificationMeta(
    'appointmentType',
  );
  late final GeneratedColumn<String> appointmentType = GeneratedColumn<String>(
    'appointment_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clinicId,
    patientId,
    doctorId,
    startsAt,
    durationMinutes,
    status,
    appointmentType,
    notes,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_appointments';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedAppointment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('clinic_id')) {
      context.handle(
        _clinicIdMeta,
        clinicId.isAcceptableOrUnknown(data['clinic_id']!, _clinicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clinicIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('doctor_id')) {
      context.handle(
        _doctorIdMeta,
        doctorId.isAcceptableOrUnknown(data['doctor_id']!, _doctorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_doctorIdMeta);
    }
    if (data.containsKey('starts_at')) {
      context.handle(
        _startsAtMeta,
        startsAt.isAcceptableOrUnknown(data['starts_at']!, _startsAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startsAtMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('appointment_type')) {
      context.handle(
        _appointmentTypeMeta,
        appointmentType.isAcceptableOrUnknown(
          data['appointment_type']!,
          _appointmentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_appointmentTypeMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedAppointment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedAppointment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clinicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clinic_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      doctorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doctor_id'],
      )!,
      startsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}starts_at'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      appointmentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appointment_type'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  CachedAppointments createAlias(String alias) {
    return CachedAppointments(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CachedAppointment extends DataClass
    implements Insertable<CachedAppointment> {
  final String id;
  final String clinicId;
  final String patientId;
  final String doctorId;
  final String startsAt;
  final int durationMinutes;
  final String status;
  final String appointmentType;
  final String notes;
  final int version;
  const CachedAppointment({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.doctorId,
    required this.startsAt,
    required this.durationMinutes,
    required this.status,
    required this.appointmentType,
    required this.notes,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['clinic_id'] = Variable<String>(clinicId);
    map['patient_id'] = Variable<String>(patientId);
    map['doctor_id'] = Variable<String>(doctorId);
    map['starts_at'] = Variable<String>(startsAt);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['status'] = Variable<String>(status);
    map['appointment_type'] = Variable<String>(appointmentType);
    map['notes'] = Variable<String>(notes);
    map['version'] = Variable<int>(version);
    return map;
  }

  CachedAppointmentsCompanion toCompanion(bool nullToAbsent) {
    return CachedAppointmentsCompanion(
      id: Value(id),
      clinicId: Value(clinicId),
      patientId: Value(patientId),
      doctorId: Value(doctorId),
      startsAt: Value(startsAt),
      durationMinutes: Value(durationMinutes),
      status: Value(status),
      appointmentType: Value(appointmentType),
      notes: Value(notes),
      version: Value(version),
    );
  }

  factory CachedAppointment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedAppointment(
      id: serializer.fromJson<String>(json['id']),
      clinicId: serializer.fromJson<String>(json['clinic_id']),
      patientId: serializer.fromJson<String>(json['patient_id']),
      doctorId: serializer.fromJson<String>(json['doctor_id']),
      startsAt: serializer.fromJson<String>(json['starts_at']),
      durationMinutes: serializer.fromJson<int>(json['duration_minutes']),
      status: serializer.fromJson<String>(json['status']),
      appointmentType: serializer.fromJson<String>(json['appointment_type']),
      notes: serializer.fromJson<String>(json['notes']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clinic_id': serializer.toJson<String>(clinicId),
      'patient_id': serializer.toJson<String>(patientId),
      'doctor_id': serializer.toJson<String>(doctorId),
      'starts_at': serializer.toJson<String>(startsAt),
      'duration_minutes': serializer.toJson<int>(durationMinutes),
      'status': serializer.toJson<String>(status),
      'appointment_type': serializer.toJson<String>(appointmentType),
      'notes': serializer.toJson<String>(notes),
      'version': serializer.toJson<int>(version),
    };
  }

  CachedAppointment copyWith({
    String? id,
    String? clinicId,
    String? patientId,
    String? doctorId,
    String? startsAt,
    int? durationMinutes,
    String? status,
    String? appointmentType,
    String? notes,
    int? version,
  }) => CachedAppointment(
    id: id ?? this.id,
    clinicId: clinicId ?? this.clinicId,
    patientId: patientId ?? this.patientId,
    doctorId: doctorId ?? this.doctorId,
    startsAt: startsAt ?? this.startsAt,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    status: status ?? this.status,
    appointmentType: appointmentType ?? this.appointmentType,
    notes: notes ?? this.notes,
    version: version ?? this.version,
  );
  CachedAppointment copyWithCompanion(CachedAppointmentsCompanion data) {
    return CachedAppointment(
      id: data.id.present ? data.id.value : this.id,
      clinicId: data.clinicId.present ? data.clinicId.value : this.clinicId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      doctorId: data.doctorId.present ? data.doctorId.value : this.doctorId,
      startsAt: data.startsAt.present ? data.startsAt.value : this.startsAt,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      status: data.status.present ? data.status.value : this.status,
      appointmentType: data.appointmentType.present
          ? data.appointmentType.value
          : this.appointmentType,
      notes: data.notes.present ? data.notes.value : this.notes,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedAppointment(')
          ..write('id: $id, ')
          ..write('clinicId: $clinicId, ')
          ..write('patientId: $patientId, ')
          ..write('doctorId: $doctorId, ')
          ..write('startsAt: $startsAt, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('status: $status, ')
          ..write('appointmentType: $appointmentType, ')
          ..write('notes: $notes, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clinicId,
    patientId,
    doctorId,
    startsAt,
    durationMinutes,
    status,
    appointmentType,
    notes,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedAppointment &&
          other.id == this.id &&
          other.clinicId == this.clinicId &&
          other.patientId == this.patientId &&
          other.doctorId == this.doctorId &&
          other.startsAt == this.startsAt &&
          other.durationMinutes == this.durationMinutes &&
          other.status == this.status &&
          other.appointmentType == this.appointmentType &&
          other.notes == this.notes &&
          other.version == this.version);
}

class CachedAppointmentsCompanion extends UpdateCompanion<CachedAppointment> {
  final Value<String> id;
  final Value<String> clinicId;
  final Value<String> patientId;
  final Value<String> doctorId;
  final Value<String> startsAt;
  final Value<int> durationMinutes;
  final Value<String> status;
  final Value<String> appointmentType;
  final Value<String> notes;
  final Value<int> version;
  final Value<int> rowid;
  const CachedAppointmentsCompanion({
    this.id = const Value.absent(),
    this.clinicId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.doctorId = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.status = const Value.absent(),
    this.appointmentType = const Value.absent(),
    this.notes = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedAppointmentsCompanion.insert({
    required String id,
    required String clinicId,
    required String patientId,
    required String doctorId,
    required String startsAt,
    this.durationMinutes = const Value.absent(),
    required String status,
    required String appointmentType,
    this.notes = const Value.absent(),
    required int version,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clinicId = Value(clinicId),
       patientId = Value(patientId),
       doctorId = Value(doctorId),
       startsAt = Value(startsAt),
       status = Value(status),
       appointmentType = Value(appointmentType),
       version = Value(version);
  static Insertable<CachedAppointment> custom({
    Expression<String>? id,
    Expression<String>? clinicId,
    Expression<String>? patientId,
    Expression<String>? doctorId,
    Expression<String>? startsAt,
    Expression<int>? durationMinutes,
    Expression<String>? status,
    Expression<String>? appointmentType,
    Expression<String>? notes,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clinicId != null) 'clinic_id': clinicId,
      if (patientId != null) 'patient_id': patientId,
      if (doctorId != null) 'doctor_id': doctorId,
      if (startsAt != null) 'starts_at': startsAt,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (status != null) 'status': status,
      if (appointmentType != null) 'appointment_type': appointmentType,
      if (notes != null) 'notes': notes,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedAppointmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? clinicId,
    Value<String>? patientId,
    Value<String>? doctorId,
    Value<String>? startsAt,
    Value<int>? durationMinutes,
    Value<String>? status,
    Value<String>? appointmentType,
    Value<String>? notes,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return CachedAppointmentsCompanion(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      startsAt: startsAt ?? this.startsAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      appointmentType: appointmentType ?? this.appointmentType,
      notes: notes ?? this.notes,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clinicId.present) {
      map['clinic_id'] = Variable<String>(clinicId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (doctorId.present) {
      map['doctor_id'] = Variable<String>(doctorId.value);
    }
    if (startsAt.present) {
      map['starts_at'] = Variable<String>(startsAt.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (appointmentType.present) {
      map['appointment_type'] = Variable<String>(appointmentType.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedAppointmentsCompanion(')
          ..write('id: $id, ')
          ..write('clinicId: $clinicId, ')
          ..write('patientId: $patientId, ')
          ..write('doctorId: $doctorId, ')
          ..write('startsAt: $startsAt, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('status: $status, ')
          ..write('appointmentType: $appointmentType, ')
          ..write('notes: $notes, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CachedVisits extends Table with TableInfo<CachedVisits, CachedVisit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CachedVisits(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _clinicIdMeta = const VerificationMeta(
    'clinicId',
  );
  late final GeneratedColumn<String> clinicId = GeneratedColumn<String>(
    'clinic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES cached_patients(id)',
  );
  static const VerificationMeta _appointmentIdMeta = const VerificationMeta(
    'appointmentId',
  );
  late final GeneratedColumn<String> appointmentId = GeneratedColumn<String>(
    'appointment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES cached_appointments(id)',
  );
  static const VerificationMeta _doctorIdMeta = const VerificationMeta(
    'doctorId',
  );
  late final GeneratedColumn<String> doctorId = GeneratedColumn<String>(
    'doctor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _followUpMeta = const VerificationMeta(
    'followUp',
  );
  late final GeneratedColumn<String> followUp = GeneratedColumn<String>(
    'follow_up',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  late final GeneratedColumn<int> completed = GeneratedColumn<int>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _currentRevisionMeta = const VerificationMeta(
    'currentRevision',
  );
  late final GeneratedColumn<int> currentRevision = GeneratedColumn<int>(
    'current_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _amendmentReasonMeta = const VerificationMeta(
    'amendmentReason',
  );
  late final GeneratedColumn<String> amendmentReason = GeneratedColumn<String>(
    'amendment_reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clinicId,
    patientId,
    appointmentId,
    doctorId,
    createdAt,
    updatedAt,
    notes,
    followUp,
    completed,
    version,
    currentRevision,
    amendmentReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_visits';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedVisit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('clinic_id')) {
      context.handle(
        _clinicIdMeta,
        clinicId.isAcceptableOrUnknown(data['clinic_id']!, _clinicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clinicIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('appointment_id')) {
      context.handle(
        _appointmentIdMeta,
        appointmentId.isAcceptableOrUnknown(
          data['appointment_id']!,
          _appointmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_appointmentIdMeta);
    }
    if (data.containsKey('doctor_id')) {
      context.handle(
        _doctorIdMeta,
        doctorId.isAcceptableOrUnknown(data['doctor_id']!, _doctorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_doctorIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('follow_up')) {
      context.handle(
        _followUpMeta,
        followUp.isAcceptableOrUnknown(data['follow_up']!, _followUpMeta),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('current_revision')) {
      context.handle(
        _currentRevisionMeta,
        currentRevision.isAcceptableOrUnknown(
          data['current_revision']!,
          _currentRevisionMeta,
        ),
      );
    }
    if (data.containsKey('amendment_reason')) {
      context.handle(
        _amendmentReasonMeta,
        amendmentReason.isAcceptableOrUnknown(
          data['amendment_reason']!,
          _amendmentReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedVisit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedVisit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clinicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clinic_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      appointmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appointment_id'],
      )!,
      doctorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doctor_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      followUp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}follow_up'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      currentRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_revision'],
      )!,
      amendmentReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amendment_reason'],
      )!,
    );
  }

  @override
  CachedVisits createAlias(String alias) {
    return CachedVisits(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CachedVisit extends DataClass implements Insertable<CachedVisit> {
  final String id;
  final String clinicId;
  final String patientId;
  final String appointmentId;
  final String doctorId;
  final String createdAt;
  final String updatedAt;
  final String notes;
  final String followUp;
  final int completed;
  final int version;
  final int currentRevision;
  final String amendmentReason;
  const CachedVisit({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.appointmentId,
    required this.doctorId,
    required this.createdAt,
    required this.updatedAt,
    required this.notes,
    required this.followUp,
    required this.completed,
    required this.version,
    required this.currentRevision,
    required this.amendmentReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['clinic_id'] = Variable<String>(clinicId);
    map['patient_id'] = Variable<String>(patientId);
    map['appointment_id'] = Variable<String>(appointmentId);
    map['doctor_id'] = Variable<String>(doctorId);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['notes'] = Variable<String>(notes);
    map['follow_up'] = Variable<String>(followUp);
    map['completed'] = Variable<int>(completed);
    map['version'] = Variable<int>(version);
    map['current_revision'] = Variable<int>(currentRevision);
    map['amendment_reason'] = Variable<String>(amendmentReason);
    return map;
  }

  CachedVisitsCompanion toCompanion(bool nullToAbsent) {
    return CachedVisitsCompanion(
      id: Value(id),
      clinicId: Value(clinicId),
      patientId: Value(patientId),
      appointmentId: Value(appointmentId),
      doctorId: Value(doctorId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      notes: Value(notes),
      followUp: Value(followUp),
      completed: Value(completed),
      version: Value(version),
      currentRevision: Value(currentRevision),
      amendmentReason: Value(amendmentReason),
    );
  }

  factory CachedVisit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedVisit(
      id: serializer.fromJson<String>(json['id']),
      clinicId: serializer.fromJson<String>(json['clinic_id']),
      patientId: serializer.fromJson<String>(json['patient_id']),
      appointmentId: serializer.fromJson<String>(json['appointment_id']),
      doctorId: serializer.fromJson<String>(json['doctor_id']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      updatedAt: serializer.fromJson<String>(json['updated_at']),
      notes: serializer.fromJson<String>(json['notes']),
      followUp: serializer.fromJson<String>(json['follow_up']),
      completed: serializer.fromJson<int>(json['completed']),
      version: serializer.fromJson<int>(json['version']),
      currentRevision: serializer.fromJson<int>(json['current_revision']),
      amendmentReason: serializer.fromJson<String>(json['amendment_reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clinic_id': serializer.toJson<String>(clinicId),
      'patient_id': serializer.toJson<String>(patientId),
      'appointment_id': serializer.toJson<String>(appointmentId),
      'doctor_id': serializer.toJson<String>(doctorId),
      'created_at': serializer.toJson<String>(createdAt),
      'updated_at': serializer.toJson<String>(updatedAt),
      'notes': serializer.toJson<String>(notes),
      'follow_up': serializer.toJson<String>(followUp),
      'completed': serializer.toJson<int>(completed),
      'version': serializer.toJson<int>(version),
      'current_revision': serializer.toJson<int>(currentRevision),
      'amendment_reason': serializer.toJson<String>(amendmentReason),
    };
  }

  CachedVisit copyWith({
    String? id,
    String? clinicId,
    String? patientId,
    String? appointmentId,
    String? doctorId,
    String? createdAt,
    String? updatedAt,
    String? notes,
    String? followUp,
    int? completed,
    int? version,
    int? currentRevision,
    String? amendmentReason,
  }) => CachedVisit(
    id: id ?? this.id,
    clinicId: clinicId ?? this.clinicId,
    patientId: patientId ?? this.patientId,
    appointmentId: appointmentId ?? this.appointmentId,
    doctorId: doctorId ?? this.doctorId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    notes: notes ?? this.notes,
    followUp: followUp ?? this.followUp,
    completed: completed ?? this.completed,
    version: version ?? this.version,
    currentRevision: currentRevision ?? this.currentRevision,
    amendmentReason: amendmentReason ?? this.amendmentReason,
  );
  CachedVisit copyWithCompanion(CachedVisitsCompanion data) {
    return CachedVisit(
      id: data.id.present ? data.id.value : this.id,
      clinicId: data.clinicId.present ? data.clinicId.value : this.clinicId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      appointmentId: data.appointmentId.present
          ? data.appointmentId.value
          : this.appointmentId,
      doctorId: data.doctorId.present ? data.doctorId.value : this.doctorId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      followUp: data.followUp.present ? data.followUp.value : this.followUp,
      completed: data.completed.present ? data.completed.value : this.completed,
      version: data.version.present ? data.version.value : this.version,
      currentRevision: data.currentRevision.present
          ? data.currentRevision.value
          : this.currentRevision,
      amendmentReason: data.amendmentReason.present
          ? data.amendmentReason.value
          : this.amendmentReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedVisit(')
          ..write('id: $id, ')
          ..write('clinicId: $clinicId, ')
          ..write('patientId: $patientId, ')
          ..write('appointmentId: $appointmentId, ')
          ..write('doctorId: $doctorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('notes: $notes, ')
          ..write('followUp: $followUp, ')
          ..write('completed: $completed, ')
          ..write('version: $version, ')
          ..write('currentRevision: $currentRevision, ')
          ..write('amendmentReason: $amendmentReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clinicId,
    patientId,
    appointmentId,
    doctorId,
    createdAt,
    updatedAt,
    notes,
    followUp,
    completed,
    version,
    currentRevision,
    amendmentReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedVisit &&
          other.id == this.id &&
          other.clinicId == this.clinicId &&
          other.patientId == this.patientId &&
          other.appointmentId == this.appointmentId &&
          other.doctorId == this.doctorId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.notes == this.notes &&
          other.followUp == this.followUp &&
          other.completed == this.completed &&
          other.version == this.version &&
          other.currentRevision == this.currentRevision &&
          other.amendmentReason == this.amendmentReason);
}

class CachedVisitsCompanion extends UpdateCompanion<CachedVisit> {
  final Value<String> id;
  final Value<String> clinicId;
  final Value<String> patientId;
  final Value<String> appointmentId;
  final Value<String> doctorId;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> notes;
  final Value<String> followUp;
  final Value<int> completed;
  final Value<int> version;
  final Value<int> currentRevision;
  final Value<String> amendmentReason;
  final Value<int> rowid;
  const CachedVisitsCompanion({
    this.id = const Value.absent(),
    this.clinicId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.appointmentId = const Value.absent(),
    this.doctorId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.followUp = const Value.absent(),
    this.completed = const Value.absent(),
    this.version = const Value.absent(),
    this.currentRevision = const Value.absent(),
    this.amendmentReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedVisitsCompanion.insert({
    required String id,
    required String clinicId,
    required String patientId,
    required String appointmentId,
    required String doctorId,
    required String createdAt,
    required String updatedAt,
    this.notes = const Value.absent(),
    this.followUp = const Value.absent(),
    this.completed = const Value.absent(),
    required int version,
    this.currentRevision = const Value.absent(),
    this.amendmentReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clinicId = Value(clinicId),
       patientId = Value(patientId),
       appointmentId = Value(appointmentId),
       doctorId = Value(doctorId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       version = Value(version);
  static Insertable<CachedVisit> custom({
    Expression<String>? id,
    Expression<String>? clinicId,
    Expression<String>? patientId,
    Expression<String>? appointmentId,
    Expression<String>? doctorId,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? notes,
    Expression<String>? followUp,
    Expression<int>? completed,
    Expression<int>? version,
    Expression<int>? currentRevision,
    Expression<String>? amendmentReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clinicId != null) 'clinic_id': clinicId,
      if (patientId != null) 'patient_id': patientId,
      if (appointmentId != null) 'appointment_id': appointmentId,
      if (doctorId != null) 'doctor_id': doctorId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (notes != null) 'notes': notes,
      if (followUp != null) 'follow_up': followUp,
      if (completed != null) 'completed': completed,
      if (version != null) 'version': version,
      if (currentRevision != null) 'current_revision': currentRevision,
      if (amendmentReason != null) 'amendment_reason': amendmentReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedVisitsCompanion copyWith({
    Value<String>? id,
    Value<String>? clinicId,
    Value<String>? patientId,
    Value<String>? appointmentId,
    Value<String>? doctorId,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? notes,
    Value<String>? followUp,
    Value<int>? completed,
    Value<int>? version,
    Value<int>? currentRevision,
    Value<String>? amendmentReason,
    Value<int>? rowid,
  }) {
    return CachedVisitsCompanion(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      patientId: patientId ?? this.patientId,
      appointmentId: appointmentId ?? this.appointmentId,
      doctorId: doctorId ?? this.doctorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      followUp: followUp ?? this.followUp,
      completed: completed ?? this.completed,
      version: version ?? this.version,
      currentRevision: currentRevision ?? this.currentRevision,
      amendmentReason: amendmentReason ?? this.amendmentReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clinicId.present) {
      map['clinic_id'] = Variable<String>(clinicId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (appointmentId.present) {
      map['appointment_id'] = Variable<String>(appointmentId.value);
    }
    if (doctorId.present) {
      map['doctor_id'] = Variable<String>(doctorId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (followUp.present) {
      map['follow_up'] = Variable<String>(followUp.value);
    }
    if (completed.present) {
      map['completed'] = Variable<int>(completed.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (currentRevision.present) {
      map['current_revision'] = Variable<int>(currentRevision.value);
    }
    if (amendmentReason.present) {
      map['amendment_reason'] = Variable<String>(amendmentReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedVisitsCompanion(')
          ..write('id: $id, ')
          ..write('clinicId: $clinicId, ')
          ..write('patientId: $patientId, ')
          ..write('appointmentId: $appointmentId, ')
          ..write('doctorId: $doctorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('notes: $notes, ')
          ..write('followUp: $followUp, ')
          ..write('completed: $completed, ')
          ..write('version: $version, ')
          ..write('currentRevision: $currentRevision, ')
          ..write('amendmentReason: $amendmentReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CachedDiagnoses extends Table
    with TableInfo<CachedDiagnoses, CachedDiagnose> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CachedDiagnoses(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES cached_visits(id)',
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [visitId, position, description];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_diagnoses';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedDiagnose> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {visitId, position};
  @override
  CachedDiagnose map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedDiagnose(
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
    );
  }

  @override
  CachedDiagnoses createAlias(String alias) {
    return CachedDiagnoses(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(visit_id, position)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class CachedDiagnose extends DataClass implements Insertable<CachedDiagnose> {
  final String visitId;
  final int position;
  final String description;
  const CachedDiagnose({
    required this.visitId,
    required this.position,
    required this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['visit_id'] = Variable<String>(visitId);
    map['position'] = Variable<int>(position);
    map['description'] = Variable<String>(description);
    return map;
  }

  CachedDiagnosesCompanion toCompanion(bool nullToAbsent) {
    return CachedDiagnosesCompanion(
      visitId: Value(visitId),
      position: Value(position),
      description: Value(description),
    );
  }

  factory CachedDiagnose.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedDiagnose(
      visitId: serializer.fromJson<String>(json['visit_id']),
      position: serializer.fromJson<int>(json['position']),
      description: serializer.fromJson<String>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'visit_id': serializer.toJson<String>(visitId),
      'position': serializer.toJson<int>(position),
      'description': serializer.toJson<String>(description),
    };
  }

  CachedDiagnose copyWith({
    String? visitId,
    int? position,
    String? description,
  }) => CachedDiagnose(
    visitId: visitId ?? this.visitId,
    position: position ?? this.position,
    description: description ?? this.description,
  );
  CachedDiagnose copyWithCompanion(CachedDiagnosesCompanion data) {
    return CachedDiagnose(
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      position: data.position.present ? data.position.value : this.position,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedDiagnose(')
          ..write('visitId: $visitId, ')
          ..write('position: $position, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(visitId, position, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedDiagnose &&
          other.visitId == this.visitId &&
          other.position == this.position &&
          other.description == this.description);
}

class CachedDiagnosesCompanion extends UpdateCompanion<CachedDiagnose> {
  final Value<String> visitId;
  final Value<int> position;
  final Value<String> description;
  final Value<int> rowid;
  const CachedDiagnosesCompanion({
    this.visitId = const Value.absent(),
    this.position = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedDiagnosesCompanion.insert({
    required String visitId,
    required int position,
    required String description,
    this.rowid = const Value.absent(),
  }) : visitId = Value(visitId),
       position = Value(position),
       description = Value(description);
  static Insertable<CachedDiagnose> custom({
    Expression<String>? visitId,
    Expression<int>? position,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (visitId != null) 'visit_id': visitId,
      if (position != null) 'position': position,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedDiagnosesCompanion copyWith({
    Value<String>? visitId,
    Value<int>? position,
    Value<String>? description,
    Value<int>? rowid,
  }) {
    return CachedDiagnosesCompanion(
      visitId: visitId ?? this.visitId,
      position: position ?? this.position,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedDiagnosesCompanion(')
          ..write('visitId: $visitId, ')
          ..write('position: $position, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CachedMedications extends Table
    with TableInfo<CachedMedications, CachedMedication> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CachedMedications(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES cached_visits(id)',
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _strengthMeta = const VerificationMeta(
    'strength',
  );
  late final GeneratedColumn<String> strength = GeneratedColumn<String>(
    'strength',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _doseMeta = const VerificationMeta('dose');
  late final GeneratedColumn<String> dose = GeneratedColumn<String>(
    'dose',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  late final GeneratedColumn<String> duration = GeneratedColumn<String>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _instructionsMeta = const VerificationMeta(
    'instructions',
  );
  late final GeneratedColumn<String> instructions = GeneratedColumn<String>(
    'instructions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    visitId,
    position,
    name,
    strength,
    dose,
    frequency,
    duration,
    instructions,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_medications';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedMedication> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('strength')) {
      context.handle(
        _strengthMeta,
        strength.isAcceptableOrUnknown(data['strength']!, _strengthMeta),
      );
    }
    if (data.containsKey('dose')) {
      context.handle(
        _doseMeta,
        dose.isAcceptableOrUnknown(data['dose']!, _doseMeta),
      );
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('instructions')) {
      context.handle(
        _instructionsMeta,
        instructions.isAcceptableOrUnknown(
          data['instructions']!,
          _instructionsMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedMedication map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMedication(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      strength: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strength'],
      )!,
      dose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dose'],
      )!,
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}duration'],
      )!,
      instructions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instructions'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
    );
  }

  @override
  CachedMedications createAlias(String alias) {
    return CachedMedications(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CachedMedication extends DataClass
    implements Insertable<CachedMedication> {
  final String id;
  final String visitId;
  final int position;
  final String name;
  final String strength;
  final String dose;
  final String frequency;
  final String duration;
  final String instructions;
  final String notes;
  const CachedMedication({
    required this.id,
    required this.visitId,
    required this.position,
    required this.name,
    required this.strength,
    required this.dose,
    required this.frequency,
    required this.duration,
    required this.instructions,
    required this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['visit_id'] = Variable<String>(visitId);
    map['position'] = Variable<int>(position);
    map['name'] = Variable<String>(name);
    map['strength'] = Variable<String>(strength);
    map['dose'] = Variable<String>(dose);
    map['frequency'] = Variable<String>(frequency);
    map['duration'] = Variable<String>(duration);
    map['instructions'] = Variable<String>(instructions);
    map['notes'] = Variable<String>(notes);
    return map;
  }

  CachedMedicationsCompanion toCompanion(bool nullToAbsent) {
    return CachedMedicationsCompanion(
      id: Value(id),
      visitId: Value(visitId),
      position: Value(position),
      name: Value(name),
      strength: Value(strength),
      dose: Value(dose),
      frequency: Value(frequency),
      duration: Value(duration),
      instructions: Value(instructions),
      notes: Value(notes),
    );
  }

  factory CachedMedication.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMedication(
      id: serializer.fromJson<String>(json['id']),
      visitId: serializer.fromJson<String>(json['visit_id']),
      position: serializer.fromJson<int>(json['position']),
      name: serializer.fromJson<String>(json['name']),
      strength: serializer.fromJson<String>(json['strength']),
      dose: serializer.fromJson<String>(json['dose']),
      frequency: serializer.fromJson<String>(json['frequency']),
      duration: serializer.fromJson<String>(json['duration']),
      instructions: serializer.fromJson<String>(json['instructions']),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'visit_id': serializer.toJson<String>(visitId),
      'position': serializer.toJson<int>(position),
      'name': serializer.toJson<String>(name),
      'strength': serializer.toJson<String>(strength),
      'dose': serializer.toJson<String>(dose),
      'frequency': serializer.toJson<String>(frequency),
      'duration': serializer.toJson<String>(duration),
      'instructions': serializer.toJson<String>(instructions),
      'notes': serializer.toJson<String>(notes),
    };
  }

  CachedMedication copyWith({
    String? id,
    String? visitId,
    int? position,
    String? name,
    String? strength,
    String? dose,
    String? frequency,
    String? duration,
    String? instructions,
    String? notes,
  }) => CachedMedication(
    id: id ?? this.id,
    visitId: visitId ?? this.visitId,
    position: position ?? this.position,
    name: name ?? this.name,
    strength: strength ?? this.strength,
    dose: dose ?? this.dose,
    frequency: frequency ?? this.frequency,
    duration: duration ?? this.duration,
    instructions: instructions ?? this.instructions,
    notes: notes ?? this.notes,
  );
  CachedMedication copyWithCompanion(CachedMedicationsCompanion data) {
    return CachedMedication(
      id: data.id.present ? data.id.value : this.id,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      position: data.position.present ? data.position.value : this.position,
      name: data.name.present ? data.name.value : this.name,
      strength: data.strength.present ? data.strength.value : this.strength,
      dose: data.dose.present ? data.dose.value : this.dose,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      duration: data.duration.present ? data.duration.value : this.duration,
      instructions: data.instructions.present
          ? data.instructions.value
          : this.instructions,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMedication(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('strength: $strength, ')
          ..write('dose: $dose, ')
          ..write('frequency: $frequency, ')
          ..write('duration: $duration, ')
          ..write('instructions: $instructions, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    visitId,
    position,
    name,
    strength,
    dose,
    frequency,
    duration,
    instructions,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMedication &&
          other.id == this.id &&
          other.visitId == this.visitId &&
          other.position == this.position &&
          other.name == this.name &&
          other.strength == this.strength &&
          other.dose == this.dose &&
          other.frequency == this.frequency &&
          other.duration == this.duration &&
          other.instructions == this.instructions &&
          other.notes == this.notes);
}

class CachedMedicationsCompanion extends UpdateCompanion<CachedMedication> {
  final Value<String> id;
  final Value<String> visitId;
  final Value<int> position;
  final Value<String> name;
  final Value<String> strength;
  final Value<String> dose;
  final Value<String> frequency;
  final Value<String> duration;
  final Value<String> instructions;
  final Value<String> notes;
  final Value<int> rowid;
  const CachedMedicationsCompanion({
    this.id = const Value.absent(),
    this.visitId = const Value.absent(),
    this.position = const Value.absent(),
    this.name = const Value.absent(),
    this.strength = const Value.absent(),
    this.dose = const Value.absent(),
    this.frequency = const Value.absent(),
    this.duration = const Value.absent(),
    this.instructions = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedMedicationsCompanion.insert({
    required String id,
    required String visitId,
    required int position,
    required String name,
    this.strength = const Value.absent(),
    this.dose = const Value.absent(),
    this.frequency = const Value.absent(),
    this.duration = const Value.absent(),
    this.instructions = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       visitId = Value(visitId),
       position = Value(position),
       name = Value(name);
  static Insertable<CachedMedication> custom({
    Expression<String>? id,
    Expression<String>? visitId,
    Expression<int>? position,
    Expression<String>? name,
    Expression<String>? strength,
    Expression<String>? dose,
    Expression<String>? frequency,
    Expression<String>? duration,
    Expression<String>? instructions,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (visitId != null) 'visit_id': visitId,
      if (position != null) 'position': position,
      if (name != null) 'name': name,
      if (strength != null) 'strength': strength,
      if (dose != null) 'dose': dose,
      if (frequency != null) 'frequency': frequency,
      if (duration != null) 'duration': duration,
      if (instructions != null) 'instructions': instructions,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedMedicationsCompanion copyWith({
    Value<String>? id,
    Value<String>? visitId,
    Value<int>? position,
    Value<String>? name,
    Value<String>? strength,
    Value<String>? dose,
    Value<String>? frequency,
    Value<String>? duration,
    Value<String>? instructions,
    Value<String>? notes,
    Value<int>? rowid,
  }) {
    return CachedMedicationsCompanion(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      position: position ?? this.position,
      name: name ?? this.name,
      strength: strength ?? this.strength,
      dose: dose ?? this.dose,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      instructions: instructions ?? this.instructions,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (strength.present) {
      map['strength'] = Variable<String>(strength.value);
    }
    if (dose.present) {
      map['dose'] = Variable<String>(dose.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (duration.present) {
      map['duration'] = Variable<String>(duration.value);
    }
    if (instructions.present) {
      map['instructions'] = Variable<String>(instructions.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMedicationsCompanion(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('strength: $strength, ')
          ..write('dose: $dose, ')
          ..write('frequency: $frequency, ')
          ..write('duration: $duration, ')
          ..write('instructions: $instructions, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Outbox extends Table with TableInfo<Outbox, OutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Outbox(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _clinicIdMeta = const VerificationMeta(
    'clinicId',
  );
  late final GeneratedColumn<String> clinicId = GeneratedColumn<String>(
    'clinic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _expectedVersionMeta = const VerificationMeta(
    'expectedVersion',
  );
  late final GeneratedColumn<int> expectedVersion = GeneratedColumn<int>(
    'expected_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'pending\'',
    defaultValue: const CustomExpression('\'pending\''),
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _remoteValueMeta = const VerificationMeta(
    'remoteValue',
  );
  late final GeneratedColumn<String> remoteValue = GeneratedColumn<String>(
    'remote_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    sequence,
    operationId,
    clinicId,
    entityType,
    entityId,
    action,
    payload,
    expectedVersion,
    state,
    error,
    remoteValue,
    attempts,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    }
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('clinic_id')) {
      context.handle(
        _clinicIdMeta,
        clinicId.isAcceptableOrUnknown(data['clinic_id']!, _clinicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clinicIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('expected_version')) {
      context.handle(
        _expectedVersionMeta,
        expectedVersion.isAcceptableOrUnknown(
          data['expected_version']!,
          _expectedVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expectedVersionMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('remote_value')) {
      context.handle(
        _remoteValueMeta,
        remoteValue.isAcceptableOrUnknown(
          data['remote_value']!,
          _remoteValueMeta,
        ),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sequence};
  @override
  OutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxData(
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      clinicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clinic_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      expectedVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_version'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      remoteValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_value'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  Outbox createAlias(String alias) {
    return Outbox(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class OutboxData extends DataClass implements Insertable<OutboxData> {
  final int sequence;
  final String operationId;
  final String clinicId;
  final String entityType;
  final String entityId;
  final String action;
  final String payload;
  final int expectedVersion;
  final String state;
  final String? error;
  final String? remoteValue;
  final int attempts;
  final String createdAt;
  const OutboxData({
    required this.sequence,
    required this.operationId,
    required this.clinicId,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payload,
    required this.expectedVersion,
    required this.state,
    this.error,
    this.remoteValue,
    required this.attempts,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sequence'] = Variable<int>(sequence);
    map['operation_id'] = Variable<String>(operationId);
    map['clinic_id'] = Variable<String>(clinicId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['action'] = Variable<String>(action);
    map['payload'] = Variable<String>(payload);
    map['expected_version'] = Variable<int>(expectedVersion);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    if (!nullToAbsent || remoteValue != null) {
      map['remote_value'] = Variable<String>(remoteValue);
    }
    map['attempts'] = Variable<int>(attempts);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      sequence: Value(sequence),
      operationId: Value(operationId),
      clinicId: Value(clinicId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      action: Value(action),
      payload: Value(payload),
      expectedVersion: Value(expectedVersion),
      state: Value(state),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      remoteValue: remoteValue == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteValue),
      attempts: Value(attempts),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxData(
      sequence: serializer.fromJson<int>(json['sequence']),
      operationId: serializer.fromJson<String>(json['operation_id']),
      clinicId: serializer.fromJson<String>(json['clinic_id']),
      entityType: serializer.fromJson<String>(json['entity_type']),
      entityId: serializer.fromJson<String>(json['entity_id']),
      action: serializer.fromJson<String>(json['action']),
      payload: serializer.fromJson<String>(json['payload']),
      expectedVersion: serializer.fromJson<int>(json['expected_version']),
      state: serializer.fromJson<String>(json['state']),
      error: serializer.fromJson<String?>(json['error']),
      remoteValue: serializer.fromJson<String?>(json['remote_value']),
      attempts: serializer.fromJson<int>(json['attempts']),
      createdAt: serializer.fromJson<String>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sequence': serializer.toJson<int>(sequence),
      'operation_id': serializer.toJson<String>(operationId),
      'clinic_id': serializer.toJson<String>(clinicId),
      'entity_type': serializer.toJson<String>(entityType),
      'entity_id': serializer.toJson<String>(entityId),
      'action': serializer.toJson<String>(action),
      'payload': serializer.toJson<String>(payload),
      'expected_version': serializer.toJson<int>(expectedVersion),
      'state': serializer.toJson<String>(state),
      'error': serializer.toJson<String?>(error),
      'remote_value': serializer.toJson<String?>(remoteValue),
      'attempts': serializer.toJson<int>(attempts),
      'created_at': serializer.toJson<String>(createdAt),
    };
  }

  OutboxData copyWith({
    int? sequence,
    String? operationId,
    String? clinicId,
    String? entityType,
    String? entityId,
    String? action,
    String? payload,
    int? expectedVersion,
    String? state,
    Value<String?> error = const Value.absent(),
    Value<String?> remoteValue = const Value.absent(),
    int? attempts,
    String? createdAt,
  }) => OutboxData(
    sequence: sequence ?? this.sequence,
    operationId: operationId ?? this.operationId,
    clinicId: clinicId ?? this.clinicId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    action: action ?? this.action,
    payload: payload ?? this.payload,
    expectedVersion: expectedVersion ?? this.expectedVersion,
    state: state ?? this.state,
    error: error.present ? error.value : this.error,
    remoteValue: remoteValue.present ? remoteValue.value : this.remoteValue,
    attempts: attempts ?? this.attempts,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxData copyWithCompanion(OutboxCompanion data) {
    return OutboxData(
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      clinicId: data.clinicId.present ? data.clinicId.value : this.clinicId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      action: data.action.present ? data.action.value : this.action,
      payload: data.payload.present ? data.payload.value : this.payload,
      expectedVersion: data.expectedVersion.present
          ? data.expectedVersion.value
          : this.expectedVersion,
      state: data.state.present ? data.state.value : this.state,
      error: data.error.present ? data.error.value : this.error,
      remoteValue: data.remoteValue.present
          ? data.remoteValue.value
          : this.remoteValue,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxData(')
          ..write('sequence: $sequence, ')
          ..write('operationId: $operationId, ')
          ..write('clinicId: $clinicId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('expectedVersion: $expectedVersion, ')
          ..write('state: $state, ')
          ..write('error: $error, ')
          ..write('remoteValue: $remoteValue, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sequence,
    operationId,
    clinicId,
    entityType,
    entityId,
    action,
    payload,
    expectedVersion,
    state,
    error,
    remoteValue,
    attempts,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxData &&
          other.sequence == this.sequence &&
          other.operationId == this.operationId &&
          other.clinicId == this.clinicId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.action == this.action &&
          other.payload == this.payload &&
          other.expectedVersion == this.expectedVersion &&
          other.state == this.state &&
          other.error == this.error &&
          other.remoteValue == this.remoteValue &&
          other.attempts == this.attempts &&
          other.createdAt == this.createdAt);
}

class OutboxCompanion extends UpdateCompanion<OutboxData> {
  final Value<int> sequence;
  final Value<String> operationId;
  final Value<String> clinicId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> action;
  final Value<String> payload;
  final Value<int> expectedVersion;
  final Value<String> state;
  final Value<String?> error;
  final Value<String?> remoteValue;
  final Value<int> attempts;
  final Value<String> createdAt;
  const OutboxCompanion({
    this.sequence = const Value.absent(),
    this.operationId = const Value.absent(),
    this.clinicId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.action = const Value.absent(),
    this.payload = const Value.absent(),
    this.expectedVersion = const Value.absent(),
    this.state = const Value.absent(),
    this.error = const Value.absent(),
    this.remoteValue = const Value.absent(),
    this.attempts = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OutboxCompanion.insert({
    this.sequence = const Value.absent(),
    required String operationId,
    required String clinicId,
    required String entityType,
    required String entityId,
    required String action,
    required String payload,
    required int expectedVersion,
    this.state = const Value.absent(),
    this.error = const Value.absent(),
    this.remoteValue = const Value.absent(),
    this.attempts = const Value.absent(),
    required String createdAt,
  }) : operationId = Value(operationId),
       clinicId = Value(clinicId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       action = Value(action),
       payload = Value(payload),
       expectedVersion = Value(expectedVersion),
       createdAt = Value(createdAt);
  static Insertable<OutboxData> custom({
    Expression<int>? sequence,
    Expression<String>? operationId,
    Expression<String>? clinicId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? action,
    Expression<String>? payload,
    Expression<int>? expectedVersion,
    Expression<String>? state,
    Expression<String>? error,
    Expression<String>? remoteValue,
    Expression<int>? attempts,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (sequence != null) 'sequence': sequence,
      if (operationId != null) 'operation_id': operationId,
      if (clinicId != null) 'clinic_id': clinicId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (action != null) 'action': action,
      if (payload != null) 'payload': payload,
      if (expectedVersion != null) 'expected_version': expectedVersion,
      if (state != null) 'state': state,
      if (error != null) 'error': error,
      if (remoteValue != null) 'remote_value': remoteValue,
      if (attempts != null) 'attempts': attempts,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OutboxCompanion copyWith({
    Value<int>? sequence,
    Value<String>? operationId,
    Value<String>? clinicId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? action,
    Value<String>? payload,
    Value<int>? expectedVersion,
    Value<String>? state,
    Value<String?>? error,
    Value<String?>? remoteValue,
    Value<int>? attempts,
    Value<String>? createdAt,
  }) {
    return OutboxCompanion(
      sequence: sequence ?? this.sequence,
      operationId: operationId ?? this.operationId,
      clinicId: clinicId ?? this.clinicId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      expectedVersion: expectedVersion ?? this.expectedVersion,
      state: state ?? this.state,
      error: error ?? this.error,
      remoteValue: remoteValue ?? this.remoteValue,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (clinicId.present) {
      map['clinic_id'] = Variable<String>(clinicId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (expectedVersion.present) {
      map['expected_version'] = Variable<int>(expectedVersion.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (remoteValue.present) {
      map['remote_value'] = Variable<String>(remoteValue.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('sequence: $sequence, ')
          ..write('operationId: $operationId, ')
          ..write('clinicId: $clinicId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('expectedVersion: $expectedVersion, ')
          ..write('state: $state, ')
          ..write('error: $error, ')
          ..write('remoteValue: $remoteValue, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class CacheMetadata extends Table
    with TableInfo<CacheMetadata, CacheMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CacheMetadata(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  CacheMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheMetadataData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  CacheMetadata createAlias(String alias) {
    return CacheMetadata(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CacheMetadataData extends DataClass
    implements Insertable<CacheMetadataData> {
  final String key;
  final String value;
  const CacheMetadataData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  CacheMetadataCompanion toCompanion(bool nullToAbsent) {
    return CacheMetadataCompanion(key: Value(key), value: Value(value));
  }

  factory CacheMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheMetadataData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  CacheMetadataData copyWith({String? key, String? value}) =>
      CacheMetadataData(key: key ?? this.key, value: value ?? this.value);
  CacheMetadataData copyWithCompanion(CacheMetadataCompanion data) {
    return CacheMetadataData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheMetadataData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheMetadataData &&
          other.key == this.key &&
          other.value == this.value);
}

class CacheMetadataCompanion extends UpdateCompanion<CacheMetadataData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const CacheMetadataCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheMetadataCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<CacheMetadataData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheMetadataCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return CacheMetadataCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheMetadataCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncResolutions extends Table
    with TableInfo<SyncResolutions, SyncResolution> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncResolutions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _clinicIdMeta = const VerificationMeta(
    'clinicId',
  );
  late final GeneratedColumn<String> clinicId = GeneratedColumn<String>(
    'clinic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  late final GeneratedColumn<String> resolvedAt = GeneratedColumn<String>(
    'resolved_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _choiceMeta = const VerificationMeta('choice');
  late final GeneratedColumn<String> choice = GeneratedColumn<String>(
    'choice',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _originalOperationsMeta =
      const VerificationMeta('originalOperations');
  late final GeneratedColumn<String> originalOperations =
      GeneratedColumn<String>(
        'original_operations',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  static const VerificationMeta _localValueMeta = const VerificationMeta(
    'localValue',
  );
  late final GeneratedColumn<String> localValue = GeneratedColumn<String>(
    'local_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _remoteValueMeta = const VerificationMeta(
    'remoteValue',
  );
  late final GeneratedColumn<String> remoteValue = GeneratedColumn<String>(
    'remote_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _resolvedValueMeta = const VerificationMeta(
    'resolvedValue',
  );
  late final GeneratedColumn<String> resolvedValue = GeneratedColumn<String>(
    'resolved_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _replacementOperationIdMeta =
      const VerificationMeta('replacementOperationId');
  late final GeneratedColumn<String> replacementOperationId =
      GeneratedColumn<String>(
        'replacement_operation_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clinicId,
    userId,
    entityId,
    resolvedAt,
    choice,
    originalOperations,
    localValue,
    remoteValue,
    resolvedValue,
    replacementOperationId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_resolutions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncResolution> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('clinic_id')) {
      context.handle(
        _clinicIdMeta,
        clinicId.isAcceptableOrUnknown(data['clinic_id']!, _clinicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clinicIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_resolvedAtMeta);
    }
    if (data.containsKey('choice')) {
      context.handle(
        _choiceMeta,
        choice.isAcceptableOrUnknown(data['choice']!, _choiceMeta),
      );
    } else if (isInserting) {
      context.missing(_choiceMeta);
    }
    if (data.containsKey('original_operations')) {
      context.handle(
        _originalOperationsMeta,
        originalOperations.isAcceptableOrUnknown(
          data['original_operations']!,
          _originalOperationsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalOperationsMeta);
    }
    if (data.containsKey('local_value')) {
      context.handle(
        _localValueMeta,
        localValue.isAcceptableOrUnknown(data['local_value']!, _localValueMeta),
      );
    } else if (isInserting) {
      context.missing(_localValueMeta);
    }
    if (data.containsKey('remote_value')) {
      context.handle(
        _remoteValueMeta,
        remoteValue.isAcceptableOrUnknown(
          data['remote_value']!,
          _remoteValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remoteValueMeta);
    }
    if (data.containsKey('resolved_value')) {
      context.handle(
        _resolvedValueMeta,
        resolvedValue.isAcceptableOrUnknown(
          data['resolved_value']!,
          _resolvedValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resolvedValueMeta);
    }
    if (data.containsKey('replacement_operation_id')) {
      context.handle(
        _replacementOperationIdMeta,
        replacementOperationId.isAcceptableOrUnknown(
          data['replacement_operation_id']!,
          _replacementOperationIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncResolution map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncResolution(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clinicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clinic_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolved_at'],
      )!,
      choice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}choice'],
      )!,
      originalOperations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_operations'],
      )!,
      localValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_value'],
      )!,
      remoteValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_value'],
      )!,
      resolvedValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolved_value'],
      )!,
      replacementOperationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}replacement_operation_id'],
      ),
    );
  }

  @override
  SyncResolutions createAlias(String alias) {
    return SyncResolutions(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SyncResolution extends DataClass implements Insertable<SyncResolution> {
  final String id;
  final String clinicId;
  final String userId;
  final String entityId;
  final String resolvedAt;
  final String choice;
  final String originalOperations;
  final String localValue;
  final String remoteValue;
  final String resolvedValue;
  final String? replacementOperationId;
  const SyncResolution({
    required this.id,
    required this.clinicId,
    required this.userId,
    required this.entityId,
    required this.resolvedAt,
    required this.choice,
    required this.originalOperations,
    required this.localValue,
    required this.remoteValue,
    required this.resolvedValue,
    this.replacementOperationId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['clinic_id'] = Variable<String>(clinicId);
    map['user_id'] = Variable<String>(userId);
    map['entity_id'] = Variable<String>(entityId);
    map['resolved_at'] = Variable<String>(resolvedAt);
    map['choice'] = Variable<String>(choice);
    map['original_operations'] = Variable<String>(originalOperations);
    map['local_value'] = Variable<String>(localValue);
    map['remote_value'] = Variable<String>(remoteValue);
    map['resolved_value'] = Variable<String>(resolvedValue);
    if (!nullToAbsent || replacementOperationId != null) {
      map['replacement_operation_id'] = Variable<String>(
        replacementOperationId,
      );
    }
    return map;
  }

  SyncResolutionsCompanion toCompanion(bool nullToAbsent) {
    return SyncResolutionsCompanion(
      id: Value(id),
      clinicId: Value(clinicId),
      userId: Value(userId),
      entityId: Value(entityId),
      resolvedAt: Value(resolvedAt),
      choice: Value(choice),
      originalOperations: Value(originalOperations),
      localValue: Value(localValue),
      remoteValue: Value(remoteValue),
      resolvedValue: Value(resolvedValue),
      replacementOperationId: replacementOperationId == null && nullToAbsent
          ? const Value.absent()
          : Value(replacementOperationId),
    );
  }

  factory SyncResolution.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncResolution(
      id: serializer.fromJson<String>(json['id']),
      clinicId: serializer.fromJson<String>(json['clinic_id']),
      userId: serializer.fromJson<String>(json['user_id']),
      entityId: serializer.fromJson<String>(json['entity_id']),
      resolvedAt: serializer.fromJson<String>(json['resolved_at']),
      choice: serializer.fromJson<String>(json['choice']),
      originalOperations: serializer.fromJson<String>(
        json['original_operations'],
      ),
      localValue: serializer.fromJson<String>(json['local_value']),
      remoteValue: serializer.fromJson<String>(json['remote_value']),
      resolvedValue: serializer.fromJson<String>(json['resolved_value']),
      replacementOperationId: serializer.fromJson<String?>(
        json['replacement_operation_id'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clinic_id': serializer.toJson<String>(clinicId),
      'user_id': serializer.toJson<String>(userId),
      'entity_id': serializer.toJson<String>(entityId),
      'resolved_at': serializer.toJson<String>(resolvedAt),
      'choice': serializer.toJson<String>(choice),
      'original_operations': serializer.toJson<String>(originalOperations),
      'local_value': serializer.toJson<String>(localValue),
      'remote_value': serializer.toJson<String>(remoteValue),
      'resolved_value': serializer.toJson<String>(resolvedValue),
      'replacement_operation_id': serializer.toJson<String?>(
        replacementOperationId,
      ),
    };
  }

  SyncResolution copyWith({
    String? id,
    String? clinicId,
    String? userId,
    String? entityId,
    String? resolvedAt,
    String? choice,
    String? originalOperations,
    String? localValue,
    String? remoteValue,
    String? resolvedValue,
    Value<String?> replacementOperationId = const Value.absent(),
  }) => SyncResolution(
    id: id ?? this.id,
    clinicId: clinicId ?? this.clinicId,
    userId: userId ?? this.userId,
    entityId: entityId ?? this.entityId,
    resolvedAt: resolvedAt ?? this.resolvedAt,
    choice: choice ?? this.choice,
    originalOperations: originalOperations ?? this.originalOperations,
    localValue: localValue ?? this.localValue,
    remoteValue: remoteValue ?? this.remoteValue,
    resolvedValue: resolvedValue ?? this.resolvedValue,
    replacementOperationId: replacementOperationId.present
        ? replacementOperationId.value
        : this.replacementOperationId,
  );
  SyncResolution copyWithCompanion(SyncResolutionsCompanion data) {
    return SyncResolution(
      id: data.id.present ? data.id.value : this.id,
      clinicId: data.clinicId.present ? data.clinicId.value : this.clinicId,
      userId: data.userId.present ? data.userId.value : this.userId,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
      choice: data.choice.present ? data.choice.value : this.choice,
      originalOperations: data.originalOperations.present
          ? data.originalOperations.value
          : this.originalOperations,
      localValue: data.localValue.present
          ? data.localValue.value
          : this.localValue,
      remoteValue: data.remoteValue.present
          ? data.remoteValue.value
          : this.remoteValue,
      resolvedValue: data.resolvedValue.present
          ? data.resolvedValue.value
          : this.resolvedValue,
      replacementOperationId: data.replacementOperationId.present
          ? data.replacementOperationId.value
          : this.replacementOperationId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncResolution(')
          ..write('id: $id, ')
          ..write('clinicId: $clinicId, ')
          ..write('userId: $userId, ')
          ..write('entityId: $entityId, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('choice: $choice, ')
          ..write('originalOperations: $originalOperations, ')
          ..write('localValue: $localValue, ')
          ..write('remoteValue: $remoteValue, ')
          ..write('resolvedValue: $resolvedValue, ')
          ..write('replacementOperationId: $replacementOperationId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clinicId,
    userId,
    entityId,
    resolvedAt,
    choice,
    originalOperations,
    localValue,
    remoteValue,
    resolvedValue,
    replacementOperationId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncResolution &&
          other.id == this.id &&
          other.clinicId == this.clinicId &&
          other.userId == this.userId &&
          other.entityId == this.entityId &&
          other.resolvedAt == this.resolvedAt &&
          other.choice == this.choice &&
          other.originalOperations == this.originalOperations &&
          other.localValue == this.localValue &&
          other.remoteValue == this.remoteValue &&
          other.resolvedValue == this.resolvedValue &&
          other.replacementOperationId == this.replacementOperationId);
}

class SyncResolutionsCompanion extends UpdateCompanion<SyncResolution> {
  final Value<String> id;
  final Value<String> clinicId;
  final Value<String> userId;
  final Value<String> entityId;
  final Value<String> resolvedAt;
  final Value<String> choice;
  final Value<String> originalOperations;
  final Value<String> localValue;
  final Value<String> remoteValue;
  final Value<String> resolvedValue;
  final Value<String?> replacementOperationId;
  final Value<int> rowid;
  const SyncResolutionsCompanion({
    this.id = const Value.absent(),
    this.clinicId = const Value.absent(),
    this.userId = const Value.absent(),
    this.entityId = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.choice = const Value.absent(),
    this.originalOperations = const Value.absent(),
    this.localValue = const Value.absent(),
    this.remoteValue = const Value.absent(),
    this.resolvedValue = const Value.absent(),
    this.replacementOperationId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncResolutionsCompanion.insert({
    required String id,
    required String clinicId,
    required String userId,
    required String entityId,
    required String resolvedAt,
    required String choice,
    required String originalOperations,
    required String localValue,
    required String remoteValue,
    required String resolvedValue,
    this.replacementOperationId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clinicId = Value(clinicId),
       userId = Value(userId),
       entityId = Value(entityId),
       resolvedAt = Value(resolvedAt),
       choice = Value(choice),
       originalOperations = Value(originalOperations),
       localValue = Value(localValue),
       remoteValue = Value(remoteValue),
       resolvedValue = Value(resolvedValue);
  static Insertable<SyncResolution> custom({
    Expression<String>? id,
    Expression<String>? clinicId,
    Expression<String>? userId,
    Expression<String>? entityId,
    Expression<String>? resolvedAt,
    Expression<String>? choice,
    Expression<String>? originalOperations,
    Expression<String>? localValue,
    Expression<String>? remoteValue,
    Expression<String>? resolvedValue,
    Expression<String>? replacementOperationId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clinicId != null) 'clinic_id': clinicId,
      if (userId != null) 'user_id': userId,
      if (entityId != null) 'entity_id': entityId,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (choice != null) 'choice': choice,
      if (originalOperations != null) 'original_operations': originalOperations,
      if (localValue != null) 'local_value': localValue,
      if (remoteValue != null) 'remote_value': remoteValue,
      if (resolvedValue != null) 'resolved_value': resolvedValue,
      if (replacementOperationId != null)
        'replacement_operation_id': replacementOperationId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncResolutionsCompanion copyWith({
    Value<String>? id,
    Value<String>? clinicId,
    Value<String>? userId,
    Value<String>? entityId,
    Value<String>? resolvedAt,
    Value<String>? choice,
    Value<String>? originalOperations,
    Value<String>? localValue,
    Value<String>? remoteValue,
    Value<String>? resolvedValue,
    Value<String?>? replacementOperationId,
    Value<int>? rowid,
  }) {
    return SyncResolutionsCompanion(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      userId: userId ?? this.userId,
      entityId: entityId ?? this.entityId,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      choice: choice ?? this.choice,
      originalOperations: originalOperations ?? this.originalOperations,
      localValue: localValue ?? this.localValue,
      remoteValue: remoteValue ?? this.remoteValue,
      resolvedValue: resolvedValue ?? this.resolvedValue,
      replacementOperationId:
          replacementOperationId ?? this.replacementOperationId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clinicId.present) {
      map['clinic_id'] = Variable<String>(clinicId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<String>(resolvedAt.value);
    }
    if (choice.present) {
      map['choice'] = Variable<String>(choice.value);
    }
    if (originalOperations.present) {
      map['original_operations'] = Variable<String>(originalOperations.value);
    }
    if (localValue.present) {
      map['local_value'] = Variable<String>(localValue.value);
    }
    if (remoteValue.present) {
      map['remote_value'] = Variable<String>(remoteValue.value);
    }
    if (resolvedValue.present) {
      map['resolved_value'] = Variable<String>(resolvedValue.value);
    }
    if (replacementOperationId.present) {
      map['replacement_operation_id'] = Variable<String>(
        replacementOperationId.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncResolutionsCompanion(')
          ..write('id: $id, ')
          ..write('clinicId: $clinicId, ')
          ..write('userId: $userId, ')
          ..write('entityId: $entityId, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('choice: $choice, ')
          ..write('originalOperations: $originalOperations, ')
          ..write('localValue: $localValue, ')
          ..write('remoteValue: $remoteValue, ')
          ..write('resolvedValue: $resolvedValue, ')
          ..write('replacementOperationId: $replacementOperationId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CachedDocuments extends Table
    with TableInfo<CachedDocuments, CachedDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CachedDocuments(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _clinicIdMeta = const VerificationMeta(
    'clinicId',
  );
  late final GeneratedColumn<String> clinicId = GeneratedColumn<String>(
    'clinic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES cached_patients(id)',
  );
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES cached_visits(id)',
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _objectPathMeta = const VerificationMeta(
    'objectPath',
  );
  late final GeneratedColumn<String> objectPath = GeneratedColumn<String>(
    'object_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sha256HexMeta = const VerificationMeta(
    'sha256Hex',
  );
  late final GeneratedColumn<String> sha256Hex = GeneratedColumn<String>(
    'sha256_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _clinicalMeta = const VerificationMeta(
    'clinical',
  );
  late final GeneratedColumn<int> clinical = GeneratedColumn<int>(
    'clinical',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _uploadedByMeta = const VerificationMeta(
    'uploadedBy',
  );
  late final GeneratedColumn<String> uploadedBy = GeneratedColumn<String>(
    'uploaded_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clinicId,
    patientId,
    visitId,
    fileName,
    contentType,
    category,
    notes,
    objectPath,
    bytes,
    sha256Hex,
    clinical,
    state,
    uploadedBy,
    createdAt,
    updatedAt,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedDocument> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('clinic_id')) {
      context.handle(
        _clinicIdMeta,
        clinicId.isAcceptableOrUnknown(data['clinic_id']!, _clinicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clinicIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentTypeMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('object_path')) {
      context.handle(
        _objectPathMeta,
        objectPath.isAcceptableOrUnknown(data['object_path']!, _objectPathMeta),
      );
    } else if (isInserting) {
      context.missing(_objectPathMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    if (data.containsKey('sha256_hex')) {
      context.handle(
        _sha256HexMeta,
        sha256Hex.isAcceptableOrUnknown(data['sha256_hex']!, _sha256HexMeta),
      );
    } else if (isInserting) {
      context.missing(_sha256HexMeta);
    }
    if (data.containsKey('clinical')) {
      context.handle(
        _clinicalMeta,
        clinical.isAcceptableOrUnknown(data['clinical']!, _clinicalMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('uploaded_by')) {
      context.handle(
        _uploadedByMeta,
        uploadedBy.isAcceptableOrUnknown(data['uploaded_by']!, _uploadedByMeta),
      );
    } else if (isInserting) {
      context.missing(_uploadedByMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedDocument(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clinicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clinic_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      ),
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      objectPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}object_path'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes'],
      )!,
      sha256Hex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256_hex'],
      )!,
      clinical: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}clinical'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      uploadedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uploaded_by'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  CachedDocuments createAlias(String alias) {
    return CachedDocuments(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CachedDocument extends DataClass implements Insertable<CachedDocument> {
  final String id;
  final String clinicId;
  final String patientId;
  final String? visitId;
  final String fileName;
  final String contentType;
  final String category;
  final String notes;
  final String objectPath;
  final int bytes;
  final String sha256Hex;
  final int clinical;
  final String state;
  final String uploadedBy;
  final String createdAt;
  final String updatedAt;
  final int version;
  const CachedDocument({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.visitId,
    required this.fileName,
    required this.contentType,
    required this.category,
    required this.notes,
    required this.objectPath,
    required this.bytes,
    required this.sha256Hex,
    required this.clinical,
    required this.state,
    required this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['clinic_id'] = Variable<String>(clinicId);
    map['patient_id'] = Variable<String>(patientId);
    if (!nullToAbsent || visitId != null) {
      map['visit_id'] = Variable<String>(visitId);
    }
    map['file_name'] = Variable<String>(fileName);
    map['content_type'] = Variable<String>(contentType);
    map['category'] = Variable<String>(category);
    map['notes'] = Variable<String>(notes);
    map['object_path'] = Variable<String>(objectPath);
    map['bytes'] = Variable<int>(bytes);
    map['sha256_hex'] = Variable<String>(sha256Hex);
    map['clinical'] = Variable<int>(clinical);
    map['state'] = Variable<String>(state);
    map['uploaded_by'] = Variable<String>(uploadedBy);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['version'] = Variable<int>(version);
    return map;
  }

  CachedDocumentsCompanion toCompanion(bool nullToAbsent) {
    return CachedDocumentsCompanion(
      id: Value(id),
      clinicId: Value(clinicId),
      patientId: Value(patientId),
      visitId: visitId == null && nullToAbsent
          ? const Value.absent()
          : Value(visitId),
      fileName: Value(fileName),
      contentType: Value(contentType),
      category: Value(category),
      notes: Value(notes),
      objectPath: Value(objectPath),
      bytes: Value(bytes),
      sha256Hex: Value(sha256Hex),
      clinical: Value(clinical),
      state: Value(state),
      uploadedBy: Value(uploadedBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      version: Value(version),
    );
  }

  factory CachedDocument.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedDocument(
      id: serializer.fromJson<String>(json['id']),
      clinicId: serializer.fromJson<String>(json['clinic_id']),
      patientId: serializer.fromJson<String>(json['patient_id']),
      visitId: serializer.fromJson<String?>(json['visit_id']),
      fileName: serializer.fromJson<String>(json['file_name']),
      contentType: serializer.fromJson<String>(json['content_type']),
      category: serializer.fromJson<String>(json['category']),
      notes: serializer.fromJson<String>(json['notes']),
      objectPath: serializer.fromJson<String>(json['object_path']),
      bytes: serializer.fromJson<int>(json['bytes']),
      sha256Hex: serializer.fromJson<String>(json['sha256_hex']),
      clinical: serializer.fromJson<int>(json['clinical']),
      state: serializer.fromJson<String>(json['state']),
      uploadedBy: serializer.fromJson<String>(json['uploaded_by']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      updatedAt: serializer.fromJson<String>(json['updated_at']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clinic_id': serializer.toJson<String>(clinicId),
      'patient_id': serializer.toJson<String>(patientId),
      'visit_id': serializer.toJson<String?>(visitId),
      'file_name': serializer.toJson<String>(fileName),
      'content_type': serializer.toJson<String>(contentType),
      'category': serializer.toJson<String>(category),
      'notes': serializer.toJson<String>(notes),
      'object_path': serializer.toJson<String>(objectPath),
      'bytes': serializer.toJson<int>(bytes),
      'sha256_hex': serializer.toJson<String>(sha256Hex),
      'clinical': serializer.toJson<int>(clinical),
      'state': serializer.toJson<String>(state),
      'uploaded_by': serializer.toJson<String>(uploadedBy),
      'created_at': serializer.toJson<String>(createdAt),
      'updated_at': serializer.toJson<String>(updatedAt),
      'version': serializer.toJson<int>(version),
    };
  }

  CachedDocument copyWith({
    String? id,
    String? clinicId,
    String? patientId,
    Value<String?> visitId = const Value.absent(),
    String? fileName,
    String? contentType,
    String? category,
    String? notes,
    String? objectPath,
    int? bytes,
    String? sha256Hex,
    int? clinical,
    String? state,
    String? uploadedBy,
    String? createdAt,
    String? updatedAt,
    int? version,
  }) => CachedDocument(
    id: id ?? this.id,
    clinicId: clinicId ?? this.clinicId,
    patientId: patientId ?? this.patientId,
    visitId: visitId.present ? visitId.value : this.visitId,
    fileName: fileName ?? this.fileName,
    contentType: contentType ?? this.contentType,
    category: category ?? this.category,
    notes: notes ?? this.notes,
    objectPath: objectPath ?? this.objectPath,
    bytes: bytes ?? this.bytes,
    sha256Hex: sha256Hex ?? this.sha256Hex,
    clinical: clinical ?? this.clinical,
    state: state ?? this.state,
    uploadedBy: uploadedBy ?? this.uploadedBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
  );
  CachedDocument copyWithCompanion(CachedDocumentsCompanion data) {
    return CachedDocument(
      id: data.id.present ? data.id.value : this.id,
      clinicId: data.clinicId.present ? data.clinicId.value : this.clinicId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      category: data.category.present ? data.category.value : this.category,
      notes: data.notes.present ? data.notes.value : this.notes,
      objectPath: data.objectPath.present
          ? data.objectPath.value
          : this.objectPath,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      sha256Hex: data.sha256Hex.present ? data.sha256Hex.value : this.sha256Hex,
      clinical: data.clinical.present ? data.clinical.value : this.clinical,
      state: data.state.present ? data.state.value : this.state,
      uploadedBy: data.uploadedBy.present
          ? data.uploadedBy.value
          : this.uploadedBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedDocument(')
          ..write('id: $id, ')
          ..write('clinicId: $clinicId, ')
          ..write('patientId: $patientId, ')
          ..write('visitId: $visitId, ')
          ..write('fileName: $fileName, ')
          ..write('contentType: $contentType, ')
          ..write('category: $category, ')
          ..write('notes: $notes, ')
          ..write('objectPath: $objectPath, ')
          ..write('bytes: $bytes, ')
          ..write('sha256Hex: $sha256Hex, ')
          ..write('clinical: $clinical, ')
          ..write('state: $state, ')
          ..write('uploadedBy: $uploadedBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clinicId,
    patientId,
    visitId,
    fileName,
    contentType,
    category,
    notes,
    objectPath,
    bytes,
    sha256Hex,
    clinical,
    state,
    uploadedBy,
    createdAt,
    updatedAt,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedDocument &&
          other.id == this.id &&
          other.clinicId == this.clinicId &&
          other.patientId == this.patientId &&
          other.visitId == this.visitId &&
          other.fileName == this.fileName &&
          other.contentType == this.contentType &&
          other.category == this.category &&
          other.notes == this.notes &&
          other.objectPath == this.objectPath &&
          other.bytes == this.bytes &&
          other.sha256Hex == this.sha256Hex &&
          other.clinical == this.clinical &&
          other.state == this.state &&
          other.uploadedBy == this.uploadedBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version);
}

class CachedDocumentsCompanion extends UpdateCompanion<CachedDocument> {
  final Value<String> id;
  final Value<String> clinicId;
  final Value<String> patientId;
  final Value<String?> visitId;
  final Value<String> fileName;
  final Value<String> contentType;
  final Value<String> category;
  final Value<String> notes;
  final Value<String> objectPath;
  final Value<int> bytes;
  final Value<String> sha256Hex;
  final Value<int> clinical;
  final Value<String> state;
  final Value<String> uploadedBy;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> version;
  final Value<int> rowid;
  const CachedDocumentsCompanion({
    this.id = const Value.absent(),
    this.clinicId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.visitId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.contentType = const Value.absent(),
    this.category = const Value.absent(),
    this.notes = const Value.absent(),
    this.objectPath = const Value.absent(),
    this.bytes = const Value.absent(),
    this.sha256Hex = const Value.absent(),
    this.clinical = const Value.absent(),
    this.state = const Value.absent(),
    this.uploadedBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedDocumentsCompanion.insert({
    required String id,
    required String clinicId,
    required String patientId,
    this.visitId = const Value.absent(),
    required String fileName,
    required String contentType,
    required String category,
    this.notes = const Value.absent(),
    required String objectPath,
    required int bytes,
    required String sha256Hex,
    this.clinical = const Value.absent(),
    required String state,
    required String uploadedBy,
    required String createdAt,
    required String updatedAt,
    required int version,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clinicId = Value(clinicId),
       patientId = Value(patientId),
       fileName = Value(fileName),
       contentType = Value(contentType),
       category = Value(category),
       objectPath = Value(objectPath),
       bytes = Value(bytes),
       sha256Hex = Value(sha256Hex),
       state = Value(state),
       uploadedBy = Value(uploadedBy),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       version = Value(version);
  static Insertable<CachedDocument> custom({
    Expression<String>? id,
    Expression<String>? clinicId,
    Expression<String>? patientId,
    Expression<String>? visitId,
    Expression<String>? fileName,
    Expression<String>? contentType,
    Expression<String>? category,
    Expression<String>? notes,
    Expression<String>? objectPath,
    Expression<int>? bytes,
    Expression<String>? sha256Hex,
    Expression<int>? clinical,
    Expression<String>? state,
    Expression<String>? uploadedBy,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clinicId != null) 'clinic_id': clinicId,
      if (patientId != null) 'patient_id': patientId,
      if (visitId != null) 'visit_id': visitId,
      if (fileName != null) 'file_name': fileName,
      if (contentType != null) 'content_type': contentType,
      if (category != null) 'category': category,
      if (notes != null) 'notes': notes,
      if (objectPath != null) 'object_path': objectPath,
      if (bytes != null) 'bytes': bytes,
      if (sha256Hex != null) 'sha256_hex': sha256Hex,
      if (clinical != null) 'clinical': clinical,
      if (state != null) 'state': state,
      if (uploadedBy != null) 'uploaded_by': uploadedBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedDocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? clinicId,
    Value<String>? patientId,
    Value<String?>? visitId,
    Value<String>? fileName,
    Value<String>? contentType,
    Value<String>? category,
    Value<String>? notes,
    Value<String>? objectPath,
    Value<int>? bytes,
    Value<String>? sha256Hex,
    Value<int>? clinical,
    Value<String>? state,
    Value<String>? uploadedBy,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return CachedDocumentsCompanion(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      patientId: patientId ?? this.patientId,
      visitId: visitId ?? this.visitId,
      fileName: fileName ?? this.fileName,
      contentType: contentType ?? this.contentType,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      objectPath: objectPath ?? this.objectPath,
      bytes: bytes ?? this.bytes,
      sha256Hex: sha256Hex ?? this.sha256Hex,
      clinical: clinical ?? this.clinical,
      state: state ?? this.state,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clinicId.present) {
      map['clinic_id'] = Variable<String>(clinicId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (objectPath.present) {
      map['object_path'] = Variable<String>(objectPath.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (sha256Hex.present) {
      map['sha256_hex'] = Variable<String>(sha256Hex.value);
    }
    if (clinical.present) {
      map['clinical'] = Variable<int>(clinical.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (uploadedBy.present) {
      map['uploaded_by'] = Variable<String>(uploadedBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedDocumentsCompanion(')
          ..write('id: $id, ')
          ..write('clinicId: $clinicId, ')
          ..write('patientId: $patientId, ')
          ..write('visitId: $visitId, ')
          ..write('fileName: $fileName, ')
          ..write('contentType: $contentType, ')
          ..write('category: $category, ')
          ..write('notes: $notes, ')
          ..write('objectPath: $objectPath, ')
          ..write('bytes: $bytes, ')
          ..write('sha256Hex: $sha256Hex, ')
          ..write('clinical: $clinical, ')
          ..write('state: $state, ')
          ..write('uploadedBy: $uploadedBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DocumentBlobs extends Table with TableInfo<DocumentBlobs, DocumentBlob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DocumentBlobs(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attachmentIdMeta = const VerificationMeta(
    'attachmentId',
  );
  late final GeneratedColumn<String> attachmentId = GeneratedColumn<String>(
    'attachment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY REFERENCES cached_documents(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _clinicIdMeta = const VerificationMeta(
    'clinicId',
  );
  late final GeneratedColumn<String> clinicId = GeneratedColumn<String>(
    'clinic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  late final GeneratedColumn<Uint8List> data = GeneratedColumn<Uint8List>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sha256HexMeta = const VerificationMeta(
    'sha256Hex',
  );
  late final GeneratedColumn<String> sha256Hex = GeneratedColumn<String>(
    'sha256_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _transferStateMeta = const VerificationMeta(
    'transferState',
  );
  late final GeneratedColumn<String> transferState = GeneratedColumn<String>(
    'transfer_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'pending\'',
    defaultValue: const CustomExpression('\'pending\''),
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    attachmentId,
    clinicId,
    userId,
    data,
    sha256Hex,
    transferState,
    error,
    attempts,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'document_blobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentBlob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attachment_id')) {
      context.handle(
        _attachmentIdMeta,
        attachmentId.isAcceptableOrUnknown(
          data['attachment_id']!,
          _attachmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attachmentIdMeta);
    }
    if (data.containsKey('clinic_id')) {
      context.handle(
        _clinicIdMeta,
        clinicId.isAcceptableOrUnknown(data['clinic_id']!, _clinicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clinicIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('sha256_hex')) {
      context.handle(
        _sha256HexMeta,
        sha256Hex.isAcceptableOrUnknown(data['sha256_hex']!, _sha256HexMeta),
      );
    } else if (isInserting) {
      context.missing(_sha256HexMeta);
    }
    if (data.containsKey('transfer_state')) {
      context.handle(
        _transferStateMeta,
        transferState.isAcceptableOrUnknown(
          data['transfer_state']!,
          _transferStateMeta,
        ),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {attachmentId};
  @override
  DocumentBlob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentBlob(
      attachmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_id'],
      )!,
      clinicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clinic_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}data'],
      )!,
      sha256Hex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256_hex'],
      )!,
      transferState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_state'],
      )!,
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  DocumentBlobs createAlias(String alias) {
    return DocumentBlobs(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class DocumentBlob extends DataClass implements Insertable<DocumentBlob> {
  final String attachmentId;
  final String clinicId;
  final String userId;
  final Uint8List data;
  final String sha256Hex;
  final String transferState;
  final String? error;
  final int attempts;
  final String createdAt;
  final String updatedAt;
  const DocumentBlob({
    required this.attachmentId,
    required this.clinicId,
    required this.userId,
    required this.data,
    required this.sha256Hex,
    required this.transferState,
    this.error,
    required this.attempts,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attachment_id'] = Variable<String>(attachmentId);
    map['clinic_id'] = Variable<String>(clinicId);
    map['user_id'] = Variable<String>(userId);
    map['data'] = Variable<Uint8List>(data);
    map['sha256_hex'] = Variable<String>(sha256Hex);
    map['transfer_state'] = Variable<String>(transferState);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    map['attempts'] = Variable<int>(attempts);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  DocumentBlobsCompanion toCompanion(bool nullToAbsent) {
    return DocumentBlobsCompanion(
      attachmentId: Value(attachmentId),
      clinicId: Value(clinicId),
      userId: Value(userId),
      data: Value(data),
      sha256Hex: Value(sha256Hex),
      transferState: Value(transferState),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      attempts: Value(attempts),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DocumentBlob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentBlob(
      attachmentId: serializer.fromJson<String>(json['attachment_id']),
      clinicId: serializer.fromJson<String>(json['clinic_id']),
      userId: serializer.fromJson<String>(json['user_id']),
      data: serializer.fromJson<Uint8List>(json['data']),
      sha256Hex: serializer.fromJson<String>(json['sha256_hex']),
      transferState: serializer.fromJson<String>(json['transfer_state']),
      error: serializer.fromJson<String?>(json['error']),
      attempts: serializer.fromJson<int>(json['attempts']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      updatedAt: serializer.fromJson<String>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attachment_id': serializer.toJson<String>(attachmentId),
      'clinic_id': serializer.toJson<String>(clinicId),
      'user_id': serializer.toJson<String>(userId),
      'data': serializer.toJson<Uint8List>(data),
      'sha256_hex': serializer.toJson<String>(sha256Hex),
      'transfer_state': serializer.toJson<String>(transferState),
      'error': serializer.toJson<String?>(error),
      'attempts': serializer.toJson<int>(attempts),
      'created_at': serializer.toJson<String>(createdAt),
      'updated_at': serializer.toJson<String>(updatedAt),
    };
  }

  DocumentBlob copyWith({
    String? attachmentId,
    String? clinicId,
    String? userId,
    Uint8List? data,
    String? sha256Hex,
    String? transferState,
    Value<String?> error = const Value.absent(),
    int? attempts,
    String? createdAt,
    String? updatedAt,
  }) => DocumentBlob(
    attachmentId: attachmentId ?? this.attachmentId,
    clinicId: clinicId ?? this.clinicId,
    userId: userId ?? this.userId,
    data: data ?? this.data,
    sha256Hex: sha256Hex ?? this.sha256Hex,
    transferState: transferState ?? this.transferState,
    error: error.present ? error.value : this.error,
    attempts: attempts ?? this.attempts,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DocumentBlob copyWithCompanion(DocumentBlobsCompanion data) {
    return DocumentBlob(
      attachmentId: data.attachmentId.present
          ? data.attachmentId.value
          : this.attachmentId,
      clinicId: data.clinicId.present ? data.clinicId.value : this.clinicId,
      userId: data.userId.present ? data.userId.value : this.userId,
      data: data.data.present ? data.data.value : this.data,
      sha256Hex: data.sha256Hex.present ? data.sha256Hex.value : this.sha256Hex,
      transferState: data.transferState.present
          ? data.transferState.value
          : this.transferState,
      error: data.error.present ? data.error.value : this.error,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentBlob(')
          ..write('attachmentId: $attachmentId, ')
          ..write('clinicId: $clinicId, ')
          ..write('userId: $userId, ')
          ..write('data: $data, ')
          ..write('sha256Hex: $sha256Hex, ')
          ..write('transferState: $transferState, ')
          ..write('error: $error, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    attachmentId,
    clinicId,
    userId,
    $driftBlobEquality.hash(data),
    sha256Hex,
    transferState,
    error,
    attempts,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentBlob &&
          other.attachmentId == this.attachmentId &&
          other.clinicId == this.clinicId &&
          other.userId == this.userId &&
          $driftBlobEquality.equals(other.data, this.data) &&
          other.sha256Hex == this.sha256Hex &&
          other.transferState == this.transferState &&
          other.error == this.error &&
          other.attempts == this.attempts &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DocumentBlobsCompanion extends UpdateCompanion<DocumentBlob> {
  final Value<String> attachmentId;
  final Value<String> clinicId;
  final Value<String> userId;
  final Value<Uint8List> data;
  final Value<String> sha256Hex;
  final Value<String> transferState;
  final Value<String?> error;
  final Value<int> attempts;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const DocumentBlobsCompanion({
    this.attachmentId = const Value.absent(),
    this.clinicId = const Value.absent(),
    this.userId = const Value.absent(),
    this.data = const Value.absent(),
    this.sha256Hex = const Value.absent(),
    this.transferState = const Value.absent(),
    this.error = const Value.absent(),
    this.attempts = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentBlobsCompanion.insert({
    required String attachmentId,
    required String clinicId,
    required String userId,
    required Uint8List data,
    required String sha256Hex,
    this.transferState = const Value.absent(),
    this.error = const Value.absent(),
    this.attempts = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : attachmentId = Value(attachmentId),
       clinicId = Value(clinicId),
       userId = Value(userId),
       data = Value(data),
       sha256Hex = Value(sha256Hex),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DocumentBlob> custom({
    Expression<String>? attachmentId,
    Expression<String>? clinicId,
    Expression<String>? userId,
    Expression<Uint8List>? data,
    Expression<String>? sha256Hex,
    Expression<String>? transferState,
    Expression<String>? error,
    Expression<int>? attempts,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (clinicId != null) 'clinic_id': clinicId,
      if (userId != null) 'user_id': userId,
      if (data != null) 'data': data,
      if (sha256Hex != null) 'sha256_hex': sha256Hex,
      if (transferState != null) 'transfer_state': transferState,
      if (error != null) 'error': error,
      if (attempts != null) 'attempts': attempts,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentBlobsCompanion copyWith({
    Value<String>? attachmentId,
    Value<String>? clinicId,
    Value<String>? userId,
    Value<Uint8List>? data,
    Value<String>? sha256Hex,
    Value<String>? transferState,
    Value<String?>? error,
    Value<int>? attempts,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return DocumentBlobsCompanion(
      attachmentId: attachmentId ?? this.attachmentId,
      clinicId: clinicId ?? this.clinicId,
      userId: userId ?? this.userId,
      data: data ?? this.data,
      sha256Hex: sha256Hex ?? this.sha256Hex,
      transferState: transferState ?? this.transferState,
      error: error ?? this.error,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attachmentId.present) {
      map['attachment_id'] = Variable<String>(attachmentId.value);
    }
    if (clinicId.present) {
      map['clinic_id'] = Variable<String>(clinicId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (data.present) {
      map['data'] = Variable<Uint8List>(data.value);
    }
    if (sha256Hex.present) {
      map['sha256_hex'] = Variable<String>(sha256Hex.value);
    }
    if (transferState.present) {
      map['transfer_state'] = Variable<String>(transferState.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentBlobsCompanion(')
          ..write('attachmentId: $attachmentId, ')
          ..write('clinicId: $clinicId, ')
          ..write('userId: $userId, ')
          ..write('data: $data, ')
          ..write('sha256Hex: $sha256Hex, ')
          ..write('transferState: $transferState, ')
          ..write('error: $error, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ClinicDatabase extends GeneratedDatabase {
  _$ClinicDatabase(QueryExecutor e) : super(e);
  $ClinicDatabaseManager get managers => $ClinicDatabaseManager(this);
  late final CachedPatients cachedPatients = CachedPatients(this);
  late final Index patientSearchIdx = Index(
    'patient_search_idx',
    'CREATE INDEX patient_search_idx ON cached_patients (clinic_id, archived, full_name, id)',
  );
  late final Index patientPhoneIdx = Index(
    'patient_phone_idx',
    'CREATE INDEX patient_phone_idx ON cached_patients (clinic_id, mobile_digits)',
  );
  late final CachedAppointments cachedAppointments = CachedAppointments(this);
  late final Index appointmentDayIdx = Index(
    'appointment_day_idx',
    'CREATE INDEX appointment_day_idx ON cached_appointments (clinic_id, starts_at, id)',
  );
  late final Index appointmentPatientIdx = Index(
    'appointment_patient_idx',
    'CREATE INDEX appointment_patient_idx ON cached_appointments (patient_id)',
  );
  late final CachedVisits cachedVisits = CachedVisits(this);
  late final Index visitTimelineIdx = Index(
    'visit_timeline_idx',
    'CREATE INDEX visit_timeline_idx ON cached_visits (clinic_id, patient_id, created_at, id)',
  );
  late final Index visitAppointmentIdx = Index(
    'visit_appointment_idx',
    'CREATE INDEX visit_appointment_idx ON cached_visits (appointment_id)',
  );
  late final CachedDiagnoses cachedDiagnoses = CachedDiagnoses(this);
  late final CachedMedications cachedMedications = CachedMedications(this);
  late final Index medicationVisitIdx = Index(
    'medication_visit_idx',
    'CREATE INDEX medication_visit_idx ON cached_medications (visit_id, position)',
  );
  late final Outbox outbox = Outbox(this);
  late final Index outboxStateIdx = Index(
    'outbox_state_idx',
    'CREATE INDEX outbox_state_idx ON outbox (clinic_id, state, sequence)',
  );
  late final Index outboxEntityIdx = Index(
    'outbox_entity_idx',
    'CREATE INDEX outbox_entity_idx ON outbox (entity_type, entity_id)',
  );
  late final CacheMetadata cacheMetadata = CacheMetadata(this);
  late final SyncResolutions syncResolutions = SyncResolutions(this);
  late final Index syncResolutionClinicIdx = Index(
    'sync_resolution_clinic_idx',
    'CREATE INDEX sync_resolution_clinic_idx ON sync_resolutions (clinic_id, resolved_at)',
  );
  late final CachedDocuments cachedDocuments = CachedDocuments(this);
  late final Index cachedDocumentPatientIdx = Index(
    'cached_document_patient_idx',
    'CREATE INDEX cached_document_patient_idx ON cached_documents (clinic_id, patient_id, created_at, id)',
  );
  late final Index cachedDocumentVisitIdx = Index(
    'cached_document_visit_idx',
    'CREATE INDEX cached_document_visit_idx ON cached_documents (clinic_id, visit_id, created_at, id)',
  );
  late final DocumentBlobs documentBlobs = DocumentBlobs(this);
  late final Index documentBlobStateIdx = Index(
    'document_blob_state_idx',
    'CREATE INDEX document_blob_state_idx ON document_blobs (clinic_id, user_id, transfer_state, created_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedPatients,
    patientSearchIdx,
    patientPhoneIdx,
    cachedAppointments,
    appointmentDayIdx,
    appointmentPatientIdx,
    cachedVisits,
    visitTimelineIdx,
    visitAppointmentIdx,
    cachedDiagnoses,
    cachedMedications,
    medicationVisitIdx,
    outbox,
    outboxStateIdx,
    outboxEntityIdx,
    cacheMetadata,
    syncResolutions,
    syncResolutionClinicIdx,
    cachedDocuments,
    cachedDocumentPatientIdx,
    cachedDocumentVisitIdx,
    documentBlobs,
    documentBlobStateIdx,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'cached_documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('document_blobs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $CachedPatientsCreateCompanionBuilder =
    CachedPatientsCompanion Function({
      required String id,
      required String clinicId,
      required String fullName,
      required String gender,
      required String birthDate,
      required String mobile,
      required String mobileDigits,
      Value<String> secondaryMobile,
      required String patientNumber,
      Value<String> address,
      Value<String> notes,
      Value<String> alerts,
      Value<int> archived,
      required String createdAt,
      required String updatedAt,
      required int version,
      Value<int> rowid,
    });
typedef $CachedPatientsUpdateCompanionBuilder =
    CachedPatientsCompanion Function({
      Value<String> id,
      Value<String> clinicId,
      Value<String> fullName,
      Value<String> gender,
      Value<String> birthDate,
      Value<String> mobile,
      Value<String> mobileDigits,
      Value<String> secondaryMobile,
      Value<String> patientNumber,
      Value<String> address,
      Value<String> notes,
      Value<String> alerts,
      Value<int> archived,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> version,
      Value<int> rowid,
    });

final class $CachedPatientsReferences
    extends BaseReferences<_$ClinicDatabase, CachedPatients, CachedPatient> {
  $CachedPatientsReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<CachedAppointments, List<CachedAppointment>>
  _cachedAppointmentsRefsTable(_$ClinicDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cachedAppointments,
        aliasName: 'cached_patients__id__cached_appointments__patient_id',
      );

  $CachedAppointmentsProcessedTableManager get cachedAppointmentsRefs {
    final manager = $CachedAppointmentsTableManager(
      $_db,
      $_db.cachedAppointments,
    ).filter((f) => f.patientId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cachedAppointmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<CachedVisits, List<CachedVisit>>
  _cachedVisitsRefsTable(_$ClinicDatabase db) => MultiTypedResultKey.fromTable(
    db.cachedVisits,
    aliasName: 'cached_patients__id__cached_visits__patient_id',
  );

  $CachedVisitsProcessedTableManager get cachedVisitsRefs {
    final manager = $CachedVisitsTableManager(
      $_db,
      $_db.cachedVisits,
    ).filter((f) => f.patientId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cachedVisitsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<CachedDocuments, List<CachedDocument>>
  _cachedDocumentsRefsTable(_$ClinicDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cachedDocuments,
        aliasName: 'cached_patients__id__cached_documents__patient_id',
      );

  $CachedDocumentsProcessedTableManager get cachedDocumentsRefs {
    final manager = $CachedDocumentsTableManager(
      $_db,
      $_db.cachedDocuments,
    ).filter((f) => f.patientId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cachedDocumentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $CachedPatientsFilterComposer
    extends Composer<_$ClinicDatabase, CachedPatients> {
  $CachedPatientsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clinicId => $composableBuilder(
    column: $table.clinicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobile => $composableBuilder(
    column: $table.mobile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobileDigits => $composableBuilder(
    column: $table.mobileDigits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secondaryMobile => $composableBuilder(
    column: $table.secondaryMobile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientNumber => $composableBuilder(
    column: $table.patientNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alerts => $composableBuilder(
    column: $table.alerts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> cachedAppointmentsRefs(
    Expression<bool> Function($CachedAppointmentsFilterComposer f) f,
  ) {
    final $CachedAppointmentsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedAppointments,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedAppointmentsFilterComposer(
            $db: $db,
            $table: $db.cachedAppointments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cachedVisitsRefs(
    Expression<bool> Function($CachedVisitsFilterComposer f) f,
  ) {
    final $CachedVisitsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedVisits,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedVisitsFilterComposer(
            $db: $db,
            $table: $db.cachedVisits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cachedDocumentsRefs(
    Expression<bool> Function($CachedDocumentsFilterComposer f) f,
  ) {
    final $CachedDocumentsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedDocuments,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedDocumentsFilterComposer(
            $db: $db,
            $table: $db.cachedDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CachedPatientsOrderingComposer
    extends Composer<_$ClinicDatabase, CachedPatients> {
  $CachedPatientsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clinicId => $composableBuilder(
    column: $table.clinicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobile => $composableBuilder(
    column: $table.mobile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobileDigits => $composableBuilder(
    column: $table.mobileDigits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secondaryMobile => $composableBuilder(
    column: $table.secondaryMobile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientNumber => $composableBuilder(
    column: $table.patientNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alerts => $composableBuilder(
    column: $table.alerts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $CachedPatientsAnnotationComposer
    extends Composer<_$ClinicDatabase, CachedPatients> {
  $CachedPatientsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clinicId =>
      $composableBuilder(column: $table.clinicId, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<String> get mobile =>
      $composableBuilder(column: $table.mobile, builder: (column) => column);

  GeneratedColumn<String> get mobileDigits => $composableBuilder(
    column: $table.mobileDigits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get secondaryMobile => $composableBuilder(
    column: $table.secondaryMobile,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientNumber => $composableBuilder(
    column: $table.patientNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get alerts =>
      $composableBuilder(column: $table.alerts, builder: (column) => column);

  GeneratedColumn<int> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  Expression<T> cachedAppointmentsRefs<T extends Object>(
    Expression<T> Function($CachedAppointmentsAnnotationComposer a) f,
  ) {
    final $CachedAppointmentsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedAppointments,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedAppointmentsAnnotationComposer(
            $db: $db,
            $table: $db.cachedAppointments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cachedVisitsRefs<T extends Object>(
    Expression<T> Function($CachedVisitsAnnotationComposer a) f,
  ) {
    final $CachedVisitsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedVisits,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedVisitsAnnotationComposer(
            $db: $db,
            $table: $db.cachedVisits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cachedDocumentsRefs<T extends Object>(
    Expression<T> Function($CachedDocumentsAnnotationComposer a) f,
  ) {
    final $CachedDocumentsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedDocuments,
      getReferencedColumn: (t) => t.patientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedDocumentsAnnotationComposer(
            $db: $db,
            $table: $db.cachedDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CachedPatientsTableManager
    extends
        RootTableManager<
          _$ClinicDatabase,
          CachedPatients,
          CachedPatient,
          $CachedPatientsFilterComposer,
          $CachedPatientsOrderingComposer,
          $CachedPatientsAnnotationComposer,
          $CachedPatientsCreateCompanionBuilder,
          $CachedPatientsUpdateCompanionBuilder,
          (CachedPatient, $CachedPatientsReferences),
          CachedPatient,
          PrefetchHooks Function({
            bool cachedAppointmentsRefs,
            bool cachedVisitsRefs,
            bool cachedDocumentsRefs,
          })
        > {
  $CachedPatientsTableManager(_$ClinicDatabase db, CachedPatients table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CachedPatientsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CachedPatientsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CachedPatientsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clinicId = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String> gender = const Value.absent(),
                Value<String> birthDate = const Value.absent(),
                Value<String> mobile = const Value.absent(),
                Value<String> mobileDigits = const Value.absent(),
                Value<String> secondaryMobile = const Value.absent(),
                Value<String> patientNumber = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> alerts = const Value.absent(),
                Value<int> archived = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPatientsCompanion(
                id: id,
                clinicId: clinicId,
                fullName: fullName,
                gender: gender,
                birthDate: birthDate,
                mobile: mobile,
                mobileDigits: mobileDigits,
                secondaryMobile: secondaryMobile,
                patientNumber: patientNumber,
                address: address,
                notes: notes,
                alerts: alerts,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clinicId,
                required String fullName,
                required String gender,
                required String birthDate,
                required String mobile,
                required String mobileDigits,
                Value<String> secondaryMobile = const Value.absent(),
                required String patientNumber,
                Value<String> address = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> alerts = const Value.absent(),
                Value<int> archived = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => CachedPatientsCompanion.insert(
                id: id,
                clinicId: clinicId,
                fullName: fullName,
                gender: gender,
                birthDate: birthDate,
                mobile: mobile,
                mobileDigits: mobileDigits,
                secondaryMobile: secondaryMobile,
                patientNumber: patientNumber,
                address: address,
                notes: notes,
                alerts: alerts,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $CachedPatientsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                cachedAppointmentsRefs = false,
                cachedVisitsRefs = false,
                cachedDocumentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (cachedAppointmentsRefs) db.cachedAppointments,
                    if (cachedVisitsRefs) db.cachedVisits,
                    if (cachedDocumentsRefs) db.cachedDocuments,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (cachedAppointmentsRefs)
                        await $_getPrefetchedData<
                          CachedPatient,
                          CachedPatients,
                          CachedAppointment
                        >(
                          currentTable: table,
                          referencedTable: $CachedPatientsReferences
                              ._cachedAppointmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $CachedPatientsReferences(
                                db,
                                table,
                                p0,
                              ).cachedAppointmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.patientId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cachedVisitsRefs)
                        await $_getPrefetchedData<
                          CachedPatient,
                          CachedPatients,
                          CachedVisit
                        >(
                          currentTable: table,
                          referencedTable: $CachedPatientsReferences
                              ._cachedVisitsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $CachedPatientsReferences(
                                db,
                                table,
                                p0,
                              ).cachedVisitsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.patientId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cachedDocumentsRefs)
                        await $_getPrefetchedData<
                          CachedPatient,
                          CachedPatients,
                          CachedDocument
                        >(
                          currentTable: table,
                          referencedTable: $CachedPatientsReferences
                              ._cachedDocumentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $CachedPatientsReferences(
                                db,
                                table,
                                p0,
                              ).cachedDocumentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.patientId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $CachedPatientsProcessedTableManager =
    ProcessedTableManager<
      _$ClinicDatabase,
      CachedPatients,
      CachedPatient,
      $CachedPatientsFilterComposer,
      $CachedPatientsOrderingComposer,
      $CachedPatientsAnnotationComposer,
      $CachedPatientsCreateCompanionBuilder,
      $CachedPatientsUpdateCompanionBuilder,
      (CachedPatient, $CachedPatientsReferences),
      CachedPatient,
      PrefetchHooks Function({
        bool cachedAppointmentsRefs,
        bool cachedVisitsRefs,
        bool cachedDocumentsRefs,
      })
    >;
typedef $CachedAppointmentsCreateCompanionBuilder =
    CachedAppointmentsCompanion Function({
      required String id,
      required String clinicId,
      required String patientId,
      required String doctorId,
      required String startsAt,
      Value<int> durationMinutes,
      required String status,
      required String appointmentType,
      Value<String> notes,
      required int version,
      Value<int> rowid,
    });
typedef $CachedAppointmentsUpdateCompanionBuilder =
    CachedAppointmentsCompanion Function({
      Value<String> id,
      Value<String> clinicId,
      Value<String> patientId,
      Value<String> doctorId,
      Value<String> startsAt,
      Value<int> durationMinutes,
      Value<String> status,
      Value<String> appointmentType,
      Value<String> notes,
      Value<int> version,
      Value<int> rowid,
    });

final class $CachedAppointmentsReferences
    extends
        BaseReferences<
          _$ClinicDatabase,
          CachedAppointments,
          CachedAppointment
        > {
  $CachedAppointmentsReferences(super.$_db, super.$_table, super.$_typedResult);

  static CachedPatients _patientIdTable(_$ClinicDatabase db) => db
      .cachedPatients
      .createAlias('cached_appointments__patient_id__cached_patients__id');

  $CachedPatientsProcessedTableManager get patientId {
    final $_column = $_itemColumn<String>('patient_id')!;

    final manager = $CachedPatientsTableManager(
      $_db,
      $_db.cachedPatients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_patientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<CachedVisits, List<CachedVisit>>
  _cachedVisitsRefsTable(_$ClinicDatabase db) => MultiTypedResultKey.fromTable(
    db.cachedVisits,
    aliasName: 'cached_appointments__id__cached_visits__appointment_id',
  );

  $CachedVisitsProcessedTableManager get cachedVisitsRefs {
    final manager = $CachedVisitsTableManager(
      $_db,
      $_db.cachedVisits,
    ).filter((f) => f.appointmentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cachedVisitsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $CachedAppointmentsFilterComposer
    extends Composer<_$ClinicDatabase, CachedAppointments> {
  $CachedAppointmentsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clinicId => $composableBuilder(
    column: $table.clinicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doctorId => $composableBuilder(
    column: $table.doctorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appointmentType => $composableBuilder(
    column: $table.appointmentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  $CachedPatientsFilterComposer get patientId {
    final $CachedPatientsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.cachedPatients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedPatientsFilterComposer(
            $db: $db,
            $table: $db.cachedPatients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> cachedVisitsRefs(
    Expression<bool> Function($CachedVisitsFilterComposer f) f,
  ) {
    final $CachedVisitsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedVisits,
      getReferencedColumn: (t) => t.appointmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedVisitsFilterComposer(
            $db: $db,
            $table: $db.cachedVisits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CachedAppointmentsOrderingComposer
    extends Composer<_$ClinicDatabase, CachedAppointments> {
  $CachedAppointmentsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clinicId => $composableBuilder(
    column: $table.clinicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doctorId => $composableBuilder(
    column: $table.doctorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appointmentType => $composableBuilder(
    column: $table.appointmentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  $CachedPatientsOrderingComposer get patientId {
    final $CachedPatientsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.cachedPatients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedPatientsOrderingComposer(
            $db: $db,
            $table: $db.cachedPatients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CachedAppointmentsAnnotationComposer
    extends Composer<_$ClinicDatabase, CachedAppointments> {
  $CachedAppointmentsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clinicId =>
      $composableBuilder(column: $table.clinicId, builder: (column) => column);

  GeneratedColumn<String> get doctorId =>
      $composableBuilder(column: $table.doctorId, builder: (column) => column);

  GeneratedColumn<String> get startsAt =>
      $composableBuilder(column: $table.startsAt, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get appointmentType => $composableBuilder(
    column: $table.appointmentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  $CachedPatientsAnnotationComposer get patientId {
    final $CachedPatientsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.cachedPatients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedPatientsAnnotationComposer(
            $db: $db,
            $table: $db.cachedPatients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> cachedVisitsRefs<T extends Object>(
    Expression<T> Function($CachedVisitsAnnotationComposer a) f,
  ) {
    final $CachedVisitsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedVisits,
      getReferencedColumn: (t) => t.appointmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedVisitsAnnotationComposer(
            $db: $db,
            $table: $db.cachedVisits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CachedAppointmentsTableManager
    extends
        RootTableManager<
          _$ClinicDatabase,
          CachedAppointments,
          CachedAppointment,
          $CachedAppointmentsFilterComposer,
          $CachedAppointmentsOrderingComposer,
          $CachedAppointmentsAnnotationComposer,
          $CachedAppointmentsCreateCompanionBuilder,
          $CachedAppointmentsUpdateCompanionBuilder,
          (CachedAppointment, $CachedAppointmentsReferences),
          CachedAppointment,
          PrefetchHooks Function({bool patientId, bool cachedVisitsRefs})
        > {
  $CachedAppointmentsTableManager(_$ClinicDatabase db, CachedAppointments table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CachedAppointmentsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CachedAppointmentsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CachedAppointmentsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clinicId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> doctorId = const Value.absent(),
                Value<String> startsAt = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> appointmentType = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedAppointmentsCompanion(
                id: id,
                clinicId: clinicId,
                patientId: patientId,
                doctorId: doctorId,
                startsAt: startsAt,
                durationMinutes: durationMinutes,
                status: status,
                appointmentType: appointmentType,
                notes: notes,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clinicId,
                required String patientId,
                required String doctorId,
                required String startsAt,
                Value<int> durationMinutes = const Value.absent(),
                required String status,
                required String appointmentType,
                Value<String> notes = const Value.absent(),
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => CachedAppointmentsCompanion.insert(
                id: id,
                clinicId: clinicId,
                patientId: patientId,
                doctorId: doctorId,
                startsAt: startsAt,
                durationMinutes: durationMinutes,
                status: status,
                appointmentType: appointmentType,
                notes: notes,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $CachedAppointmentsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({patientId = false, cachedVisitsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (cachedVisitsRefs) db.cachedVisits,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (patientId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.patientId,
                                    referencedTable:
                                        $CachedAppointmentsReferences
                                            ._patientIdTable(db),
                                    referencedColumn:
                                        $CachedAppointmentsReferences
                                            ._patientIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (cachedVisitsRefs)
                        await $_getPrefetchedData<
                          CachedAppointment,
                          CachedAppointments,
                          CachedVisit
                        >(
                          currentTable: table,
                          referencedTable: $CachedAppointmentsReferences
                              ._cachedVisitsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $CachedAppointmentsReferences(
                                db,
                                table,
                                p0,
                              ).cachedVisitsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.appointmentId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $CachedAppointmentsProcessedTableManager =
    ProcessedTableManager<
      _$ClinicDatabase,
      CachedAppointments,
      CachedAppointment,
      $CachedAppointmentsFilterComposer,
      $CachedAppointmentsOrderingComposer,
      $CachedAppointmentsAnnotationComposer,
      $CachedAppointmentsCreateCompanionBuilder,
      $CachedAppointmentsUpdateCompanionBuilder,
      (CachedAppointment, $CachedAppointmentsReferences),
      CachedAppointment,
      PrefetchHooks Function({bool patientId, bool cachedVisitsRefs})
    >;
typedef $CachedVisitsCreateCompanionBuilder =
    CachedVisitsCompanion Function({
      required String id,
      required String clinicId,
      required String patientId,
      required String appointmentId,
      required String doctorId,
      required String createdAt,
      required String updatedAt,
      Value<String> notes,
      Value<String> followUp,
      Value<int> completed,
      required int version,
      Value<int> currentRevision,
      Value<String> amendmentReason,
      Value<int> rowid,
    });
typedef $CachedVisitsUpdateCompanionBuilder =
    CachedVisitsCompanion Function({
      Value<String> id,
      Value<String> clinicId,
      Value<String> patientId,
      Value<String> appointmentId,
      Value<String> doctorId,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<String> notes,
      Value<String> followUp,
      Value<int> completed,
      Value<int> version,
      Value<int> currentRevision,
      Value<String> amendmentReason,
      Value<int> rowid,
    });

final class $CachedVisitsReferences
    extends BaseReferences<_$ClinicDatabase, CachedVisits, CachedVisit> {
  $CachedVisitsReferences(super.$_db, super.$_table, super.$_typedResult);

  static CachedPatients _patientIdTable(_$ClinicDatabase db) => db
      .cachedPatients
      .createAlias('cached_visits__patient_id__cached_patients__id');

  $CachedPatientsProcessedTableManager get patientId {
    final $_column = $_itemColumn<String>('patient_id')!;

    final manager = $CachedPatientsTableManager(
      $_db,
      $_db.cachedPatients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_patientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static CachedAppointments _appointmentIdTable(_$ClinicDatabase db) => db
      .cachedAppointments
      .createAlias('cached_visits__appointment_id__cached_appointments__id');

  $CachedAppointmentsProcessedTableManager get appointmentId {
    final $_column = $_itemColumn<String>('appointment_id')!;

    final manager = $CachedAppointmentsTableManager(
      $_db,
      $_db.cachedAppointments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_appointmentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<CachedDiagnoses, List<CachedDiagnose>>
  _cachedDiagnosesRefsTable(_$ClinicDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cachedDiagnoses,
        aliasName: 'cached_visits__id__cached_diagnoses__visit_id',
      );

  $CachedDiagnosesProcessedTableManager get cachedDiagnosesRefs {
    final manager = $CachedDiagnosesTableManager(
      $_db,
      $_db.cachedDiagnoses,
    ).filter((f) => f.visitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cachedDiagnosesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<CachedMedications, List<CachedMedication>>
  _cachedMedicationsRefsTable(_$ClinicDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cachedMedications,
        aliasName: 'cached_visits__id__cached_medications__visit_id',
      );

  $CachedMedicationsProcessedTableManager get cachedMedicationsRefs {
    final manager = $CachedMedicationsTableManager(
      $_db,
      $_db.cachedMedications,
    ).filter((f) => f.visitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cachedMedicationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<CachedDocuments, List<CachedDocument>>
  _cachedDocumentsRefsTable(_$ClinicDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cachedDocuments,
        aliasName: 'cached_visits__id__cached_documents__visit_id',
      );

  $CachedDocumentsProcessedTableManager get cachedDocumentsRefs {
    final manager = $CachedDocumentsTableManager(
      $_db,
      $_db.cachedDocuments,
    ).filter((f) => f.visitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cachedDocumentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $CachedVisitsFilterComposer
    extends Composer<_$ClinicDatabase, CachedVisits> {
  $CachedVisitsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clinicId => $composableBuilder(
    column: $table.clinicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doctorId => $composableBuilder(
    column: $table.doctorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get followUp => $composableBuilder(
    column: $table.followUp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentRevision => $composableBuilder(
    column: $table.currentRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amendmentReason => $composableBuilder(
    column: $table.amendmentReason,
    builder: (column) => ColumnFilters(column),
  );

  $CachedPatientsFilterComposer get patientId {
    final $CachedPatientsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.cachedPatients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedPatientsFilterComposer(
            $db: $db,
            $table: $db.cachedPatients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CachedAppointmentsFilterComposer get appointmentId {
    final $CachedAppointmentsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.appointmentId,
      referencedTable: $db.cachedAppointments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedAppointmentsFilterComposer(
            $db: $db,
            $table: $db.cachedAppointments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> cachedDiagnosesRefs(
    Expression<bool> Function($CachedDiagnosesFilterComposer f) f,
  ) {
    final $CachedDiagnosesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedDiagnoses,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedDiagnosesFilterComposer(
            $db: $db,
            $table: $db.cachedDiagnoses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cachedMedicationsRefs(
    Expression<bool> Function($CachedMedicationsFilterComposer f) f,
  ) {
    final $CachedMedicationsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedMedications,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedMedicationsFilterComposer(
            $db: $db,
            $table: $db.cachedMedications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cachedDocumentsRefs(
    Expression<bool> Function($CachedDocumentsFilterComposer f) f,
  ) {
    final $CachedDocumentsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedDocuments,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedDocumentsFilterComposer(
            $db: $db,
            $table: $db.cachedDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CachedVisitsOrderingComposer
    extends Composer<_$ClinicDatabase, CachedVisits> {
  $CachedVisitsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clinicId => $composableBuilder(
    column: $table.clinicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doctorId => $composableBuilder(
    column: $table.doctorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get followUp => $composableBuilder(
    column: $table.followUp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentRevision => $composableBuilder(
    column: $table.currentRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amendmentReason => $composableBuilder(
    column: $table.amendmentReason,
    builder: (column) => ColumnOrderings(column),
  );

  $CachedPatientsOrderingComposer get patientId {
    final $CachedPatientsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.cachedPatients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedPatientsOrderingComposer(
            $db: $db,
            $table: $db.cachedPatients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CachedAppointmentsOrderingComposer get appointmentId {
    final $CachedAppointmentsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.appointmentId,
      referencedTable: $db.cachedAppointments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedAppointmentsOrderingComposer(
            $db: $db,
            $table: $db.cachedAppointments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CachedVisitsAnnotationComposer
    extends Composer<_$ClinicDatabase, CachedVisits> {
  $CachedVisitsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clinicId =>
      $composableBuilder(column: $table.clinicId, builder: (column) => column);

  GeneratedColumn<String> get doctorId =>
      $composableBuilder(column: $table.doctorId, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get followUp =>
      $composableBuilder(column: $table.followUp, builder: (column) => column);

  GeneratedColumn<int> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get currentRevision => $composableBuilder(
    column: $table.currentRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get amendmentReason => $composableBuilder(
    column: $table.amendmentReason,
    builder: (column) => column,
  );

  $CachedPatientsAnnotationComposer get patientId {
    final $CachedPatientsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.cachedPatients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedPatientsAnnotationComposer(
            $db: $db,
            $table: $db.cachedPatients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CachedAppointmentsAnnotationComposer get appointmentId {
    final $CachedAppointmentsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.appointmentId,
      referencedTable: $db.cachedAppointments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedAppointmentsAnnotationComposer(
            $db: $db,
            $table: $db.cachedAppointments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> cachedDiagnosesRefs<T extends Object>(
    Expression<T> Function($CachedDiagnosesAnnotationComposer a) f,
  ) {
    final $CachedDiagnosesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedDiagnoses,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedDiagnosesAnnotationComposer(
            $db: $db,
            $table: $db.cachedDiagnoses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cachedMedicationsRefs<T extends Object>(
    Expression<T> Function($CachedMedicationsAnnotationComposer a) f,
  ) {
    final $CachedMedicationsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedMedications,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedMedicationsAnnotationComposer(
            $db: $db,
            $table: $db.cachedMedications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cachedDocumentsRefs<T extends Object>(
    Expression<T> Function($CachedDocumentsAnnotationComposer a) f,
  ) {
    final $CachedDocumentsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedDocuments,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedDocumentsAnnotationComposer(
            $db: $db,
            $table: $db.cachedDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CachedVisitsTableManager
    extends
        RootTableManager<
          _$ClinicDatabase,
          CachedVisits,
          CachedVisit,
          $CachedVisitsFilterComposer,
          $CachedVisitsOrderingComposer,
          $CachedVisitsAnnotationComposer,
          $CachedVisitsCreateCompanionBuilder,
          $CachedVisitsUpdateCompanionBuilder,
          (CachedVisit, $CachedVisitsReferences),
          CachedVisit,
          PrefetchHooks Function({
            bool patientId,
            bool appointmentId,
            bool cachedDiagnosesRefs,
            bool cachedMedicationsRefs,
            bool cachedDocumentsRefs,
          })
        > {
  $CachedVisitsTableManager(_$ClinicDatabase db, CachedVisits table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CachedVisitsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CachedVisitsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CachedVisitsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clinicId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> appointmentId = const Value.absent(),
                Value<String> doctorId = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> followUp = const Value.absent(),
                Value<int> completed = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> currentRevision = const Value.absent(),
                Value<String> amendmentReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedVisitsCompanion(
                id: id,
                clinicId: clinicId,
                patientId: patientId,
                appointmentId: appointmentId,
                doctorId: doctorId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                notes: notes,
                followUp: followUp,
                completed: completed,
                version: version,
                currentRevision: currentRevision,
                amendmentReason: amendmentReason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clinicId,
                required String patientId,
                required String appointmentId,
                required String doctorId,
                required String createdAt,
                required String updatedAt,
                Value<String> notes = const Value.absent(),
                Value<String> followUp = const Value.absent(),
                Value<int> completed = const Value.absent(),
                required int version,
                Value<int> currentRevision = const Value.absent(),
                Value<String> amendmentReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedVisitsCompanion.insert(
                id: id,
                clinicId: clinicId,
                patientId: patientId,
                appointmentId: appointmentId,
                doctorId: doctorId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                notes: notes,
                followUp: followUp,
                completed: completed,
                version: version,
                currentRevision: currentRevision,
                amendmentReason: amendmentReason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $CachedVisitsReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                patientId = false,
                appointmentId = false,
                cachedDiagnosesRefs = false,
                cachedMedicationsRefs = false,
                cachedDocumentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (cachedDiagnosesRefs) db.cachedDiagnoses,
                    if (cachedMedicationsRefs) db.cachedMedications,
                    if (cachedDocumentsRefs) db.cachedDocuments,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (patientId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.patientId,
                                    referencedTable: $CachedVisitsReferences
                                        ._patientIdTable(db),
                                    referencedColumn: $CachedVisitsReferences
                                        ._patientIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (appointmentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.appointmentId,
                                    referencedTable: $CachedVisitsReferences
                                        ._appointmentIdTable(db),
                                    referencedColumn: $CachedVisitsReferences
                                        ._appointmentIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (cachedDiagnosesRefs)
                        await $_getPrefetchedData<
                          CachedVisit,
                          CachedVisits,
                          CachedDiagnose
                        >(
                          currentTable: table,
                          referencedTable: $CachedVisitsReferences
                              ._cachedDiagnosesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $CachedVisitsReferences(
                                db,
                                table,
                                p0,
                              ).cachedDiagnosesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.visitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cachedMedicationsRefs)
                        await $_getPrefetchedData<
                          CachedVisit,
                          CachedVisits,
                          CachedMedication
                        >(
                          currentTable: table,
                          referencedTable: $CachedVisitsReferences
                              ._cachedMedicationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $CachedVisitsReferences(
                                db,
                                table,
                                p0,
                              ).cachedMedicationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.visitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cachedDocumentsRefs)
                        await $_getPrefetchedData<
                          CachedVisit,
                          CachedVisits,
                          CachedDocument
                        >(
                          currentTable: table,
                          referencedTable: $CachedVisitsReferences
                              ._cachedDocumentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $CachedVisitsReferences(
                                db,
                                table,
                                p0,
                              ).cachedDocumentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.visitId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $CachedVisitsProcessedTableManager =
    ProcessedTableManager<
      _$ClinicDatabase,
      CachedVisits,
      CachedVisit,
      $CachedVisitsFilterComposer,
      $CachedVisitsOrderingComposer,
      $CachedVisitsAnnotationComposer,
      $CachedVisitsCreateCompanionBuilder,
      $CachedVisitsUpdateCompanionBuilder,
      (CachedVisit, $CachedVisitsReferences),
      CachedVisit,
      PrefetchHooks Function({
        bool patientId,
        bool appointmentId,
        bool cachedDiagnosesRefs,
        bool cachedMedicationsRefs,
        bool cachedDocumentsRefs,
      })
    >;
typedef $CachedDiagnosesCreateCompanionBuilder =
    CachedDiagnosesCompanion Function({
      required String visitId,
      required int position,
      required String description,
      Value<int> rowid,
    });
typedef $CachedDiagnosesUpdateCompanionBuilder =
    CachedDiagnosesCompanion Function({
      Value<String> visitId,
      Value<int> position,
      Value<String> description,
      Value<int> rowid,
    });

final class $CachedDiagnosesReferences
    extends BaseReferences<_$ClinicDatabase, CachedDiagnoses, CachedDiagnose> {
  $CachedDiagnosesReferences(super.$_db, super.$_table, super.$_typedResult);

  static CachedVisits _visitIdTable(_$ClinicDatabase db) => db.cachedVisits
      .createAlias('cached_diagnoses__visit_id__cached_visits__id');

  $CachedVisitsProcessedTableManager get visitId {
    final $_column = $_itemColumn<String>('visit_id')!;

    final manager = $CachedVisitsTableManager(
      $_db,
      $_db.cachedVisits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_visitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $CachedDiagnosesFilterComposer
    extends Composer<_$ClinicDatabase, CachedDiagnoses> {
  $CachedDiagnosesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  $CachedVisitsFilterComposer get visitId {
    final $CachedVisitsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.cachedVisits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedVisitsFilterComposer(
            $db: $db,
            $table: $db.cachedVisits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CachedDiagnosesOrderingComposer
    extends Composer<_$ClinicDatabase, CachedDiagnoses> {
  $CachedDiagnosesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  $CachedVisitsOrderingComposer get visitId {
    final $CachedVisitsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.cachedVisits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedVisitsOrderingComposer(
            $db: $db,
            $table: $db.cachedVisits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CachedDiagnosesAnnotationComposer
    extends Composer<_$ClinicDatabase, CachedDiagnoses> {
  $CachedDiagnosesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  $CachedVisitsAnnotationComposer get visitId {
    final $CachedVisitsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.cachedVisits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedVisitsAnnotationComposer(
            $db: $db,
            $table: $db.cachedVisits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CachedDiagnosesTableManager
    extends
        RootTableManager<
          _$ClinicDatabase,
          CachedDiagnoses,
          CachedDiagnose,
          $CachedDiagnosesFilterComposer,
          $CachedDiagnosesOrderingComposer,
          $CachedDiagnosesAnnotationComposer,
          $CachedDiagnosesCreateCompanionBuilder,
          $CachedDiagnosesUpdateCompanionBuilder,
          (CachedDiagnose, $CachedDiagnosesReferences),
          CachedDiagnose,
          PrefetchHooks Function({bool visitId})
        > {
  $CachedDiagnosesTableManager(_$ClinicDatabase db, CachedDiagnoses table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CachedDiagnosesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CachedDiagnosesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CachedDiagnosesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> visitId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedDiagnosesCompanion(
                visitId: visitId,
                position: position,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String visitId,
                required int position,
                required String description,
                Value<int> rowid = const Value.absent(),
              }) => CachedDiagnosesCompanion.insert(
                visitId: visitId,
                position: position,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $CachedDiagnosesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({visitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (visitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.visitId,
                                referencedTable: $CachedDiagnosesReferences
                                    ._visitIdTable(db),
                                referencedColumn: $CachedDiagnosesReferences
                                    ._visitIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $CachedDiagnosesProcessedTableManager =
    ProcessedTableManager<
      _$ClinicDatabase,
      CachedDiagnoses,
      CachedDiagnose,
      $CachedDiagnosesFilterComposer,
      $CachedDiagnosesOrderingComposer,
      $CachedDiagnosesAnnotationComposer,
      $CachedDiagnosesCreateCompanionBuilder,
      $CachedDiagnosesUpdateCompanionBuilder,
      (CachedDiagnose, $CachedDiagnosesReferences),
      CachedDiagnose,
      PrefetchHooks Function({bool visitId})
    >;
typedef $CachedMedicationsCreateCompanionBuilder =
    CachedMedicationsCompanion Function({
      required String id,
      required String visitId,
      required int position,
      required String name,
      Value<String> strength,
      Value<String> dose,
      Value<String> frequency,
      Value<String> duration,
      Value<String> instructions,
      Value<String> notes,
      Value<int> rowid,
    });
typedef $CachedMedicationsUpdateCompanionBuilder =
    CachedMedicationsCompanion Function({
      Value<String> id,
      Value<String> visitId,
      Value<int> position,
      Value<String> name,
      Value<String> strength,
      Value<String> dose,
      Value<String> frequency,
      Value<String> duration,
      Value<String> instructions,
      Value<String> notes,
      Value<int> rowid,
    });

final class $CachedMedicationsReferences
    extends
        BaseReferences<_$ClinicDatabase, CachedMedications, CachedMedication> {
  $CachedMedicationsReferences(super.$_db, super.$_table, super.$_typedResult);

  static CachedVisits _visitIdTable(_$ClinicDatabase db) => db.cachedVisits
      .createAlias('cached_medications__visit_id__cached_visits__id');

  $CachedVisitsProcessedTableManager get visitId {
    final $_column = $_itemColumn<String>('visit_id')!;

    final manager = $CachedVisitsTableManager(
      $_db,
      $_db.cachedVisits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_visitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $CachedMedicationsFilterComposer
    extends Composer<_$ClinicDatabase, CachedMedications> {
  $CachedMedicationsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strength => $composableBuilder(
    column: $table.strength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dose => $composableBuilder(
    column: $table.dose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $CachedVisitsFilterComposer get visitId {
    final $CachedVisitsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.cachedVisits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedVisitsFilterComposer(
            $db: $db,
            $table: $db.cachedVisits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CachedMedicationsOrderingComposer
    extends Composer<_$ClinicDatabase, CachedMedications> {
  $CachedMedicationsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strength => $composableBuilder(
    column: $table.strength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dose => $composableBuilder(
    column: $table.dose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $CachedVisitsOrderingComposer get visitId {
    final $CachedVisitsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.cachedVisits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedVisitsOrderingComposer(
            $db: $db,
            $table: $db.cachedVisits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CachedMedicationsAnnotationComposer
    extends Composer<_$ClinicDatabase, CachedMedications> {
  $CachedMedicationsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get strength =>
      $composableBuilder(column: $table.strength, builder: (column) => column);

  GeneratedColumn<String> get dose =>
      $composableBuilder(column: $table.dose, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<String> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $CachedVisitsAnnotationComposer get visitId {
    final $CachedVisitsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.cachedVisits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedVisitsAnnotationComposer(
            $db: $db,
            $table: $db.cachedVisits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CachedMedicationsTableManager
    extends
        RootTableManager<
          _$ClinicDatabase,
          CachedMedications,
          CachedMedication,
          $CachedMedicationsFilterComposer,
          $CachedMedicationsOrderingComposer,
          $CachedMedicationsAnnotationComposer,
          $CachedMedicationsCreateCompanionBuilder,
          $CachedMedicationsUpdateCompanionBuilder,
          (CachedMedication, $CachedMedicationsReferences),
          CachedMedication,
          PrefetchHooks Function({bool visitId})
        > {
  $CachedMedicationsTableManager(_$ClinicDatabase db, CachedMedications table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CachedMedicationsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CachedMedicationsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CachedMedicationsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> visitId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> strength = const Value.absent(),
                Value<String> dose = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<String> duration = const Value.absent(),
                Value<String> instructions = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMedicationsCompanion(
                id: id,
                visitId: visitId,
                position: position,
                name: name,
                strength: strength,
                dose: dose,
                frequency: frequency,
                duration: duration,
                instructions: instructions,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String visitId,
                required int position,
                required String name,
                Value<String> strength = const Value.absent(),
                Value<String> dose = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<String> duration = const Value.absent(),
                Value<String> instructions = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMedicationsCompanion.insert(
                id: id,
                visitId: visitId,
                position: position,
                name: name,
                strength: strength,
                dose: dose,
                frequency: frequency,
                duration: duration,
                instructions: instructions,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $CachedMedicationsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({visitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (visitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.visitId,
                                referencedTable: $CachedMedicationsReferences
                                    ._visitIdTable(db),
                                referencedColumn: $CachedMedicationsReferences
                                    ._visitIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $CachedMedicationsProcessedTableManager =
    ProcessedTableManager<
      _$ClinicDatabase,
      CachedMedications,
      CachedMedication,
      $CachedMedicationsFilterComposer,
      $CachedMedicationsOrderingComposer,
      $CachedMedicationsAnnotationComposer,
      $CachedMedicationsCreateCompanionBuilder,
      $CachedMedicationsUpdateCompanionBuilder,
      (CachedMedication, $CachedMedicationsReferences),
      CachedMedication,
      PrefetchHooks Function({bool visitId})
    >;
typedef $OutboxCreateCompanionBuilder =
    OutboxCompanion Function({
      Value<int> sequence,
      required String operationId,
      required String clinicId,
      required String entityType,
      required String entityId,
      required String action,
      required String payload,
      required int expectedVersion,
      Value<String> state,
      Value<String?> error,
      Value<String?> remoteValue,
      Value<int> attempts,
      required String createdAt,
    });
typedef $OutboxUpdateCompanionBuilder =
    OutboxCompanion Function({
      Value<int> sequence,
      Value<String> operationId,
      Value<String> clinicId,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> action,
      Value<String> payload,
      Value<int> expectedVersion,
      Value<String> state,
      Value<String?> error,
      Value<String?> remoteValue,
      Value<int> attempts,
      Value<String> createdAt,
    });

class $OutboxFilterComposer extends Composer<_$ClinicDatabase, Outbox> {
  $OutboxFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clinicId => $composableBuilder(
    column: $table.clinicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedVersion => $composableBuilder(
    column: $table.expectedVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteValue => $composableBuilder(
    column: $table.remoteValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $OutboxOrderingComposer extends Composer<_$ClinicDatabase, Outbox> {
  $OutboxOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clinicId => $composableBuilder(
    column: $table.clinicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedVersion => $composableBuilder(
    column: $table.expectedVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteValue => $composableBuilder(
    column: $table.remoteValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $OutboxAnnotationComposer extends Composer<_$ClinicDatabase, Outbox> {
  $OutboxAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clinicId =>
      $composableBuilder(column: $table.clinicId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get expectedVersion => $composableBuilder(
    column: $table.expectedVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<String> get remoteValue => $composableBuilder(
    column: $table.remoteValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $OutboxTableManager
    extends
        RootTableManager<
          _$ClinicDatabase,
          Outbox,
          OutboxData,
          $OutboxFilterComposer,
          $OutboxOrderingComposer,
          $OutboxAnnotationComposer,
          $OutboxCreateCompanionBuilder,
          $OutboxUpdateCompanionBuilder,
          (OutboxData, BaseReferences<_$ClinicDatabase, Outbox, OutboxData>),
          OutboxData,
          PrefetchHooks Function()
        > {
  $OutboxTableManager(_$ClinicDatabase db, Outbox table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $OutboxFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $OutboxOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $OutboxAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sequence = const Value.absent(),
                Value<String> operationId = const Value.absent(),
                Value<String> clinicId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> expectedVersion = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String?> remoteValue = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => OutboxCompanion(
                sequence: sequence,
                operationId: operationId,
                clinicId: clinicId,
                entityType: entityType,
                entityId: entityId,
                action: action,
                payload: payload,
                expectedVersion: expectedVersion,
                state: state,
                error: error,
                remoteValue: remoteValue,
                attempts: attempts,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> sequence = const Value.absent(),
                required String operationId,
                required String clinicId,
                required String entityType,
                required String entityId,
                required String action,
                required String payload,
                required int expectedVersion,
                Value<String> state = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String?> remoteValue = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                required String createdAt,
              }) => OutboxCompanion.insert(
                sequence: sequence,
                operationId: operationId,
                clinicId: clinicId,
                entityType: entityType,
                entityId: entityId,
                action: action,
                payload: payload,
                expectedVersion: expectedVersion,
                state: state,
                error: error,
                remoteValue: remoteValue,
                attempts: attempts,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $OutboxProcessedTableManager =
    ProcessedTableManager<
      _$ClinicDatabase,
      Outbox,
      OutboxData,
      $OutboxFilterComposer,
      $OutboxOrderingComposer,
      $OutboxAnnotationComposer,
      $OutboxCreateCompanionBuilder,
      $OutboxUpdateCompanionBuilder,
      (OutboxData, BaseReferences<_$ClinicDatabase, Outbox, OutboxData>),
      OutboxData,
      PrefetchHooks Function()
    >;
typedef $CacheMetadataCreateCompanionBuilder =
    CacheMetadataCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $CacheMetadataUpdateCompanionBuilder =
    CacheMetadataCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $CacheMetadataFilterComposer
    extends Composer<_$ClinicDatabase, CacheMetadata> {
  $CacheMetadataFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $CacheMetadataOrderingComposer
    extends Composer<_$ClinicDatabase, CacheMetadata> {
  $CacheMetadataOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $CacheMetadataAnnotationComposer
    extends Composer<_$ClinicDatabase, CacheMetadata> {
  $CacheMetadataAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $CacheMetadataTableManager
    extends
        RootTableManager<
          _$ClinicDatabase,
          CacheMetadata,
          CacheMetadataData,
          $CacheMetadataFilterComposer,
          $CacheMetadataOrderingComposer,
          $CacheMetadataAnnotationComposer,
          $CacheMetadataCreateCompanionBuilder,
          $CacheMetadataUpdateCompanionBuilder,
          (
            CacheMetadataData,
            BaseReferences<_$ClinicDatabase, CacheMetadata, CacheMetadataData>,
          ),
          CacheMetadataData,
          PrefetchHooks Function()
        > {
  $CacheMetadataTableManager(_$ClinicDatabase db, CacheMetadata table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CacheMetadataFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CacheMetadataOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CacheMetadataAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  CacheMetadataCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => CacheMetadataCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $CacheMetadataProcessedTableManager =
    ProcessedTableManager<
      _$ClinicDatabase,
      CacheMetadata,
      CacheMetadataData,
      $CacheMetadataFilterComposer,
      $CacheMetadataOrderingComposer,
      $CacheMetadataAnnotationComposer,
      $CacheMetadataCreateCompanionBuilder,
      $CacheMetadataUpdateCompanionBuilder,
      (
        CacheMetadataData,
        BaseReferences<_$ClinicDatabase, CacheMetadata, CacheMetadataData>,
      ),
      CacheMetadataData,
      PrefetchHooks Function()
    >;
typedef $SyncResolutionsCreateCompanionBuilder =
    SyncResolutionsCompanion Function({
      required String id,
      required String clinicId,
      required String userId,
      required String entityId,
      required String resolvedAt,
      required String choice,
      required String originalOperations,
      required String localValue,
      required String remoteValue,
      required String resolvedValue,
      Value<String?> replacementOperationId,
      Value<int> rowid,
    });
typedef $SyncResolutionsUpdateCompanionBuilder =
    SyncResolutionsCompanion Function({
      Value<String> id,
      Value<String> clinicId,
      Value<String> userId,
      Value<String> entityId,
      Value<String> resolvedAt,
      Value<String> choice,
      Value<String> originalOperations,
      Value<String> localValue,
      Value<String> remoteValue,
      Value<String> resolvedValue,
      Value<String?> replacementOperationId,
      Value<int> rowid,
    });

class $SyncResolutionsFilterComposer
    extends Composer<_$ClinicDatabase, SyncResolutions> {
  $SyncResolutionsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clinicId => $composableBuilder(
    column: $table.clinicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get choice => $composableBuilder(
    column: $table.choice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalOperations => $composableBuilder(
    column: $table.originalOperations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localValue => $composableBuilder(
    column: $table.localValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteValue => $composableBuilder(
    column: $table.remoteValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolvedValue => $composableBuilder(
    column: $table.resolvedValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replacementOperationId => $composableBuilder(
    column: $table.replacementOperationId,
    builder: (column) => ColumnFilters(column),
  );
}

class $SyncResolutionsOrderingComposer
    extends Composer<_$ClinicDatabase, SyncResolutions> {
  $SyncResolutionsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clinicId => $composableBuilder(
    column: $table.clinicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get choice => $composableBuilder(
    column: $table.choice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalOperations => $composableBuilder(
    column: $table.originalOperations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localValue => $composableBuilder(
    column: $table.localValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteValue => $composableBuilder(
    column: $table.remoteValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolvedValue => $composableBuilder(
    column: $table.resolvedValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replacementOperationId => $composableBuilder(
    column: $table.replacementOperationId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SyncResolutionsAnnotationComposer
    extends Composer<_$ClinicDatabase, SyncResolutions> {
  $SyncResolutionsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clinicId =>
      $composableBuilder(column: $table.clinicId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get choice =>
      $composableBuilder(column: $table.choice, builder: (column) => column);

  GeneratedColumn<String> get originalOperations => $composableBuilder(
    column: $table.originalOperations,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localValue => $composableBuilder(
    column: $table.localValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteValue => $composableBuilder(
    column: $table.remoteValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolvedValue => $composableBuilder(
    column: $table.resolvedValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get replacementOperationId => $composableBuilder(
    column: $table.replacementOperationId,
    builder: (column) => column,
  );
}

class $SyncResolutionsTableManager
    extends
        RootTableManager<
          _$ClinicDatabase,
          SyncResolutions,
          SyncResolution,
          $SyncResolutionsFilterComposer,
          $SyncResolutionsOrderingComposer,
          $SyncResolutionsAnnotationComposer,
          $SyncResolutionsCreateCompanionBuilder,
          $SyncResolutionsUpdateCompanionBuilder,
          (
            SyncResolution,
            BaseReferences<_$ClinicDatabase, SyncResolutions, SyncResolution>,
          ),
          SyncResolution,
          PrefetchHooks Function()
        > {
  $SyncResolutionsTableManager(_$ClinicDatabase db, SyncResolutions table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SyncResolutionsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SyncResolutionsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SyncResolutionsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clinicId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> resolvedAt = const Value.absent(),
                Value<String> choice = const Value.absent(),
                Value<String> originalOperations = const Value.absent(),
                Value<String> localValue = const Value.absent(),
                Value<String> remoteValue = const Value.absent(),
                Value<String> resolvedValue = const Value.absent(),
                Value<String?> replacementOperationId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncResolutionsCompanion(
                id: id,
                clinicId: clinicId,
                userId: userId,
                entityId: entityId,
                resolvedAt: resolvedAt,
                choice: choice,
                originalOperations: originalOperations,
                localValue: localValue,
                remoteValue: remoteValue,
                resolvedValue: resolvedValue,
                replacementOperationId: replacementOperationId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clinicId,
                required String userId,
                required String entityId,
                required String resolvedAt,
                required String choice,
                required String originalOperations,
                required String localValue,
                required String remoteValue,
                required String resolvedValue,
                Value<String?> replacementOperationId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncResolutionsCompanion.insert(
                id: id,
                clinicId: clinicId,
                userId: userId,
                entityId: entityId,
                resolvedAt: resolvedAt,
                choice: choice,
                originalOperations: originalOperations,
                localValue: localValue,
                remoteValue: remoteValue,
                resolvedValue: resolvedValue,
                replacementOperationId: replacementOperationId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SyncResolutionsProcessedTableManager =
    ProcessedTableManager<
      _$ClinicDatabase,
      SyncResolutions,
      SyncResolution,
      $SyncResolutionsFilterComposer,
      $SyncResolutionsOrderingComposer,
      $SyncResolutionsAnnotationComposer,
      $SyncResolutionsCreateCompanionBuilder,
      $SyncResolutionsUpdateCompanionBuilder,
      (
        SyncResolution,
        BaseReferences<_$ClinicDatabase, SyncResolutions, SyncResolution>,
      ),
      SyncResolution,
      PrefetchHooks Function()
    >;
typedef $CachedDocumentsCreateCompanionBuilder =
    CachedDocumentsCompanion Function({
      required String id,
      required String clinicId,
      required String patientId,
      Value<String?> visitId,
      required String fileName,
      required String contentType,
      required String category,
      Value<String> notes,
      required String objectPath,
      required int bytes,
      required String sha256Hex,
      Value<int> clinical,
      required String state,
      required String uploadedBy,
      required String createdAt,
      required String updatedAt,
      required int version,
      Value<int> rowid,
    });
typedef $CachedDocumentsUpdateCompanionBuilder =
    CachedDocumentsCompanion Function({
      Value<String> id,
      Value<String> clinicId,
      Value<String> patientId,
      Value<String?> visitId,
      Value<String> fileName,
      Value<String> contentType,
      Value<String> category,
      Value<String> notes,
      Value<String> objectPath,
      Value<int> bytes,
      Value<String> sha256Hex,
      Value<int> clinical,
      Value<String> state,
      Value<String> uploadedBy,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> version,
      Value<int> rowid,
    });

final class $CachedDocumentsReferences
    extends BaseReferences<_$ClinicDatabase, CachedDocuments, CachedDocument> {
  $CachedDocumentsReferences(super.$_db, super.$_table, super.$_typedResult);

  static CachedPatients _patientIdTable(_$ClinicDatabase db) => db
      .cachedPatients
      .createAlias('cached_documents__patient_id__cached_patients__id');

  $CachedPatientsProcessedTableManager get patientId {
    final $_column = $_itemColumn<String>('patient_id')!;

    final manager = $CachedPatientsTableManager(
      $_db,
      $_db.cachedPatients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_patientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static CachedVisits _visitIdTable(_$ClinicDatabase db) => db.cachedVisits
      .createAlias('cached_documents__visit_id__cached_visits__id');

  $CachedVisitsProcessedTableManager? get visitId {
    final $_column = $_itemColumn<String>('visit_id');
    if ($_column == null) return null;
    final manager = $CachedVisitsTableManager(
      $_db,
      $_db.cachedVisits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_visitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<DocumentBlobs, List<DocumentBlob>>
  _documentBlobsRefsTable(_$ClinicDatabase db) => MultiTypedResultKey.fromTable(
    db.documentBlobs,
    aliasName: 'cached_documents__id__document_blobs__attachment_id',
  );

  $DocumentBlobsProcessedTableManager get documentBlobsRefs {
    final manager = $DocumentBlobsTableManager(
      $_db,
      $_db.documentBlobs,
    ).filter((f) => f.attachmentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_documentBlobsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $CachedDocumentsFilterComposer
    extends Composer<_$ClinicDatabase, CachedDocuments> {
  $CachedDocumentsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clinicId => $composableBuilder(
    column: $table.clinicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get objectPath => $composableBuilder(
    column: $table.objectPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256Hex => $composableBuilder(
    column: $table.sha256Hex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clinical => $composableBuilder(
    column: $table.clinical,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadedBy => $composableBuilder(
    column: $table.uploadedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  $CachedPatientsFilterComposer get patientId {
    final $CachedPatientsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.cachedPatients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedPatientsFilterComposer(
            $db: $db,
            $table: $db.cachedPatients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CachedVisitsFilterComposer get visitId {
    final $CachedVisitsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.cachedVisits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedVisitsFilterComposer(
            $db: $db,
            $table: $db.cachedVisits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> documentBlobsRefs(
    Expression<bool> Function($DocumentBlobsFilterComposer f) f,
  ) {
    final $DocumentBlobsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.documentBlobs,
      getReferencedColumn: (t) => t.attachmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DocumentBlobsFilterComposer(
            $db: $db,
            $table: $db.documentBlobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CachedDocumentsOrderingComposer
    extends Composer<_$ClinicDatabase, CachedDocuments> {
  $CachedDocumentsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clinicId => $composableBuilder(
    column: $table.clinicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get objectPath => $composableBuilder(
    column: $table.objectPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256Hex => $composableBuilder(
    column: $table.sha256Hex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clinical => $composableBuilder(
    column: $table.clinical,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadedBy => $composableBuilder(
    column: $table.uploadedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  $CachedPatientsOrderingComposer get patientId {
    final $CachedPatientsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.cachedPatients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedPatientsOrderingComposer(
            $db: $db,
            $table: $db.cachedPatients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CachedVisitsOrderingComposer get visitId {
    final $CachedVisitsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.cachedVisits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedVisitsOrderingComposer(
            $db: $db,
            $table: $db.cachedVisits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CachedDocumentsAnnotationComposer
    extends Composer<_$ClinicDatabase, CachedDocuments> {
  $CachedDocumentsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clinicId =>
      $composableBuilder(column: $table.clinicId, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get objectPath => $composableBuilder(
    column: $table.objectPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<String> get sha256Hex =>
      $composableBuilder(column: $table.sha256Hex, builder: (column) => column);

  GeneratedColumn<int> get clinical =>
      $composableBuilder(column: $table.clinical, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get uploadedBy => $composableBuilder(
    column: $table.uploadedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  $CachedPatientsAnnotationComposer get patientId {
    final $CachedPatientsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.patientId,
      referencedTable: $db.cachedPatients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedPatientsAnnotationComposer(
            $db: $db,
            $table: $db.cachedPatients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CachedVisitsAnnotationComposer get visitId {
    final $CachedVisitsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.cachedVisits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedVisitsAnnotationComposer(
            $db: $db,
            $table: $db.cachedVisits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> documentBlobsRefs<T extends Object>(
    Expression<T> Function($DocumentBlobsAnnotationComposer a) f,
  ) {
    final $DocumentBlobsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.documentBlobs,
      getReferencedColumn: (t) => t.attachmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DocumentBlobsAnnotationComposer(
            $db: $db,
            $table: $db.documentBlobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CachedDocumentsTableManager
    extends
        RootTableManager<
          _$ClinicDatabase,
          CachedDocuments,
          CachedDocument,
          $CachedDocumentsFilterComposer,
          $CachedDocumentsOrderingComposer,
          $CachedDocumentsAnnotationComposer,
          $CachedDocumentsCreateCompanionBuilder,
          $CachedDocumentsUpdateCompanionBuilder,
          (CachedDocument, $CachedDocumentsReferences),
          CachedDocument,
          PrefetchHooks Function({
            bool patientId,
            bool visitId,
            bool documentBlobsRefs,
          })
        > {
  $CachedDocumentsTableManager(_$ClinicDatabase db, CachedDocuments table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CachedDocumentsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CachedDocumentsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CachedDocumentsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clinicId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String?> visitId = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> objectPath = const Value.absent(),
                Value<int> bytes = const Value.absent(),
                Value<String> sha256Hex = const Value.absent(),
                Value<int> clinical = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String> uploadedBy = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedDocumentsCompanion(
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
                state: state,
                uploadedBy: uploadedBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clinicId,
                required String patientId,
                Value<String?> visitId = const Value.absent(),
                required String fileName,
                required String contentType,
                required String category,
                Value<String> notes = const Value.absent(),
                required String objectPath,
                required int bytes,
                required String sha256Hex,
                Value<int> clinical = const Value.absent(),
                required String state,
                required String uploadedBy,
                required String createdAt,
                required String updatedAt,
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => CachedDocumentsCompanion.insert(
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
                state: state,
                uploadedBy: uploadedBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $CachedDocumentsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                patientId = false,
                visitId = false,
                documentBlobsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (documentBlobsRefs) db.documentBlobs,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (patientId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.patientId,
                                    referencedTable: $CachedDocumentsReferences
                                        ._patientIdTable(db),
                                    referencedColumn: $CachedDocumentsReferences
                                        ._patientIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (visitId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.visitId,
                                    referencedTable: $CachedDocumentsReferences
                                        ._visitIdTable(db),
                                    referencedColumn: $CachedDocumentsReferences
                                        ._visitIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (documentBlobsRefs)
                        await $_getPrefetchedData<
                          CachedDocument,
                          CachedDocuments,
                          DocumentBlob
                        >(
                          currentTable: table,
                          referencedTable: $CachedDocumentsReferences
                              ._documentBlobsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $CachedDocumentsReferences(
                                db,
                                table,
                                p0,
                              ).documentBlobsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.attachmentId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $CachedDocumentsProcessedTableManager =
    ProcessedTableManager<
      _$ClinicDatabase,
      CachedDocuments,
      CachedDocument,
      $CachedDocumentsFilterComposer,
      $CachedDocumentsOrderingComposer,
      $CachedDocumentsAnnotationComposer,
      $CachedDocumentsCreateCompanionBuilder,
      $CachedDocumentsUpdateCompanionBuilder,
      (CachedDocument, $CachedDocumentsReferences),
      CachedDocument,
      PrefetchHooks Function({
        bool patientId,
        bool visitId,
        bool documentBlobsRefs,
      })
    >;
typedef $DocumentBlobsCreateCompanionBuilder =
    DocumentBlobsCompanion Function({
      required String attachmentId,
      required String clinicId,
      required String userId,
      required Uint8List data,
      required String sha256Hex,
      Value<String> transferState,
      Value<String?> error,
      Value<int> attempts,
      required String createdAt,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $DocumentBlobsUpdateCompanionBuilder =
    DocumentBlobsCompanion Function({
      Value<String> attachmentId,
      Value<String> clinicId,
      Value<String> userId,
      Value<Uint8List> data,
      Value<String> sha256Hex,
      Value<String> transferState,
      Value<String?> error,
      Value<int> attempts,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

final class $DocumentBlobsReferences
    extends BaseReferences<_$ClinicDatabase, DocumentBlobs, DocumentBlob> {
  $DocumentBlobsReferences(super.$_db, super.$_table, super.$_typedResult);

  static CachedDocuments _attachmentIdTable(_$ClinicDatabase db) => db
      .cachedDocuments
      .createAlias('document_blobs__attachment_id__cached_documents__id');

  $CachedDocumentsProcessedTableManager get attachmentId {
    final $_column = $_itemColumn<String>('attachment_id')!;

    final manager = $CachedDocumentsTableManager(
      $_db,
      $_db.cachedDocuments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_attachmentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $DocumentBlobsFilterComposer
    extends Composer<_$ClinicDatabase, DocumentBlobs> {
  $DocumentBlobsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clinicId => $composableBuilder(
    column: $table.clinicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256Hex => $composableBuilder(
    column: $table.sha256Hex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transferState => $composableBuilder(
    column: $table.transferState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $CachedDocumentsFilterComposer get attachmentId {
    final $CachedDocumentsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attachmentId,
      referencedTable: $db.cachedDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedDocumentsFilterComposer(
            $db: $db,
            $table: $db.cachedDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DocumentBlobsOrderingComposer
    extends Composer<_$ClinicDatabase, DocumentBlobs> {
  $DocumentBlobsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clinicId => $composableBuilder(
    column: $table.clinicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256Hex => $composableBuilder(
    column: $table.sha256Hex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transferState => $composableBuilder(
    column: $table.transferState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $CachedDocumentsOrderingComposer get attachmentId {
    final $CachedDocumentsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attachmentId,
      referencedTable: $db.cachedDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedDocumentsOrderingComposer(
            $db: $db,
            $table: $db.cachedDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DocumentBlobsAnnotationComposer
    extends Composer<_$ClinicDatabase, DocumentBlobs> {
  $DocumentBlobsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clinicId =>
      $composableBuilder(column: $table.clinicId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<Uint8List> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get sha256Hex =>
      $composableBuilder(column: $table.sha256Hex, builder: (column) => column);

  GeneratedColumn<String> get transferState => $composableBuilder(
    column: $table.transferState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $CachedDocumentsAnnotationComposer get attachmentId {
    final $CachedDocumentsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attachmentId,
      referencedTable: $db.cachedDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CachedDocumentsAnnotationComposer(
            $db: $db,
            $table: $db.cachedDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DocumentBlobsTableManager
    extends
        RootTableManager<
          _$ClinicDatabase,
          DocumentBlobs,
          DocumentBlob,
          $DocumentBlobsFilterComposer,
          $DocumentBlobsOrderingComposer,
          $DocumentBlobsAnnotationComposer,
          $DocumentBlobsCreateCompanionBuilder,
          $DocumentBlobsUpdateCompanionBuilder,
          (DocumentBlob, $DocumentBlobsReferences),
          DocumentBlob,
          PrefetchHooks Function({bool attachmentId})
        > {
  $DocumentBlobsTableManager(_$ClinicDatabase db, DocumentBlobs table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DocumentBlobsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DocumentBlobsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DocumentBlobsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> attachmentId = const Value.absent(),
                Value<String> clinicId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<Uint8List> data = const Value.absent(),
                Value<String> sha256Hex = const Value.absent(),
                Value<String> transferState = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentBlobsCompanion(
                attachmentId: attachmentId,
                clinicId: clinicId,
                userId: userId,
                data: data,
                sha256Hex: sha256Hex,
                transferState: transferState,
                error: error,
                attempts: attempts,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String attachmentId,
                required String clinicId,
                required String userId,
                required Uint8List data,
                required String sha256Hex,
                Value<String> transferState = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DocumentBlobsCompanion.insert(
                attachmentId: attachmentId,
                clinicId: clinicId,
                userId: userId,
                data: data,
                sha256Hex: sha256Hex,
                transferState: transferState,
                error: error,
                attempts: attempts,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $DocumentBlobsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({attachmentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (attachmentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.attachmentId,
                                referencedTable: $DocumentBlobsReferences
                                    ._attachmentIdTable(db),
                                referencedColumn: $DocumentBlobsReferences
                                    ._attachmentIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $DocumentBlobsProcessedTableManager =
    ProcessedTableManager<
      _$ClinicDatabase,
      DocumentBlobs,
      DocumentBlob,
      $DocumentBlobsFilterComposer,
      $DocumentBlobsOrderingComposer,
      $DocumentBlobsAnnotationComposer,
      $DocumentBlobsCreateCompanionBuilder,
      $DocumentBlobsUpdateCompanionBuilder,
      (DocumentBlob, $DocumentBlobsReferences),
      DocumentBlob,
      PrefetchHooks Function({bool attachmentId})
    >;

class $ClinicDatabaseManager {
  final _$ClinicDatabase _db;
  $ClinicDatabaseManager(this._db);
  $CachedPatientsTableManager get cachedPatients =>
      $CachedPatientsTableManager(_db, _db.cachedPatients);
  $CachedAppointmentsTableManager get cachedAppointments =>
      $CachedAppointmentsTableManager(_db, _db.cachedAppointments);
  $CachedVisitsTableManager get cachedVisits =>
      $CachedVisitsTableManager(_db, _db.cachedVisits);
  $CachedDiagnosesTableManager get cachedDiagnoses =>
      $CachedDiagnosesTableManager(_db, _db.cachedDiagnoses);
  $CachedMedicationsTableManager get cachedMedications =>
      $CachedMedicationsTableManager(_db, _db.cachedMedications);
  $OutboxTableManager get outbox => $OutboxTableManager(_db, _db.outbox);
  $CacheMetadataTableManager get cacheMetadata =>
      $CacheMetadataTableManager(_db, _db.cacheMetadata);
  $SyncResolutionsTableManager get syncResolutions =>
      $SyncResolutionsTableManager(_db, _db.syncResolutions);
  $CachedDocumentsTableManager get cachedDocuments =>
      $CachedDocumentsTableManager(_db, _db.cachedDocuments);
  $DocumentBlobsTableManager get documentBlobs =>
      $DocumentBlobsTableManager(_db, _db.documentBlobs);
}
