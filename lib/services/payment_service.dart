import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_parser.dart';

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

class PaymentService extends ChangeNotifier {
  static const String _backendUrlKey = 'backend_url';
  static const String _defaultBackendUrl = 'http://10.0.2.2:3000'; // Android emulator

  String _backendUrl = _defaultBackendUrl;
  final Set<String> _processedHashes = {};

  Set<String> get processedHashes => _processedHashes;
  String get backendUrl => _backendUrl;

  PaymentService() {
    _loadBackendUrl();
  }

  Future<void> _loadBackendUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_backendUrlKey);
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _backendUrl = savedUrl;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao carregar URL do backend: $e');
    }
  }

  Future<void> updateBackendUrl(String newUrl) async {
    if (newUrl == _backendUrl) return;
    _backendUrl = newUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backendUrlKey, newUrl);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao salvar URL do backend: $e');
    }
  }

  bool isNotificationProcessed(String hash) {
    return _processedHashes.contains(hash);
  }

  void markAsProcessed(String hash) {
    _processedHashes.add(hash);
    notifyListeners();
  }

  Future<PaymentResponse> confirmPayment(ExtractedPayment payment) async {
    try {
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
      debugPrint('   - URL: $_backendUrl/payments/confirm');

      final payload = {
        'amount': payment.amount,
        'packageName': payment.packageName,
      };

      final response = await http
          .post(
            Uri.parse('$_backendUrl/payments/confirm'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Timeout ao conectar com backend');
            },
          );

      debugPrint('📥 Resposta recebida: ${response.statusCode}');
      debugPrint('   - Body: ${response.body}');

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

  PaymentResponse _handleResponse(http.Response response, ExtractedPayment payment) {
    try {
      switch (response.statusCode) {
        case 200:
        case 201:
          debugPrint('✅ Pagamento confirmado com sucesso!');
          markAsProcessed(payment.notificationHash);
          return PaymentResponse(
            success: true,
            message: 'Pagamento confirmado com sucesso',
            statusCode: response.statusCode,
            data: _tryParseJson(response.body),
          );
        case 404:
          debugPrint('ℹ️ Nenhum pagamento pendente encontrado (404)');
          markAsProcessed(payment.notificationHash);
          return PaymentResponse(
            success: true,
            message: 'Nenhum pagamento pendente encontrado',
            statusCode: 404,
          );
        case 409:
          debugPrint('⚠️ Pagamento já foi confirmado (409)');
          markAsProcessed(payment.notificationHash);
          return PaymentResponse(
            success: true,
            message: 'Pagamento já foi confirmado',
            statusCode: 409,
          );
        case 400:
          debugPrint('❌ Erro de validação (400)');
          return PaymentResponse(
            success: false,
            message: 'Erro de validação: ${response.body}',
            statusCode: 400,
            data: _tryParseJson(response.body),
          );
        case 500:
        case 502:
        case 503:
          debugPrint('❌ Erro no servidor (${response.statusCode})');
          return PaymentResponse(
            success: false,
            message: 'Erro no servidor',
            statusCode: response.statusCode,
          );
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

  dynamic _tryParseJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}