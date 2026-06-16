import '../enums/pending_d20_type.dart';
import 'roll_event.dart';

class TurnState {
  final String playerId;

  // Score tracking
  final int turnStartScore;
  int liveScore;

  // Points earned THIS TURN ONLY
  int normalPointsThisTurn;
  int trotterBonusThisTurn;
  int trotterEventsThisTurn;

  bool hasStreakThisTurn = false;
  bool hasSuperStreakThisTurn = false;

  bool pendingBankedStreak = false;
  bool pendingBankedSuperStreak = false;

  // Player options
  bool canWaddleOut;

  // D20 state
  PendingD20Type pendingD20Type;

  // Roll history
  List<RollEvent> rollHistory;

  TurnState({
    required this.playerId,
    required this.turnStartScore,
    required this.liveScore,
    this.normalPointsThisTurn = 0,
    this.trotterBonusThisTurn = 0,
    this.trotterEventsThisTurn = 0,
    this.canWaddleOut = false,
    this.pendingD20Type = PendingD20Type.none,
    List<RollEvent>? rollHistory,
  }) : rollHistory = rollHistory ?? [];
}
