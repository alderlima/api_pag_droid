import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/notification_parser.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedPackage = NotificationParser.WHITELIST_PACKAGES.first;
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  bool _isSending = false;

  final List<String> _packages = NotificationParser.WHITELIST_PACKAGES;

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _simulateNotification() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSending = true);
      final service = context.read<NotificationService>();
      service.simulateNotification(
        packageName: _selectedPackage,
        title: _titleController.text,
        text: _textController.text,
      );
      // Feedback visual
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificação simulada enviada!')),
      );
      // Limpar campos (opcional)
      _titleController.clear();
      _textController.clear();
      setState(() => _isSending = false);
    }
  }

  void _fillExample() {
    setState(() {
      _selectedPackage = 'com.nu.production';
      _titleController.text = 'Transferência recebida';
      _textController.text = 'Recebemos sua transferência de R$ 150,00.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simular Notificação'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Preencha os dados da notificação que deseja simular.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              // Pacote
              DropdownButtonFormField<String>(
                value: _selectedPackage,
                decoration: const InputDecoration(
                  labelText: 'Pacote do app',
                  border: OutlineInputBorder(),
                ),
                items: _packages.map((pkg) {
                  return DropdownMenuItem(
                    value: pkg,
                    child: Text(pkg),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPackage = value!);
                },
                validator: (value) => value == null ? 'Selecione um pacote' : null,
              ),
              const SizedBox(height: 16),
              // Título
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título da notificação',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Campo obrigatório'
                    : null,
              ),
              const SizedBox(height: 16),
              // Texto
              TextFormField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Texto da notificação',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty
                    ? 'Campo obrigatório'
                    : null,
              ),
              const SizedBox(height: 24),
              // Botões
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _simulateNotification,
                      icon: const Icon(Icons.send),
                      label: Text(_isSending ? 'Enviando...' : 'Simular'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _fillExample,
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('Exemplo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Aviso sobre apps habilitados
              Consumer<NotificationService>(
                builder: (context, service, _) {
                  final isEnabled = service.enabledApps
                      .any((app) => app.packageName == _selectedPackage);
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isEnabled ? Colors.green : Colors.orange,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isEnabled ? Icons.check_circle : Icons.warning,
                          color: isEnabled ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isEnabled
                                ? 'Este app está habilitado para monitoramento.'
                                : 'Atenção: Este app NÃO está habilitado. A notificação será ignorada.',
                            style: TextStyle(
                              color: isEnabled ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}