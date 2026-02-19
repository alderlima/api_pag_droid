import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'notification_parser.dart';

/// Modelo para resposta do servidor
class PaymentResponse {
  final bool success;
  final String message;
  final int? statusCode;
  final dynamic data;

  PaymentResponse({
    required this.success,
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'PaymentResponse(success: $success, message: $message)';
}

/// Serviço responsável por comunicação HTTP com o backend
class PaymentService extends ChangeNotifier {
  /// URL base do backend (para emulador usar 10.0.2.2, para dispositivo físico use IP da máquina)
  static const String BACKEND_URL = 'http://127.0.0.1:3000';
  
  /// Endpoint para confirmar pagamento
  static const String CONFIRM_ENDPOINT = '$BACKEND_URL/payments/confirm';
  
  /// Timeout para requisições HTTP (segundos)
  static const int HTTP_TIMEOUT = 10;

  /// Histórico de confirmações enviadas
  final List<Map<String, dynamic>> _confirmationHistory = [];
  
  /// Hashes de notificações já processadas
  final Set<String> _processedHashes = {};

  List<Map<String, dynamic>> get confirmationHistory => _confirmationHistory;
  Set<String> get processedHashes => _processedHashes;

  /// Verifica se uma notificação já foi processada
  bool isNotificationProcessed(String hash) {
    return _processedHashes.contains(hash);
  }

  /// Marca uma notificação como processada
  void markAsProcessed(String hash) {
    _processedHashes.add(hash);
    notifyListeners();
  }

  /// Confirma um pagamento no backend
  /// Retorna PaymentResponse com resultado
  Future<PaymentResponse> confirmPayment(ExtractedPayment payment) async {
    try {
      // Verificar se já foi processado
      if (isNotificationProcessed(payment.notificationHash)) {
        debugPrint('⚠️ Notificação já processada: ${payment.notificationHash}');
        return PaymentResponse(
          success: false,
          message: 'Notificação já processada',
          statusCode: 409,
        );
      }

      debugPrint('📤 Enviando confirmação de pagamento...');
      debugPrint('   - Valor: R\$ ${payment.amount}');
      debugPrint('   - Pacote: ${payment.packageName}');
      debugPrint('   - URL: $CONFIRM_ENDPOINT');

      // Preparar payload
      final payload = {
        'amount': payment.amount,
        'packageName': payment.packageName,
      };

      debugPrint('   - Payload: ${jsonEncode(payload)}');

      // Fazer requisição HTTP
      final response = await http
          .post(
            Uri.parse(CONFIRM_ENDPOINT),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: HTTP_TIMEOUT),
            onTimeout: () {
              throw TimeoutException(
                'Timeout ao conectar com backend',
              );
            },
          );

      debugPrint('📥 Resposta recebida: ${response.statusCode}');
      debugPrint('   - Body: ${response.body}');

      // Processar resposta
      return _handleResponse(response, payment);
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout: ${e.message}');
      return PaymentResponse(
        success: false,
        message: 'Timeout ao conectar com backend',
        statusCode: 408,
      );
    } on http.ClientException catch (e) {
      debugPrint('❌ Erro de conexão: ${e.message}');
      return PaymentResponse(
        success: false,
        message: 'Erro de conexão: ${e.message}',
        statusCode: 0,
      );
    } catch (e) {
      debugPrint('❌ Erro inesperado: $e');
      return PaymentResponse(
        success: false,
        message: 'Erro inesperado: $e',
        statusCode: 500,
      );
    }
  }

  /// Processa a resposta do servidor
  PaymentResponse _handleResponse(
    http.Response response,
    ExtractedPayment payment,
  ) {
    try {
      switch (response.statusCode) {
        // Sucesso: pagamento confirmado
        case 200:
        case 201:
          debugPrint('✅ Pagamento confirmado com sucesso!');
          markAsProcessed(payment.notificationHash);
          
          // Adicionar ao histórico
          _confirmationHistory.add({
            'amount': payment.amount,
            'packageName': payment.packageName,
            'hash': payment.notificationHash,
            'timestamp': DateTime.now().toIso8601String(),
            'status': 'success',
            'statusCode': response.statusCode,
          });
          
          notifyListeners();
          
          return PaymentResponse(
            success: true,
            message: 'Pagamento confirmado com sucesso',
            statusCode: response.statusCode,
            data: _tryParseJson(response.body),
          );

        // Não encontrado: sem pagamento pendente
        case 404:
          debugPrint('ℹ️ Nenhum pagamento pendente encontrado (404)');
          markAsProcessed(payment.notificationHash);
          
          return PaymentResponse(
            success: true, // Não é erro, apenas não há pagamento
            message: 'Nenhum pagamento pendente encontrado',
            statusCode: 404,
          );

        // Conflito: pagamento já confirmado
        case 409:
          debugPrint('⚠️ Pagamento já foi confirmado (409)');
          markAsProcessed(payment.notificationHash);
          
          return PaymentResponse(
            success: true, // Não é erro, pagamento já estava confirmado
            message: 'Pagamento já foi confirmado',
            statusCode: 409,
          );

        // Erro de validação
        case 400:
          debugPrint('❌ Erro de validação (400)');
          
          return PaymentResponse(
            success: false,
            message: 'Erro de validação: ${response.body}',
            statusCode: 400,
            data: _tryParseJson(response.body),
          );

        // Erro no servidor
        case 500:
        case 502:
        case 503:
          debugPrint('❌ Erro no servidor (${response.statusCode})');
          
          return PaymentResponse(
            success: false,
            message: 'Erro no servidor',
            statusCode: response.statusCode,
          );

        // Outros erros
        default:
          debugPrint('❌ Erro desconhecido (${response.statusCode})');
          
          return PaymentResponse(
            success: false,
            message: 'Erro HTTP ${response.statusCode}',
            statusCode: response.statusCode,
            data: _tryParseJson(response.body),
          );
      }
    } catch (e) {
      debugPrint('❌ Erro ao processar resposta: $e');
      return PaymentResponse(
        success: false,
        message: 'Erro ao processar resposta: $e',
        statusCode: response.statusCode,
      );
    }
  }

  /// Tenta fazer parse de JSON, retorna null se falhar
  dynamic _tryParseJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  /// Retorna o histórico de confirmações
  List<Map<String, dynamic>> getConfirmationHistory() {
    return List.unmodifiable(_confirmationHistory);
  }

  /// Limpa o histórico de confirmações
  void clearHistory() {
    _confirmationHistory.clear();
    notifyListeners();
  }

  /// Retorna estatísticas
  Map<String, dynamic> getStatistics() {
    return {
      'totalProcessed': _processedHashes.length,
      'totalConfirmed': _confirmationHistory.length,
      'totalAmount': _confirmationHistory.fold<double>(
        0.0,
        (sum, item) => sum + (item['amount'] as double? ?? 0.0),
      ),
    };
  }
}

/// Exceção para timeout
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}