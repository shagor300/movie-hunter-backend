import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageSettingsService extends GetxService {
  late SharedPreferences _prefs;

  final RxBool isSmartDownloadsEnabled = true.obs;
  final RxBool deleteCompleted = false.obs;
  final RxBool downloadNextEpisode = true.obs;
  final RxBool customSchedule = false.obs;
  final RxString scheduleFrom = '01:00'.obs;
  final RxString scheduleTo = '07:00'.obs;
  final RxDouble downloadSpeedLimit = 0.0.obs; // 0 = unlimited, in MB/s
  final RxDouble storageLimit = 10.0.obs; // GB

  Future<StorageSettingsService> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromPrefs();
    return this;
  }

  void _loadFromPrefs() {
    isSmartDownloadsEnabled.value =
        _prefs.getBool('isSmartDownloadsEnabled') ?? true;
    deleteCompleted.value = _prefs.getBool('deleteCompleted') ?? false;
    downloadNextEpisode.value = _prefs.getBool('downloadNextEpisode') ?? true;
    customSchedule.value = _prefs.getBool('customSchedule') ?? false;
    scheduleFrom.value = _prefs.getString('scheduleFrom') ?? '01:00 AM';
    scheduleTo.value = _prefs.getString('scheduleTo') ?? '07:00 AM';
    downloadSpeedLimit.value = _prefs.getDouble('downloadSpeedLimit') ?? 0.0;
    storageLimit.value = _prefs.getDouble('storageLimit') ?? 10.0;
  }

  Future<void> saveSettings() async {
    await _prefs.setBool(
      'isSmartDownloadsEnabled',
      isSmartDownloadsEnabled.value,
    );
    await _prefs.setBool('deleteCompleted', deleteCompleted.value);
    await _prefs.setBool('downloadNextEpisode', downloadNextEpisode.value);
    await _prefs.setBool('customSchedule', customSchedule.value);
    await _prefs.setString('scheduleFrom', scheduleFrom.value);
    await _prefs.setString('scheduleTo', scheduleTo.value);
    await _prefs.setDouble('downloadSpeedLimit', downloadSpeedLimit.value);
    await _prefs.setDouble('storageLimit', storageLimit.value);
  }
}
