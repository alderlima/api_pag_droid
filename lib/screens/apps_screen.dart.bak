import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:installed_apps/installed_apps.dart';

import '../services/notification_service.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({Key? key}) : super(key: key);

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  List<Map<String, dynamic>> _installedApps = [];
  bool _isLoadingApps = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  Future<void> _loadInstalledApps() async {
    setState(() => _isLoadingApps = true);

    try {
      final apps = await InstalledApps.getInstalledApps(
        true,
        true,
      );

      setState(() {
        _installedApps =
            List<Map<String, dynamic>>.from(apps);
      });
    } catch (e) {
      debugPrint('Erro ao carregar apps: $e');
    }

    setState(() => _isLoadingApps = false);
  }

  List<Map<String, dynamic>> get _filteredApps {
    if (_searchQuery.isEmpty) return _installedApps;

    return _installedApps.where((app) {
      final name = (app['name'] ?? '').toString();
      final package = (app['packageName'] ?? '').toString();

      return name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          package
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, service, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: 'Pesquisar aplicativos...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoadingApps
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredApps.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: _filteredApps.length,
                          itemBuilder: (context, index) {
                            final app = _filteredApps[index];

                            final name =
                                (app['name'] ?? '').toString();
                            final package =
                                (app['packageName'] ?? '').toString();
                            final icon =
                                app['icon'] as Uint8List?;

                            final isEnabled = service.enabledApps
                                .any((a) =>
                                    a.packageName == package);

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: icon != null
                                    ? Image.memory(
                                        icon,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.android),
                                title: Text(name),
                                subtitle: Text(
                                  package,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                                trailing: Switch(
                                  value: isEnabled,
                                  onChanged: (value) {
                                    if (value) {
                                      service.enableApp(
                                        package,
                                        name,
                                      );
                                    } else {
                                      service.disableApp(
                                        package,
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apps,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum aplicativo encontrado',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
