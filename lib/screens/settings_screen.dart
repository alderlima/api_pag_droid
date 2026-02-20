import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/payment_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().checkNotificationListenerStatus();
      _urlController.text = context.read<PaymentService>().backendUrl;
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NotificationService, PaymentService>(
      builder: (context, notificationService, paymentService, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Permissões
            Text('Permissões', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              child: Column(children: [
                ListTile(
                  leading: Icon(
                    notificationService.isNotificationListenerEnabled
                        ? Icons.check_circle
                        : Icons.error_outline,
                    color: notificationService.isNotificationListenerEnabled
                        ? Colors.green
                        : Colors.red,
                  ),
                  title: const Text('Listener de Notificações'),
                  subtitle: Text(
                    notificationService.isNotificationListenerEnabled
                        ? 'Ativo'
                        : 'Inativo',
                  ),
                  trailing: ElevatedButton(
                    onPressed: notificationService.openNotificationListenerSettings,
                    child: const Text('Configurar'),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // Backend
            Text('Backend', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('URL do servidor de confirmação',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        hintText: 'Ex: http://10.0.2.2:3000',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: () async {
                            final newUrl = _urlController.text.trim();
                            if (newUrl.isNotEmpty) {
                              await paymentService.updateBackendUrl(newUrl);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('URL salva com sucesso!')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('URL inválida'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'URL atual: ${paymentService.backendUrl}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Informações
            Text('Informações', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Versão'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: const Text('Apps Monitorando'),
                  subtitle: Text('${notificationService.enabledApps.length} app(s)'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Total de Logs'),
                  subtitle: Text('${notificationService.notifications.length} notificação(ões)'),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // Ajuda
            Text('Como Usar', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHelpItem(context, '1. Ativar Permissão',
                        'Clique em "Configurar" para conceder permissão de Listener de Notificações.'),
                    const SizedBox(height: 12),
                    _buildHelpItem(context, '2. Selecionar Apps',
                        'Vá para a aba "Aplicativos" e ative os apps que deseja monitorar.'),
                    const SizedBox(height: 12),
                    _buildHelpItem(context, '3. Configurar URL do Backend',
                        'Insira a URL do servidor que receberá as confirmações de pagamento.'),
                    const SizedBox(height: 12),
                    _buildHelpItem(context, '4. Ver Logs',
                        'Vá para a aba "Logs" para ver todas as notificações capturadas.'),
                    const SizedBox(height: 12),
                    _buildHelpItem(context, '5. Gerenciar Logs',
                        'Clique em uma notificação para ver detalhes ou use o botão "Limpar" para deletar todos.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sobre
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sobre MacroNotify',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'MacroNotify monitora notificações do Android usando NotificationListenerService. Você pode selecionar apps, visualizar logs e, automaticamente, extrair e confirmar pagamentos para um servidor configurado.',
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
        Text(title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(description, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}