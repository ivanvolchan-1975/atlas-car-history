import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home/home_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/maintenance/maintenance_screen.dart';
import 'screens/diagnostics/diagnostics_screen.dart';
import 'screens/parts/parts_screen.dart';
import 'screens/expenses/expenses_screen.dart';
import 'screens/documents/documents_screen.dart';
import 'screens/reminders/reminders_screen.dart';
import 'screens/backup/backup_screen.dart';

class CarHistoryApp extends StatelessWidget {
  const CarHistoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geely Atlas — История',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final _screens = const [
    HomeScreen(),
    HistoryScreen(),
    PartsScreen(),
    MaintenanceScreen(),
    _MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'История',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_suggest_outlined),
            selectedIcon: Icon(Icons.settings_suggest),
            label: 'Запчасти',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'ТО',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Ещё',
          ),
        ],
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final items = [
      (Icons.medical_services, 'Диагностика', 'Неисправности и проблемы',
          Colors.red, const DiagnosticsScreen()),
      (Icons.account_balance_wallet, 'Расходы', 'Аналитика затрат',
          Colors.orange, const ExpensesScreen()),
      (Icons.folder, 'Документы', 'Страховки, техпаспорт, чеки',
          Colors.indigo, const DocumentsScreen()),
      (Icons.notifications, 'Напоминания', 'ТО, страховка, события',
          Colors.purple, const RemindersScreen()),
      (Icons.backup, 'Резервное копирование', 'Экспорт и импорт данных',
          Colors.teal, const BackupScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Ещё')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.directions_car, size: 40, color: cs.primary),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Geely Atlas 2018',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimaryContainer)),
                      Text('VIN: Y4K8752S7JB305112',
                          style: TextStyle(
                              fontSize: 12, fontFamily: 'monospace',
                              color: cs.onPrimaryContainer.withOpacity(0.7))),
                      Text('BelGee • 2.0 бензин • МКПП',
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onPrimaryContainer.withOpacity(0.7))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            final (icon, title, subtitle, color, screen) = item;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color),
                ),
                title: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(subtitle, style: TextStyle(color: cs.outline)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => screen)),
              ),
            );
          }),
        ],
      ),
    );
  }
}
