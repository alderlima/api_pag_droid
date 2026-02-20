import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notification_model.dart';
import '../models/app_model.dart';

class NotificationService extends ChangeNotifier {
  static const platform = MethodChannel('com.macronotify.macro_notify/notifications');
  static const eventChannel = EventChannel('com.macronotify.macro_notify/notifications_stream');

  final _notificationStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get notificationStream => _notificationStreamController.stream;

  List<NotificationModel> _notifications = [];
  List<AppModel> _enabledApps = [];
  bool _isNotificationListenerEnabled = false;
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  List<AppModel> get enabledApps => _enabledApps;
  bool get isNotificationListenerEnabled => _isNotificationListenerEnabled;
  bool get isLoading => _isLoading;

  NotificationService() {
    _initializeService();
    _listenToNotificationStream();
  }

  void _listenToNotificationStream() {
    eventChannel.receiveBroadcastStream().listen((dynamic event) {
      if (event is Map) {
        final data = Map<String, dynamic>.from(event);
        debugPrint('📩 Notificação recebida via EventChannel: $data');
        _notificationStreamController.add(data);
      }
    }, onError: (error) {
      debugPrint('❌ Erro no EventChannel: $error');
    });
  }

  Future<void> _initializeService() async {
    await checkNotificationListenerStatus();
    await loadNotifications();
    await loadEnabledApps();
  }

  Future<void> checkNotificationListenerStatus() async {
    try {
      final bool isEnabled = await platform.invokeMethod('isNotificationListenerEnabled');
      _isNotificationListenerEnabled = isEnabled;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao verificar status do listener: $e');
    }
  }

  Future<void> openNotificationListenerSettings() async {
    try {
      await platform.invokeMethod('openNotificationListenerSettings');
    } catch (e) {
      debugPrint('Erro ao abrir configurações: $e');
    }
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final List<dynamic> result = await platform.invokeMethod('getNotifications', {'limit': 500});
      _notifications = result.map((item) {
        return NotificationModel.fromMap(Map<String, dynamic>.from(item as Map));
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar notificações: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
      await platform.invokeMethod('deleteNotification', {'id': id});
      _notifications.removeWhere((n) => n.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erro ao deletar notificação: $e');
      rethrow;
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      await platform.invokeMethod('clearAllNotifications');
      _notifications.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao limpar notificações: $e');
      rethrow;
    }
  }

  Future<void> loadEnabledApps() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getEnabledApps');
      _enabledApps = result.map((item) {
        return AppModel.fromMap(Map<String, dynamic>.from(item as Map));
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar apps habilitados: $e');
    }
  }

  Future<void> enableApp(String packageName, String appName) async {
    try {
      await platform.invokeMethod('enableApp', {
        'packageName': packageName,
        'appName': appName,
      });
      await loadEnabledApps();
    } catch (e) {
      debugPrint('Erro ao habilitar app: $e');
    }
  }

  Future<void> disableApp(String packageName) async {
    try {
      await platform.invokeMethod('disableApp', {'packageName': packageName});
      await loadEnabledApps();
    } catch (e) {
      debugPrint('Erro ao desabilitar app: $e');
    }
  }

  /// Simula uma notificação para testes
  Future<void> simulateNotification(Map<String, dynamic> data) async {
    // Cria um modelo de notificação
    final notification = NotificationModel.fromMap({
      ...data,
      'id': data['id'] ?? DateTime.now().millisecondsSinceEpoch * -1, // ID negativo para simulado
      'isActive': 1,
    });

    // Adiciona à lista local
    _notifications.insert(0, notification);
    notifyListeners();

    // Emite no stream para o processador capturar
    _notificationStreamController.add(data);
  }

  @override
  void dispose() {
    _notificationStreamController.close();
    super.dispose();
  }
}