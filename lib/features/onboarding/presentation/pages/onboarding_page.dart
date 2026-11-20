import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/localization/locale_service.dart';
import '../../../../core/theme/theme_service.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/phase1_notice_banner.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingPage extends GetView<OnboardingController> {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    final localeService = Get.find<LocaleService>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('app_name'.tr),
        actions: [
          IconButton(
            tooltip: 'language'.tr,
            icon: const Icon(Icons.language),
            onPressed: () => localeService.toggleLocale(),
          ),
          Obx(
            () => IconButton(
              tooltip: 'theme_mode'.tr,
              icon: Icon(
                themeService.isDarkMode.value
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              onPressed: () => themeService.toggleTheme(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Phase1NoticeBanner(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: controller.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: scheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.domain_verification,
                                    size: 32,
                                    color: scheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'onboarding_title'.tr,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'onboarding_subtitle'.tr,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'owner_avatar_optional'.tr,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 10),
                            GetBuilder<OnboardingController>(
                              id: 'avatar_picker',
                              builder: (ctrl) => Wrap(
                                alignment: WrapAlignment.spaceEvenly,
                                spacing: 12,
                                runSpacing: 12,
                                children: List.generate(
                                  ctrl.avatarOptions.length,
                                  (index) {
                                    final isSelected =
                                        ctrl.selectedAvatarIndex == index;
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(40),
                                      onTap: () => ctrl.selectAvatar(index),
                                      child: CircleAvatar(
                                        radius: 28,
                                        backgroundColor: isSelected
                                            ? scheme.primary
                                            : scheme.primary
                                                .withValues(alpha: 0.1),
                                        child: Icon(
                                          ctrl.avatarOptions[index],
                                          size: 28,
                                          color: isSelected
                                              ? Colors.white
                                              : scheme.primary,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: controller.nameController,
                              validator: AppValidators.requiredField,
                              decoration: InputDecoration(
                                labelText: 'owner_full_name'.tr,
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: controller.phoneController,
                              validator: AppValidators.phoneValidator,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'owner_phone'.tr,
                                prefixIcon: const Icon(Icons.phone_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Obx(
                              () => DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: controller.selectedCurrency.value,
                                decoration: InputDecoration(
                                  labelText: 'default_currency'.tr,
                                  prefixIcon:
                                      const Icon(Icons.payments_outlined),
                                ),
                                items: controller.currencies
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          CurrencyUtils.getCurrencyLabel(c),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    controller.selectedCurrency.value = val;
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 28),
                            ElevatedButton.icon(
                              onPressed: controller.completeOwnerSetup,
                              icon: const Icon(Icons.check_circle_outline),
                              label: Text('complete_setup'.tr),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
