import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../models/app_model.dart';

class NotificationService extends ChangeNotifier {
  static const platform = MethodChannel('com.macronotify.macro_notify/notifications');

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
      print('Erro ao verificar status do listener: $e');
    }
  }

  Future<void> openNotificationListenerSettings() async {
    try {
      await platform.invokeMethod('openNotificationListenerSettings');
    } catch (e) {
      print('Erro ao abrir configurações: $e');
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
      print('Erro ao carregar notificações: $e');
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
      print('Erro ao deletar notificação: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      await platform.invokeMethod('clearAllNotifications');
      _notifications.clear();
      notifyListeners();
    } catch (e) {
      print('Erro ao limpar notificações: $e');
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
      print('Erro ao carregar apps habilitados: $e');
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
      print('Erro ao habilitar app: $e');
    }
  }

  Future<void> disableApp(String packageName) async {
    try {
      await platform.invokeMethod('disableApp', {'packageName': packageName});
      await loadEnabledApps();
    } catch (e) {
      print('Erro ao desabilitar app: $e');
    }
  }

  Future<Map<String, bool>> checkPermissions() async {
    try {
      final Map<dynamic, dynamic> result = await platform.invokeMethod('checkPermissions');
      return {
        'notificationListener': result['notificationListener'] as bool? ?? false,
        'postNotifications': result['postNotifications'] as bool? ?? false,
      };
    } catch (e) {
      print('Erro ao verificar permissões: $e');
      return {'notificationListener': false, 'postNotifications': false};
    }
  }

  Future<void> requestPermissions() async {
    try {
      await platform.invokeMethod('requestPermissions');
    } catch (e) {
      print('Erro ao solicitar permissões: $e');
    }
  }

  void refreshNotifications() {
    loadNotifications();
  }
}
