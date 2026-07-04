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
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: app.iconUrl.isNotEmpty
            ? Image.network(app.iconUrl, width: 40, height: 40, fit: BoxFit.cover)
            : Container(
                width: 40,
                height: 40,
                color: Colors.grey.shade200,
                child: Icon(Icons.apps, color: Colors.grey.shade400),
              ),
      ),
      title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('v${app.currentVersion}', style: TextStyle(color: Colors.grey.shade600)),
      trailing: StatusBadge(status: app.status),
      onTap: onTap,
    );
  }
}
