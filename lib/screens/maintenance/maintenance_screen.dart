import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/maintenance_item.dart';
import '../../widgets/photo_gallery.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  List<MaintenanceItem> _items = [];
  int _currentMileage = 70000;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await DatabaseHelper.instance.getMaintenanceItems();
    final car = await DatabaseHelper.instance.getCar();
    if (mounted) {
      setState(() {
        _items = items;
        _currentMileage = car?.mileage ?? 70000;
        _loading = false;
      });
    }
  }

  Future<void> _addItem() async {
    final result = await Navigator.push<MaintenanceItem>(
      context,
      MaterialPageRoute(
          builder: (_) => MaintenanceItemForm(currentMileage: _currentMileage)),
    );
    if (result != null) {
      await DatabaseHelper.instance.insertMaintenanceItem(result);
      _load();
    }
  }

  Future<void> _openItem(MaintenanceItem item) async {
    final result = await Navigator.push<MaintenanceItem>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MaintenanceItemForm(initial: item, currentMileage: _currentMileage),
      ),
    );
    if (result != null) {
      await DatabaseHelper.instance.updateMaintenanceItem(result);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Техническое обслуживание')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _items.length,
              itemBuilder: (_, i) => _MaintenanceCard(
                item: _items[i],
                currentMileage: _currentMileage,
                onTap: () => _openItem(_items[i]),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  final MaintenanceItem item;
  final int currentMileage;
  final VoidCallback onTap;

  const _MaintenanceCard({
    required this.item,
    required this.currentMileage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,###', 'ru');
    final dateFmt = DateFormat('dd.MM.yyyy');

    final next = item.nextChangeMileage;
    final kmLeft = next != null ? next - currentMileage : null;
    final isOverdue = kmLeft != null && kmLeft <= 0;
    final isWarning = kmLeft != null && kmLeft > 0 && kmLeft <= 1500;

    final color = isOverdue
        ? cs.error
        : isWarning
            ? Colors.orange
            : cs.primary;

    double progress = 0;
    if (item.lastChangedMileage != null && next != null) {
      final interval = item.intervalKm;
      final done = currentMileage - item.lastChangedMileage!;
      progress = (done / interval).clamp(0.0, 1.0);
    }

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
                  Text(item.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Просрочено',
                          style: TextStyle(
                              fontSize: 11, color: cs.onErrorContainer,
                              fontWeight: FontWeight.bold)),
                    )
                  else if (isWarning)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Скоро',
                          style: TextStyle(
                              fontSize: 11, color: Colors.orange,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (item.lastChangedMileage != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: _InfoCol(
                      'Последняя замена',
                      item.lastChangedMileage != null
                          ? '${fmt.format(item.lastChangedMileage!)} км'
                          : '—',
                      sub: item.lastChangedDate != null
                          ? dateFmt.format(item.lastChangedDate!)
                          : null,
                    ),
                  ),
                  Expanded(
                    child: _InfoCol(
                      'Следующая замена',
                      next != null ? '${fmt.format(next)} км' : '—',
                      highlight: isOverdue || isWarning ? color : null,
                    ),
                  ),
                  Expanded(
                    child: _InfoCol(
                      'Осталось',
                      kmLeft != null
                          ? '${fmt.format(kmLeft.abs())} км'
                          : '—',
                      highlight: isOverdue ? cs.error : isWarning ? Colors.orange : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Интервал: каждые ${fmt.format(item.intervalKm)} км',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.outline)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCol extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color? highlight;

  const _InfoCol(this.label, this.value, {this.sub, this.highlight});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: highlight)),
        if (sub != null)
          Text(sub!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 11)),
      ],
    );
  }
}

// ─── FORM ───────────────────────────────────────────────────────────────────

class MaintenanceItemForm extends StatefulWidget {
  final MaintenanceItem? initial;
  final int currentMileage;

  const MaintenanceItemForm({super.key, this.initial, required this.currentMileage});

  @override
  State<MaintenanceItemForm> createState() => _MaintenanceItemFormState();
}

class _MaintenanceItemFormState extends State<MaintenanceItemForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _brand;
  late TextEditingController _lastMileage;
  late TextEditingController _intervalKm;
  late TextEditingController _cost;
  late TextEditingController _comment;
  DateTime? _lastDate;
  List<String> _photos = [];

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _name = TextEditingController(text: i?.name ?? '');
    _brand = TextEditingController(text: i?.brand ?? '');
    _lastMileage = TextEditingController(text: i?.lastChangedMileage?.toString() ?? '');
    _intervalKm = TextEditingController(text: i?.intervalKm.toString() ?? '10000');
    _cost = TextEditingController(text: i?.cost?.toStringAsFixed(0) ?? '');
    _comment = TextEditingController(text: i?.comment ?? '');
    _lastDate = i?.lastChangedDate;
    _photos = List.from(i?.photoPaths != null ? [i!.photoPath ?? ''].where((s) => s.isNotEmpty).toList() : []);
  }

  @override
  void dispose() {
    _name.dispose(); _brand.dispose(); _lastMileage.dispose();
    _intervalKm.dispose(); _cost.dispose(); _comment.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastDate ?? DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _lastDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final item = MaintenanceItem(
      id: widget.initial?.id,
      name: _name.text.trim(),
      brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      lastChangedDate: _lastDate,
      lastChangedMileage: int.tryParse(_lastMileage.text),
      intervalKm: int.tryParse(_intervalKm.text) ?? 10000,
      cost: double.tryParse(_cost.text),
      comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
      photoPath: _photos.isNotEmpty ? _photos.first : null,
    );
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd.MM.yyyy');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Новый элемент ТО' : 'Редактировать'),
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
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'Название *', prefixIcon: Icon(Icons.build)),
              validator: (v) => (v == null || v.isEmpty) ? 'Обязательное поле' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _brand,
              decoration: const InputDecoration(
                  labelText: 'Производитель / Марка', prefixIcon: Icon(Icons.label)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lastMileage,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Пробег последней замены', suffixText: 'км'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: ListTile(
                      title: const Text('Дата', style: TextStyle(fontSize: 13)),
                      subtitle: Text(_lastDate != null
                          ? dateFmt.format(_lastDate!)
                          : 'Не указана'),
                      trailing: const Icon(Icons.calendar_today, size: 18),
                      onTap: _pickDate,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _intervalKm,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Интервал замены *', suffixText: 'км',
                  prefixIcon: Icon(Icons.loop)),
              validator: (v) => (v == null || v.isEmpty) ? 'Укажите интервал' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cost,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Стоимость', suffixText: '₽',
                  prefixIcon: Icon(Icons.payments)),
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
              onAdd: (p) => setState(() {
                _photos.clear();
                _photos.add(p);
              }),
              onRemove: (i) => setState(() => _photos.removeAt(i)),
            ),
          ],
        ),
      ),
    );
  }
}
