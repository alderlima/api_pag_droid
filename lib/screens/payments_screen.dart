import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/payment_service.dart';
import '../services/notification_processor.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  late NotificationProcessor _processor;

  @override
  void initState() {
    super.initState();
    _processor = context.read<NotificationProcessor>();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PaymentService, NotificationProcessor>(
      builder: (context, paymentService, processor, _) {
        final history = processor.getProcessingHistory();
        final stats = processor.getStatistics();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Confirmações de Pagamento'),
            elevation: 0,
            actions: [
              if (history.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showClearDialog(context, processor),
                  tooltip: 'Limpar histórico',
                ),
            ],
          ),
          body: history.isEmpty
              ? _buildEmptyState(context)
              : Column(
                  children: [
                    _buildStatsCard(context, stats),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final result = history[history.length - 1 - index];
                          return _buildResultCard(context, result);
                        },
                      ),
                    ),
                  ],
                ),
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
            Icons.payment,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma confirmação de pagamento',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'As confirmações aparecerão aqui',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, Map<String, dynamic> stats) {
    final totalAmount = stats['totalAmount'] as double;
    final successful = stats['successful'] as int;
    final failed = stats['failed'] as int;
    final successRate = stats['successRate'] as String;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estatísticas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                context,
                'Total',
                'R\$ ${totalAmount.toStringAsFixed(2)}',
                Icons.attach_money,
              ),
              _buildStatItem(
                context,
                'Sucesso',
                successful.toString(),
                Icons.check_circle,
              ),
              _buildStatItem(
                context,
                'Erro',
                failed.toString(),
                Icons.error,
              ),
              _buildStatItem(
                context,
                'Taxa',
                '$successRate%',
                Icons.trending_up,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, ProcessingResult result) {
    final isSuccess = result.success;
    final statusColor = isSuccess
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          isSuccess ? Icons.check_circle : Icons.error_circle,
          color: statusColor,
        ),
        title: Text(
          result.payment != null
              ? 'R\$ ${result.payment!.amount.toStringAsFixed(2)}'
              : 'Processamento',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Text(
          result.message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: statusColor,
              ),
        ),
        trailing: Text(
          _formatTime(result.timestamp),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  context,
                  'Status',
                  isSuccess ? 'Sucesso' : 'Erro',
                  isSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 8),
                if (result.payment != null) ...[
                  _buildDetailRow(
                    context,
                    'Valor',
                    'R\$ ${result.payment!.amount.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    context,
                    'Pacote',
                    result.payment!.packageName,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    context,
                    'Hash',
                    result.payment!.notificationHash.substring(0, 16) + '...',
                  ),
                  const SizedBox(height: 8),
                ],
                _buildDetailRow(
                  context,
                  'Mensagem',
                  result.message,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  context,
                  'Timestamp',
                  DateFormat('dd/MM/yyyy HH:mm:ss').format(result.timestamp),
                ),
                if (result.paymentResponse != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    context,
                    'HTTP Status',
                    result.paymentResponse!.statusCode?.toString() ?? 'N/A',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, [
    Color? valueColor,
  ]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: valueColor,
                ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'agora';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m atrás';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h atrás';
    } else {
      return DateFormat('dd/MM HH:mm').format(time);
    }
  }

  void _showClearDialog(
    BuildContext context,
    NotificationProcessor processor,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Histórico'),
        content: const Text(
          'Tem certeza que deseja limpar todo o histórico de confirmações?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              processor.clearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Histórico limpo')),
              );
            },
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
}
