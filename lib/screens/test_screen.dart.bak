import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/payment_service.dart';
import '../services/notification_processor.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedPackage = '';
  String _title = '';
  String _text = '';
  String _action = 'posted';
  bool _isSimulating = false;

  final List<String> _actionOptions = ['posted', 'removed'];

  @override
  Widget build(BuildContext context) {
    final notificationService = context.watch<NotificationService>();
    final enabledPackages = notificationService.enabledApps.map((e) => e.packageName).toList();

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
              // Pacote
              DropdownButtonFormField<String>(
                value: _selectedPackage.isEmpty ? null : _selectedPackage,
                hint: const Text('Selecione o pacote do app'),
                items: [
                  ...enabledPackages.map((pkg) => DropdownMenuItem(
                        value: pkg,
                        child: Text(pkg),
                      )),
                  if (enabledPackages.isEmpty)
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Nenhum app habilitado'),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPackage = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecione um pacote';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Pacote do App',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Ação
              DropdownButtonFormField<String>(
                value: _action,
                items: _actionOptions.map((a) => DropdownMenuItem(
                      value: a,
                      child: Text(a),
                    )).toList(),
                onChanged: (value) {
                  setState(() {
                    _action = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Ação',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Título
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Título da Notificação',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _title = value ?? '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Texto
              TextFormField(
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Texto da Notificação',
                  hintText: 'Ex: Recebemos sua transferência de R$ 0,01.',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _text = value ?? '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Botão simular
              ElevatedButton.icon(
                onPressed: _isSimulating ? null : _simulateNotification,
                icon: const Icon(Icons.play_arrow),
                label: Text(_isSimulating ? 'Simulando...' : 'Simular Notificação'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 24),

              // Ajuda
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instruções',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Certifique-se de que o app de destino está habilitado na aba "Aplicativos".\n'
                        '2. Preencha os campos com os dados da notificação que deseja simular.\n'
                        '3. O valor em R$ será extraído automaticamente do texto pelo parser.\n'
                        '4. Após simular, a notificação aparecerá na aba "Logs" e será processada como se fosse real.',
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

  void _simulateNotification() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isSimulating = true;
      });

      // Criar dados da notificação simulada
      final now = DateTime.now();
      final notificationData = {
        'packageName': _selectedPackage,
        'title': _title,
        'text': _text,
        'timestamp': now.millisecondsSinceEpoch,
        'action': _action,
        // ID simulado (negativo para não conflitar com IDs reais)
        'id': -now.millisecondsSinceEpoch,
      };

      // Enviar para o serviço
      final notificationService = context.read<NotificationService>();
      await notificationService.simulateNotification(notificationData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificação simulada com sucesso!')),
        );
        // Limpar campos? Vamos manter para nova simulação
        _formKey.currentState?.reset();
        setState(() {
          _selectedPackage = '';
          _title = '';
          _text = '';
          _action = 'posted';
          _isSimulating = false;
        });
      }
    }
  }
}