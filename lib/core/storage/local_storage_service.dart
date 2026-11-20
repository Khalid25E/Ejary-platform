import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../constants/app_constants.dart';

class LocalStorageService extends GetxService {
  late final GetStorage _box;

  final RxString rxCurrency = 'SAR'.obs;
  final RxString rxOwnerName = 'أحمد محمد المنصور'.obs;
  final RxString rxOwnerPhone = '+966 50 123 4567'.obs;

  Future<LocalStorageService> init() async {
    await GetStorage.init();
    _box = GetStorage();
    rxCurrency.value = defaultCurrency;
    rxOwnerName.value = ownerName;
    rxOwnerPhone.value = ownerPhone;
    return this;
  }

  bool get isOwnerSetupDone =>
      _box.read<bool>(AppConstants.keyOwnerSetupDone) ?? false;

  Future<void> setOwnerSetupDone(bool value) async {
    await _box.write(AppConstants.keyOwnerSetupDone, value);
  }

  String get ownerName =>
      _box.read<String>(AppConstants.keyOwnerName) ?? 'أحمد محمد المنصور';

  Future<void> setOwnerName(String value) async {
    await _box.write(AppConstants.keyOwnerName, value);
    rxOwnerName.value = value;
  }

  String get ownerPhone =>
      _box.read<String>(AppConstants.keyOwnerPhone) ?? '+966 50 123 4567';

  Future<void> setOwnerPhone(String value) async {
    await _box.write(AppConstants.keyOwnerPhone, value);
    rxOwnerPhone.value = value;
  }

  String? get ownerAvatar => _box.read<String>(AppConstants.keyOwnerAvatar);

  Future<void> setOwnerAvatar(String? value) async {
    await _box.write(AppConstants.keyOwnerAvatar, value);
  }

  String get defaultCurrency =>
      _box.read<String>(AppConstants.keyCurrency) ?? 'SAR';

  Future<void> setDefaultCurrency(String value) async {
    await _box.write(AppConstants.keyCurrency, value);
    rxCurrency.value = value;
  }

  String get themeMode =>
      _box.read<String>(AppConstants.keyThemeMode) ?? 'light';

  Future<void> setThemeMode(String value) async {
    await _box.write(AppConstants.keyThemeMode, value);
  }

  String get localeCode => _box.read<String>(AppConstants.keyLocale) ?? 'ar';

  Future<void> setLocaleCode(String value) async {
    await _box.write(AppConstants.keyLocale, value);
  }

  bool get notificationsEnabled =>
      _box.read<bool>(AppConstants.keyNotificationsEnabled) ?? true;

  Future<void> setNotificationsEnabled(bool value) async {
    await _box.write(AppConstants.keyNotificationsEnabled, value);
  }
}
