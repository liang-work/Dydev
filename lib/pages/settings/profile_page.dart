import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

/// Placeholder profile / settings page.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '个人设置',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('用户名: ${user?.username ?? '-'}'),
                  const SizedBox(height: 8),
                  Text('昵称: ${user?.nickname ?? '-'}'),
                  const SizedBox(height: 8),
                  Text('邮箱: ${user?.email ?? '-'}'),
                  const SizedBox(height: 8),
                  Text('个人简介: ${user?.bio ?? '-'}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
