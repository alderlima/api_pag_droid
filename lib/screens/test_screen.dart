import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/payment_service.dart';
import '../services/notification_processor.dart';
import '../models/notification_model.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _packageController = TextEditingController(text: 'com.nu.production');
  final _titleController = TextEditingController(text: 'Transferência recebida');
  final _textController = TextEditingController(text: 'Recebemos sua transferência de R\$ 0,01.');
  final _amountController = TextEditingController(text: '0.01');
  bool _simulateWithAmount = true;
  String _lastResult = '';

  @override
  void dispose() {
    _packageController.dispose();
    _titleController.dispose();
    _textController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _simulateNotification() async {
    final packageName = _packageController.text.trim();
    final title = _titleController.text.trim();
    String text = _textController.text.trim();

    if (_simulateWithAmount) {
      final amount = _amountController.text.trim().replaceAll(',', '.');
      if (double.tryParse(amount) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Valor inválido'), backgroundColor: Colors.red),
        );
        return;
      }
      // Se o usuário preencheu o valor separadamente, substitui ou insere no texto
      if (!text.contains('R\$')) {
        text = 'Recebemos sua transferência de R\$ $amount.';
      }
    }

    if (packageName.isEmpty || title.isEmpty || text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos'), backgroundColor: Colors.red),
      );
      return;
    }

    final notificationService = context.read<NotificationService>();
    final processor = context.read<NotificationProcessor>();

    // Cria um mapa simulando o evento que viria do EventChannel
    final fakeData = {
      'packageName': packageName,
      'title': title,
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Injeta diretamente no stream do NotificationService
    // Nota: Isso requer que o stream seja público ou um método para teste.
    // Vamos usar o método privado? Melhor criar um método público no NotificationService para testes.
    // Mas como não podemos modificar o NotificationService agora, vamos simular chamando o processor diretamente,
    // pulando a verificação de app habilitado? O processor já verifica enabledApps, então precisamos garantir
    // que o app esteja habilitado na lista.
    // Vamos adicionar temporariamente à lista de enabledApps se necessário.
    // Para simplificar, vamos verificar se o package está habilitado e, se não estiver, habilitá-lo automaticamente para o teste.
    final isEnabled = notificationService.enabledApps.any((a) => a.packageName == packageName);
    if (!isEnabled) {
      await notificationService.enableApp(packageName, 'App de Teste');
    }

    // Processa diretamente a notificação
    final result = await processor.processNotification(
      packageName: packageName,
      title: title,
      text: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _lastResult = '''
✅ Notificação simulada processada.
Status: ${result.success ? 'Sucesso' : 'Falha'}
Mensagem: ${result.message}
Valor extraído: ${result.payment?.amount?.toStringAsFixed(2) ?? 'N/A'}
Hash: ${result.payment?.notificationHash ?? 'N/A'}
''';
    });

    // Recarrega as notificações para aparecer na tela de logs
    notificationService.loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador de Notificações'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Simular notificação bancária',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _packageController,
                        decoration: const InputDecoration(
                          labelText: 'Pacote do app (ex: com.nu.production)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Título da notificação',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _textController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Texto da notificação',
                          hintText: 'Ex: Recebemos sua transferência de R\$ 0,01.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text('Usar campo de valor separado'),
                              value: _simulateWithAmount,
                              onChanged: (val) => setState(() => _simulateWithAmount = val ?? false),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      if (_simulateWithAmount) ...[
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Valor (R\$)',
                            hintText: '0,01',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _simulateNotification,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Simular Notificação'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_lastResult.isNotEmpty)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Resultado do processamento:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_lastResult),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Instruções:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Preencha os dados da notificação que deseja simular.\n'
                        '2. O pacote deve corresponder a um app bancário da whitelist (ex: com.nu.production).\n'
                        '3. O valor em R\$ será extraído automaticamente do texto pelo parser.\n'
                        '4. Clique em "Simular Notificação".\n'
                        '5. O resultado aparecerá acima e a notificação será adicionada aos Logs.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}