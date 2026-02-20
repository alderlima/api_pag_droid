import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final _packageController = TextEditingController();
  final _titleController = TextEditingController();
  final _textController = TextEditingController();

  // Pacotes comuns para preencher automaticamente
  final List<String> _commonPackages = [
    'com.nu.production',           // Nubank
    'com.itau.mobile',             // Itaú
    'com.bradesco.bdrco',          // Bradesco
    'com.banco.bbsa.mobile',       // Banco do Brasil
    'com.banco.santander',         // Santander
    'com.caixa',                   // Caixa
    'com.whatsapp.w4b',            // WhatsApp
  ];

  void _fillExample() {
    setState(() {
      _packageController.text = 'com.nu.production';
      _titleController.text = 'Transferência recebida';
      _textController.text = 'Recebemos sua transferência de R\$ 150,00.'; // ← escape do cifrão
    });
  }

  void _simulateNotification(NotificationService service) {
    final package = _packageController.text.trim();
    final title = _titleController.text.trim();
    final text = _textController.text.trim();

    if (package.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o pacote do app')),
      );
      return;
    }

    // Verifica se o app está habilitado (opcional, apenas informativo)
    final isEnabled = service.enabledApps.any((app) => app.packageName == package);
    if (!isEnabled) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('App não habilitado'),
          content: Text(
              'O pacote "$package" não está habilitado na aba "Aplicativos".\n'
              'A notificação será ignorada pelo processador. Deseja continuar mesmo assim?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _injectNotification(service, package, title, text);
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
    } else {
      _injectNotification(service, package, title, text);
    }
  }

  void _injectNotification(
    NotificationService service,
    String package,
    String title,
    String text,
  ) {
    // Simula o mesmo formato que o EventChannel enviaria
    final fakeData = {
      'packageName': package,
      'title': title,
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Injeta diretamente no stream de notificações
    service.simulateNotification(fakeData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notificação simulada injetada: $package'),
        duration: const Duration(seconds: 2),
      ),
    );

    // Opcional: limpar campos ou não
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<NotificationService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simular Notificação'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Preencha os dados da notificação como se fosse enviada pelo sistema.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),

              // Campo Pacote
              const Text('Pacote do app', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _packageController.text.isNotEmpty
                    ? _packageController.text
                    : null,
                hint: const Text('Selecione ou digite um pacote'),
                items: [
                  ..._commonPackages.map((p) => DropdownMenuItem(value: p, child: Text(p))),
                  const DropdownMenuItem(value: 'outro', child: Text('Outro...')),
                ],
                onChanged: (value) {
                  if (value == 'outro') {
                    // Abre diálogo para entrada manual ou apenas limpa
                    _packageController.clear();
                  } else if (value != null) {
                    _packageController.text = value;
                  }
                },
                validator: (value) => value == null ? 'Selecione um pacote' : null,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _packageController,
                decoration: const InputDecoration(
                  hintText: 'ou digite manualmente',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Campo Título
              const Text('Título', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Ex: Transferência recebida',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Campo Texto
              const Text('Texto', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: _textController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ex: Recebemos sua transferência de R$ 150,00.',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _fillExample,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Preencher Exemplo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _simulateNotification(service),
                      icon: const Icon(Icons.send),
                      label: const Text('Simular'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔔 Como testar:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Certifique-se de que o app de destino está habilitado em "Aplicativos".\n'
                      '2. Preencha os dados (use o botão "Preencher Exemplo").\n'
                      '3. Clique em "Simular".\n'
                      '4. Verifique os logs e a tela de pagamentos.\n'
                      '5. O backend deve receber a confirmação se houver um pagamento pendente com o mesmo valor.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _packageController.dispose();
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }
}