/// 결정 퍼널의 한 단계: 라벨(예: '후보', '1차 선택', '오늘의 픽')과 그 시점의 잔여 개수.
class FunnelStage {
  const FunnelStage(this.label, this.count);
  final String label;
  final int count;
}

/// 스와이프 → 토너먼트 → 우승까지 이어지는 한 번의 '결정 세션'을 추적한다.
/// Phase 1 결정 보조 기능(타이머, 퍼널, 재개, 확신도)의 공유 상태.
class DecisionSessionService {
  DecisionSessionService._();
  static final instance = DecisionSessionService._();

  DateTime? _startedAt;
  final List<FunnelStage> _stages = [];

  DateTime? get startedAt => _startedAt;
  bool get isActive => _startedAt != null;
  List<FunnelStage> get stages => List.unmodifiable(_stages);

  /// 결정 플로우 진입 시(모드 선택, 보관함에서 시작) 새 세션을 연다.
  void begin() {
    _startedAt = DateTime.now();
    _stages.clear();
  }

  /// 스와이프에서 토너먼트로 넘어오는 경우처럼 진행 중이던 세션은 유지한다.
  void beginIfAbsent() {
    _startedAt ??= DateTime.now();
  }

  /// 후보 수가 줄어드는 시점마다(스와이프 완료, 토너먼트 라운드 진출 등) 기록한다.
  void recordStage(String label, int count) {
    _stages.add(FunnelStage(label, count));
  }

  /// 우승이 확정되면 타이머만 멈춘다. 퍼널 기록은 결과 화면이 읽을 수 있도록
  /// 다음 begin() 호출 전까지 유지한다.
  void end() {
    _startedAt = null;
  }
}
