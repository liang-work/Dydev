import 'package:flutter/material.dart';
import '../../../models/store_app.dart';
import 'my_app_tile.dart';

/// Section displaying the developer's own apps.
class MyAppsSection extends StatelessWidget {
  final List<StoreApp> apps;

  const MyAppsSection({super.key, required this.apps});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '我的应用',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (apps.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.apps_outlined, size: 48, color: Theme.of(context).colorScheme.surfaceContainerHigh),
                  const SizedBox(height: 8),
                  Text('暂无应用', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          )
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: apps.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
              itemBuilder: (context, index) => MyAppTile(app: apps[index]),
            ),
          ),
      ],
    );
  }
}
