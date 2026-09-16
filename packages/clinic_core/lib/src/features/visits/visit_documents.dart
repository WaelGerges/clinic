import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../domain/models.dart';
import '../../domain/clinic_time.dart';
import '../../presentation/common.dart';
import '../../presentation/language.dart';

enum VisitDocumentKind { prescription, summary, referral }


/// Normalizes Eastern Arabic-Indic digits to Western digits.
///
/// `DateFormat(..., 'ar')` emits ٠-٩ while every other number in the document
/// is formatted with `toString()`, which emits 0-9. Printing both on the same
/// page looks like a defect, and Egyptian clinical paperwork conventionally
/// uses Western digits, so the whole document is normalized to them.
String latinDigits(String value) {
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  var result = value;
  for (var digit = 0; digit < 10; digit++) {
    result = result.replaceAll(eastern[digit], '$digit');
  }
  return result;
}

Future<Uint8List> buildVisitDocument({
  required ClinicSession session,
  required Patient patient,
  required Visit visit,
  required VisitDocumentKind kind,
  required bool arabic,
  String referral = '',
  PdfPageFormat format = PdfPageFormat.a4,
}) async {
  if (!session.clinicalRead ||
      patient.clinicId != session.clinicId ||
      visit.clinicId != session.clinicId ||
      visit.patientId != patient.id ||
      !visit.completed ||
      (kind == VisitDocumentKind.referral && !session.isDoctor)) {
    throw const ClinicFailure(
      'forbidden',
      'Only completed visits with clinical access can be printed.',
    );
  }
  await initializeDateFormatting(arabic ? 'ar' : 'en');
  final normal = pw.Font.ttf(
    await rootBundle.load(
      'packages/clinic_core/assets/fonts/Amiri-Regular.ttf',
    ),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('packages/clinic_core/assets/fonts/Amiri-Bold.ttf'),
  );
  String documentText(String text, [List<Object?> args = const []]) {
    for (var i = 0; i < args.length; i++) {
      text = text.replaceAll('{$i}', latinDigits(args[i].toString()));
    }
    return latinDigits(text);
  }

  String label(String en, String ar) => arabic ? ar : en;
  final title = switch (kind) {
    VisitDocumentKind.prescription => label('Prescription', 'وصفة طبية'),
    VisitDocumentKind.summary => label('Visit summary', 'ملخص الزيارة'),
    VisitDocumentKind.referral => label('Referral letter', 'خطاب إحالة'),
  };
  // Direction follows the document's language. Content is consulted only for
  // a line written entirely in the other script (a Latin-only drug name in an
  // Arabic document, or an Arabic-only name in an English one). Deciding from
  // "contains any Arabic" flipped whole mixed lines - an Arabic patient name
  // in an English document turned the entire line RTL.
  final arabicLetter = RegExp(r'[\u0600-\u06ff]');
  final latinLetter = RegExp(r'[A-Za-z]');
  pw.TextDirection directionFor(String value) {
    final hasArabic = arabicLetter.hasMatch(value);
    final hasLatin = latinLetter.hasMatch(value);
    if (arabic) {
      return hasLatin && !hasArabic
          ? pw.TextDirection.ltr
          : pw.TextDirection.rtl;
    }
    return hasArabic && !hasLatin
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;
  }

  pw.Text pdfText(String value, {pw.TextStyle? style}) =>
      pw.Text(value, style: style, textDirection: directionFor(value));
  List<pw.Widget> textBlocks(String value) {
    final result = <pw.Widget>[];
    while (value.length > 600) {
      var split = value.lastIndexOf(' ', 600);
      if (split < 1) split = 600;
      result.add(pdfText(value.substring(0, split)));
      value = value.substring(split).trimLeft();
    }
    if (value.isNotEmpty) result.add(pdfText(value));
    return result;
  }

  final document = pw.Document(title: title, author: session.clinicName);
  pw.Widget section(String heading, String body) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.SizedBox(height: 14),
      pdfText(
        heading,
        style: pw.TextStyle(
          font: bold,
          fontSize: 14,
          color: PdfColor.fromHex('#007E80'),
        ),
      ),
      ...textBlocks(body.isEmpty ? label('Not recorded', 'غير مسجل') : body),
    ],
  );
  document.addPage(
    pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(36),
      theme: pw.ThemeData.withFont(base: normal, bold: bold),
      textDirection: arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pdfText(
            session.clinicName,
            style: pw.TextStyle(
              font: bold,
              fontSize: 23,
              color: PdfColor.fromHex('#007E80'),
            ),
          ),
          pdfText(
            documentText(title),
            style: pw.TextStyle(font: bold, fontSize: 19),
          ),
          pw.Divider(color: PdfColors.teal),
        ],
      ),
      footer: (context) => pw.Column(
        children: [
          pw.Divider(),
          pdfText(
            label(
              'Generated from a saved visit - review before use.',
              'تم الإنشاء من زيارة محفوظة - تراجع قبل الاستخدام.',
            ),
            style: const pw.TextStyle(fontSize: 9),
          ),
          pdfText(
            documentText("{0} / {1}", [context.pageNumber, context.pagesCount]),
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
      build: (context) => [
        if (session.isDemo)
          pdfText(
            label('FICTIONAL PREVIEW', 'معاينة ببيانات خيالية'),
            style: pw.TextStyle(font: bold, color: PdfColors.red),
          ),
        pdfText(
          documentText("{0}: {1}", [label('Patient', 'المريض'), patient.name]),
          style: pw.TextStyle(font: bold, fontSize: 15),
        ),
        pdfText(
          documentText("{0}: {1}", [
            label('Patient ID', 'رقم المريض'),
            patient.number,
          ]),
        ),
        pdfText(
          documentText("{0}: {1}", [
            label('Date of birth', 'تاريخ الميلاد'),
            DateFormat(
              'd MMMM yyyy',
              arabic ? 'ar' : 'en',
            ).format(patient.birthDate),
          ]),
        ),
        pdfText(
          documentText("{0}: {1}", [
            label('Visit date', 'تاريخ الزيارة'),
            DateFormat(
              'd MMMM yyyy HH:mm',
              arabic ? 'ar' : 'en',
            ).format(ClinicTime.local(visit.createdAt)),
          ]),
        ),
        pdfText(
          documentText("{0}: {1}", [
            label('Revision', 'المراجعة'),
            visit.currentRevision,
          ]),
        ),
        if (kind == VisitDocumentKind.referral)
          section(label('Referral request', 'طلب الإحالة'), referral),
        if (kind != VisitDocumentKind.prescription)
          section(label('Diagnosis', 'التشخيص'), visit.diagnoses.join('\n')),
        if (kind == VisitDocumentKind.summary)
          section(label('Clinical notes', 'الملاحظات السريرية'), visit.notes),
        if (kind != VisitDocumentKind.referral) ...[
          pw.SizedBox(height: 14),
          pdfText(
            label('Medications', 'الأدوية'),
            style: pw.TextStyle(
              font: bold,
              fontSize: 14,
              color: PdfColors.teal,
            ),
          ),
          if (visit.medications.isEmpty)
            pdfText(label('No medications recorded.', 'لا توجد أدوية مسجلة.')),
          for (var i = 0; i < visit.medications.length; i++) ...[
            pw.SizedBox(height: 10),
            pw.Inseparable(
              canSpan: visit.medications[i].toMap().values.join().length > 1800,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pdfText(
                    '${i + 1}. ${visit.medications[i].name} ${visit.medications[i].strength}',
                    style: pw.TextStyle(font: bold, fontSize: 14),
                  ),
                  for (final entry in <String, String>{
                    label('Dose', 'الجرعة'): visit.medications[i].dose,
                    label('Frequency', 'التكرار'):
                        visit.medications[i].frequency,
                    label('Duration', 'المدة'): visit.medications[i].duration,
                    label('Instructions', 'التعليمات'):
                        visit.medications[i].instructions,
                    label('Notes', 'ملاحظات'): visit.medications[i].notes,
                  }.entries)
                    if (entry.value.isNotEmpty)
                      ...textBlocks('${entry.key}: ${entry.value}'),
                ],
              ),
            ),
          ],
        ],
        section(
          label('Follow-up instructions', 'تعليمات المتابعة'),
          visit.followUp,
        ),
        pw.SizedBox(height: 30),
        pdfText(
          label(
            'Doctor name / signature: ____________________',
            'اسم الطبيب / التوقيع: ____________________',
          ),
        ),
      ],
    ),
  );
  return document.save();
}

class VisitDocumentsScreen extends ConsumerStatefulWidget {
  const VisitDocumentsScreen({
    super.key,
    required this.patientId,
    required this.visitId,
  });
  final String patientId, visitId;
  @override
  ConsumerState<VisitDocumentsScreen> createState() =>
      _VisitDocumentsScreenState();
}

class _VisitDocumentsScreenState extends ConsumerState<VisitDocumentsScreen> {
  Patient? patient;
  Visit? visit;
  String? error;
  bool arabic = appLanguage.value.languageCode == 'ar';
  VisitDocumentKind kind = VisitDocumentKind.prescription;
  final referral = TextEditingController();
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final repo = ref.read(repositoryProvider);
    try {
      if (!repo.session.clinicalRead) {
        throw const ClinicFailure('forbidden', 'Clinical access restricted');
      }
      final p = await repo.patient(widget.patientId);
      final v = await repo.visitForPrinting(widget.patientId, widget.visitId);
      if (p == null || !v.completed) {
        throw const ClinicFailure(
          'not_found',
          'Only completed visits with clinical access can be printed.',
        );
      }
      if (mounted) {
        setState(() {
          patient = p;
          visit = v;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = safeError(e));
    }
  }

  @override
  void dispose() {
    referral.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr('Print visit documents'))),
    body: error != null
        ? Center(child: Text(tr(error!)))
        : visit == null
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DropdownButton<VisitDocumentKind>(
                      value: kind,
                      items: [
                        DropdownMenuItem(
                          value: VisitDocumentKind.prescription,
                          child: Text(tr('Prescription')),
                        ),
                        DropdownMenuItem(
                          value: VisitDocumentKind.summary,
                          child: Text(tr('Visit summary')),
                        ),
                        if (ref.read(repositoryProvider).session.isDoctor)
                          DropdownMenuItem(
                            value: VisitDocumentKind.referral,
                            child: Text(tr('Referral letter')),
                          ),
                      ],
                      onChanged: (v) => setState(() => kind = v!),
                    ),
                    ChoiceChip(
                      label: Text(tr('English')),
                      selected: !arabic,
                      onSelected: (_) => setState(() => arabic = false),
                    ),
                    ChoiceChip(
                      label: Text(tr('العربية')),
                      selected: arabic,
                      onSelected: (_) => setState(() => arabic = true),
                    ),
                  ],
                ),
              ),
              if (kind == VisitDocumentKind.referral)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: referral,
                    maxLength: 3000,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: tr('Referral recipient and reason'),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  tr(
                    'Clinical text is printed as recorded. Review the document and the recipient before printing or sharing.',
                  ),
                ),
              ),
              Expanded(
                child: PdfPreview(
                  key: ValueKey('${kind.name}-$arabic-${referral.text}'),
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  allowPrinting: true,
                  allowSharing: true,
                  pdfFileName: 'visit-${visit!.id}-${kind.name}.pdf',
                  build: (format) => buildVisitDocument(
                    session: ref.read(repositoryProvider).session,
                    patient: patient!,
                    visit: visit!,
                    kind: kind,
                    arabic: arabic,
                    referral: referral.text,
                    format: format,
                  ),
                ),
              ),
            ],
          ),
  );
}
