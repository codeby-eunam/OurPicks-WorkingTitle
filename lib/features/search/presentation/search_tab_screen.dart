import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/place.dart';
import '../../../shared/widgets/floating_contact_button.dart';
import '../../library/data/library_api.dart';

/// Port of app/(tabs)/search.tsx: 공개 보관함 탐색.
class SearchTabScreen extends StatefulWidget {
  const SearchTabScreen({super.key});

  @override
  State<SearchTabScreen> createState() => _SearchTabScreenState();
}

class _SearchTabScreenState extends State<SearchTabScreen> {
  List<ListItem> _publicLists = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final lists = await LibraryApi().fetchPublicLists();
      if (mounted) setState(() => _publicLists = lists);
    } catch (_) {
      // RN: console.error only, empty-state UI already covers this case
    }
  }

  List<ListItem> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _publicLists;
    return _publicLists.where((l) => l.title.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('공개 보관함 탐색', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
                      const SizedBox(height: 4),
                      const Text('다른 사람들이 공유한 맛집 리스트', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: '보관함 이름으로 검색...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      children: [
                        if (_publicLists.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 60),
                            child: Column(
                              children: [
                                Text('🔒', style: TextStyle(fontSize: 52)),
                                SizedBox(height: 10),
                                Text('공개된 보관함이 없어요', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
                                SizedBox(height: 6),
                                Text('내 보관함 탭에서 보관함을 공개로 설정하면\n여기에 나타나요', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                          )
                        else if (filtered.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 60),
                            child: Column(
                              children: [
                                Text('🔍', style: TextStyle(fontSize: 52)),
                                SizedBox(height: 10),
                                Text('검색 결과가 없어요', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
                                SizedBox(height: 6),
                                Text('다른 키워드로 검색해보세요', style: TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                          )
                        else ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text('공개 보관함 ${filtered.length}개', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.62,
                              children: [for (final item in filtered) _PublicListCard(item: item)],
                            ),
                          ),
                        ],
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFFE0F4F4), borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.public, color: AppColors.secondary),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('내 보관함도 공유해보세요!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                    SizedBox(height: 4),
                                    Text('내 보관함 탭에서 토글을 켜면\n공개 보관함으로 등록돼요', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const FloatingContactButton(),
          ],
        ),
      ),
    );
  }
}

class _PublicListCard extends StatelessWidget {
  const _PublicListCard({required this.item});

  final ListItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/share/${item.shareToken}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: GridView.count(
                    crossAxisCount: 2,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [for (final uri in item.images) CachedNetworkImage(imageUrl: uri, fit: BoxFit.cover)],
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(10)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.public, size: 10, color: Colors.white),
                        SizedBox(width: 3),
                        Text('공개', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
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
    );
  }
}
