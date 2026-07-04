import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dashboard_stats.dart';
import '../../providers/dashboard_provider.dart';
import 'widgets/stat_card.dart';
import 'widgets/my_apps_section.dart';
import 'widgets/quick_actions.dart';

/// The main dashboard page showing statistics, my apps and quick actions.
///
/// Statistics are computed locally from the developer's own app list
/// rather than from a separate server endpoint.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final stats = provider.stats;

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.isLoading && provider.myApps.isEmpty)
              const Center(child: CircularProgressIndicator())
            else ...[
              // ---- Stats row ----
              _buildStatsRow(context, stats),
              const SizedBox(height: 32),

              // ---- My Apps + Quick Actions ----
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: MyAppsSection(apps: provider.myApps)),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: QuickActions()),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, DashboardStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
        final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: itemWidth,
              child: StatCard(
                title: '我的应用',
                value: '${stats.myAppCount}',
                icon: Icons.apps,
                color: Colors.blue,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: StatCard(
                title: '总下载量',
                value: _formatCount(stats.totalDownloads),
                icon: Icons.download_outlined,
                color: Colors.green,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: StatCard(
                title: '收到评价',
                value: '${stats.totalReviews}',
                icon: Icons.star_outline,
                color: Colors.orange,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: StatCard(
                title: '平台应用',
                value: '${stats.publishedAppCount}',
                icon: Icons.store,
                color: Colors.purple,
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return '$count';
  }
}
