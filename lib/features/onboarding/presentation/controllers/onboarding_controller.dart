import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../routes/app_routes.dart';

class OnboardingController extends GetxController {
  final LocalStorageService _storage = Get.find<LocalStorageService>();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController phoneController;

  final RxString selectedCurrency = 'SAR'.obs;
  int selectedAvatarIndex = 0;

  final List<IconData> avatarOptions = const [
    Icons.account_circle,
    Icons.business_center,
    Icons.apartment,
    Icons.verified_user,
  ];

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController(text: _storage.ownerName);
    phoneController = TextEditingController(text: _storage.ownerPhone);
    selectedCurrency.value = _storage.defaultCurrency;
  }

  void selectAvatar(int index) {
    selectedAvatarIndex = index;
    update(['avatar_picker']);
  }

  Future<void> completeOwnerSetup() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    await _storage.setOwnerName(nameController.text.trim());
    await _storage.setOwnerPhone(phoneController.text.trim());
    await _storage.setDefaultCurrency(selectedCurrency.value);
    await _storage.setOwnerAvatar('avatar_$selectedAvatarIndex');
    await _storage.setOwnerSetupDone(true);

    Get.offAllNamed(AppRoutes.dashboard);
  }

  List<String> get currencies => AppConstants.supportedCurrencies;

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
