import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/software.dart';
import '../../models/telemetry_data.dart';
import '../../providers/auth_provider.dart';

class TelemetryListPage extends StatefulWidget {
  const TelemetryListPage({super.key});

  @override
  State<TelemetryListPage> createState() => _TelemetryListPageState();
}

class _TelemetryListPageState extends State<TelemetryListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Software> _softwares = [];
  List<TelemetryData> _data = [];
  List<Map<String, dynamic>> _issues = [];
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _definitions = [];
  bool _loadingData = false;
  bool _loadingStats = false;
  bool _loadingIssues = false;

  // Filters
  String _filterSoftware = 'all';
  String _filterDataType = 'all';
  String _filterVersion = 'all';
  String _filterEnvironment = 'all';
  List<String> _availableVersions = [];
  List<String> _availableEnvironments = [];

  // Selection
  final Set<int> _selectedIds = {};

  // Detail dialog
  TelemetryData? _selectedItem;

  // Issue detail
  Map<String, dynamic>? _selectedIssue;
  List<TelemetryData> _issueLogs = [];
  bool _loadingIssueLogs = false;

  // Definition dialog
  bool _showDefDialog = false;
  final _defLabelCtrl = TextEditingController();
  final _defFieldCtrl = TextEditingController(text: 'content.');
  String _defDataType = 'metric';
  String _defAggregation = 'avg';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChange);
    _loadSoftwares();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _defLabelCtrl.dispose();
    _defFieldCtrl.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (!_tabController.indexIsChanging) {
      if (_tabController.index == 1) _loadIssues();
      if (_tabController.index == 3) _loadStats();
    }
  }

  Future<void> _loadSoftwares() async {
    try {
      final api = context.read<AuthProvider>().apiService;
      _softwares = await api.getSoftwares();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    setState(() => _loadingData = true);
    try {
      final params = <String, dynamic>{};
      if (_filterSoftware != 'all') params['software'] = _filterSoftware;
      if (_filterDataType != 'all') params['data_type'] = _filterDataType;
      if (_filterVersion != 'all') params['version'] = _filterVersion;
      if (_filterEnvironment != 'all') params['environment'] = _filterEnvironment;
      final api = context.read<AuthProvider>().apiService;
      _data = await api.getTelemetryData(params: params);
      if (_filterSoftware != 'all' && (_availableVersions.isEmpty || _availableEnvironments.isEmpty)) {
        _updateFilterOptions();
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingData = false);
  }

  Future<void> _updateFilterOptions() async {
    try {
      final api = context.read<AuthProvider>().apiService;
      final allData = await api.getTelemetryData(params: {'software': _filterSoftware, 'limit': 1000});
      _availableVersions = allData.map((d) => d.version).where((v) => v.isNotEmpty).toSet().toList()..sort();
      _availableEnvironments = allData.map((d) => d.environment).where((e) => e.isNotEmpty).toSet().toList()..sort();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _loadStats() async {
    if (_filterSoftware == 'all') return;
    setState(() => _loadingStats = true);
    try {
      final params = <String, dynamic>{};
      if (_filterVersion != 'all') params['version'] = _filterVersion;
      if (_filterEnvironment != 'all') params['environment'] = _filterEnvironment;
      if (_filterDataType != 'all') params['data_type'] = _filterDataType;
      final api = context.read<AuthProvider>().apiService;
      _stats = await api.getTelemetryStats(_filterSoftware, params: params);
      _definitions = await api.getMetricDefinitions(params: {'software': _filterSoftware});
    } catch (_) {}
    if (mounted) setState(() => _loadingStats = false);
  }

  Future<void> _loadIssues() async {
    if (_filterSoftware == 'all') return;
    setState(() => _loadingIssues = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      _issues = await api.getIssues(params: {'software': _filterSoftware});
    } catch (_) {}
    if (mounted) setState(() => _loadingIssues = false);
  }

  void _viewIssueDetail(Map<String, dynamic> issue) async {
    setState(() {
      _selectedIssue = issue;
      _loadingIssueLogs = true;
    });
    try {
      final api = context.read<AuthProvider>().apiService;
      _issueLogs = await api.getIssueLogs(issue['id'] as int);
    } catch (_) {}
    if (mounted) setState(() => _loadingIssueLogs = false);
  }

  Future<void> _updateIssueStatus(int id, String status) async {
    try {
      await context.read<AuthProvider>().apiService.updateIssue(id, {'status': status});
      if (_selectedIssue != null) {
        _selectedIssue!['status'] = status;
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('更新失败: $e')));
    }
  }

  void _toggleSelect(int id) {
    setState(() {
      if (_selectedIds.contains(id)) { _selectedIds.remove(id); } else { _selectedIds.add(id); }
    });
  }

  bool get _allSelected => _data.isNotEmpty && _selectedIds.length == _data.length;

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) { _selectedIds.clear(); } else { _selectedIds.addAll(_data.map((d) => d.id)); }
    });
  }

  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('确认'), content: Text('确定要批量删除这 ${_selectedIds.length} 条遥测数据吗？'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: Colors.red)))],
    ));
    if (confirm != true) return;
    try {
      await context.read<AuthProvider>().apiService.batchDeleteTelemetry(_selectedIds.toList());
      _selectedIds.clear();
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
    }
  }

  Future<void> _saveDef() async {
    try {
      final data = {
        'label': _defLabelCtrl.text,
        'field_path': _defFieldCtrl.text,
        'data_type': _defDataType,
        'aggregation': _defAggregation,
        'software': _filterSoftware,
      };
      await context.read<AuthProvider>().apiService.createMetricDefinition(data);
      setState(() => _showDefDialog = false);
      _loadStats();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    }
  }

  Future<void> _deleteDef(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('确认'), content: const Text('确定删除此指标定义吗？'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: Colors.red)))],
    ));
    if (confirm != true) return;
    try {
      await context.read<AuthProvider>().apiService.deleteMetricDefinition(id);
      _loadStats();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
    }
  }

  int get _errorCount => _data.where((d) {
    if (d.dataType != 'log' || d.content == null) return false;
    try {
      return jsonEncode(d.content).toLowerCase().contains('error');
    } catch (_) {
      return false;
    }
  }).length;

  bool get _canEdit {
    if (_filterSoftware == 'all') return false;
    final sw = _softwares.cast<Software?>().firstWhere(
      (s) => s!.id == _filterSoftware, orElse: () => null);
    return sw != null && ['owner', 'admin', 'developer'].contains(sw.role);
  }

  String _formatDate(String d) {
    try { return DateTime.parse(d).toLocal().toString().substring(0, 19); } catch (_) { return d; }
  }

  String _formatTime(String d) {
    try { return DateTime.parse(d).toLocal().toString().substring(11, 19); } catch (_) { return d; }
  }

  String _summary(dynamic content) {
    final s = content is String ? content : jsonEncode(content);
    return s.length > 80 ? '${s.substring(0, 80)}...' : s;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('软件遥测'),
            actions: [
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
            ],
          ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade50,
            child: Wrap(
              spacing: 16, runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<String>(
                  value: _filterSoftware,
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('所有软件')),
                    ..._softwares.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, style: const TextStyle(fontSize: 13)))),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _filterSoftware = v ?? 'all';
                      _filterVersion = 'all';
                      _filterEnvironment = 'all';
                      _availableVersions = [];
                      _availableEnvironments = [];
                    });
                    _loadData();
                    if (_tabController.index == 1) _loadIssues();
                    if (_tabController.index == 3) _loadStats();
                  },
                ),
                DropdownButton<String>(
                  value: _filterDataType,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('所有类型')),
                    DropdownMenuItem(value: 'trace', child: Text('Trace')),
                    DropdownMenuItem(value: 'metric', child: Text('Metric')),
                    DropdownMenuItem(value: 'log', child: Text('Log')),
                  ],
                  onChanged: (v) { setState(() => _filterDataType = v ?? 'all'); _loadData(); },
                ),
                if (_filterSoftware != 'all') ...[
                  DropdownButton<String>(
                    value: _filterVersion,
                    items: [const DropdownMenuItem(value: 'all', child: Text('所有版本')),
                      ..._availableVersions.map((v) => DropdownMenuItem(value: v, child: Text('v$v')))],
                    onChanged: (v) { setState(() => _filterVersion = v ?? 'all'); _loadData(); },
                  ),
                  DropdownButton<String>(
                    value: _filterEnvironment,
                    items: [const DropdownMenuItem(value: 'all', child: Text('所有环境')),
                      ..._availableEnvironments.map((e) => DropdownMenuItem(value: e, child: Text(e)))],
                    onChanged: (v) { setState(() => _filterEnvironment = v ?? 'all'); _loadData(); },
                  ),
                ],
                if (_selectedIds.isNotEmpty && _canEdit)
                  FilledButton.tonalIcon(
                    onPressed: _batchDelete,
                    icon: const Icon(Icons.delete, size: 16),
                    label: Text('批量删除 (${_selectedIds.length})'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red),
                  ),
              ],
            ),
          ),
          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '实时监控'),
              Tab(text: '问题追踪'),
              Tab(text: '原始数据'),
              Tab(text: '统计分析'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMonitorTab(theme),
                _buildIssuesTab(theme),
                _buildDataTab(theme),
                _buildStatsTab(theme),
              ],
            ),
          ),
        ],
      ),
        ),
        _buildDetailDialog(),
        _buildIssueDialog(),
        _buildDefDialog(),
      ],
    );
  }

  Widget _buildDetailDialog() {
    if (_selectedItem == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      color: Colors.black26,
      child: Center(
        child: Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('遥测详情', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _detailRow('上报时间', _formatDate(_selectedItem!.timestamp)),
                  _detailRow('IP 地址', _selectedItem!.ipAddress ?? '未知'),
                  _detailRow('设备 ID', _selectedItem!.deviceId ?? '未提供'),
                  const SizedBox(height: 12),
                  const Text('数据负载', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      width: double.infinity, padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: SingleChildScrollView(
                        child: Text(const JsonEncoder.withIndent('  ').convert(_selectedItem!.content), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => setState(() => _selectedItem = null), child: const Text('关闭'))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIssueDialog() {
    if (_selectedIssue == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      color: Colors.black26,
      child: Center(
        child: Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                        child: Text('${_selectedIssue!['status']}', style: const TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      Text('#${_selectedIssue!['id']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${_selectedIssue!['title']}', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statBox('总次数', '${_selectedIssue!['count'] ?? 0}'),
                      const SizedBox(width: 12),
                      _statBox('受影响用户', '${_selectedIssue!['affected_users_count'] ?? 0}'),
                      const SizedBox(width: 12),
                      _statBox('首次发现', _formatDate('${_selectedIssue!['first_seen'] ?? ''}')),
                      const SizedBox(width: 12),
                      _statBox('最近出现', _formatDate('${_selectedIssue!['last_seen'] ?? ''}')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('标记状态: '),
                      ...['open', 'resolving', 'resolved', 'ignored'].map((s) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(s, style: const TextStyle(fontSize: 12)),
                          selected: _selectedIssue!['status'] == s,
                          onSelected: (_) => _updateIssueStatus(_selectedIssue!['id'] as int, s),
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('最近日志', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _loadingIssueLogs
                        ? const Center(child: CircularProgressIndicator())
                        : _issueLogs.isEmpty
                            ? const Center(child: Text('暂无日志'))
                            : ListView.builder(
                                itemCount: _issueLogs.length,
                                itemBuilder: (_, i) {
                                  final log = _issueLogs[i];
                                  return Container(
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.only(bottom: 4),
                                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(4)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(log.deviceId ?? '', style: TextStyle(color: theme.colorScheme.primary, fontFamily: 'monospace', fontSize: 11)),
                                            const Spacer(),
                                            Text(_formatDate(log.timestamp), style: const TextStyle(fontSize: 10)),
                                          ],
                                        ),
                                        Text(jsonEncode(log.content), style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                  Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => setState(() => _selectedIssue = null), child: const Text('关闭'))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefDialog() {
    if (!_showDefDialog) return const SizedBox.shrink();
    return Material(
      color: Colors.black26,
      child: Center(
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('配置自定义统计指标'),
                const SizedBox(height: 4),
                Text('定义如何从上报的 JSON 数据中提取并计算统计值。', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 16),
                TextField(controller: _defLabelCtrl, decoration: const InputDecoration(labelText: '指标名称', border: OutlineInputBorder(), hintText: '如: 平均FPS')),
                const SizedBox(height: 12),
                TextField(controller: _defFieldCtrl, decoration: const InputDecoration(labelText: 'JSON 字段路径', border: OutlineInputBorder(), hintText: 'content.fps')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _defDataType,
                  decoration: const InputDecoration(labelText: '数据来源类型', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'metric', child: Text('Metric')),
                    DropdownMenuItem(value: 'log', child: Text('Log')),
                    DropdownMenuItem(value: 'trace', child: Text('Trace')),
                  ],
                  onChanged: (v) => setState(() => _defDataType = v ?? 'metric'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _defAggregation,
                  decoration: const InputDecoration(labelText: '聚合方式', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'avg', child: Text('平均值 (Avg)')),
                    DropdownMenuItem(value: 'sum', child: Text('总和 (Sum)')),
                    DropdownMenuItem(value: 'max', child: Text('最大值 (Max)')),
                    DropdownMenuItem(value: 'min', child: Text('最小值 (Min)')),
                    DropdownMenuItem(value: 'count', child: Text('计数 (Count)')),
                    DropdownMenuItem(value: 'dist', child: Text('分布 (Dist)')),
                  ],
                  onChanged: (v) => setState(() => _defAggregation = v ?? 'avg'),
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  OutlinedButton(onPressed: () => setState(() => _showDefDialog = false), child: const Text('取消')),
                  const SizedBox(width: 12),
                  FilledButton(onPressed: _saveDef, child: const Text('保存配置')),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonitorTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _metricCard('总上报量', '${_data.length}', Icons.bar_chart, Colors.grey, '当前页面缓存数量')),
            const SizedBox(width: 16),
            Expanded(child: _metricCard('错误日志', '$_errorCount', Icons.error_outline, Colors.red, '需关注的异常条目')),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('实时流水', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('最新的遥测数据', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 12),
                if (_data.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('等待实时数据上报...', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                    ),
                  )
                else
                  ..._data.take(10).map((d) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: d.dataType == 'trace' ? Colors.blue.shade50 : d.dataType == 'metric' ? Colors.green.shade50 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            d.dataType == 'trace' ? Icons.history : d.dataType == 'metric' ? Icons.show_chart : Icons.terminal,
                            size: 16,
                            color: d.dataType == 'trace' ? Colors.blue : d.dataType == 'metric' ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(d.softwareName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(3)),
                                    child: Text(d.version, style: const TextStyle(fontSize: 10)),
                                  ),
                                ],
                              ),
                              Text(_summary(d.content), style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Text(_formatTime(d.timestamp), style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                      ],
                    ),
                  )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIssuesTab(ThemeData theme) {
    if (_filterSoftware == 'all') {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('请先选择一个软件以查看异常聚类。', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    if (_loadingIssues) return const Center(child: CircularProgressIndicator());
    if (_issues.isEmpty) {
      return Center(child: Text('未发现异常聚类', style: TextStyle(color: Colors.grey.shade500)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _issues.length,
      itemBuilder: (_, i) {
        final issue = _issues[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _viewIssueDetail(issue),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: issue['priority'] == 'critical' ? Colors.red.shade50 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('${issue['priority'] ?? 'N/A'}', style: TextStyle(fontSize: 10, color: issue['priority'] == 'critical' ? Colors.red : Colors.grey)),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                              child: Text('${issue['status'] ?? 'N/A'}', style: const TextStyle(fontSize: 10)),
                            ),
                            const SizedBox(width: 6),
                            Text('#${issue['id']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('${issue['title'] ?? ''}', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('发生 ${issue['count'] ?? 0} 次', style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 16),
                            Text('影响 ${issue['affected_users_count'] ?? 0} 用户', style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 16),
                            Text('最后出现: ${_formatTime('${issue['last_seen'] ?? ''}')}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataTab(ThemeData theme) {
    return Column(
      children: [
        if (_data.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Checkbox(value: _allSelected, onChanged: (_) => _toggleSelectAll()),
                const SizedBox(width: 8),
                Text('${_data.length} 条记录', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
        Expanded(
          child: _loadingData
              ? const Center(child: CircularProgressIndicator())
              : _data.isEmpty
                  ? Center(child: Text('暂无遥测数据', style: TextStyle(color: Colors.grey.shade500)))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('')),
                          DataColumn(label: Text('时间')),
                          DataColumn(label: Text('软件')),
                          DataColumn(label: Text('类型')),
                          DataColumn(label: Text('环境/版本')),
                          DataColumn(label: Text('内容')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: _data.map((d) => DataRow(cells: [
                          DataCell(Checkbox(value: _selectedIds.contains(d.id), onChanged: (_) => _toggleSelect(d.id))),
                          DataCell(Text(_formatDate(d.timestamp), style: const TextStyle(fontSize: 12))),
                          DataCell(Text(d.softwareName)),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(3)),
                            child: Text(d.dataType.toUpperCase(), style: const TextStyle(fontSize: 10)),
                          )),
                          DataCell(Text('${d.environment} / ${d.version}', style: const TextStyle(fontSize: 12))),
                          DataCell(Container(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Text(_summary(d.content), style: const TextStyle(fontFamily: 'monospace', fontSize: 11), overflow: TextOverflow.ellipsis),
                          )),
                          DataCell(TextButton(
                            onPressed: () => setState(() => _selectedItem = d),
                            child: const Text('详情'),
                          )),
                        ])).toList(),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildStatsTab(ThemeData theme) {
    if (_filterSoftware == 'all') {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('请先在上方筛选器中选择一个具体的软件以查看统计分析。', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    if (_loadingStats) return const Center(child: CircularProgressIndicator());
    if (_stats == null) return const Center(child: Text('暂无统计数据'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text('${_stats!['unique_devices'] ?? 0}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      const SizedBox(height: 8),
                      Text('累计唯一用户 (设备)', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_stats!['os_distribution'] != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('操作系统分布', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...(_stats!['os_distribution'] as List).map((os) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${os['os_name'] ?? '未知'}', style: const TextStyle(fontSize: 13)),
                            Text('${os['count'] ?? 0}', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: ((os['count'] as num?)?.toDouble() ?? 0) / ((_stats!['total_count'] as num?)?.toDouble() ?? 1),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (_stats!['version_distribution'] != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('版本分布', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...(_stats!['version_distribution'] as List).map((ver) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('v${ver['version'] ?? '未知'}', style: const TextStyle(fontSize: 13)),
                            Text('${ver['count'] ?? 0}', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: ((ver['count'] as num?)?.toDouble() ?? 0) / ((_stats!['total_count'] as num?)?.toDouble() ?? 1),
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (_stats!['custom_metrics'] != null)
          Wrap(
            spacing: 16, runSpacing: 16,
            children: [
              ...(_stats!['custom_metrics'] as List).map((m) {
                final metric = m as Map<String, dynamic>;
                return SizedBox(
                  width: 200,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${metric['label'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (_canEdit)
                                InkWell(
                                  onTap: () => _deleteDef(metric['id'] as int),
                                  child: Icon(Icons.delete, size: 14, color: Colors.red.shade400),
                                ),
                            ],
                          ),
                          Text('${metric['aggregation'] ?? ''}', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                          const SizedBox(height: 8),
                          Text('${metric['value'] ?? 'N/A'}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (_canEdit)
                GestureDetector(
                  onTap: () {
                    _defLabelCtrl.clear();
                    _defFieldCtrl.text = 'content.';
                    _defDataType = 'metric';
                    _defAggregation = 'avg';
                    setState(() => _showDefDialog = true);
                  },
                  child: SizedBox(
                    width: 200, height: 100,
                    child: Card(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 32, color: Colors.grey.shade400),
                            const Text('添加自定义指标', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Icon(icon, size: 18, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(color: Colors.grey.shade600)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
