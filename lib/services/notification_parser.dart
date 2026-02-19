import 'package:flutter/foundation.dart'; // <-- necessário para debugPrint
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Modelo para representar um pagamento extraído de uma notificação
class ExtractedPayment {
  final double amount;
  final String packageName;
  final String title;
  final String text;
  final DateTime timestamp;
  final String notificationHash;

  ExtractedPayment({
    required this.amount,
    required this.packageName,
    required this.title,
    required this.text,
    required this.timestamp,
    required this.notificationHash,
  });

  @override
  String toString() {
    return 'ExtractedPayment(amount: R\$ $amount, package: $packageName, hash: $notificationHash)';
  }
}

/// Serviço responsável por fazer parsing de notificações
class NotificationParser {
  /// Lista de pacotes permitidos para processar (usar igualdade exata)
  static const List<String> WHITELIST_PACKAGES = [
    'com.nu.production', // Nu Pagbank
    'com.itau.mobile', // Itaú
    'com.bradesco.bdrco', // Bradesco
    'com.caixa', // Caixa
    'com.banco.santander', // Santander
    'com.banco.bbsa.mobile', // Banco do Brasil
  ];

  /// Palavras-chave para identificar notificações de pagamento recebido
  static const List<String> PAYMENT_KEYWORDS = [
    'transferência recebida',
    'pix recebido',
    'você recebeu',
    'recebemos sua transferência',
    'pagamento recebido',
    'recebimento confirmado',
    'transferência de r',
    'pix de r',
  ];

  /// Regex para extrair valor monetário em formato brasileiro
  /// Exemplos: "R$ 0,01", "R$ 1.234,56", "0,01", "1.234,56"
  static final RegExp AMOUNT_REGEX = RegExp(
    r'[Rr]\$?\s*([0-9]{1,3}(?:\.[0-9]{3})*(?:,[0-9]{2})?)',
    multiLine: true,
  );

  /// Verifica se o pacote está na whitelist (igualdade exata)
  static bool isPackageWhitelisted(String packageName) {
    return WHITELIST_PACKAGES.contains(packageName);
  }

  /// Verifica se a notificação contém palavras-chave de pagamento
  static bool containsPaymentKeywords(String title, String text) {
    final combined = '$title $text'.toLowerCase();
    return PAYMENT_KEYWORDS.any((keyword) => combined.contains(keyword));
  }

  /// Extrai o valor monetário do texto
  /// Converte de formato brasileiro (1.234,56) para double (1234.56)
  static double? extractAmount(String text) {
    try {
      final match = AMOUNT_REGEX.firstMatch(text);
      if (match == null) return null;

      String amountStr = match.group(1) ?? '';
      
      // Remover pontos de separação de milhares
      amountStr = amountStr.replaceAll('.', '');
      
      // Substituir vírgula por ponto para conversão
      amountStr = amountStr.replaceAll(',', '.');
      
      final amount = double.tryParse(amountStr);
      return amount;
    } catch (e) {
      debugPrint('Erro ao extrair valor: $e');
      return null;
    }
  }

  /// Gera hash da notificação para prevenção de duplicidade
  /// Hash = SHA256(packageName + title + text + timestamp)
  static String generateNotificationHash(
    String packageName,
    String title,
    String text,
    DateTime timestamp,
  ) {
    final input = '$packageName|$title|$text|${timestamp.toIso8601String()}';
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// Processa uma notificação e extrai informações de pagamento
  /// Retorna ExtractedPayment se válida, null caso contrário
  static ExtractedPayment? parseNotification({
    required String packageName,
    required String title,
    required String text,
    required DateTime timestamp,
  }) {
    // Validar pacote
    if (!isPackageWhitelisted(packageName)) {
      debugPrint('❌ Pacote não permitido: $packageName');
      return null;
    }

    // Validar palavras-chave
    if (!containsPaymentKeywords(title, text)) {
      debugPrint('❌ Notificação não contém palavras-chave de pagamento');
      return null;
    }

    // Extrair valor
    final amount = extractAmount(text);
    if (amount == null || amount <= 0) {
      debugPrint('❌ Não foi possível extrair valor válido');
      return null;
    }

    // Gerar hash
    final hash = generateNotificationHash(packageName, title, text, timestamp);

    debugPrint('✅ Notificação válida:');
    debugPrint('   - Pacote: $packageName');
    debugPrint('   - Valor: R\$ $amount');
    debugPrint('   - Hash: $hash');

    return ExtractedPayment(
      amount: amount,
      packageName: packageName,
      title: title,
      text: text,
      timestamp: timestamp,
      notificationHash: hash,
    );
  }
}
