import '../enums/game_phase.dart';
import 'player_in_match.dart';
import 'set_state.dart';
import 'turn_state.dart';

class MatchState {
  List<PlayerInMatch> players;
  int activePlayerIndex;
  GamePhase phase;

  SetState currentSet;
  TurnState? currentTurn;

  bool isGameComplete;
  List<String> winnerIds;

  MatchState({
    required this.players,
    required this.activePlayerIndex,
    required this.phase,
    required this.currentSet,
    this.currentTurn,
    this.isGameComplete = false,
    List<String>? winnerIds,
  }) : winnerIds = winnerIds ?? [];
}
