import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/place.dart';
import '../../auth/application/user_notifier.dart';
import '../data/library_api.dart';
import 'library_state.dart';

const _kToggleDebounce = Duration(milliseconds: 1500);

/// Port of context/LibraryContext.tsx as a Riverpod Notifier.
class LibraryNotifier extends Notifier<LibraryState> {
  final _api = LibraryApi();
  final Map<String, Timer> _debounceMap = {};
  String? _uid;

  @override
  LibraryState build() {
    ref.listen<String?>(
      userProvider.select((s) => s.user?.kakaoId),
      (previous, next) => _onUidChanged(next),
      fireImmediately: true,
    );
    ref.onDispose(() {
      for (final timer in _debounceMap.values) {
        timer.cancel();
      }
    });
    return const LibraryState();
  }

  Future<void> _onUidChanged(String? uid) async {
    _uid = uid;
    if (uid == null) {
      state = const LibraryState(lists: [], loading: false);
      return;
    }
    state = state.copyWith(loading: true);
    try {
      final lists = await _api.fetchLists(uid);
      state = LibraryState(lists: lists, loading: false);
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  /// 로그인 상태면 서버에 생성, 비로그인 상태면 로컬 임시 리스트로만 추가.
  Future<void> addList(String title, List<Place> places) async {
    final uid = _uid;
    if (uid == null) {
      final cafeCount = places.where((p) => p.category == '카페').length;
      final type = cafeCount > places.length / 2 ? '카페' : '식당';
      final local = ListItem(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        count: places.length,
        type: type,
        icon: type == '카페' ? 'local-cafe' : 'restaurant',
        images: rebuildImages(places),
        places: places,
        isPublic: false,
        ownerUid: 'local',
      );
      state = state.copyWith(lists: [local, ...state.lists]);
      return;
    }

    final created = await _api.createList(
      uid: uid,
      title: title,
      places: places,
    );
    state = state.copyWith(lists: [created, ...state.lists]);
  }

  void addPlacesToList(String listId, List<Place> places) {
    final uid = _uid;
    final updatedLists = <ListItem>[];
    ListItem? updatedTarget;
    List<Place> newlyAdded = const [];

    for (final list in state.lists) {
      if (list.id != listId) {
        updatedLists.add(list);
        continue;
      }
      final existingIds = list.places.map((p) => p.id).toSet();
      newlyAdded = places.where((p) => !existingIds.contains(p.id)).toList();
      if (newlyAdded.isEmpty) {
        updatedLists.add(list);
        continue;
      }
      final merged = [...list.places, ...newlyAdded];
      updatedTarget = list.copyWith(
        places: merged,
        count: merged.length,
        images: rebuildImages(merged),
      );
      updatedLists.add(updatedTarget);
    }

    state = state.copyWith(lists: updatedLists);

    if (uid != null && updatedTarget != null) {
      for (final place in newlyAdded) {
        _api.addRestaurant(uid, listId, place).catchError((_) {});
      }
    }
  }

  /// 순서 변경은 RN에서도 서버 동기화 없이 로컬 표시 순서만 바꾸는 기능이었다.
  void reorderPlaces(String listId, List<Place> newOrder) {
    state = state.copyWith(
      lists: state.lists
          .map((l) => l.id == listId ? l.copyWith(places: newOrder) : l)
          .toList(),
    );
  }

  void deleteList(String listId) {
    final uid = _uid;
    state = state.copyWith(
      lists: state.lists.where((l) => l.id != listId).toList(),
    );
    _debounceMap.remove(listId)?.cancel();
    if (uid != null) {
      _api.deleteList(uid, listId).catchError((_) {});
    }
  }

  void renameList(String listId, String title) {
    final uid = _uid;
    state = state.copyWith(
      lists: state.lists
          .map((l) => l.id == listId ? l.copyWith(title: title) : l)
          .toList(),
    );
    if (uid != null) {
      _api.renameList(uid, listId, title).catchError((_) {});
    }
  }

  /// 즉시 UI 반영, 1.5초 debounce 후 서버에 최종 상태만 전송.
  void togglePublic(String listId) {
    state = state.copyWith(
      lists: state.lists
          .map((l) => l.id == listId ? l.copyWith(isPublic: !l.isPublic) : l)
          .toList(),
    );

    _debounceMap.remove(listId)?.cancel();
    _debounceMap[listId] = Timer(_kToggleDebounce, () {
      _debounceMap.remove(listId);
      final uid = _uid;
      if (uid == null) return;
      final list = state.lists.where((l) => l.id == listId).firstOrNull;
      if (list != null) {
        _api.setVisibility(uid, listId, list.isPublic).catchError((_) {});
      }
    });
  }

  void removePlaceFromList(String listId, String placeId) {
    final uid = _uid;
    state = state.copyWith(
      lists: state.lists.map((l) {
        if (l.id != listId) return l;
        final places = l.places.where((p) => p.id != placeId).toList();
        return l.copyWith(
          places: places,
          count: places.length,
          images: rebuildImages(places),
        );
      }).toList(),
    );
    if (uid != null) {
      _api.removeRestaurant(uid, listId, placeId).catchError((_) {});
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

final libraryProvider = NotifierProvider<LibraryNotifier, LibraryState>(
  LibraryNotifier.new,
);
