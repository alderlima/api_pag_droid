import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../models/app_model.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  List<Application> _apps = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      final installedApps = await DeviceApps.getInstalledApplications(
        includeSystemApps: true,   // 🔥 importante para não vir vazio
        includeAppIcons: true,
      );

      installedApps.sort((a, b) => a.appName.compareTo(b.appName));

      debugPrint("Apps encontrados: ${installedApps.length}");

      setState(() {
        _apps = installedApps;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar apps: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<NotificationService>();
    final enabledApps = service.enabledApps;

    final filtered = _apps.where((app) {
      final name = app.appName.toLowerCase();
      final pkg = app.packageName.toLowerCase();
      final q = _search.toLowerCase();
      return name.contains(q) || pkg.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplicativos'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Pesquisar app...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadApps,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final app = filtered[i];
                        final isEnabled = enabledApps.any(
                          (e) => e.packageName == app.packageName,
                        );

                        return ListTile(
                          leading: app is ApplicationWithIcon
                              ? Image.memory(app.icon, width: 40, height: 40)
                              : const Icon(Icons.apps),
                          title: Text(app.appName),
                          subtitle: Text(app.packageName),
                          trailing: Switch(
                            value: isEnabled,
                            onChanged: (v) async {
                              if (v) {
                                await service.enableApp(
                                  AppModel(
                                    packageName: app.packageName,
                                    appName: app.appName,
                                    isEnabled: true,
                                  ),
                                );
                              } else {
                                await service.disableApp(app.packageName);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
