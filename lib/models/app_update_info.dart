/// Model representing remote update configuration JSON.
class AppUpdateInfo {
  final int latestVersionCode;
  final String latestVersionName;
  final String updateUrl;
  final bool isForceUpdate;
  final List<String> whatsNew;

  AppUpdateInfo({
    required this.latestVersionCode,
    required this.latestVersionName,
    required this.updateUrl,
    required this.isForceUpdate,
    required this.whatsNew,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      latestVersionCode: json['latest_version_code'] as int? ?? 0,
      latestVersionName: json['latest_version_name'] as String? ?? '0.0.0',
      updateUrl: json['update_url'] as String? ?? '',
      isForceUpdate: json['is_force_update'] as bool? ?? false,
      whatsNew:
          (json['whats_new'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
