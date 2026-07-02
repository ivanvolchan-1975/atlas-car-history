import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/diagnostic.dart';
import '../../widgets/photo_gallery.dart';
import '../../widgets/status_chip.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  List<Diagnostic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await DatabaseHelper.instance.getDiagnostics();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  Future<void> _add() async {
    final result = await Navigator.push<Diagnostic>(
      context,
      MaterialPageRoute(builder: (_) => const DiagnosticForm()),
    );
    if (result != null) {
      await DatabaseHelper.instance.insertDiagnostic(result);
      _load();
    }
  }

  Future<void> _open(Diagnostic item) async {
    final result = await Navigator.push<Diagnostic>(
      context,
      MaterialPageRoute(builder: (_) => DiagnosticDetail(diagnostic: item)),
    );
    if (result != null) {
      await DatabaseHelper.instance.updateDiagnostic(result);
      _load();
    }
  }

  Future<void> _delete(Diagnostic item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить?'),
        content: Text('Удалить "${item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseHelper.instance.deleteDiagnostic(item.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _items.where((d) => d.status != DiagnosticStatus.resolved).toList();
    final resolved = _items.where((d) => d.status == DiagnosticStatus.resolved).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Диагностика')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _EmptyState(onAdd: _add)
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (active.isNotEmpty) ...[
                      _SectionHeader(
                          'Активные (${active.length})', Colors.orange),
                      ...active.map((d) => _DiagCard(
                          item: d,
                          onTap: () => _open(d),
                          onDelete: () => _delete(d))),
                    ],
                    if (resolved.isNotEmpty) ...[
                      _SectionHeader('Устранено (${resolved.length})', Colors.green),
                      ...resolved.map((d) => _DiagCard(
                          item: d,
                          onTap: () => _open(d),
                          onDelete: () => _delete(d))),
                    ],
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader(this.title, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13, color: color)),
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
          Icon(Icons.medical_services_outlined, size: 80,
              color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          const Text('Неисправностей не найдено'),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Добавить неисправность'),
          ),
        ],
      ),
    );
  }
}

class _DiagCard extends StatelessWidget {
  final Diagnostic item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DiagCard({required this.item, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold)),
                    if (item.description != null && item.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(item.description!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.outline),
                          maxLines: 2),
                    ],
                    const SizedBox(height: 8),
                    DiagnosticStatusChip(status: item.status),
                  ],
                ),
              ),
              Column(
                children: [
                  if (item.photoPaths.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.photo, size: 14, color: cs.outline),
                          const SizedBox(width: 2),
                          Text('${item.photoPaths.length}',
                              style: TextStyle(fontSize: 12, color: cs.outline)),
                        ],
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: onDelete,
                    color: cs.error,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── FORM ───────────────────────────────────────────────────────────────────

class DiagnosticForm extends StatefulWidget {
  final Diagnostic? initial;
  const DiagnosticForm({super.key, this.initial});

  @override
  State<DiagnosticForm> createState() => _DiagnosticFormState();
}

class _DiagnosticFormState extends State<DiagnosticForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _title;
  late TextEditingController _desc;
  late TextEditingController _cost;
  late DiagnosticStatus _status;
  List<String> _photos = [];

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _title = TextEditingController(text: d?.title ?? '');
    _desc = TextEditingController(text: d?.description ?? '');
    _cost = TextEditingController(text: d?.cost?.toStringAsFixed(0) ?? '');
    _status = d?.status ?? DiagnosticStatus.searching;
    _photos = List.from(d?.photoPaths ?? []);
  }

  @override
  void dispose() {
    _title.dispose(); _desc.dispose(); _cost.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final d = Diagnostic(
      id: widget.initial?.id,
      title: _title.text.trim(),
      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      status: _status,
      createdAt: widget.initial?.createdAt ?? DateTime.now(),
      resolvedAt: _status == DiagnosticStatus.resolved ? DateTime.now() : null,
      cost: double.tryParse(_cost.text),
      photoPaths: _photos,
    );
    Navigator.pop(context, d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Новая неисправность' : 'Редактировать'),
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
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                  labelText: 'Название неисправности *',
                  prefixIcon: Icon(Icons.warning_amber)),
              validator: (v) => (v == null || v.isEmpty) ? 'Обязательное поле' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Описание', prefixIcon: Icon(Icons.description)),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Статус',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: DiagnosticStatus.values.map((s) {
                        return ChoiceChip(
                          label: Text(s.label),
                          selected: _status == s,
                          onSelected: (_) => setState(() => _status = s),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cost,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Стоимость ремонта', suffixText: '₽',
                  prefixIcon: Icon(Icons.payments)),
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

class DiagnosticDetail extends StatefulWidget {
  final Diagnostic diagnostic;
  const DiagnosticDetail({super.key, required this.diagnostic});

  @override
  State<DiagnosticDetail> createState() => _DiagnosticDetailState();
}

class _DiagnosticDetailState extends State<DiagnosticDetail> {
  late Diagnostic _diag;

  @override
  void initState() {
    super.initState();
    _diag = widget.diagnostic;
  }

  Future<void> _edit() async {
    final result = await Navigator.push<Diagnostic>(
      context,
      MaterialPageRoute(builder: (_) => DiagnosticForm(initial: _diag)),
    );
    if (result != null) setState(() => _diag = result);
    Navigator.pop(context, _diag);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd MMMM yyyy', 'ru');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Неисправность'),
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
                  Text(_diag.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DiagnosticStatusChip(status: _diag.status),
                  if (_diag.description != null && _diag.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Описание',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: cs.outline)),
                    const SizedBox(height: 4),
                    Text(_diag.description!),
                  ],
                  const SizedBox(height: 12),
                  Text('Дата: ${dateFmt.format(_diag.createdAt)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.outline)),
                  if (_diag.cost != null)
                    Text('Стоимость: ${_diag.cost!.toStringAsFixed(0)} ₽',
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          PhotoGallery(paths: _diag.photoPaths),
        ],
      ),
    );
  }
}
