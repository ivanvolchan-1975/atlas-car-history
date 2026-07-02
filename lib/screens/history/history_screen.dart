import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/service_record.dart';
import '../../widgets/photo_gallery.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ServiceRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await DatabaseHelper.instance.getServiceRecords();
    if (mounted) setState(() { _records = records; _loading = false; });
  }

  Future<void> _addRecord() async {
    final result = await Navigator.push<ServiceRecord>(
      context,
      MaterialPageRoute(builder: (_) => const ServiceRecordForm()),
    );
    if (result != null) {
      await DatabaseHelper.instance.insertServiceRecord(result);
      _load();
    }
  }

  Future<void> _openRecord(ServiceRecord record) async {
    final result = await Navigator.push<ServiceRecord>(
      context,
      MaterialPageRoute(builder: (_) => ServiceRecordDetail(record: record)),
    );
    if (result != null) {
      await DatabaseHelper.instance.updateServiceRecord(result);
      _load();
    }
  }

  Future<void> _deleteRecord(ServiceRecord record) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: Text('Удалить запись от ${DateFormat('dd.MM.yyyy').format(record.date)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseHelper.instance.deleteServiceRecord(record.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('История обслуживания')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? _EmptyState(onAdd: _addRecord)
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _records.length,
                  itemBuilder: (_, i) => _RecordCard(
                    record: _records[i],
                    onTap: () => _openRecord(_records[i]),
                    onDelete: () => _deleteRecord(_records[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecord,
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
          Icon(Icons.history, size: 80, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          const Text('История пуста'),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Добавить запись'),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final ServiceRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RecordCard({required this.record, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,###', 'ru');
    final dateFmt = DateFormat('dd MMMM yyyy', 'ru');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.build, size: 20, color: cs.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateFmt.format(record.date),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.outline)),
                        Text(record.description,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    color: cs.error,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Badge(Icons.speed, '${fmt.format(record.mileage)} км'),
                  const SizedBox(width: 8),
                  if (record.cost > 0)
                    _Badge(Icons.payments, '${fmt.format(record.cost.toInt())} ₽'),
                  const Spacer(),
                  if (record.photoPaths.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.photo, size: 16, color: cs.outline),
                        const SizedBox(width: 4),
                        Text('${record.photoPaths.length}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.outline)),
                      ],
                    ),
                ],
              ),
              if (record.comment != null && record.comment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(record.comment!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.outline),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              if (record.photoPaths.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: record.photoPaths.length.clamp(0, 5),
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(record.photoPaths[i]),
                          width: 64, height: 64, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              width: 64, height: 64,
                              color: cs.surfaceContainerHighest,
                              child: const Icon(Icons.broken_image))),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Badge(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── FORM ───────────────────────────────────────────────────────────────────

class ServiceRecordForm extends StatefulWidget {
  final ServiceRecord? initial;
  const ServiceRecordForm({super.key, this.initial});

  @override
  State<ServiceRecordForm> createState() => _ServiceRecordFormState();
}

class _ServiceRecordFormState extends State<ServiceRecordForm> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  late TextEditingController _mileage;
  late TextEditingController _desc;
  late TextEditingController _cost;
  late TextEditingController _comment;
  List<String> _photos = [];

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _date = r?.date ?? DateTime.now();
    _mileage = TextEditingController(text: r?.mileage.toString() ?? '');
    _desc = TextEditingController(text: r?.description ?? '');
    _cost = TextEditingController(text: r?.cost.toStringAsFixed(0) ?? '0');
    _comment = TextEditingController(text: r?.comment ?? '');
    _photos = List.from(r?.photoPaths ?? []);
  }

  @override
  void dispose() {
    _mileage.dispose(); _desc.dispose(); _cost.dispose(); _comment.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final record = ServiceRecord(
      id: widget.initial?.id,
      date: _date,
      mileage: int.tryParse(_mileage.text) ?? 0,
      description: _desc.text.trim(),
      cost: double.tryParse(_cost.text) ?? 0,
      comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
      photoPaths: _photos,
    );
    Navigator.pop(context, record);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMMM yyyy', 'ru');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Новая запись' : 'Редактировать'),
        actions: [
          FilledButton(onPressed: _save, child: const Text('Сохранить')),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Дата'),
                subtitle: Text(dateFmt.format(_date)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mileage,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Пробег', suffixText: 'км', prefixIcon: Icon(Icons.speed)),
              validator: (v) => (v == null || v.isEmpty) ? 'Укажите пробег' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Описание работ', prefixIcon: Icon(Icons.description)),
              validator: (v) => (v == null || v.isEmpty) ? 'Укажите описание' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cost,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Стоимость', suffixText: '₽', prefixIcon: Icon(Icons.payments)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _comment,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Комментарий', prefixIcon: Icon(Icons.comment)),
            ),
            const SizedBox(height: 20),
            PhotoGallery(
              paths: _photos,
              onAdd: (p) => setState(() => _photos.add(p)),
              onRemove: (i) => setState(() => _photos.removeAt(i)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── DETAIL ─────────────────────────────────────────────────────────────────

class ServiceRecordDetail extends StatefulWidget {
  final ServiceRecord record;
  const ServiceRecordDetail({super.key, required this.record});

  @override
  State<ServiceRecordDetail> createState() => _ServiceRecordDetailState();
}

class _ServiceRecordDetailState extends State<ServiceRecordDetail> {
  late ServiceRecord _record;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
  }

  Future<void> _edit() async {
    final result = await Navigator.push<ServiceRecord>(
      context,
      MaterialPageRoute(builder: (_) => ServiceRecordForm(initial: _record)),
    );
    if (result != null) setState(() => _record = result);
    Navigator.pop(context, _record);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd MMMM yyyy', 'ru');
    final fmt = NumberFormat('#,###', 'ru');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Запись обслуживания'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _edit),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateFmt.format(_record.date),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.outline)),
                  const SizedBox(height: 4),
                  Text(_record.description,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Badge(Icons.speed, '${fmt.format(_record.mileage)} км'),
                      const SizedBox(width: 8),
                      if (_record.cost > 0)
                        _Badge(Icons.payments, '${fmt.format(_record.cost.toInt())} ₽'),
                    ],
                  ),
                  if (_record.comment != null && _record.comment!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Комментарий',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: cs.outline)),
                    const SizedBox(height: 4),
                    Text(_record.comment!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          PhotoGallery(paths: _record.photoPaths),
        ],
      ),
    );
  }
}
