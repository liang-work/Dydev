import 'package:flutter/material.dart';
import '../../../models/store_app.dart';
import '../../../widgets/status_badge.dart';

/// A single row in the My Apps list showing icon, name, version and status.
class MyAppTile extends StatelessWidget {
  final StoreApp app;
  final VoidCallback? onTap;

  const MyAppTile({super.key, required this.app, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: app.iconUrl.isNotEmpty
            ? Image.network(app.iconUrl, width: 40, height: 40, fit: BoxFit.cover)
            : Container(
                width: 40,
                height: 40,
                color: cs.surfaceContainerHighest,
                child: Icon(Icons.apps, color: cs.onSurfaceVariant),
              ),
      ),
      title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('v${app.currentVersion}', style: TextStyle(color: cs.onSurfaceVariant)),
      trailing: StatusBadge(status: app.status),
      onTap: onTap,
    );
  }
}
