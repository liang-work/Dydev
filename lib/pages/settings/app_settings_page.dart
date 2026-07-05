import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  String _appVersion = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = info.version;
          _buildNumber = info.buildNumber;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProv = context.watch<ThemeProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account settings link (top)
            Card(
              child: ListTile(
                leading: Icon(Icons.person, color: theme.colorScheme.primary),
                title: Text('settings.account'.tr()),
                subtitle: Text('settings.account.description'.tr(),
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/dashboard/settings'),
              ),
            ),
            const SizedBox(height: 16),
            // Language
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('settings.language'.tr(), style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('settings.language.description'.tr(),
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Locale>(
                      initialValue: context.locale,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: Locale('zh', 'CN'), child: Text('中文')),
                        DropdownMenuItem(value: Locale('en', 'US'), child: Text('English')),
                      ],
                      onChanged: (locale) {
                        if (locale != null) context.setLocale(locale);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Theme
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('settings.theme'.tr(), style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('settings.theme.description'.tr(),
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 16),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('浅色')),
                        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('深色')),
                        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.settings_brightness), label: Text('跟随系统')),
                      ],
                      selected: {themeProv.mode},
                      onSelectionChanged: (selected) {
                        themeProv.setMode(selected.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // About
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('settings.about'.tr(), style: theme.textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _aboutRow('应用名称', 'dydev'),
                    _aboutRow('版本号', _appVersion.isNotEmpty ? _appVersion : '...'),
                    _aboutRow('构建号', _buildNumber.isNotEmpty ? _buildNumber : '...'),
                    const Divider(height: 24),
                    _aboutRow('版权', '© dynamic network 团队版权所有'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aboutRow(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
          Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
