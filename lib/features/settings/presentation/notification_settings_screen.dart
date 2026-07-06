import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/floating_contact_button.dart';

class _NotifItem {
  const _NotifItem(this.key, this.title, this.desc);
  final String key;
  final String title;
  final String desc;
}

const _kNotifItems = [
  _NotifItem('recommend', '맛집 추천 알림', '내 주변 새 맛집이 등록되면 알려드려요'),
  _NotifItem('library', '보관함 업데이트', '저장한 맛집에 변동사항이 생기면 알려드려요'),
  _NotifItem('marketing', '마케팅 · 이벤트 알림', '혜택 및 이벤트 정보를 보내드려요'),
];

/// Port of app/notification-settings.tsx. Toggles are local-only for now
/// (RN also has no backend wired up yet — TODO: PATCH /api/user/notifications).
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final Map<String, bool> _settings = {'recommend': true, 'library': true, 'marketing': false};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('알림은 기기 설정에서 허용한 경우에만 수신돼요.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < _kNotifItems.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 18),
                      _buildRow(_kNotifItems[i]),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '알림을 모두 끄려면 기기의 [설정 → 앱 → 당맷치]에서 변경해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
          const FloatingContactButton(),
        ],
      ),
    );
  }

  Widget _buildRow(_NotifItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(item.desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
          Switch(
            value: _settings[item.key] ?? false,
            onChanged: (v) => setState(() => _settings[item.key] = v),
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
