import 'package:flutter/material.dart';
import '../models/diagnostic.dart';
import '../models/spare_part.dart';

class DiagnosticStatusChip extends StatelessWidget {
  final DiagnosticStatus status;

  const DiagnosticStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      DiagnosticStatus.searching => (Colors.orange, Icons.search),
      DiagnosticStatus.waitingReplacement => (Colors.red, Icons.warning_amber),
      DiagnosticStatus.inProgress => (Colors.blue, Icons.build),
      DiagnosticStatus.resolved => (Colors.green, Icons.check_circle),
    };

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(status.label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class PartStatusChip extends StatelessWidget {
  final PartStatus status;

  const PartStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      PartStatus.needToBuy => (Colors.red, Icons.shopping_cart),
      PartStatus.ordered => (Colors.orange, Icons.local_shipping),
      PartStatus.received => (Colors.blue, Icons.inventory),
      PartStatus.installed => (Colors.green, Icons.check_circle),
    };

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(status.label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
