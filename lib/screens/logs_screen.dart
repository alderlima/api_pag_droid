import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/notification_processor.dart';
import '../widgets/notification_card.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({Key? key}) : super(key: key);

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NotificationService, NotificationProcessor>(
      builder: (context, service, processor, _) {
        // Filtra apenas notificações de apps habilitados
        final enabledPackages = service.enabledApps.map((e) => e.packageName).toSet();
        final filteredNotifications = service.notifications
            .where((n) => enabledPackages.contains(n.packageName))
            .toList();

        return RefreshIndicator(
          onRefresh: () => service.loadNotifications(),
          child: Column(
            children: [
              // Header com informações
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total de Notificações',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${filteredNotifications.length}',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                        if (filteredNotifications.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Limpar Logs'),
                                    content: const Text(
                                      'Tem certeza que deseja limpar todos os logs de notificações?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          try {
                                            await service.clearAllNotifications();
                                            if (mounted) Navigator.pop(context);
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Erro ao limpar: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text('Limpar'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Limpar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Lista de notificações
              Expanded(
                child: service.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredNotifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_none,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhuma notificação de apps monitorados',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ative aplicativos na aba "Aplicativos"',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: filteredNotifications.length,
                            itemBuilder: (context, index) {
                              final notification = filteredNotifications[index];
                              // Obtém o resultado do processamento (se houver)
                              final result = processor.getProcessingResultForNotification(
                                packageName: notification.packageName,
                                title: notification.title,
                                text: notification.text,
                                timestamp: DateTime.fromMillisecondsSinceEpoch(notification.timestamp),
                              );
                              return NotificationCard(
                                notification: notification,
                                processingResult: result,
                                onDelete: () async {
                                  try {
                                    await service.deleteNotification(notification.id);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Notificação deletada')),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Erro ao deletar: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}