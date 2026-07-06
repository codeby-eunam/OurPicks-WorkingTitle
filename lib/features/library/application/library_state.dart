import '../../../shared/models/place.dart';

class LibraryState {
  const LibraryState({this.lists = const [], this.loading = false});

  final List<ListItem> lists;
  final bool loading;

  LibraryState copyWith({List<ListItem>? lists, bool? loading}) {
    return LibraryState(lists: lists ?? this.lists, loading: loading ?? this.loading);
  }
}
