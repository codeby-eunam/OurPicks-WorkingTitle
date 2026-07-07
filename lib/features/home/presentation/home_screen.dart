import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' show Geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/local_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/restaurant.dart';
import '../../../shared/services/analytics_service.dart';
import '../../../shared/services/restaurant_api.dart';
import '../../auth/application/user_notifier.dart';
import '../../discovery/application/decision_resume.dart';
import '../../discovery/application/decision_session.dart';
import '../../settings/application/locale_notifier.dart';

const _kFoodFilters = [
  (id: 'all', emoji: '🍽️'),
  (id: 'korean', emoji: '🍚'),
  (id: 'japanese', emoji: '🍣'),
  (id: 'chinese', emoji: '🥢'),
  (id: 'western', emoji: '🍝'),
  (id: 'snack', emoji: '🍢'),
  (id: 'asian', emoji: '🍜'),
  (id: 'cafe', emoji: '☕'),
];

/// Port of app/(tabs)/index.tsx: location + category select → mode-select.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _location = '서울역';
  ({double lat, double lng})? _locationCoords;
  bool _searchVisible = false;
  final _searchController = TextEditingController();
  List<String> _selectedFilters = ['all'];
  bool _locating = false;
  bool _startLoading = false;
  List<Restaurant> _searchResults = [];
  bool _searching = false;
  List<String> _recentSearches = [];
  Timer? _debounce;
  ResumableSession? _resumeSession;

  AppLocalizations get _t => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _maybeShowLanguagePicker();
    _loadRecentSearches();
    _loadResumeSession();
    _searchController.addListener(_onSearchTextChanged);
  }

  Future<void> _loadResumeSession() async {
    final session = await DecisionResumeService.instance.load();
    if (mounted) setState(() => _resumeSession = session);
  }

  void _dismissResumeSession() {
    DecisionResumeService.instance.clear();
    setState(() => _resumeSession = null);
  }

  void _resume() {
    final session = _resumeSession;
    if (session == null) return;
    DecisionResumeService.instance.clear();
    DecisionSessionService.instance.begin();
    setState(() => _resumeSession = null);
    if (session.mode == ResumeMode.swipe) {
      context.push(
        '/swipe',
        extra: {
          'restaurants': session.restaurants,
          'locationName': session.locationName,
          'liked': session.liked,
        },
      );
    } else {
      context.push(
        '/tournament',
        extra: {
          'restaurants': session.restaurants,
          'locationName': session.locationName,
        },
      );
    }
  }

  Future<void> _maybeShowLanguagePicker() async {
    await ref.read(localeProvider.notifier).ready;
    if (!mounted) return;
    if (!ref.read(localeProvider).hasChosen) {
      context.go('/language-picker');
      return;
    }
    _maybeRedirectToLanding();
  }

  Future<void> _maybeRedirectToLanding() async {
    await ref.read(userProvider.notifier).ready;
    if (!mounted) return;
    final state = ref.read(userProvider);
    if (!state.isLoggedIn && !state.hasSeenLanding) {
      context.go('/landing');
    }
  }

  Future<void> _loadRecentSearches() async {
    final list = await LocalStore.instance.getStringList(
      LocalStore.keyRecentLocationSearches,
    );
    if (mounted && list != null) setState(() => _recentSearches = list);
  }

  void _onSearchTextChanged() {
    _debounce?.cancel();
    final text = _searchController.text.trim();
    if (text.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _searching = true);
      try {
        final results = await RestaurantApi().searchLocation(text);
        if (mounted) setState(() => _searchResults = results);
      } catch (_) {
        if (mounted) setState(() => _searchResults = []);
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleCurrentLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showAlert(
          _t.homeLocationPermissionTitle,
          _t.homeLocationPermissionMessage,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (!mounted) return;
      _locationCoords = (lat: position.latitude, lng: position.longitude);

      try {
        final placemarks = await Geocoding().placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        final place = placemarks.firstOrNull;
        final parts = [
          place?.subLocality,
          place?.locality,
        ].whereType<String>().where((s) => s.isNotEmpty);
        final label = parts.join(' ');
        if (mounted) {
          setState(
            () => _location = label.isNotEmpty
                ? _t.homeNearSuffix(label)
                : _t.homeCurrentLocationLabel,
          );
        }
      } catch (_) {
        if (mounted) setState(() => _location = _t.homeCurrentLocationLabel);
      }
    } catch (_) {
      _showAlert(_t.homeErrorTitle, _t.homeLocationFetchError);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// homeNearSuffix wraps the raw place name differently per locale
  /// ("Near {name}" vs "{name} 근처"), so strip whichever wrapping is active
  /// to recover the bare name for re-searching.
  String _stripNearSuffix(String location) {
    final wrapper = _t.homeNearSuffix('');
    if (wrapper.isEmpty) return location;
    if (location.startsWith(wrapper)) return location.substring(wrapper.length);
    if (location.endsWith(wrapper)) {
      return location.substring(0, location.length - wrapper.length);
    }
    return location;
  }

  void _showAlert(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t.commonConfirm),
          ),
        ],
      ),
    );
  }

  void _closeModal() {
    setState(() {
      _searchVisible = false;
      _searchController.clear();
    });
  }

  Future<void> _selectLocation(String name, {double? lat, double? lng}) async {
    setState(() {
      _location = name;
      _locationCoords = (lat != null && lng != null)
          ? (lat: lat, lng: lng)
          : null;
    });
    final updated = [
      name,
      ..._recentSearches.where((s) => s != name),
    ].take(7).toList();
    setState(() => _recentSearches = updated);
    await LocalStore.instance.setStringList(
      LocalStore.keyRecentLocationSearches,
      updated,
    );
    if (!mounted) return;
    AnalyticsService.instance.logLocationSearched(
      _searchController.text.isNotEmpty ? _searchController.text : name,
      _searchResults.length,
      selectedPlace: name,
    );
    _closeModal();
  }

  Future<void> _clearRecentSearches() async {
    setState(() => _recentSearches = []);
    await LocalStore.instance.setStringList(
      LocalStore.keyRecentLocationSearches,
      [],
    );
  }

  void _toggleFilter(String id) {
    setState(() {
      if (id == 'all') {
        _selectedFilters = ['all'];
      } else {
        final without = _selectedFilters.where((f) => f != 'all').toList();
        final next = without.contains(id)
            ? without.where((f) => f != id).toList()
            : [...without, id];
        _selectedFilters = next.isEmpty ? ['all'] : next;
      }
    });
    AnalyticsService.instance.logFilterSelected(_selectedFilters, _location);
  }

  Future<void> _handleStart() async {
    setState(() => _startLoading = true);
    try {
      var coords = _locationCoords;
      if (coords == null) {
        final query = _stripNearSuffix(_location);
        final results = await RestaurantApi().searchLocation(query);
        if (!mounted) return;
        if (results.isNotEmpty) {
          coords = (lat: results.first.lat, lng: results.first.lng);
          setState(() => _locationCoords = coords);
        } else {
          _showAlert(_t.homeLocationErrorTitle, _t.homeLocationNotFoundMessage);
          return;
        }
      }

      if (!mounted) return;
      context.push(
        '/mode-select',
        extra: {
          'lat': coords.lat,
          'lng': coords.lng,
          'locationName': _location,
          'categoryFilters': _selectedFilters.join(','),
        },
      );
    } catch (_) {
      _showAlert(_t.homeErrorTitle, _t.homeLocationConfirmError);
    } finally {
      if (mounted) setState(() => _startLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                children: [
                  if (_resumeSession != null)
                    _buildResumeBanner(_resumeSession!),
                  _buildSearchBar(),
                  _buildFilterGrid(),
                  _buildStartButton(),
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      _t.homeTagline,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _searchVisible ? _buildSearchModal() : null,
    );
  }

  /// 오늘/어제/N일 전 형태로 상대적인 날짜를 표현한다.
  String _relativeDay(DateTime savedAt) {
    final today = DateTime.now();
    final diff = DateTime(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime(savedAt.year, savedAt.month, savedAt.day)).inDays;
    if (diff <= 0) return _t.homeResumeBannerToday;
    if (diff == 1) return _t.homeResumeBannerYesterday;
    return _t.homeResumeBannerDaysAgo(diff);
  }

  Widget _buildResumeBanner(ResumableSession session) {
    final relativeDay = _relativeDay(session.savedAt);
    final locationLabel = session.locationName.isNotEmpty
        ? session.locationName
        : _t.homeResumeBannerFallbackLocation;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('⏳', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t.homeResumeBannerQuestion(relativeDay, locationLabel),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  _t.homeResumeBannerRemaining(session.restaurants.length),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _resume,
            child: Text(_t.homeResumeContinueButton),
          ),
          IconButton(
            onPressed: _dismissResumeSession,
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, size: 18, color: AppColors.primary),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _searchVisible = true),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  _locating ? _t.homeLocatingLabel : _location,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _locating ? null : _handleCurrentLocation,
            icon: _locating
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.my_location,
                    size: 22,
                    color: Color(0xFF6B7280),
                  ),
          ),
          IconButton(
            onPressed: () => setState(() => _searchVisible = true),
            icon: const Icon(Icons.search, size: 20, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  String _filterLabel(String id) {
    switch (id) {
      case 'korean':
        return _t.homeFilterKorean;
      case 'japanese':
        return _t.homeFilterJapanese;
      case 'chinese':
        return _t.homeFilterChinese;
      case 'western':
        return _t.homeFilterWestern;
      case 'snack':
        return _t.homeFilterSnack;
      case 'asian':
        return _t.homeFilterAsian;
      case 'cafe':
        return _t.homeFilterCafe;
      default:
        return _t.homeFilterAll;
    }
  }

  Widget _buildFilterGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9,
        children: [
          for (final f in _kFoodFilters)
            _FilterChip(
              emoji: f.emoji,
              label: _filterLabel(f.id),
              active: _selectedFilters.contains(f.id),
              onTap: () => _toggleFilter(f.id),
            ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 28),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _startLoading ? null : _handleStart,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: _startLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _t.homeStartButton,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSearchModal() {
    final isSearching = _searchController.text.trim().length >= 2;
    return Material(
      color: Colors.white,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _closeModal,
                      icon: const Icon(Icons.chevron_left, size: 26),
                    ),
                    Expanded(
                      child: Text(
                        _t.homeSearchModalTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: _t.homeSearchHint,
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  _handleCurrentLocation();
                  _closeModal();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.my_location,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _t.homeUseCurrentLocation,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _searching
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : isSearching
                    ? _buildResultsList()
                    : _buildRecentList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          _t.homeNoSearchResults,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return ListTile(
          leading: const Icon(
            Icons.location_on_outlined,
            size: 16,
            color: Color(0xFF9CA3AF),
          ),
          title: Text(item.placeName),
          subtitle: item.addressName.isNotEmpty ? Text(item.addressName) : null,
          onTap: () => _selectLocation(
            _t.homeNearSuffix(item.placeName),
            lat: item.lat,
            lng: item.lng,
          ),
        );
      },
    );
  }

  Widget _buildRecentList() {
    return ListView(
      children: [
        if (_recentSearches.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _t.homeRecentSearchesLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: _clearRecentSearches,
                  child: Text(
                    _t.homeClearAllButton,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        if (_recentSearches.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                _t.homeNoRecentSearches,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          for (final item in _recentSearches)
            ListTile(
              leading: const Icon(
                Icons.history,
                size: 16,
                color: Color(0xFF9CA3AF),
              ),
              title: Text(item),
              onTap: () => _selectLocation(item),
            ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.emoji,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
            width: 0.5,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
