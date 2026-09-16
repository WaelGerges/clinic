import 'package:clinic_core/src/presentation/language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';
import '../data/repository.dart';

final repositoryProvider = Provider<ClinicRepository>(
  (ref) => throw StateError('Clinic session required'),
);
final changesProvider = StreamProvider<int>((ref) async* {
  var revision = 0;
  yield revision;
  await for (final _ in ref.watch(repositoryProvider).changes) {
    yield ++revision;
  }
});

ThemeData clinicTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors = ColorScheme.fromSeed(
    seedColor: const Color(0xff007e80),
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colors,
    scaffoldBackgroundColor: dark
        ? const Color(0xff0c1728)
        : const Color(0xfff5f8fa),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xff0c1728) : const Color(0xfff5f8fa),
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.all(16),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: .5)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45),
    ),
  );
}

class LoadView<T> extends ConsumerWidget {
  const LoadView({super.key, required this.load, required this.builder});
  final Future<T> Function(ClinicRepository) load;
  final Widget Function(T) builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(changesProvider);
    return FutureBuilder<T>(
      future: load(ref.watch(repositoryProvider)),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return EmptyPanel(
            icon: Icons.error_outline,
            title: 'Unable to load',
            message: tr(safeError(snapshot.error!)),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return builder(snapshot.data as T);
      },
    );
  }
}

String safeError(Object error) => error is ClinicFailure
    ? error.message
    : 'The operation could not be completed. Your saved local work has not been deleted.';
Future<bool> runAction(
  BuildContext context,
  Future<void> Function() operation, {
  String? success,
}) async {
  try {
    await operation();
    if (context.mounted && success != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr(success))));
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(safeError(error))),
          duration: const Duration(seconds: 6),
        ),
      );
    }
    return false;
  }
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          tr(title),
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(tr(message), textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final AppointmentStatus status;
  @override
  Widget build(BuildContext context) => Semantics(
    label: tr('Appointment status: {0}', [tr(status.label)]),
    child: Chip(
      avatar: Icon(
        status == AppointmentStatus.completed
            ? Icons.check_circle_outline
            : status == AppointmentStatus.withDoctor
            ? Icons.medical_services_outlined
            : Icons.schedule,
        size: 16,
      ),
      label: Text(tr(status.label)),
      backgroundColor: status == AppointmentStatus.withDoctor
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      visualDensity: VisualDensity.compact,
    ),
  );
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });
  final String title;
  final Widget child;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr(title),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class PatientIdentity extends StatelessWidget {
  const PatientIdentity(this.patient, {super.key});
  final Patient patient;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CircleAvatar(
        radius: 26,
        child: Text(
          patient.name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((e) => e.isEmpty ? '' : e[0])
              .join(),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(patient.name, style: Theme.of(context).textTheme.titleLarge),
            Text(
              tr("{0} years · {1} · {2}", [
                patient.ageAt(DateTime.now()),
                tr(patient.gender),
                patient.number,
              ]),
            ),
            Text(patient.mobile),
          ],
        ),
      ),
    ],
  );
}

class MedicalAlert extends StatelessWidget {
  const MedicalAlert(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Semantics(
    label: tr('Important medical alert'),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 22,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            tr(message),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    ),
  );
}
