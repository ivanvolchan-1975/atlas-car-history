import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/reminder.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Reminder> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await DatabaseHelper.instance.getReminders();
    if (mounted) setState(() { _reminders = r; _loading = false; });
  }

  Future<void> _add() async {
    final result = await showDialog<Reminder>(
      context: context,
      builder: (_) => const ReminderDialog(),
    );
    if (result != null) {
      await DatabaseHelper.instance.insertReminder(result);
      _load();
    }
  }

  Future<void> _toggle(Reminder r) async {
    final updated = r.copyWith(isCompleted: !r.isCompleted);
    await DatabaseHelper.instance.updateReminder(updated);
    _load();
  }

  Future<void> _delete(Reminder r) async {
    await DatabaseHelper.instance.deleteReminder(r.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final active = _reminders.where((r) => !r.isCompleted).toList();
    final done = _reminders.where((r) => r.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Напоминания')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? _Empty(onAdd: _add)
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (active.isNotEmpty) ...[
                      const _SectionHeader('Активные'),
                      ...active.map((r) => _ReminderCard(
                            reminder: r,
                            onToggle: () => _toggle(r),
                            onDelete: () => _delete(r),
                          )),
                    ],
                    if (done.isNotEmpty) ...[
                      const _SectionHeader('Выполнено'),
                      ...done.map((r) => _ReminderCard(
                            reminder: r,
                            onToggle: () => _toggle(r),
                            onDelete: () => _delete(r),
                          )),
                    ],
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_alert),
        label: const Text('Добавить'),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: Theme.of(context).colorScheme.outline)),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onAdd;
  const _Empty({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80,
              color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          const Text('Напоминаний нет'),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_alert),
            label: const Text('Добавить напоминание'),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd MMMM yyyy', 'ru');
    final isOverdue = !reminder.isCompleted &&
        reminder.dueDate.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: reminder.isCompleted,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          reminder.title,
          style: TextStyle(
            decoration:
                reminder.isCompleted ? TextDecoration.lineThrough : null,
            color: reminder.isCompleted ? cs.outline : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12,
                    color: isOverdue ? cs.error : cs.outline),
                const SizedBox(width: 4),
                Text(
                  dateFmt.format(reminder.dueDate),
                  style: TextStyle(
                      fontSize: 12,
                      color: isOverdue ? cs.error : cs.outline,
                      fontWeight: isOverdue ? FontWeight.bold : null),
                ),
                if (isOverdue) ...[
                  const SizedBox(width: 4),
                  Text('— Просрочено',
                      style: TextStyle(
                          fontSize: 12, color: cs.error,
                          fontWeight: FontWeight.bold)),
                ],
              ],
            ),
            if (reminder.dueMileage != null)
              Text('Пробег: ${NumberFormat('#,###', 'ru').format(reminder.dueMileage!)} км',
                  style: TextStyle(fontSize: 12, color: cs.outline)),
            if (reminder.description != null && reminder.description!.isNotEmpty)
              Text(reminder.description!,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: cs.error, size: 20),
          onPressed: onDelete,
        ),
        isThreeLine: true,
      ),
    );
  }
}

// ─── DIALOG ─────────────────────────────────────────────────────────────────

class ReminderDialog extends StatefulWidget {
  const ReminderDialog({super.key});

  @override
  State<ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _mileage = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _title.dispose(); _desc.dispose(); _mileage.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (_title.text.trim().isEmpty) return;
    final r = Reminder(
      title: _title.text.trim(),
      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      dueDate: _date,
      dueMileage: int.tryParse(_mileage.text),
    );
    Navigator.pop(context, r);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMMM yyyy', 'ru');
    return AlertDialog(
      title: const Text('Новое напоминание'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Название *'),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            decoration: const InputDecoration(labelText: 'Описание'),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Дата', style: TextStyle(fontSize: 14)),
            subtitle: Text(dateFmt.format(_date)),
            trailing: const Icon(Icons.calendar_today, size: 18),
            onTap: _pickDate,
          ),
          TextField(
            controller: _mileage,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'По пробегу (км)', suffixText: 'км'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(onPressed: _save, child: const Text('Создать')),
      ],
    );
  }
}
