import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().checkNotificationListenerStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, service, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Seção de Permissões
            Text(
              'Permissões',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      service.isNotificationListenerEnabled
                          ? Icons.check_circle
                          : Icons.error_outline,
                      color: service.isNotificationListenerEnabled
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: const Text('Listener de Notificações'),
                    subtitle: Text(
                      service.isNotificationListenerEnabled
                          ? 'Ativo'
                          : 'Inativo',
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        service.openNotificationListenerSettings();
                      },
                      child: const Text('Ativar'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Seção de Informações
            Text(
              'Informações',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Versão'),
                    subtitle: const Text('1.0.0'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.notifications_active),
                    title: const Text('Apps Monitorando'),
                    subtitle: Text('${service.enabledApps.length} app(s)'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Total de Logs'),
                    subtitle: Text('${service.notifications.length} notificação(ões)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Seção de Ajuda
            Text(
              'Como Usar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHelpItem(
                      context,
                      '1. Ativar Permissão',
                      'Clique em "Ativar" para conceder permissão de Listener de Notificações ao app.',
                    ),
                    const SizedBox(height: 12),
                    _buildHelpItem(
                      context,
                      '2. Selecionar Apps',
                      'Vá para a aba "Aplicativos" e ative os apps que deseja monitorar.',
                    ),
                    const SizedBox(height: 12),
                    _buildHelpItem(
                      context,
                      '3. Ver Logs',
                      'Vá para a aba "Logs" para ver todas as notificações capturadas.',
                    ),
                    const SizedBox(height: 12),
                    _buildHelpItem(
                      context,
                      '4. Gerenciar Logs',
                      'Clique em uma notificação para ver detalhes ou use o botão "Limpar" para deletar todos.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Seção de Sobre
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sobre MacroNotify',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'MacroNotify é um aplicativo que monitora notificações do seu dispositivo Android usando NotificationListenerService. Você pode selecionar quais aplicativos deseja monitorar e visualizar um histórico completo de todas as notificações capturadas.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem(BuildContext context, String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
