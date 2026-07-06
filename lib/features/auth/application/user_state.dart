import '../../../shared/models/app_user.dart';

class UserState {
  const UserState({
    this.user,
    this.hasSeenLanding = false,
    this.lastUsedProvider,
    this.pendingLogin,
    this.initialized = false,
  });

  final AppUser? user;
  final bool hasSeenLanding;
  final AuthProvider? lastUsedProvider;
  final PendingLogin? pendingLogin;

  /// True once the AsyncStorage-equivalent restore on app start has completed.
  final bool initialized;

  bool get isLoggedIn => user != null;

  UserState copyWith({
    AppUser? user,
    bool clearUser = false,
    bool? hasSeenLanding,
    AuthProvider? lastUsedProvider,
    PendingLogin? pendingLogin,
    bool clearPendingLogin = false,
    bool? initialized,
  }) {
    return UserState(
      user: clearUser ? null : (user ?? this.user),
      hasSeenLanding: hasSeenLanding ?? this.hasSeenLanding,
      lastUsedProvider: lastUsedProvider ?? this.lastUsedProvider,
      pendingLogin: clearPendingLogin ? null : (pendingLogin ?? this.pendingLogin),
      initialized: initialized ?? this.initialized,
    );
  }
}
