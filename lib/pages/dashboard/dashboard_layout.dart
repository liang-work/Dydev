import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'widgets/sidebar.dart';

/// The main authenticated layout with a left sidebar and content area.
///
/// This widget wraps all dashboard sub-pages.
class DashboardLayout extends StatefulWidget {
  final Widget child;

  const DashboardLayout({super.key, required this.child});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Left sidebar (hidden on mobile – a production app would
            // use a Drawer for small screens).
            Sidebar(
              currentRoute: ModalRoute.of(context)?.settings.name ?? '',
              onNavigate: (route) => Navigator.of(context).pushReplacementNamed(route),
              onLogout: () async {
                await context.read<AuthProvider>().logout();
              },
            ),

            // Main content area.
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: Column(
                  children: [
                    // Top header bar.
                    _buildTopBar(context),
                    // Page content.
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Text(
            '仪表板',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (auth.user != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  auth.user!.nickname.isNotEmpty ? auth.user!.nickname : auth.user!.username,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
