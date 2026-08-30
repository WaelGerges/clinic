import '../domain/models.dart';
import '../domain/clinic_time.dart';
import 'database.dart';
import 'repository.dart';

Future<ClinicRepository> createDemoRepository(AppKind kind) async {
  final now = ClinicTime.now();
  const clinic = 'demo-clinic', doctor = 'demo-doctor';
  final repository = ClinicRepository(
    db: ClinicDatabase.memory(),
    session: ClinicSession(
      userId: kind == AppKind.doctor ? doctor : 'demo-assistant',
      clinicId: clinic,
      clinicName: 'Main Clinic · Fictional',
      role: kind == AppKind.doctor ? ClinicRole.doctor : ClinicRole.assistant,
      doctorId: doctor,
      isDemo: true,
      isAdmin: kind == AppKind.doctor,
    ),
  );
  final names = ['Ahmed Ali', 'Sara Hassan', 'Mona Adel', 'Omar Mostafa'];
  final patients = List.generate(
    4,
    (i) => Patient(
      id: 'demo-patient-$i',
      clinicId: clinic,
      name: names[i],
      gender: i == 1 || i == 2 ? 'Female' : 'Male',
      birthDate: DateTime.utc(1985 + i * 3, 4, 12),
      mobile: '0100000000$i',
      number: 'P-${1042 + i}',
      address: 'Fictional address, Cairo',
      notes: 'Fictional record. Do not enter real patient information.',
      alerts: i == 0 ? 'Sample alert — verify with the patient' : '',
      createdAt: now.subtract(const Duration(days: 180)),
      updatedAt: now,
      version: 1,
    ),
  );
  final appointments = List.generate(
    4,
    (i) => Appointment(
      id: 'demo-appointment-$i',
      clinicId: clinic,
      patientId: patients[i].id,
      doctorId: doctor,
      startsAt: ClinicTime.at(now, 9, i * 15),
      status: [
        AppointmentStatus.withDoctor,
        AppointmentStatus.waiting,
        AppointmentStatus.arrived,
        AppointmentStatus.scheduled,
      ][i],
      version: 1,
    ),
  );
  final previousDate = now.subtract(const Duration(days: 30));
  appointments.add(
    Appointment(
      id: 'demo-previous-appointment',
      clinicId: clinic,
      patientId: patients.first.id,
      doctorId: doctor,
      startsAt: previousDate,
      status: AppointmentStatus.completed,
      version: 3,
    ),
  );
  final previous = Visit(
    id: 'demo-previous-visit',
    clinicId: clinic,
    patientId: patients.first.id,
    appointmentId: 'demo-previous-appointment',
    doctorId: doctor,
    createdAt: previousDate,
    updatedAt: previousDate,
    diagnoses: ['Fictional assessment for preview'],
    notes:
        'Training example only. This is not a real medical record or treatment recommendation.',
    followUp: 'Fictional follow-up note',
    completed: true,
    version: 2,
    currentRevision: 1,
  );
  await repository.seedDemo(patients, appointments, [previous]);
  return repository;
}
