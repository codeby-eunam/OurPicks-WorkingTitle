import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/place.dart';
import '../../../shared/services/restaurant_api.dart';
import '../../../shared/widgets/floating_contact_button.dart';
import '../../../shared/widgets/social_login_required_view.dart';
import '../../auth/application/user_notifier.dart';
import '../application/library_notifier.dart';

/// Port of app/(tabs)/library.tsx: 내 보관함 CRUD.
class LibraryTabScreen extends ConsumerWidget {
  const LibraryTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(userProvider).isLoggedIn;

    if (!isLoggedIn) {
      return const Scaffold(
        body: SafeArea(
          child: SocialLoginRequiredView(
            emoji: '📂',
            title: '로그인이 필요해요',
            description: '보관함을 이용하려면\n소셜 로그인이 필요합니다',
          ),
        ),
      );
    }

    final libraryState = ref.watch(libraryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {},
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('내 보관함', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
                          const SizedBox(height: 4),
                          const Text('당신만을 위한 맛있는 기록들', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  if (libraryState.loading)
                    const SliverToBoxAdapter(
                      child: Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
                    )
                  else if (libraryState.lists.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            Text('📂', style: TextStyle(fontSize: 52)),
                            SizedBox(height: 8),
                            Text('아직 리스트가 없어요', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
                            SizedBox(height: 4),
                            Text('아래 버튼을 눌러\n첫 번째 리스트를 만들어보세요!', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.55,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == libraryState.lists.length) {
                            return _NewListCard(onTap: () => _openCreateModal(context, ref));
                          }
                          return _LibraryCard(item: libraryState.lists[index]);
                        },
                        childCount: libraryState.lists.length + 1,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
            const FloatingContactButton(),
          ],
        ),
      ),
    );
  }

  void _openCreateModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const _CreateListSheet(),
    );
  }
}

class _LibraryCard extends ConsumerWidget {
  const _LibraryCard({required this.item});

  final ListItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push('/library-detail', extra: {'listId': item.id}),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: GridView.count(
                    crossAxisCount: 2,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    mainAxisSpacing: 0,
                    crossAxisSpacing: 0,
                    children: [for (final uri in item.images) CachedNetworkImage(imageUrl: uri, fit: BoxFit.cover)],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(item.icon == 'local-cafe' ? Icons.local_cafe : Icons.restaurant, size: 13, color: const Color(0xFF9CA3AF)),
                          const SizedBox(width: 4),
                          Text('가게 ${item.count}개', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => ref.read(libraryProvider.notifier).togglePublic(item.id),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 18,
                        padding: const EdgeInsets.all(2),
                        alignment: item.isPublic ? Alignment.centerRight : Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: item.isPublic ? AppColors.secondary : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item.isPublic ? '공개' : '비공개',
                        style: TextStyle(fontSize: 11, fontWeight: item.isPublic ? FontWeight.w700 : FontWeight.w500, color: item.isPublic ? AppColors.secondary : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showOptions(context, ref, item),
                  child: const Padding(padding: EdgeInsets.all(2), child: Icon(Icons.more_horiz, size: 18, color: Color(0xFF9CA3AF))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref, ListItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF374151)),
              title: const Text('이름 수정'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, ref, item);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('보관함 삭제', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, ref, item);
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ListItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('보관함 삭제'),
        content: Text('"${item.title}"을(를) 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              ref.read(libraryProvider.notifier).deleteList(item.id);
              Navigator.pop(context);
            },
            child: const Text('삭제', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, ListItem item) {
    final controller = TextEditingController(text: item.title);
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
              if (title.isNotEmpty) ref.read(libraryProvider.notifier).renameList(item.id, title);
              Navigator.pop(context);
            },
            child: const Text('완료'),
          ),
        ],
      ),
    );
  }
}

class _NewListCard extends StatelessWidget {
  const _NewListCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5, style: BorderStyle.solid),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Center(child: Text('+', style: TextStyle(fontSize: 26, color: Colors.white))),
            ),
            const SizedBox(height: 10),
            const Text('새 리스트 만들기', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _CreateListSheet extends ConsumerStatefulWidget {
  const _CreateListSheet();

  @override
  ConsumerState<_CreateListSheet> createState() => _CreateListSheetState();
}

class _CreateListSheetState extends ConsumerState<_CreateListSheet> {
  int _step = 1;
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final List<Place> _selected = [];
  List<Place> _results = [];
  bool _searching = false;
  bool _creating = false;

  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final restaurants = await RestaurantApi().searchLocation(query);
      if (mounted) setState(() => _results = restaurants.map(placeFromRestaurant).toList());
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _togglePlace(Place place) {
    setState(() {
      final existing = _selected.indexWhere((p) => p.id == place.id);
      if (existing >= 0) {
        _selected.removeAt(existing);
      } else {
        _selected.add(place);
      }
    });
  }

  Future<void> _createList() async {
    if (_selected.isEmpty || _creating) return;
    setState(() => _creating = true);
    try {
      await ref.read(libraryProvider.notifier).addList(_nameController.text.trim(), _selected);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('리스트 생성에 실패했습니다. 다시 시도해주세요.')));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _step == 1 ? () => Navigator.pop(context) : () => setState(() => _step = 1),
                      icon: Icon(_step == 1 ? Icons.close : Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(_step == 1 ? '새 리스트 만들기' : '가게 추가', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Expanded(
                child: _step == 1 ? _buildStep1() : _buildStep2(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('리스트 이름을 지어주세요', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('#시험기간 #데이트 처럼 기억하기 쉬운 이름이 좋아요', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            maxLength: 30,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: '예: 시험 기간 카공 맛집'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nameController.text.trim().isEmpty ? null : () => setState(() => _step = 2),
              child: const Text('다음'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStep2(ScrollController scrollController) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _handleSearch,
                decoration: const InputDecoration(hintText: '가게 이름을 검색해보세요', prefixIcon: Icon(Icons.search)),
              ),
              if (_selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: const Color(0xFFFFF0EB), borderRadius: BorderRadius.circular(10)),
                      child: Text('${_selected.length}개 선택됨', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _searching
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (_results.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            _searchController.text.trim().isNotEmpty ? '검색 결과가 없어요' : '가게 이름을 검색해보세요',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      for (final place in _results.where((p) => !_selected.any((s) => s.id == p.id)))
                        ListTile(
                          leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: place.image, width: 48, height: 48, fit: BoxFit.cover)),
                          title: Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${place.categoryName}\n${place.address}', maxLines: 2),
                          isThreeLine: true,
                          onTap: () => _togglePlace(place),
                        ),
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selected.isEmpty || _creating) ? null : _createList,
              child: _creating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_selected.isNotEmpty ? '리스트 만들기 (${_selected.length}개)' : '가게를 선택해주세요'),
            ),
          ),
        ),
      ],
    );
  }
}
