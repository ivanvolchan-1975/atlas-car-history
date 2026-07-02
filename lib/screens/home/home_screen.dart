import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/car.dart';
import '../history/history_screen.dart';
import '../maintenance/maintenance_screen.dart';
import '../diagnostics/diagnostics_screen.dart';
import '../parts/parts_screen.dart';
import '../expenses/expenses_screen.dart';
import '../documents/documents_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Car? _car;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCar();
  }

  Future<void> _loadCar() async {
    final car = await DatabaseHelper.instance.getCar();
    if (mounted) setState(() { _car = car; _loading = false; });
  }

  Future<void> _updateMileage() async {
    final controller = TextEditingController(text: _car?.mileage.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Обновить пробег'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Текущий пробег (км)',
            suffixText: 'км',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (result != null && _car != null) {
      final updated = _car!.copyWith(mileage: result);
      await DatabaseHelper.instance.updateCar(updated);
      _loadCar();
    }
  }

  Future<void> _pickCarPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Сфотографировать'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Из галереи'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || _car == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked != null) {
      final updated = _car!.copyWith(photoPath: picked.path);
      await DatabaseHelper.instance.updateCar(updated);
      _loadCar();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final car = _car;
    if (car == null) return const Scaffold(body: Center(child: Text('Нет данных')));

    final cs = Theme.of(context).colorScheme;
    final mileage = car.mileage;
    final nextSvc = car.nextServiceMileage ?? (car.lastServiceMileage != null ? car.lastServiceMileage! + 10000 : null);
    final kmLeft = nextSvc != null ? nextSvc - mileage : null;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('${car.make} ${car.model}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              background: _CarPhotoHeader(car: car, onTap: _pickCarPhoto),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoCard(car: car, kmLeft: kmLeft, nextSvc: nextSvc,
                      onMileageTap: _updateMileage),
                  const SizedBox(height: 20),
                  Text('Быстрый доступ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _QuickActions(car: car),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarPhotoHeader extends StatelessWidget {
  final Car car;
  final VoidCallback onTap;

  const _CarPhotoHeader({required this.car, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (car.photoPath != null && File(car.photoPath!).existsSync())
          Image.file(File(car.photoPath!), fit: BoxFit.cover)
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, cs.primaryContainer],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_car, size: 80, color: cs.onPrimary.withOpacity(0.4)),
                const SizedBox(height: 8),
                Text('Нажмите чтобы добавить фото',
                    style: TextStyle(color: cs.onPrimary.withOpacity(0.6))),
              ],
            ),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
            ),
          ),
        ),
        Positioned(
          bottom: 60,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: onTap,
            backgroundColor: Colors.white.withOpacity(0.9),
            child: const Icon(Icons.camera_alt, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Car car;
  final int? kmLeft;
  final int? nextSvc;
  final VoidCallback onMileageTap;

  const _InfoCard({
    required this.car,
    this.kmLeft,
    this.nextSvc,
    required this.onMileageTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,###', 'ru');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text('Информация об автомобиле',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: cs.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow('VIN', car.vin, monospace: true),
            _InfoRow('Двигатель', car.engine),
            _InfoRow('КПП', car.transmission),
            _InfoRow('Год', car.year.toString()),
            _InfoRow('Страна сборки', car.country),
            const Divider(height: 20),
            InkWell(
              onTap: onMileageTap,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Icon(Icons.speed, color: cs.secondary, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Текущий пробег',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text('${fmt.format(car.mileage)} км',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold, color: cs.secondary)),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.edit, size: 18, color: cs.outline),
                ],
              ),
            ),
            if (nextSvc != null) ...[
              const SizedBox(height: 12),
              _ServiceProgress(
                  current: car.mileage,
                  last: car.lastServiceMileage ?? car.mileage - 10000,
                  next: nextSvc!,
                  kmLeft: kmLeft),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool monospace;

  const _InfoRow(this.label, this.value, {this.monospace = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline)),
          ),
          Expanded(
            child: Text(value,
                style: monospace
                    ? const TextStyle(fontFamily: 'monospace', fontSize: 13)
                    : null),
          ),
        ],
      ),
    );
  }
}

class _ServiceProgress extends StatelessWidget {
  final int current;
  final int last;
  final int next;
  final int? kmLeft;

  const _ServiceProgress({
    required this.current,
    required this.last,
    required this.next,
    this.kmLeft,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,###', 'ru');
    final interval = next - last;
    final done = current - last;
    final progress = interval > 0 ? (done / interval).clamp(0.0, 1.0) : 0.0;
    final isOverdue = (kmLeft ?? 1) <= 0;
    final color = isOverdue ? cs.error : progress > 0.8 ? Colors.orange : cs.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('До следующего ТО',
                style: Theme.of(context).textTheme.bodySmall),
            Text(
              isOverdue
                  ? 'Просрочено!'
                  : '${fmt.format(kmLeft ?? 0)} км',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Последнее: ${fmt.format(last)} км',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.outline)),
            Text('Следующее: ${fmt.format(next)} км',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.outline)),
          ],
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final Car car;

  const _QuickActions({required this.car});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.history, 'История', Colors.purple, const HistoryScreen()),
      (Icons.build_circle, 'ТО', Colors.blue, const MaintenanceScreen()),
      (Icons.settings_suggest, 'Запчасти', Colors.teal, const PartsScreen()),
      (Icons.medical_services, 'Диагностика', Colors.red, const DiagnosticsScreen()),
      (Icons.account_balance_wallet, 'Расходы', Colors.orange, const ExpensesScreen()),
      (Icons.folder, 'Документы', Colors.indigo, const DocumentsScreen()),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: actions.map((a) {
        final (icon, label, color, screen) = a;
        return _ActionTile(
            icon: icon, label: label, color: color, destination: screen);
      }).toList(),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Widget destination;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => destination)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }
}
