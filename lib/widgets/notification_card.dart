import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_processor.dart';

class NotificationCard extends StatefulWidget {
  final NotificationModel notification;
  final ProcessingResult? processingResult;
  final VoidCallback onDelete;

  const NotificationCard({
    Key? key,
    required this.notification,
    this.processingResult,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  bool _isExpanded = false;

  IconData _getStatusIcon() {
    if (widget.processingResult == null) return Icons.hourglass_empty;
    return widget.processingResult!.success ? Icons.check_circle : Icons.error;
  }

  Color _getStatusColor(BuildContext context) {
    if (widget.processingResult == null) return Colors.grey;
    return widget.processingResult!.success
        ? Colors.green
        : Theme.of(context).colorScheme.error;
  }

  String _getStatusTooltip() {
    if (widget.processingResult == null) return 'Aguardando processamento';
    return widget.processingResult!.success
        ? 'Enviado com sucesso: ${widget.processingResult!.message}'
        : 'Falha no envio: ${widget.processingResult!.message}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Icon(
                widget.notification.action == 'posted'
                    ? Icons.notifications_active
                    : Icons.notifications_off,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.notification.title.isEmpty
                        ? 'Sem Título'
                        : widget.notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Tooltip(
                  message: _getStatusTooltip(),
                  child: Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(context),
                    size: 20,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.notification.packageName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  widget.notification.formattedTime,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  child: const Text('Expandir'),
                  onTap: () {
                    setState(() => _isExpanded = !_isExpanded);
                  },
                ),
                PopupMenuItem(
                  child: const Text('Deletar'),
                  onTap: widget.onDelete,
                ),
              ],
            ),
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
            },
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  _buildDetailRow(context, 'Pacote', widget.notification.packageName),
                  _buildDetailRow(context, 'Ação', widget.notification.action),
                  _buildDetailRow(context, 'ID', widget.notification.id.toString()),
                  if (widget.processingResult != null) ...[
                    _buildDetailRow(
                      context,
                      'Status',
                      widget.processingResult!.success ? 'Sucesso' : 'Falha',
                      widget.processingResult!.success ? Colors.green : Colors.red,
                    ),
                    _buildDetailRow(
                      context,
                      'Mensagem',
                      widget.processingResult!.message,
                    ),
                    if (widget.processingResult!.payment != null) ...[
                      _buildDetailRow(
                        context,
                        'Valor',
                        'R\$ ${widget.processingResult!.payment!.amount.toStringAsFixed(2)}',
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  if (widget.notification.title.isNotEmpty)
                    _buildDetailSection(context, 'Título', widget.notification.title),
                  if (widget.notification.text.isNotEmpty)
                    _buildDetailSection(context, 'Texto', widget.notification.text),
                  if (widget.notification.subText.isNotEmpty)
                    _buildDetailSection(context, 'Subtítulo', widget.notification.subText),
                  if (widget.notification.bigText.isNotEmpty)
                    _buildDetailSection(context, 'Texto Grande', widget.notification.bigText),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Deletar Notificação'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: valueColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}