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
  List<InstalledAppInfo> _installedApps = [];
  bool _isLoadingApps = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  /// 🔹 Carrega aplicativos instalados
  Future<void> _loadInstalledApps() async {
    setState(() => _isLoadingApps = true);

    try {
      final dynamic appsRaw =
          await InstalledApps.getInstalledApps(true, true);

      // Conversão segura para evitar Object?
      final List<InstalledAppInfo> typedApps =
          List<InstalledAppInfo>.from(appsRaw);

      setState(() {
        _installedApps = typedApps;
      });
    } catch (e) {
      debugPrint('Erro ao carregar apps: $e');
    }

    setState(() => _isLoadingApps = false);
  }

  /// 🔹 Filtro de busca
  List<InstalledAppInfo> get _filteredApps {
    if (_searchQuery.isEmpty) return _installedApps;

    return _installedApps
        .where((InstalledAppInfo app) {
          final name = app.name ?? '';
          final package = app.packageName ?? '';

          return name
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              package
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, service, _) {
        return Column(
          children: [
            /// 🔍 Campo de busca
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

            /// 📱 Lista de apps
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
                            final InstalledAppInfo app =
                                _filteredApps[index];

                            final bool isEnabled = service.enabledApps
                                .any((a) =>
                                    a.packageName == app.packageName);

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading:
                                    _buildAppIcon(app.icon),
                                title: Text(app.name ?? ''),
                                subtitle: Text(
                                  app.packageName ?? '',
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                                trailing: Switch(
                                  value: isEnabled,
                                  onChanged: (value) {
                                    if (value) {
                                      service.enableApp(
                                        app.packageName ?? '',
                                        app.name ?? '',
                                      );
                                    } else {
                                      service.disableApp(
                                        app.packageName ?? '',
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

  /// 🔹 Ícone seguro
  Widget _buildAppIcon(Uint8List? iconBytes) {
    if (iconBytes == null) {
      return const Icon(Icons.android, size: 40);
    }

    return Image.memory(
      iconBytes,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
    );
  }

  /// 🔹 Estado vazio
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
