import 'dart:async';
import 'package:flutter/material.dart';
import 'notification_parser.dart';
import 'payment_service.dart';
import 'notification_service.dart';

class ProcessingResult {
  final bool success;
  final String message;
  final ExtractedPayment? payment;
  final PaymentResponse? paymentResponse;
  final DateTime timestamp;

  ProcessingResult({
    required this.success,
    required this.message,
    this.payment,
    this.paymentResponse,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'ProcessingResult(success: $success, message: $message, timestamp: $timestamp)';
  }
}

class NotificationProcessor extends ChangeNotifier {
  final NotificationService notificationService;
  final PaymentService paymentService;

  StreamSubscription? _notificationSubscription;
  final List<ProcessingResult> _processingHistory = [];
  final List<Map<String, dynamic>> _pendingNotifications = [];
  bool _isProcessing = false;

  List<ProcessingResult> get processingHistory => _processingHistory;

  NotificationProcessor({
    required this.notificationService,
    required this.paymentService,
  }) {
    _listenToNotifications();
  }

  void _listenToNotifications() {
    _notificationSubscription = notificationService.notificationStream.listen(
      (data) {
        _pendingNotifications.add(data);
        _processNext();
      },
      onError: (error) {
        debugPrint('❌ Erro no stream de notificações: $error');
      },
    );
  }

  Future<void> _processNext() async {
    if (_isProcessing || _pendingNotifications.isEmpty) return;

    _isProcessing = true;
    final data = _pendingNotifications.removeAt(0);

    final packageName = data['packageName'] as String? ?? '';
    final isEnabled = notificationService.enabledApps.any((app) => app.packageName == packageName);

    if (!isEnabled) {
      debugPrint('⏭️ Notificação ignorada (app não habilitado): $packageName');
      _isProcessing = false;
      _processNext();
      return;
    }

    final title = data['title'] as String? ?? '';
    final text = data['text'] as String? ?? '';
    final timestamp = data['timestamp'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int)
        : DateTime.now();

    await _processNotification(
      packageName: packageName,
      title: title,
      text: text,
      timestamp: timestamp,
    );

    _isProcessing = false;
    _processNext();
  }

  Future<void> _processNotification({
    required String packageName,
    required String title,
    required String text,
    required DateTime timestamp,
  }) async {
    try {
      debugPrint('\n🔄 Iniciando processamento de notificação...');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📱 Pacote: $packageName');
      debugPrint('📝 Título: $title');
      debugPrint('📄 Texto: $text');
      debugPrint('⏰ Timestamp: $timestamp');

      debugPrint('\n[1/3] Fazendo parsing da notificação...');
      final payment = NotificationParser.parseNotification(
        packageName: packageName,
        title: title,
        text: text,
        timestamp: timestamp,
      );

      if (payment == null) {
        final result = ProcessingResult(
          success: false,
          message: 'Notificação não atende aos critérios de processamento',
          timestamp: DateTime.now(),
        );
        _addToHistory(result);
        return;
      }

      debugPrint('✅ Parsing concluído');
      debugPrint('   - Valor extraído: R\$ ${payment.amount}');
      debugPrint('   - Hash: ${payment.notificationHash}');

      debugPrint('\n[2/3] Verificando duplicidade...');
      if (paymentService.isNotificationProcessed(payment.notificationHash)) {
        final result = ProcessingResult(
          success: false,
          message: 'Notificação já foi processada anteriormente',
          payment: payment,
          timestamp: DateTime.now(),
        );
        _addToHistory(result);
        return;
      }
      debugPrint('✅ Notificação é nova');

      debugPrint('\n[3/3] Enviando para backend...');
      final paymentResponse = await paymentService.confirmPayment(payment);

      if (paymentResponse.success) {
        debugPrint('✅ Confirmação enviada com sucesso');
        final result = ProcessingResult(
          success: true,
          message: paymentResponse.message,
          payment: payment,
          paymentResponse: paymentResponse,
          timestamp: DateTime.now(),
        );
        _addToHistory(result);
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('✅ PROCESSAMENTO CONCLUÍDO COM SUCESSO\n');
      } else {
        debugPrint('❌ Erro ao enviar confirmação: ${paymentResponse.message}');
        final result = ProcessingResult(
          success: false,
          message: paymentResponse.message,
          payment: payment,
          paymentResponse: paymentResponse,
          timestamp: DateTime.now(),
        );
        _addToHistory(result);
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('❌ PROCESSAMENTO FALHOU\n');
      }
    } catch (e) {
      debugPrint('❌ Erro inesperado: $e');
      final result = ProcessingResult(
        success: false,
        message: 'Erro inesperado: $e',
        timestamp: DateTime.now(),
      );
      _addToHistory(result);
    }
  }

  void _addToHistory(ProcessingResult result) {
    _processingHistory.add(result);
    notifyListeners();
  }

  List<ProcessingResult> getProcessingHistory() {
    return List.unmodifiable(_processingHistory);
  }

  Map<String, dynamic> getStatistics() {
    final total = _processingHistory.length;
    final successful = _processingHistory.where((r) => r.success).length;
    final failed = total - successful;
    final totalAmount = _processingHistory
        .where((r) => r.payment != null)
        .fold<double>(0.0, (sum, r) => sum + (r.payment?.amount ?? 0.0));

    return {
      'totalProcessed': total,
      'successful': successful,
      'failed': failed,
      'totalAmount': totalAmount,
      'successRate': total > 0 ? (successful / total * 100).toStringAsFixed(1) : '0.0',
    };
  }

  void clearHistory() {
    _processingHistory.clear();
    notifyListeners();
  }

  List<ProcessingResult> getRecentProcessing({int limit = 10}) {
    return _processingHistory.reversed.take(limit).toList();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}