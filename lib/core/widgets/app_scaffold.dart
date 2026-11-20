import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../localization/locale_service.dart';
import '../theme/theme_service.dart';
import 'phase1_notice_banner.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showPhase1Banner;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showPhase1Banner = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    final localeService = Get.find<LocaleService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...(actions ?? []),
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
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if (showPhase1Banner) const Phase1NoticeBanner(),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
