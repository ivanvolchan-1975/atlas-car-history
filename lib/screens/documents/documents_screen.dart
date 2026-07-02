import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../database/database_helper.dart';
import '../../models/document.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<Document> _docs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final docs = await DatabaseHelper.instance.getDocuments();
    if (mounted) setState(() { _docs = docs; _loading = false; });
  }

  Future<void> _addDocument() async {
    final type = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Сфотографировать'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.purple),
              title: const Text('Из галереи'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF файл'),
              onTap: () => Navigator.pop(ctx, 'pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.orange),
              title: const Text('Любой файл'),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
          ],
        ),
      ),
    );
    if (type == null) return;

    String? filePath;

    if (type == 'camera') {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);
      filePath = picked?.path;
    } else if (type == 'gallery') {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      filePath = picked?.path;
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: type == 'pdf' ? FileType.custom : FileType.any,
        allowedExtensions: type == 'pdf' ? ['pdf'] : null,
      );
      filePath = result?.files.first.path;
    }

    if (filePath == null || !mounted) return;

    // Ask for metadata
    final result = await showDialog<Document>(
      context: context,
      builder: (ctx) => _DocumentMetaDialog(filePath: filePath!),
    );
    if (result != null) {
      await DatabaseHelper.instance.insertDocument(result);
      _load();
    }
  }

  Future<void> _deleteDoc(Document doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить документ?'),
        content: Text('Удалить "${doc.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseHelper.instance.deleteDocument(doc.id!);
      _load();
    }
  }

  Future<void> _shareDoc(Document doc) async {
    final file = XFile(doc.filePath);
    await Share.shareXFiles([file], text: doc.title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Документы')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _docs.isEmpty
              ? _EmptyState(onAdd: _addDocument)
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _docs.length,
                  itemBuilder: (_, i) => _DocCard(
                    doc: _docs[i],
                    onShare: () => _shareDoc(_docs[i]),
                    onDelete: () => _deleteDoc(_docs[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDocument,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80,
              color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          const Text('Документов нет'),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Добавить документ'),
          ),
        ],
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final Document doc;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _DocCard({required this.doc, required this.onShare, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd.MM.yyyy');
    final isImage = ['.jpg', '.jpeg', '.png', '.heic']
        .any((ext) => doc.filePath.toLowerCase().endsWith(ext));

    final (icon, color) = switch (doc.type) {
      DocumentType.insurance => (Icons.shield, Colors.green),
      DocumentType.techPassport => (Icons.badge, Colors.blue),
      DocumentType.receipt => (Icons.receipt, Colors.orange),
      DocumentType.pdf => (Icons.picture_as_pdf, Colors.red),
      DocumentType.photo => (Icons.photo, Colors.purple),
      DocumentType.other => (Icons.insert_drive_file, Colors.grey),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: isImage && File(doc.filePath).existsSync()
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(doc.filePath),
                    width: 48, height: 48, fit: BoxFit.cover),
              )
            : Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
        title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doc.type.label,
                style: TextStyle(fontSize: 12, color: cs.outline)),
            Text('Добавлено: ${dateFmt.format(doc.addedAt)}',
                style: TextStyle(fontSize: 12, color: cs.outline)),
            if (doc.expiresAt != null)
              Text('Действует до: ${dateFmt.format(doc.expiresAt!)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: doc.expiresAt!.isBefore(DateTime.now())
                          ? cs.error
                          : Colors.green)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.share, size: 20), onPressed: onShare),
            IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: cs.error),
                onPressed: onDelete),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _DocumentMetaDialog extends StatefulWidget {
  final String filePath;
  const _DocumentMetaDialog({required this.filePath});

  @override
  State<_DocumentMetaDialog> createState() => _DocumentMetaDialogState();
}

class _DocumentMetaDialogState extends State<_DocumentMetaDialog> {
  final _title = TextEditingController();
  DocumentType _type = DocumentType.other;
  DateTime? _expires;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save() {
    if (_title.text.trim().isEmpty) return;
    final doc = Document(
      title: _title.text.trim(),
      type: _type,
      filePath: widget.filePath,
      addedAt: DateTime.now(),
      expiresAt: _expires,
    );
    Navigator.pop(context, doc);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd.MM.yyyy');
    return AlertDialog(
      title: const Text('Информация о документе'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Название *'),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DocumentType>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Тип'),
            items: DocumentType.values
                .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                .toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Срок действия', style: TextStyle(fontSize: 14)),
            subtitle: Text(_expires != null ? dateFmt.format(_expires!) : 'Не указан'),
            trailing: const Icon(Icons.calendar_today, size: 18),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 365)),
                firstDate: DateTime.now(),
                lastDate: DateTime(2040),
              );
              if (picked != null) setState(() => _expires = picked);
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(onPressed: _save, child: const Text('Сохранить')),
      ],
    );
  }
}
