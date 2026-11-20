import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Phase1NoticeBanner extends StatelessWidget {
  const Phase1NoticeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF422006) : const Color(0xFFFEF3C7),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF854D0E) : const Color(0xFFF59E0B),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.architecture_outlined,
            size: 18,
            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${'phase1_banner_title'.tr}: ${'phase1_banner_desc'.tr}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
