import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/spare_part.dart';
import '../../widgets/photo_gallery.dart';
import '../../widgets/status_chip.dart';

class PartsScreen extends StatefulWidget {
  const PartsScreen({super.key});

  @override
  State<PartsScreen> createState() => _PartsScreenState();
}

class _PartsScreenState extends State<PartsScreen> with SingleTickerProviderStateMixin {
  List<SparePart> _parts = [];
  bool _loading = true;
  String _search = '';
  String? _filterCategory;
  String? _filterStatus;
  late TabController _tab;

  final _tabs = const ['Все', 'Купить', 'Заказано', 'Получено', 'Установлено'];
  final _tabStatuses = [null, 'needToBuy', 'ordered', 'received', 'installed'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) {
        setState(() => _filterStatus = _tabStatuses[_tab.index]);
        _load();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final parts = await DatabaseHelper.instance.getSpareParts(
      query: _search.isEmpty ? null : _search,
      category: _filterCategory,
      status: _filterStatus,
    );
    if (mounted) setState(() { _parts = parts; _loading = false; });
  }

  Future<void> _add() async {
    final result = await Navigator.push<SparePart>(
      context,
      MaterialPageRoute(builder: (_) => const PartForm()),
    );
    if (result != null) {
      await DatabaseHelper.instance.insertSparePart(result);
      _load();
    }
  }

  Future<void> _open(SparePart part) async {
    final result = await Navigator.push<SparePart>(
      context,
      MaterialPageRoute(builder: (_) => PartDetail(part: part)),
    );
    if (result != null) {
      await DatabaseHelper.instance.updateSparePart(result);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Запчасти'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Поиск по OEM, названию...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() => _search = '');
                                _load();
                              })
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                    onChanged: (v) {
                      setState(() => _search = v);
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String?>(
                  icon: Icon(
                    Icons.filter_list,
                    color: _filterCategory != null ? cs.primary : null,
                  ),
                  tooltip: 'Фильтр по категории',
                  onSelected: (v) {
                    setState(() => _filterCategory = v);
                    _load();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: null, child: Text('Все категории')),
                    ...partCategories.map((c) => PopupMenuItem(value: c, child: Text(c))),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _parts.isEmpty
                    ? _EmptyState(onAdd: _add)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                        itemCount: _parts.length,
                        itemBuilder: (_, i) => _PartCard(
                          part: _parts[i],
                          onTap: () => _open(_parts[i]),
                        ),
                      ),
          ),
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings_suggest_outlined, size: 80,
              color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          const Text('Запчастей нет'),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Добавить запчасть'),
          ),
        ],
      ),
    );
  }
}

class _PartCard extends StatelessWidget {
  final SparePart part;
  final VoidCallback onTap;

  const _PartCard({required this.part, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,###', 'ru');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: part.photoPartPath != null && File(part.photoPartPath!).existsSync()
                    ? Image.file(File(part.photoPartPath!),
                        width: 64, height: 64, fit: BoxFit.cover)
                    : Container(
                        width: 64, height: 64,
                        color: cs.surfaceContainerHighest,
                        child: Icon(Icons.settings_suggest, color: cs.outline)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(part.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold),
                        maxLines: 2),
                    if (part.oemNumber != null) ...[
                      const SizedBox(height: 2),
                      Text('OEM: ${part.oemNumber}',
                          style: TextStyle(
                              fontSize: 12, fontFamily: 'monospace',
                              color: cs.secondary)),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(part.category,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.outline)),
                        if (part.price != null) ...[
                          const SizedBox(width: 8),
                          Text('${fmt.format(part.price!.toInt())} ₽',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold,
                                  color: cs.primary)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    PartStatusChip(status: part.status),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── DETAIL ─────────────────────────────────────────────────────────────────

class PartDetail extends StatefulWidget {
  final SparePart part;
  const PartDetail({super.key, required this.part});

  @override
  State<PartDetail> createState() => _PartDetailState();
}

class _PartDetailState extends State<PartDetail> {
  late SparePart _part;

  @override
  void initState() {
    super.initState();
    _part = widget.part;
  }

  Future<void> _edit() async {
    final result = await Navigator.push<SparePart>(
      context,
      MaterialPageRoute(builder: (_) => PartForm(initial: _part)),
    );
    if (result != null) setState(() => _part = result);
    Navigator.pop(context, _part);
  }

  Future<void> _quickStatus(PartStatus status) async {
    final updated = _part.copyWith(status: status);
    await DatabaseHelper.instance.updateSparePart(updated);
    setState(() => _part = updated);
    Navigator.pop(context, _part);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,###', 'ru');
    final dateFmt = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(_part.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _edit),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Photos
          if (_part.photoPartPath != null || _part.photoBoxPath != null) ...[
            Row(
              children: [
                if (_part.photoPartPath != null)
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(_part.photoPartPath!),
                          height: 160, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox()),
                    ),
                  ),
                if (_part.photoPartPath != null && _part.photoBoxPath != null)
                  const SizedBox(width: 8),
                if (_part.photoBoxPath != null)
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(_part.photoBoxPath!),
                          height: 160, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox()),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          // Status actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Статус', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(width: 8),
                      PartStatusChip(status: _part.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: PartStatus.values.map((s) {
                      return ActionChip(
                        label: Text(s.label, style: const TextStyle(fontSize: 12)),
                        onPressed: _part.status == s ? null : () => _quickStatus(s),
                        backgroundColor: _part.status == s
                            ? cs.primaryContainer
                            : null,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_part.oemNumber != null)
                    _Row('OEM номер', _part.oemNumber!, mono: true),
                  _Row('Категория', _part.category),
                  if (_part.manufacturer != null)
                    _Row('Производитель', _part.manufacturer!),
                  if (_part.price != null)
                    _Row('Цена', '${fmt.format(_part.price!.toInt())} ₽'),
                  if (_part.shop != null)
                    _Row('Магазин', _part.shop!),
                  if (_part.purchaseDate != null)
                    _Row('Дата покупки', dateFmt.format(_part.purchaseDate!)),
                  if (_part.installDate != null)
                    _Row('Дата установки', dateFmt.format(_part.installDate!)),
                ],
              ),
            ),
          ),
          if (_part.bestAnalog != null || _part.analogs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Аналоги', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    if (_part.bestAnalog != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 16, color: cs.primary),
                            const SizedBox(width: 8),
                            Text('Лучший: ',
                                style: TextStyle(fontWeight: FontWeight.bold,
                                    color: cs.primary, fontSize: 13)),
                            Text(_part.bestAnalog!,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_part.analogs.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: _part.analogs
                            .map((a) => Chip(
                                  label: Text(a, style: const TextStyle(fontFamily: 'monospace')),
                                  padding: EdgeInsets.zero,
                                ))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (_part.comment != null && _part.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Комментарий',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(_part.comment!),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  const _Row(this.label, this.value, {this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline)),
          ),
          Expanded(
            child: Text(value,
                style: mono
                    ? const TextStyle(fontFamily: 'monospace', fontSize: 13)
                    : const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ─── FORM ───────────────────────────────────────────────────────────────────

class PartForm extends StatefulWidget {
  final SparePart? initial;
  const PartForm({super.key, this.initial});

  @override
  State<PartForm> createState() => _PartFormState();
}

class _PartFormState extends State<PartForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _oem;
  late TextEditingController _analogs;
  late TextEditingController _bestAnalog;
  late TextEditingController _manufacturer;
  late TextEditingController _price;
  late TextEditingController _shop;
  late TextEditingController _shopUrl;
  late TextEditingController _comment;
  late PartStatus _status;
  late String _category;
  DateTime? _purchaseDate;
  DateTime? _installDate;
  String? _photoPartPath;
  String? _photoBoxPath;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name ?? '');
    _oem = TextEditingController(text: p?.oemNumber ?? '');
    _analogs = TextEditingController(text: p?.analogs.join(', ') ?? '');
    _bestAnalog = TextEditingController(text: p?.bestAnalog ?? '');
    _manufacturer = TextEditingController(text: p?.manufacturer ?? '');
    _price = TextEditingController(text: p?.price?.toStringAsFixed(0) ?? '');
    _shop = TextEditingController(text: p?.shop ?? '');
    _shopUrl = TextEditingController(text: p?.shopUrl ?? '');
    _comment = TextEditingController(text: p?.comment ?? '');
    _status = p?.status ?? PartStatus.needToBuy;
    _category = p?.category ?? partCategories.first;
    _purchaseDate = p?.purchaseDate;
    _installDate = p?.installDate;
    _photoPartPath = p?.photoPartPath;
    _photoBoxPath = p?.photoBoxPath;
  }

  @override
  void dispose() {
    _name.dispose(); _oem.dispose(); _analogs.dispose(); _bestAnalog.dispose();
    _manufacturer.dispose(); _price.dispose(); _shop.dispose();
    _shopUrl.dispose(); _comment.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isPurchase) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isPurchase ? _purchaseDate : _installDate) ?? DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isPurchase) _purchaseDate = picked;
        else _installDate = picked;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final analogList = _analogs.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final part = SparePart(
      id: widget.initial?.id,
      name: _name.text.trim(),
      category: _category,
      oemNumber: _oem.text.trim().isEmpty ? null : _oem.text.trim(),
      analogs: analogList,
      bestAnalog: _bestAnalog.text.trim().isEmpty ? null : _bestAnalog.text.trim(),
      manufacturer: _manufacturer.text.trim().isEmpty ? null : _manufacturer.text.trim(),
      price: double.tryParse(_price.text),
      shop: _shop.text.trim().isEmpty ? null : _shop.text.trim(),
      shopUrl: _shopUrl.text.trim().isEmpty ? null : _shopUrl.text.trim(),
      purchaseDate: _purchaseDate,
      installDate: _installDate,
      comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
      photoPartPath: _photoPartPath,
      photoBoxPath: _photoBoxPath,
      status: _status,
    );
    Navigator.pop(context, part);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd.MM.yyyy');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Новая запчасть' : 'Редактировать'),
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
                  labelText: 'Название *', prefixIcon: Icon(Icons.settings_suggest)),
              validator: (v) => (v == null || v.isEmpty) ? 'Обязательное поле' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                  labelText: 'Категория', prefixIcon: Icon(Icons.category)),
              items: partCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _oem,
              decoration: const InputDecoration(
                  labelText: 'OEM номер', prefixIcon: Icon(Icons.tag)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _analogs,
              decoration: const InputDecoration(
                  labelText: 'Аналоги (через запятую)',
                  prefixIcon: Icon(Icons.compare)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bestAnalog,
              decoration: const InputDecoration(
                  labelText: 'Лучший аналог', prefixIcon: Icon(Icons.star)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _manufacturer,
              decoration: const InputDecoration(
                  labelText: 'Производитель', prefixIcon: Icon(Icons.factory)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Цена', suffixText: '₽'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _shop,
                    decoration: const InputDecoration(labelText: 'Магазин'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _shopUrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                  labelText: 'Ссылка на магазин', prefixIcon: Icon(Icons.link)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(true),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Дата покупки'),
                      child: Text(_purchaseDate != null
                          ? dateFmt.format(_purchaseDate!)
                          : 'Не указана'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(false),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Дата установки'),
                      child: Text(_installDate != null
                          ? dateFmt.format(_installDate!)
                          : 'Не указана'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Статус', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: PartStatus.values.map((s) {
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
              controller: _comment,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Комментарий', prefixIcon: Icon(Icons.comment)),
            ),
            const SizedBox(height: 20),
            // Photos
            Text('Фото детали', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            PhotoGallery(
              paths: _photoPartPath != null ? [_photoPartPath!] : [],
              onAdd: (p) => setState(() => _photoPartPath = p),
              onRemove: (_) => setState(() => _photoPartPath = null),
            ),
            const SizedBox(height: 16),
            Text('Фото коробки', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            PhotoGallery(
              paths: _photoBoxPath != null ? [_photoBoxPath!] : [],
              onAdd: (p) => setState(() => _photoBoxPath = p),
              onRemove: (_) => setState(() => _photoBoxPath = null),
            ),
          ],
        ),
      ),
    );
  }
}
