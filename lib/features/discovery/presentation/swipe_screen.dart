import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/place.dart';
import '../../../shared/models/restaurant.dart';
import '../../../shared/models/restaurant_category.dart';
import '../../../shared/services/analytics_service.dart';
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
    image: 'https://picsum.photos/seed/${r.id}/200/200',
    placeUrl: r.placeUrl,
  );
}

/// Lightweight card: name, address and a simple category icon — no per-card
/// webview/network page load. Reviews and hours are only fetched once the
/// user commits to a specific place (tournament match preview).
class _SwipeCard extends StatelessWidget {
  const _SwipeCard({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final address = r.roadAddressName.isNotEmpty
        ? r.roadAddressName
        : r.addressName;

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
              child: Text(
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
  String? _swipeDir; // 'pass' | 'yumi'
  int _choiceCount = 0;
  DateTime _viewStart = DateTime.now();

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

  Future<void> _animateCard(bool like) async {
    setState(() => _swipeDir = like ? 'yumi' : 'pass');
    await _exitController.forward(from: 0);
    setState(() => _swipeDir = null);
    _advance(like);
    _exitController.value = 0;
    _fadeInController.forward(from: 0);
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
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _exitController,
                        _fadeInController,
                      ]),
                      builder: (context, child) {
                        final exitT = _exitController.value;
                        final dx =
                            (_swipeDir == 'yumi'
                                ? 500.0
                                : (_swipeDir == 'pass' ? -500.0 : 0.0)) *
                            exitT;
                        final rotateSign = _swipeDir == 'yumi'
                            ? 1.0
                            : (_swipeDir == 'pass' ? -1.0 : 0.0);
                        final opacity = (1 - exitT) * _fadeInController.value;

                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: Transform.rotate(
                            angle: rotateSign * exitT * 12 * pi / 180,
                            child: Opacity(
                              opacity: opacity.clamp(0.0, 1.0),
                              child: child,
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
                          if (_swipeDir == 'pass')
                            Positioned.fill(
                              child: _overlayLabel('PASS', Colors.red),
                            ),
                          if (_swipeDir == 'yumi')
                            Positioned.fill(
                              child: _overlayLabel('YUMI!', _kOrange),
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
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _actionButton(
                        icon: Icons.close,
                        color: Colors.white.withValues(alpha: 0.22),
                        iconColor: Colors.white,
                        label: 'PASS',
                        onTap: () => _animateCard(false),
                      ),
                      const SizedBox(width: 28),
                      _actionButton(
                        icon: Icons.restaurant,
                        color: _kOrange,
                        iconColor: Colors.white,
                        label: 'YUMI!',
                        labelColor: _kOrange,
                        onTap: () => _animateCard(true),
                      ),
                    ],
                  ),
                ),
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

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required String label,
    Color labelColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 60,
              height: 60,
              child: Icon(icon, color: iconColor),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: labelColor.withValues(alpha: 0.9),
            letterSpacing: 0.5,
          ),
        ),
      ],
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
