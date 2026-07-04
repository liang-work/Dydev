import 'package:flutter/material.dart';
import '../models/store_app.dart';

/// A small coloured badge that displays an app's current status.
class StatusBadge extends StatelessWidget {
  final AppStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      AppStatus.draft => (Colors.grey.shade200, Colors.grey.shade700),
      AppStatus.pending => (Colors.orange.shade100, Colors.orange.shade800),
      AppStatus.published => (Colors.green.shade100, Colors.green.shade800),
      AppStatus.rejected => (Colors.red.shade100, Colors.red.shade800),
      AppStatus.removed => (Colors.grey.shade300, Colors.grey.shade600),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
