import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import 'widgets/stat_card.dart';
import 'widgets/my_apps_section.dart';
import 'widgets/quick_actions.dart';

/// The main dashboard page showing statistics, my apps and quick actions.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Load data when the page first appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Stats row ----
            if (provider.isLoading && provider.myApps.isEmpty)
              const Center(child: CircularProgressIndicator())
            else ...[
              _buildStatsRow(provider),
              const SizedBox(height: 32),

              // ---- My Apps section + Quick Actions side by side ----
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // My apps list (left, flex 2).
                  Expanded(
                    flex: 2,
                    child: MyAppsSection(apps: provider.myApps),
                  ),
                  const SizedBox(width: 24),
                  // Quick actions (right, flex 1).
                  Expanded(
                    flex: 1,
                    child: QuickActions(),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(DashboardProvider provider) {
    final stats = provider.stats;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount,
              child: StatCard(
                title: '我的应用',
                value: '${stats.myAppCount}',
                icon: Icons.apps,
                color: Colors.blue,
              ),
            ),
            SizedBox(
              width: (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount,
              child: StatCard(
                title: '总下载量',
                value: _formatCount(provider.totalDownloads),
                icon: Icons.download_outlined,
                color: Colors.green,
              ),
            ),
            SizedBox(
              width: (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount,
              child: StatCard(
                title: '收到评价',
                value: '${stats.reviewCount}',
                icon: Icons.star_outline,
                color: Colors.orange,
              ),
            ),
            SizedBox(
              width: (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount,
              child: StatCard(
                title: '平台应用',
                value: '${stats.platformAppCount}',
                icon: Icons.store,
                color: Colors.purple,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Format large numbers in a human-readable way (e.g. 1234 -> "1.2k").
  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return '$count';
  }
}
