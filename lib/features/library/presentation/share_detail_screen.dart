import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/place.dart';
import '../../../shared/models/restaurant.dart';
import '../../auth/application/user_notifier.dart';
import '../data/library_api.dart';

Restaurant _placeToRestaurant(Place p) {
  return Restaurant(
    id: p.id,
    placeName: p.name,
    categoryName: p.categoryName,
    addressName: p.address,
    roadAddressName: '',
    x: '0',
    y: '0',
    placeUrl: p.placeUrl,
    // p.image is either a real photo URL (already absolute) or the
    // picsum.photos placeholder used when no real photo was ever fetched.
    photoUrl: p.image.contains('picsum.photos') ? '' : p.image,
  );
}

/// Port of app/share/[shareToken].tsx: read-only public list view.
class ShareDetailScreen extends ConsumerStatefulWidget {
  const ShareDetailScreen({super.key, required this.shareToken});

  final String shareToken;

  @override
  ConsumerState<ShareDetailScreen> createState() => _ShareDetailScreenState();
}

class _ShareDetailScreenState extends ConsumerState<ShareDetailScreen> {
  ListItem? _list;
  bool _loading = true;
  bool _error = false;
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await LibraryApi().fetchShared(widget.shareToken);
      if (!mounted) return;
      if (list == null) {
        setState(() => _error = true);
        return;
      }
      final user = ref.read(userProvider).user;
      if (user != null && list.ownerUid == user.kakaoId) {
        // Owner viewing their own public list: go straight to the editable
        // library detail page instead of this read-only share view.
        _redirected = true;
        context.pushReplacement('/library-detail', extra: {'listId': list.id});
        return;
      }
      setState(() => _list = list);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _redirected) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    final t = AppLocalizations.of(context)!;
    if (_error || _list == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔒', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  t.shareNotViewableTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.shareNotViewableMessage,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final list = _list!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.chevron_left, size: 32),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => _handleShare(list, t),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    icon: const Icon(Icons.ios_share, size: 14),
                    label: Text(
                      t.libraryShareButton,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    onPressed: () => context.push(
                      '/swipe',
                      extra: {
                        'restaurants': list.places
                            .map(_placeToRestaurant)
                            .toList(),
                        'locationName': list.title,
                      },
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    icon: const Icon(
                      Icons.swipe,
                      size: 14,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Swipe',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    onPressed: () => context.push(
                      '/tournament',
                      extra: {
                        'restaurants': list.places
                            .map(_placeToRestaurant)
                            .toList(),
                      },
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    icon: const Text('🏆', style: TextStyle(fontSize: 13)),
                    label: const Text(
                      'Tournament',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 40),
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
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                t.libraryOwnerWishlist(
                                  list.ownerUserId ??
                                      t.libraryOwnerFallbackName,
                                ),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            list.title,
                            maxLines: 2,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            t.libraryDescriptionGeneric(list.places.length),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
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
                          for (final place in list.places)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 0.5,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: GestureDetector(
                                onTap: () => context.push(
                                  '/restaurant-detail',
                                  extra: {
                                    'placeId': place.id,
                                    'placeUrl': place.placeUrl,
                                  },
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AspectRatio(
                                      aspectRatio: 1.4,
                                      child: CachedNetworkImage(
                                        imageUrl: place.image,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        10,
                                        12,
                                        6,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            place.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            place.address,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleShare(ListItem list, AppLocalizations t) async {
    final token = list.shareToken ?? widget.shareToken;
    final url = 'https://dangmatch-y7al.vercel.app/share/$token';
    await SharePlus.instance.share(
      ShareParams(text: t.shareCheckOutMessage(list.title, url)),
    );
  }
}
