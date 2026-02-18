class NotificationModel {
  final int id;
  final String packageName;
  final String title;
  final String text;
  final String subText;
  final String bigText;
  final int timestamp;
  final String action;
  final bool isActive;

  NotificationModel({
    required this.id,
    required this.packageName,
    required this.title,
    required this.text,
    required this.subText,
    required this.bigText,
    required this.timestamp,
    required this.action,
    required this.isActive,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as int? ?? 0,
      packageName: map['packageName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      text: map['text'] as String? ?? '',
      subText: map['subText'] as String? ?? '',
      bigText: map['bigText'] as String? ?? '',
      timestamp: map['timestamp'] as int? ?? 0,
      action: map['action'] as String? ?? 'posted',
      isActive: (map['isActive'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageName': packageName,
      'title': title,
      'text': text,
      'subText': subText,
      'bigText': bigText,
      'timestamp': timestamp,
      'action': action,
      'isActive': isActive ? 1 : 0,
    };
  }

  String get formattedTime {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String get displayContent {
    if (bigText.isNotEmpty) return bigText;
    if (text.isNotEmpty) return text;
    if (subText.isNotEmpty) return subText;
    return 'Sem conteúdo';
  }
}
