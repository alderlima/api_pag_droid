import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _notificationJson = 'Nenhuma notificação recebida ainda.';
  static const EventChannel _eventChannel = EventChannel('com.macronotify.macro_notify/notifications_stream');

  @override
  void initState() {
    super.initState();
    _eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
  }

  void _onEvent(event) {
    setState(() {
      // Formatar o JSON para melhor legibilidade
      try {
        final dynamic jsonDecoded = json.decode(event);
        _notificationJson = const JsonEncoder.withIndent('  ').convert(jsonDecoded);
      } catch (e) {
        _notificationJson = 'Erro ao formatar JSON: $e\nDados brutos: $event';
      }
    });
  }

  void _onError(Object error) {
    setState(() {
      _notificationJson = 'Erro no stream de notificações: $error';
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _notificationJson));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('JSON copiado para a área de transferência!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug de Notificação Bruta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _copyToClipboard,
              child: const Text('Copiar JSON'),
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _notificationJson,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
