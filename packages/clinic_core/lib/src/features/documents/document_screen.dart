import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../domain/clinic_time.dart';
import '../../domain/models.dart';
import '../../presentation/common.dart';

class ClinicDocumentsPanel extends ConsumerStatefulWidget {
  const ClinicDocumentsPanel({
    super.key,
    required this.patientId,
    this.visitId,
    this.compact = false,
  });

  final String patientId;
  final String? visitId;
  final bool compact;

  @override
  ConsumerState<ClinicDocumentsPanel> createState() =>
      _ClinicDocumentsPanelState();
}

class _ClinicDocumentsPanelState extends ConsumerState<ClinicDocumentsPanel> {
  final picker = ImagePicker();
  bool refreshing = false, archived = false, adding = false;
  String? warning;

  @override
  void initState() {
    super.initState();
    unawaited(_recoverLostImage());
    unawaited(refresh());
  }

  Future<void> _recoverLostImage() async {
    try {
      final response = await picker.retrieveLostData();
      if (response.isEmpty || !mounted) return;
      final file = response.files?.firstOrNull;
      if (file != null) await _stageXFile(file);
    } catch (_) {
      if (mounted) {
        setState(() {
          warning = 'A previously interrupted camera import could not be recovered.';
        });
      }
    }
  }

  Future<void> refresh() async {
    if (refreshing) return;
    setState(() => refreshing = true);
    try {
      await ref.read(repositoryProvider).refreshDocuments(widget.patientId);
      if (mounted) setState(() => warning = null);
    } catch (_) {
      if (mounted) {
        setState(() {
          warning = 'Online refresh failed. Showing protected local documents.';
        });
      }
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  Future<void> chooseSource() async {
    if (adding) return;
    final source = await showModalBottomSheet<_DocumentSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Add patient document'),
              subtitle: Text('JPEG, PNG, WebP, or PDF · maximum 20 MB'),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Choose file'),
              onTap: () => Navigator.pop(context, _DocumentSource.file),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, _DocumentSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose photo'),
              onTap: () => Navigator.pop(context, _DocumentSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    setState(() => adding = true);
    try {
      if (source == _DocumentSource.file) {
        final file = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
        );
        if (file == null) return;
        if (await file.length() > ClinicDocument.maxBytes) {
          throw const ClinicFailure(
            'invalid_document',
            'The selected document is larger than 20 MB.',
          );
        }
        await _stage(file.name, await file.readAsBytes());
      } else {
        final file = await picker.pickImage(
          source: source == _DocumentSource.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          imageQuality: 95,
          requestFullMetadata: false,
        );
        if (file != null) await _stageXFile(file);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(safeError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => adding = false);
    }
  }

  Future<void> _stageXFile(XFile file) async {
    final length = await file.length();
    if (length > ClinicDocument.maxBytes) {
      throw const ClinicFailure(
        'invalid_document',
        'The selected image is larger than 20 MB.',
      );
    }
    await _stage(file.name, await file.readAsBytes());
  }

  Future<void> _stage(String fileName, Uint8List bytes) async {
    final contentType = ClinicDocument.detectContentType(bytes);
    if (contentType == null) {
      throw const ClinicFailure(
        'invalid_document',
        'The selected file is not a supported image or PDF.',
      );
    }
    if (!mounted) return;
    final repo = ref.read(repositoryProvider);
    final metadata = await showDialog<_DocumentMetadata>(
      context: context,
      builder: (_) => _DocumentMetadataDialog(
        fileName: fileName,
        bytes: bytes.length,
        clinicalRead: repo.session.clinicalRead,
        visitDocument: widget.visitId != null,
      ),
    );
    if (metadata == null || !mounted) return;
    await repo.stageDocument(
      patientId: widget.patientId,
      visitId: widget.visitId,
      fileName: fileName,
      contentType: contentType,
      category: metadata.category,
      notes: metadata.notes,
      clinical: metadata.clinical,
      data: bytes,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document protected locally and queued for upload.'),
        ),
      );
      setState(() {});
    }
  }

  Future<void> preview(ClinicDocument value) async {
    try {
      final content = await ref
          .read(repositoryProvider)
          .documentContent(value.id, purpose: 'preview');
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DocumentPreviewScreen(content: content),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(safeError(error))),
        );
      }
    }
  }

  Future<void> share(ClinicDocument value) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share a medical document?'),
        content: const Text(
          'The selected external app may keep a copy outside the clinic’s protected storage. Confirm the recipient before sending.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    File? temporary;
    try {
      final content = await ref
          .read(repositoryProvider)
          .documentContent(value.id, purpose: 'share');
      final directory = await getTemporaryDirectory();
      final safeName = value.fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      temporary = File(
        p.join(directory.path, 'clinic_${const Uuid().v4()}_$safeName'),
      );
      await temporary.writeAsBytes(content.data, flush: true);
      if (!mounted) return;
      final box = Overlay.of(context).context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              temporary.path,
              name: value.fileName,
              mimeType: value.contentType,
            ),
          ],
          subject: 'Clinic document: ${value.fileName}',
          sharePositionOrigin: origin,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(safeError(error))),
        );
      }
    } finally {
      try {
        if (temporary != null && await temporary.exists()) {
          await temporary.delete();
        }
      } catch (_) {}
    }
  }

  Future<void> archive(ClinicDocument value) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(value.isArchived ? 'Restore document?' : 'Archive document?'),
        content: Text(
          value.isArchived
              ? 'The document will return to the patient record.'
              : 'The protected object is retained, but normal access is revoked immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(value.isArchived ? 'Restore' : 'Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await runAction(
      context,
      () async {
        await ref
            .read(repositoryProvider)
            .setDocumentArchived(value, !value.isArchived);
        if (mounted) setState(() {});
      },
      success: value.isArchived ? 'Document restored.' : 'Document archived.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    return StreamBuilder<void>(
      stream: repo.changes,
      builder: (context, _) => FutureBuilder<List<ClinicDocument>>(
        future: repo.documents(
          widget.patientId,
          visitId: widget.visitId,
          archived: archived,
        ),
        builder: (context, snapshot) {
          final values = snapshot.data ?? const <ClinicDocument>[];
          final content = Column(
            children: [
              if (warning != null)
                MaterialBanner(
                  content: Text(warning!),
                  actions: [
                    TextButton(onPressed: refresh, child: const Text('Retry')),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Current')),
                          ButtonSegment(value: true, label: Text('Archived')),
                        ],
                        selected: {archived},
                        onSelectionChanged: (value) {
                          setState(() => archived = value.single);
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh documents',
                      onPressed: refreshing ? null : refresh,
                      icon: refreshing
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: values.isEmpty
                    ? EmptyPanel(
                        icon: Icons.description_outlined,
                        title: archived
                            ? 'No archived documents'
                            : 'No documents yet',
                        message: archived
                            ? 'Archived documents remain protected and can be restored here.'
                            : 'Add an image or PDF. It is encrypted locally before upload.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: values.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final value = values[index];
                          return Card(
                            child: ListTile(
                              onTap: value.isArchived ? null : () => preview(value),
                              leading: Icon(
                                value.isPdf
                                    ? Icons.picture_as_pdf_outlined
                                    : Icons.image_outlined,
                              ),
                              title: Text(
                                value.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${value.category.label} · ${_formatBytes(value.bytes)} · ${DateFormat.yMMMd().format(ClinicTime.local(value.createdAt))}\n${_stateLabel(value.state)}${value.clinical ? ' · Clinical' : ''}',
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                tooltip: 'Document actions',
                                onSelected: (action) async {
                                  switch (action) {
                                    case 'preview':
                                      await preview(value);
                                    case 'share':
                                      await share(value);
                                    case 'retry':
                                      await runAction(
                                        context,
                                        () => repo.retryDocument(value.id),
                                        success: 'Document queued to retry.',
                                      );
                                    case 'archive':
                                      await archive(value);
                                  }
                                },
                                itemBuilder: (_) => [
                                  if (!value.isArchived)
                                    const PopupMenuItem(
                                      value: 'preview',
                                      child: Text('Preview'),
                                    ),
                                  if (value.isReady && !value.isArchived)
                                    const PopupMenuItem(
                                      value: 'share',
                                      child: Text('Share / save copy'),
                                    ),
                                  if (value.state == 'failed')
                                    const PopupMenuItem(
                                      value: 'retry',
                                      child: Text('Retry upload'),
                                    ),
                                  if (value.isReady || value.isArchived)
                                    PopupMenuItem(
                                      value: 'archive',
                                      child: Text(
                                        value.isArchived ? 'Restore' : 'Archive',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
          return Stack(
            children: [
              content,
              if (!archived)
                Positioned(
                  right: 18,
                  bottom: 18,
                  child: FloatingActionButton.extended(
                    heroTag: 'document-add-${widget.patientId}-${widget.visitId}',
                    onPressed: adding ? null : chooseSource,
                    icon: adding
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Add document'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class DocumentPreviewScreen extends StatelessWidget {
  const DocumentPreviewScreen({super.key, required this.content});
  final ClinicDocumentContent content;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(content.document.fileName)),
    body: SafeArea(
      child: content.document.isImage
          ? InteractiveViewer(
              minScale: 0.5,
              maxScale: 6,
              child: Center(
                child: Image.memory(
                  content.data,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const EmptyPanel(
                    icon: Icons.broken_image_outlined,
                    title: 'Image preview failed',
                    message: 'The protected file was retained.',
                  ),
                ),
              ),
            )
          : PdfViewer.data(
              content.data,
              sourceName: content.document.fileName,
              params: const PdfViewerParams(
                maxImageBytesCachedOnMemory: 40 * 1024 * 1024,
              ),
            ),
    ),
  );
}

class _DocumentMetadataDialog extends StatefulWidget {
  const _DocumentMetadataDialog({
    required this.fileName,
    required this.bytes,
    required this.clinicalRead,
    required this.visitDocument,
  });
  final String fileName;
  final int bytes;
  final bool clinicalRead, visitDocument;

  @override
  State<_DocumentMetadataDialog> createState() =>
      _DocumentMetadataDialogState();
}

class _DocumentMetadataDialogState extends State<_DocumentMetadataDialog> {
  final notes = TextEditingController();
  ClinicDocumentCategory category = ClinicDocumentCategory.other;
  late bool clinical = widget.visitDocument || widget.clinicalRead;

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Document details'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.fileName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _formatBytes(widget.bytes),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ClinicDocumentCategory>(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final value in ClinicDocumentCategory.values)
                DropdownMenuItem(value: value, child: Text(value.label)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => category = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notes,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              alignLabelWithHint: true,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: clinical,
            onChanged: widget.visitDocument || !widget.clinicalRead
                ? null
                : (value) => setState(() => clinical = value),
            title: const Text('Clinical document'),
            subtitle: Text(
              widget.visitDocument
                  ? 'Visit documents are always clinical.'
                  : widget.clinicalRead
                  ? 'Only staff with clinical access can open it.'
                  : 'Clinical access has not been granted.',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(
          context,
          _DocumentMetadata(category, notes.text.trim(), clinical),
        ),
        child: const Text('Protect and add'),
      ),
    ],
  );
}

enum _DocumentSource { file, camera, gallery }

class _DocumentMetadata {
  const _DocumentMetadata(this.category, this.notes, this.clinical);
  final ClinicDocumentCategory category;
  final String notes;
  final bool clinical;
}

String _formatBytes(int value) {
  if (value >= 1024 * 1024) {
    return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (value >= 1024) return '${(value / 1024).toStringAsFixed(1)} KB';
  return '$value B';
}

String _stateLabel(String state) => switch (state) {
  'pending' => 'Waiting to upload',
  'failed' => 'Upload needs attention',
  'archived' => 'Archived',
  'ready' => 'Available',
  _ => 'Synchronizing',
};
