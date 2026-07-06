import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Port of app/receipt.tsx — placeholder, feature not built yet in RN either.
class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, this.restaurantName});

  final String? restaurantName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('영수증')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧾', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            Text(restaurantName ?? '영수증', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('영수증 출력 기능은 준비 중이에요', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
