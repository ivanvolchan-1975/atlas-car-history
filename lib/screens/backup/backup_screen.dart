import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../database/database_helper.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _working = false;

  Future<void> _export() async {
    setState(() => _working = true);
    try {
      await DatabaseHelper.instance.closeDatabase();
      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      final dbFile = File(dbPath);
      if (!dbFile.existsSync()) {
        _showSnack('База данных не найдена', isError: true);
        return;
      }
      // Re-open
      await DatabaseHelper.instance.database;

      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final name =
          'atlas_backup_${now.year}${_pad(now.month)}${_pad(now.day)}.db';
      final exportFile = File('${dir.path}/$name');
      await dbFile.copy(exportFile.path);

      await Share.shareXFiles(
        [XFile(exportFile.path)],
        text: 'Резервная копия Geely Atlas $name',
      );
    } catch (e) {
      _showSnack('Ошибка экспорта: $e', isError: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _import() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Восстановить из резервной копии?'),
        content: const Text(
            'Все текущие данные будут заменены данными из файла резервной копии. Продолжить?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Восстановить')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _working = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final sourcePath = result.files.first.path;
      if (sourcePath == null) return;

      await DatabaseHelper.instance.closeDatabase();
      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      await File(sourcePath).copy(dbPath);
      // Re-open database
      await DatabaseHelper.instance.database;

      _showSnack('Данные успешно восстановлены!');
    } catch (e) {
      _showSnack('Ошибка импорта: $e', isError: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
    ));
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Резервное копирование')),
      body: _working
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_upload_outlined,
                            size: 64, color: cs.primary),
                        const SizedBox(height: 12),
                        Text('Экспорт данных',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Сохраните резервную копию всей базы данных.\n'
                          'Файл можно отправить в облако, на почту или сохранить на компьютере.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.outline),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _export,
                          icon: const Icon(Icons.save_alt),
                          label: const Text('Экспортировать'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_download_outlined,
                            size: 64, color: cs.secondary),
                        const SizedBox(height: 12),
                        Text('Восстановление данных',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Восстановите данные из ранее сохранённой резервной копии.\n'
                          'ВНИМАНИЕ: текущие данные будут заменены!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.outline),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _import,
                          icon: const Icon(Icons.restore),
                          label: const Text('Восстановить из файла'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: cs.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: cs.onErrorContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'При смене телефона: экспортируйте базу данных, '
                            'установите приложение на новый телефон, '
                            'затем восстановите данные из файла.',
                            style: TextStyle(
                                color: cs.onErrorContainer, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
