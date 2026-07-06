/// 스와이프 → 토너먼트 → 우승까지 이어지는 한 번의 '결정 세션'을 추적한다.
/// Phase 1 결정 보조 기능(타이머, 퍼널, 재개, 확신도)의 공유 상태.
class DecisionSessionService {
  DecisionSessionService._();
  static final instance = DecisionSessionService._();

  DateTime? _startedAt;

  DateTime? get startedAt => _startedAt;
  bool get isActive => _startedAt != null;

  /// 결정 플로우 진입 시(모드 선택, 보관함에서 시작) 새 세션을 연다.
  void begin() {
    _startedAt = DateTime.now();
  }

  /// 스와이프에서 토너먼트로 넘어오는 경우처럼 진행 중이던 세션은 유지한다.
  void beginIfAbsent() {
    _startedAt ??= DateTime.now();
  }

  /// 우승이 확정되면 세션을 닫는다.
  void end() {
    _startedAt = null;
  }
}
