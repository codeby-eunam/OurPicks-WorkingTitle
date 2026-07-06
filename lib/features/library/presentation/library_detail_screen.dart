import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/place.dart';
import '../../../shared/models/restaurant.dart';
import '../../../shared/services/restaurant_api.dart';
import '../../../shared/widgets/floating_contact_button.dart';
import '../../auth/application/user_notifier.dart';
import '../../discovery/application/decision_session.dart';
import '../application/library_notifier.dart';

String _normalizeUid(String? uid) => (uid ?? '').replaceFirst('kakao:', '');

Restaurant _placeToRestaurant(Place p) {
  return Restaurant(id: p.id, placeName: p.name, categoryName: p.categoryName, addressName: p.address, roadAddressName: '', x: '0', y: '0', placeUrl: p.placeUrl);
}

/// Port of app/library-detail.tsx. Simplified vs. RN: this always resolves
/// the list from libraryProvider by [listId] (Flutter state is shared app-wide,
/// so there's no need for RN's dual JSON-params/context fallback).
class LibraryDetailScreen extends ConsumerWidget {
  const LibraryDetailScreen({super.key, required this.listId});

  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(libraryProvider).lists;
    final list = lists.where((l) => l.id == listId).firstOrNull;
    final user = ref.watch(userProvider).user;

    if (list == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('보관함을 찾을 수 없어요.')));
    }

    final isOwner = user != null && _normalizeUid(list.ownerUid) == _normalizeUid(user.kakaoId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.chevron_left, size: 32)),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => _handleShare(list),
                        icon: const Icon(Icons.ios_share, size: 14),
                        label: const Text('공유하기', style: TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          DecisionSessionService.instance.begin();
                          context.push('/swipe', extra: {'restaurants': list.places.map(_placeToRestaurant).toList(), 'locationName': list.title});
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                        icon: const Icon(Icons.swipe, size: 14, color: Colors.white),
                        label: const Text('Swipe', style: TextStyle(fontSize: 13, color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          DecisionSessionService.instance.begin();
                          context.push('/tournament', extra: {'restaurants': list.places.map(_placeToRestaurant).toList()});
                        },
                        icon: const Text('🏆', style: TextStyle(fontSize: 13)),
                        label: const Text('Tournament', style: TextStyle(fontSize: 13, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.all(Radius.circular(2)))),
                                  const SizedBox(width: 6),
                                  Text(
                                    isOwner ? '나의 찜 리스트' : '${list.ownerUserId ?? '누군가'}의 찜 리스트',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(child: Text(list.title, maxLines: 2, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
                                  if (isOwner)
                                    IconButton(
                                      onPressed: () => _showOptions(context, ref, list),
                                      icon: const Icon(Icons.more_horiz),
                                      style: IconButton.styleFrom(backgroundColor: AppColors.surfaceMuted),
                                    ),
                                ],
                              ),
                              Text('${isOwner ? '내가 찜한' : '찜한'} 최고의 맛집 리스트 (${list.places.length}곳)', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.62,
                            children: [
                              for (final place in list.places) _PlaceCard(place: place, isOwner: isOwner, listId: list.id),
                              if (isOwner)
                                _AddPlaceCard(onTap: () => _openSearch(context, ref, list)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const FloatingContactButton(bottomOffset: 64),
            Align(alignment: Alignment.bottomCenter, child: _BottomTabBar()),
          ],
        ),
      ),
    );
  }

  Future<void> _handleShare(ListItem list) async {
    final token = list.shareToken;
    if (token == null) return;
    final url = 'https://dangmatch-y7al.vercel.app/share/$token';
    await SharePlus.instance.share(ShareParams(text: 'Dangmatch에서 "${list.title}" 리스트를 확인해보세요!\n$url'));
  }

  void _showOptions(BuildContext context, WidgetRef ref, ListItem list) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('이름 수정'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, ref, list);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.swap_vert),
              title: const Text('순서 바꾸기'),
              onTap: () {
                Navigator.pop(context);
                _openReorder(context, ref, list);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('보관함 삭제', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('보관함 삭제'),
                    content: Text('"${list.title}"을(를) 삭제할까요?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                      TextButton(
                        onPressed: () {
                          ref.read(libraryProvider.notifier).deleteList(list.id);
                          Navigator.pop(context);
                          context.pop();
                        },
                        child: const Text('삭제', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, ListItem list) {
    final controller = TextEditingController(text: list.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이름 수정'),
        content: TextField(controller: controller, maxLength: 30, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) ref.read(libraryProvider.notifier).renameList(list.id, title);
              Navigator.pop(context);
            },
            child: const Text('완료'),
          ),
        ],
      ),
    );
  }

  void _openReorder(BuildContext context, WidgetRef ref, ListItem list) {
    var items = [...list.places];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) => SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('순서 바꾸기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(libraryProvider.notifier).reorderPlaces(list.id, items);
                          Navigator.pop(context);
                        },
                        child: const Text('완료'),
                      ),
                    ],
                  ),
                ),
                const Text('드래그 핸들을 꾹 누른 채로 이동하세요', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Expanded(
                  child: ReorderableListView.builder(
                    scrollController: scrollController,
                    itemCount: items.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = items.removeAt(oldIndex);
                        items.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final place = items[index];
                      return ListTile(
                        key: ValueKey(place.id),
                        leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: place.image, width: 44, height: 44, fit: BoxFit.cover)),
                        title: Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(place.categoryName),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSearch(BuildContext context, WidgetRef ref, ListItem list) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LibrarySearchSheet(list: list),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place, required this.isOwner, required this.listId});

  final Place place;
  final bool isOwner;
  final String listId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: () => context.push('/restaurant-detail', extra: {'placeId': place.id, 'placeUrl': place.placeUrl}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(aspectRatio: 1.4, child: CachedNetworkImage(imageUrl: place.image, fit: BoxFit.cover, width: double.infinity)),
                if (isOwner)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _confirmRemove(context),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 13, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(place.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10)),
                child: Text(place.categoryName, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) => AlertDialog(
          title: const Text('가게 삭제'),
          content: Text('"${place.name}"을(를) 이 보관함에서 삭제할까요?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            TextButton(
              onPressed: () {
                ref.read(libraryProvider.notifier).removePlaceFromList(listId, place.id);
                Navigator.pop(context);
              },
              child: const Text('삭제', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPlaceCard extends StatelessWidget {
  const _AddPlaceCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5)),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 46, height: 46, decoration: const BoxDecoration(color: Color(0xFFE5E7EB), shape: BoxShape.circle), child: const Icon(Icons.add, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            const Text('새로운 맛집 추가', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _LibrarySearchSheet extends ConsumerStatefulWidget {
  const _LibrarySearchSheet({required this.list});
  final ListItem list;

  @override
  ConsumerState<_LibrarySearchSheet> createState() => _LibrarySearchSheetState();
}

class _LibrarySearchSheetState extends ConsumerState<_LibrarySearchSheet> {
  final _controller = TextEditingController();
  List<Place> _results = [];
  bool _searching = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final restaurants = await RestaurantApi().searchLocation(query);
      if (mounted) setState(() => _results = restaurants.map(placeFromRestaurant).toList());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingIds = widget.list.places.map((p) => p.id).toSet();
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: _search,
                      decoration: const InputDecoration(hintText: '가게 이름으로 검색...', prefixIcon: Icon(Icons.search)),
                    ),
                  ),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                ],
              ),
            ),
            Expanded(
              child: _searching
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ListView(
                      controller: scrollController,
                      children: [
                        for (final place in _results.where((p) => !existingIds.contains(p.id)))
                          ListTile(
                            leading: const Icon(Icons.restaurant, color: AppColors.primary),
                            title: Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${place.categoryName} · ${place.address}', maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: FilledButton(
                              onPressed: () => ref.read(libraryProvider.notifier).addPlacesToList(widget.list.id, [place]),
                              child: const Text('추가'),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _tabItem(context, Icons.home_outlined, '홈', '/'),
            _tabItem(context, Icons.search, '탐색', '/search'),
            _tabItem(context, Icons.bookmark, '보관함', '/library', active: true),
            _tabItem(context, Icons.person_outline, '마이', '/profile'),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(BuildContext context, IconData icon, String label, String path, {bool active = false}) {
    return Expanded(
      child: InkWell(
        onTap: () => context.go(path),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: active ? AppColors.primary : const Color(0xFF9CA3AF)),
            Text(label, style: TextStyle(fontSize: 11, color: active ? AppColors.primary : const Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
