import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/place.dart';
import '../../../shared/models/restaurant.dart';
import '../../../shared/models/restaurant_category.dart';
import '../../../shared/services/analytics_service.dart';
import '../../../shared/services/restaurant_api.dart';
import '../../../shared/services/restaurant_stats_service.dart';
import '../../library/application/library_notifier.dart';
import '../application/decision_resume.dart';
import '../application/decision_session.dart';
import 'widgets/decision_timer_chip.dart';

const _kBgTeal = Color(0xFF1E7874);
const _kOrange = Color(0xFFF57C4A);

Place _toPlace(Restaurant r) {
  final categoryShort = categoryLabelFor(r.categoryName);
  final isCafe = r.categoryName.contains('카페');
  return Place(
    id: r.id,
    name: r.placeName,
    category: isCafe ? '카페' : '식당',
    categoryName: categoryShort,
    address: r.roadAddressName.isNotEmpty ? r.roadAddressName : r.addressName,
    image: r.photoUrl.isNotEmpty
        ? '$kApiBase${r.photoUrl}'
        : 'https://picsum.photos/seed/${r.id}/200/200',
    placeUrl: r.placeUrl,
  );
}

/// Lightweight card: name, address and a simple category icon — no per-card
/// webview/network page load. Reviews and hours are only fetched once the
/// user commits to a specific place (tournament match preview).
class _SwipeCard extends StatefulWidget {
  const _SwipeCard({required this.restaurant});

  final Restaurant restaurant;

  @override
  State<_SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<_SwipeCard> {
  String? _lazyPhotoUrl;
  String? _lazyPhotoForId;

  @override
  void initState() {
    super.initState();
    _maybeFetchKakaoPhoto();
  }

  @override
  void didUpdateWidget(covariant _SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurant.id != widget.restaurant.id) {
      _maybeFetchKakaoPhoto();
    }
  }

  /// Kakao's Local API returns no photo field at all, so for Kakao-sourced
  /// restaurants (no photoUrl from the backend) we look one up lazily -
  /// one small request per card as the user swipes, not upfront for the
  /// whole result list.
  Future<void> _maybeFetchKakaoPhoto() async {
    final r = widget.restaurant;
    if (r.photoUrl.isNotEmpty || !r.placeUrl.contains('kakao.com')) return;
    final id = r.id;
    final url = await RestaurantApi().fetchPlacePhoto(id);
    if (mounted && widget.restaurant.id == id) {
      setState(() {
        _lazyPhotoForId = id;
        _lazyPhotoUrl = url;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    final address = r.roadAddressName.isNotEmpty
        ? r.roadAddressName
        : r.addressName;
    // Fresh API results carry a relative proxy path; library round-trips
    // (Place.image) are already absolute - don't double-prefix those.
    final photoUrl = r.photoUrl.isNotEmpty
        ? (r.photoUrl.startsWith('http')
              ? r.photoUrl
              : '$kApiBase${r.photoUrl}')
        : (_lazyPhotoForId == r.id ? (_lazyPhotoUrl ?? '') : '');

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: _kBgTeal.withValues(alpha: 0.08),
              alignment: Alignment.center,
              child: photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : Text(
                              categoryEmojiFor(r.categoryName),
                              style: const TextStyle(fontSize: 96),
                            ),
                      errorBuilder: (context, error, stackTrace) => Text(
                        categoryEmojiFor(r.categoryName),
                        style: const TextStyle(fontSize: 96),
                      ),
                    )
                  : Text(
                      categoryEmojiFor(r.categoryName),
                      style: const TextStyle(fontSize: 96),
                    ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    categoryLabelFor(r.categoryName),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r.placeName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Port of app/swipe.tsx.
class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({
    super.key,
    required this.restaurants,
    required this.locationName,
    this.initialLiked = const [],
  });

  final List<Restaurant> restaurants;
  final String locationName;

  /// 이전 세션에서 이어하기로 들어온 경우 이미 좋아요한 항목들.
  final List<Restaurant> initialLiked;

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen>
    with TickerProviderStateMixin {
  late final List<Restaurant> _restaurants;
  int _index = 0;
  final List<Restaurant> _liked = [];
  bool _done = false;
  int _choiceCount = 0;
  DateTime _viewStart = DateTime.now();

  double _dragDx = 0;
  bool _isDragging = false;
  Animation<double>? _positionAnimation;

  late final AnimationController _exitController;
  late final AnimationController _fadeInController;

  @override
  void initState() {
    super.initState();
    _restaurants = [...widget.restaurants]..shuffle(Random());
    _liked.addAll(widget.initialLiked);
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1,
    );
    _loadChoiceCount();
    _saveResumeSession();
  }

  void _saveResumeSession() {
    DecisionResumeService.instance.saveSwipeSession(
      remaining: _restaurants.sublist(_index),
      liked: _liked,
      locationName: widget.locationName,
    );
  }

  @override
  void dispose() {
    _exitController.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  Restaurant? get _current =>
      _index < _restaurants.length ? _restaurants[_index] : null;

  Future<void> _loadChoiceCount() async {
    final current = _current;
    if (current == null) return;
    setState(() => _choiceCount = 0);
    final count = await RestaurantStatsService.instance.getChoiceCount(
      current.id,
    );
    if (mounted && _current?.id == current.id)
      setState(() => _choiceCount = count);
  }

  void _advance(bool like) {
    final current = _current;
    if (current == null) return;

    final dwellMs = DateTime.now().difference(_viewStart).inMilliseconds;
    final catShort = categoryLabelFor(current.categoryName);
    AnalyticsService.instance.logCardViewed(
      current.id,
      current.placeName,
      catShort,
      widget.locationName,
      dwellMs,
    );

    if (like) {
      RestaurantStatsService.instance.recordSwipeChoice(current.id);
      _liked.add(current);
    } else {
      RestaurantStatsService.instance.recordSwipePass(current.id);
    }

    if (_index + 1 >= _restaurants.length) {
      DecisionSessionService.instance.recordStage(
        AppLocalizations.of(context)!.funnelStageFirstPick,
        _liked.length,
      );
      DecisionResumeService.instance.clear();
      setState(() => _done = true);
    } else {
      setState(() => _index += 1);
      _viewStart = DateTime.now();
      _loadChoiceCount();
      _saveResumeSession();
    }
  }

  static const _swipeThreshold = 120.0;
  static const _flingVelocityThreshold = 800.0;

  void _handlePanStart(DragStartDetails details) {
    setState(() => _isDragging = true);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() => _dragDx += details.delta.dx);
  }

  void _handlePanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    final passedThreshold =
        _dragDx.abs() > _swipeThreshold ||
        velocity.abs() > _flingVelocityThreshold;
    if (passedThreshold) {
      _flingOff(_dragDx > 0);
    } else {
      _snapBack();
    }
  }

  Future<void> _flingOff(bool like) async {
    final screenWidth = MediaQuery.of(context).size.width;
    setState(() {
      _isDragging = false;
      _positionAnimation =
          Tween<double>(
            begin: _dragDx,
            end: like ? screenWidth * 1.5 : -screenWidth * 1.5,
          ).animate(
            CurvedAnimation(parent: _exitController, curve: Curves.easeOut),
          );
    });
    await _exitController.forward(from: 0);
    _advance(like);
    _exitController.value = 0;
    setState(() {
      _dragDx = 0;
      _positionAnimation = null;
    });
    _fadeInController.forward(from: 0);
  }

  Future<void> _snapBack() async {
    setState(() {
      _isDragging = false;
      _positionAnimation = Tween<double>(begin: _dragDx, end: 0).animate(
        CurvedAnimation(parent: _exitController, curve: Curves.easeOut),
      );
    });
    await _exitController.forward(from: 0);
    _exitController.value = 0;
    setState(() {
      _dragDx = 0;
      _positionAnimation = null;
    });
  }

  void _goToResult(List<Restaurant> likedList) {
    if (likedList.length == 1) {
      final r = likedList[0];
      AnalyticsService.instance.logRestaurantSelected(
        r.id,
        r.placeName,
        categoryLabelFor(r.categoryName),
        'swipe',
        widget.locationName,
      );
      DecisionSessionService.instance.recordStage(
        AppLocalizations.of(context)!.funnelStageTodaysPick,
        1,
      );
      DecisionResumeService.instance.clear();
      context.push('/result', extra: {'restaurant': r});
    } else if (likedList.length >= 2) {
      DecisionResumeService.instance.clear();
      context.push(
        '/tournament',
        extra: {'restaurants': likedList, 'locationName': widget.locationName},
      );
    }
  }

  void _openSaveModal() {
    final lists = ref.read(libraryProvider).lists;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) =>
          _SaveToLibrarySheet(liked: _liked, startInNewMode: lists.isEmpty),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    if (current == null) return const SizedBox.shrink();

    final progress = _restaurants.isNotEmpty
        ? (_index + 1) / _restaurants.length
        : 0.0;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _kBgTeal,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const Text(
                        'Dangmatch',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          const DecisionTimerChip(light: true),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_index + 1}/${_restaurants.length}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _kOrange,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: GestureDetector(
                      onHorizontalDragStart: _handlePanStart,
                      onHorizontalDragUpdate: _handlePanUpdate,
                      onHorizontalDragEnd: _handlePanEnd,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _exitController,
                          _fadeInController,
                        ]),
                        builder: (context, child) {
                          final dx = _isDragging
                              ? _dragDx
                              : (_positionAnimation?.value ?? 0);
                          final rotateAngle =
                              (dx / 300).clamp(-1.0, 1.0) * 12 * pi / 180;
                          final exitFade = _isDragging
                              ? 1.0
                              : (1 - _exitController.value).clamp(0.0, 1.0);
                          final opacity = exitFade * _fadeInController.value;
                          final passOpacity = dx < 0
                              ? (dx.abs() / 150).clamp(0.0, 1.0)
                              : 0.0;
                          final yumiOpacity = dx > 0
                              ? (dx / 150).clamp(0.0, 1.0)
                              : 0.0;

                          return Transform.translate(
                            offset: Offset(dx, 0),
                            child: Transform.rotate(
                              angle: rotateAngle,
                              child: Opacity(
                                opacity: opacity.clamp(0.0, 1.0),
                                child: Stack(
                                  children: [
                                    child!,
                                    if (passOpacity > 0)
                                      Positioned.fill(
                                        child: Opacity(
                                          opacity: passOpacity,
                                          child: _overlayLabel(
                                            'PASS',
                                            Colors.red,
                                          ),
                                        ),
                                      ),
                                    if (yumiOpacity > 0)
                                      Positioned.fill(
                                        child: Opacity(
                                          opacity: yumiOpacity,
                                          child: _overlayLabel(
                                            'YUMI!',
                                            _kOrange,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                color: const Color(0xFFF0F0F0),
                                child: _SwipeCard(restaurant: current),
                              ),
                            ),
                            if (_choiceCount > 0)
                              Positioned(
                                top: 10,
                                left: 10,
                                child: _badge(
                                  t.swipeChoiceCountBadge(_choiceCount),
                                ),
                              ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: () => _goToResult([current]),
                                child: _badge(t.swipeTodaysPickBadge),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildBottomCta(t),
              ],
            ),
            if (_done) _buildDoneOverlay(t),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: _kOrange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _overlayLabel(String text, Color color) {
    return Container(
      color: color.withValues(alpha: 0.35),
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: (text == 'PASS' ? -15 : 15) * pi / 180,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCta(AppLocalizations t) {
    Widget cta;
    if (_liked.isEmpty) {
      cta = _ctaButton(
        t.swipeCantStartTournament,
        const Color(0xFFE5E7EB),
        const Color(0xFF9CA3AF),
        null,
      );
    } else if (_liked.length == 1) {
      cta = _ctaButton(
        t.swipeInstantWin,
        _kOrange,
        Colors.white,
        () => _goToResult(_liked),
      );
    } else {
      cta = _ctaButton(
        t.swipeStartTournamentWithCount(_liked.length),
        _kBgTeal,
        Colors.white,
        () => _goToResult(_liked),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      child: cta,
    );
  }

  Widget _ctaButton(String text, Color bg, Color fg, VoidCallback? onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }

  Widget _buildDoneOverlay(AppLocalizations t) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.swipeSelectedListTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const Divider(height: 24),
            Flexible(
              child: _liked.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          const Text('😅', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 8),
                          Text(
                            t.swipeNoSelections,
                            style: const TextStyle(color: Color(0xFF9CA3AF)),
                          ),
                        ],
                      ),
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _liked.length,
                        itemBuilder: (context, i) {
                          final r = _liked[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: _kBgTeal,
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    r.placeName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
            const Divider(height: 24),
            if (_liked.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _openSaveModal,
                  child: Text(t.swipeAddToLibraryButton),
                ),
              ),
              const SizedBox(height: 10),
            ],
            _buildBottomCta(t),
            TextButton(
              onPressed: () => context.go('/'),
              child: Text(
                t.swipeGoHomeButton,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveToLibrarySheet extends ConsumerStatefulWidget {
  const _SaveToLibrarySheet({
    required this.liked,
    required this.startInNewMode,
  });

  final List<Restaurant> liked;
  final bool startInNewMode;

  @override
  ConsumerState<_SaveToLibrarySheet> createState() =>
      _SaveToLibrarySheetState();
}

class _SaveToLibrarySheetState extends ConsumerState<_SaveToLibrarySheet> {
  late bool _newMode = widget.startInNewMode;
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final lists = ref.watch(libraryProvider).lists;
    final places = widget.liked.map(_toPlace).toList();
    final t = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 36,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.swipeAddToLibrarySheetTitle,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: lists.isEmpty
                      ? null
                      : () => setState(() => _newMode = false),
                  child: Text(
                    t.swipeAddToExisting,
                    style: TextStyle(
                      fontWeight: _newMode
                          ? FontWeight.normal
                          : FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _newMode = true),
                  child: Text(
                    t.swipeCreateNewList,
                    style: TextStyle(
                      fontWeight: _newMode
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!_newMode)
            lists.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(t.swipeNoListsYet),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final list in lists)
                          ListTile(
                            leading: const Text(
                              '🗂',
                              style: TextStyle(fontSize: 20),
                            ),
                            title: Text(list.title),
                            subtitle: Text(t.searchPlaceCount(list.count)),
                            onTap: () {
                              ref
                                  .read(libraryProvider.notifier)
                                  .addPlacesToList(list.id, places);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(t.swipeAddedToLibraryMessage),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  )
          else
            Column(
              children: [
                TextField(
                  controller: _nameController,
                  maxLength: 30,
                  decoration: InputDecoration(hintText: t.swipeNewListNameHint),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) return;
                      await ref
                          .read(libraryProvider.notifier)
                          .addList(name, places);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(t.swipeListCreatedMessage(name)),
                          ),
                        );
                      }
                    },
                    child: Text(t.swipeCreateAndSaveButton(places.length)),
                  ),
                ),
              ],
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.commonCancel),
          ),
        ],
      ),
    );
  }
}
