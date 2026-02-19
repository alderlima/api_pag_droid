import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/notification_service.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({Key? key}) : super(key: key);

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  static const platform = MethodChannel('com.macronotify.macro_notify/notifications');

  List<Map<String, dynamic>> _installedApps = [];
  bool _isLoadingApps = false;
  String _searchQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  Future<void> _loadInstalledApps() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingApps = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Iniciando carregamento de apps...');
      
      final String result = await platform.invokeMethod('getInstalledApps');
      
      debugPrint('Resultado recebido: ${result.substring(0, result.length > 100 ? 100 : result.length)}...');
      
      final List<dynamic> appsJson = jsonDecode(result);
      
      if (!mounted) return;
      
      setState(() {
        _installedApps = appsJson.map((app) {
          return {
            'name': app['name'] ?? 'App Desconhecido',
            'packageName': app['packageName'] ?? '',
          };
        }).toList();
        
        // Ordenar por nome
        _installedApps.sort((a, b) => 
          (a['name'] as String).compareTo(b['name'] as String)
        );
        
        debugPrint('Total de apps carregados: ${_installedApps.length}');
      });
    } on PlatformException catch (e) {
      debugPrint('Erro de plataforma: ${e.code} - ${e.message}');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar apps: ${e.message}';
        });
      }
    } catch (e) {
      debugPrint('Erro geral: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar apps: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingApps = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredApps {
    if (_searchQuery.isEmpty) return _installedApps;

    return _installedApps.where((app) {
      final name = (app['name'] ?? '').toString().toLowerCase();
      final package = (app['packageName'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || package.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, service, _) {
        return Column(
          children: [
            // Search bar
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
            // Conteúdo principal
            Expanded(
              child: _isLoadingApps
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Carregando aplicativos...'),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorState(context)
                      : _filteredApps.isEmpty
                          ? _buildEmptyState(context)
                          : _buildAppsList(context, service),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppsList(BuildContext context, dynamic service) {
    return RefreshIndicator(
      onRefresh: _loadInstalledApps,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _filteredApps.length,
        itemBuilder: (context, index) {
          final app = _filteredApps[index];
          final name = (app['name'] ?? 'App Desconhecido').toString();
          final package = (app['packageName'] ?? '').toString();

          final isEnabled = service.enabledApps.any((a) => a.packageName == package);

          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.android),
              ),
              title: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                package,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: Switch(
                value: isEnabled,
                onChanged: (value) {
                  if (value) {
                    service.enableApp(package, name);
                  } else {
                    service.disableApp(package);
                  }
                },
              ),
            ),
          );
        },
      ),
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
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Nenhum app corresponde à sua busca'
                : 'Nenhum app instalado',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadInstalledApps,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao Carregar Apps',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _errorMessage ?? 'Erro desconhecido',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadInstalledApps,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }
}
