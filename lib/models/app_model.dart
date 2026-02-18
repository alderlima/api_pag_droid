class AppModel {
  final String packageName;
  final String appName;

  AppModel({
    required this.packageName,
    required this.appName,
  });

  factory AppModel.fromMap(Map<String, dynamic> map) {
    return AppModel(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppModel &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;
}
