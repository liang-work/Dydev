import 'package:flutter/material.dart';
import '../models/store_app.dart';

/// A small coloured badge that displays an app's current status.
class StatusBadge extends StatelessWidget {
  final AppStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (status) {
      AppStatus.draft => (cs.surfaceContainerHighest, cs.onSurface),
      AppStatus.pending => (cs.secondaryContainer, cs.onSecondaryContainer),
      AppStatus.published => (cs.tertiaryContainer, cs.onTertiaryContainer),
      AppStatus.rejected => (cs.errorContainer, cs.onErrorContainer),
      AppStatus.removed => (cs.surfaceContainerHigh, cs.onSurfaceVariant),
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
