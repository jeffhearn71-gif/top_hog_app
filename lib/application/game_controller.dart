import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/enums/game_phase.dart';
import '../domain/enums/pending_d20_type.dart';
import '../domain/models/match_state.dart';
import '../domain/models/player_in_match.dart';
import '../domain/models/roll_event.dart';
import '../domain/models/set_state.dart';
import '../domain/models/turn_state.dart';
import '../domain/rules/top_hog_rule_engine.dart';

class GameController extends ChangeNotifier {
  MatchState state;
  final TopHogRuleEngine rules;
  final Random rng;
  String? lastTriggeredEvent;

  GameController({required this.state, TopHogRuleEngine? rules, Random? rng})
    : rules = rules ?? TopHogRuleEngine(),
      rng = rng ?? Random();

  PlayerInMatch get currentPlayer => state.players[state.activePlayerIndex];

  /// Start the current player's turn.
  void startTurn() {
    final player = currentPlayer;

    state.currentTurn = TurnState(
      playerId: player.trueId,
      turnStartScore: player.setBankedScore,
      liveScore: player.setBankedScore,
    );

    state.phase = GamePhase.awaitingPlayerAction;
    notifyListeners();
  }

  /// Roll the 2D6 dice and immediately handle the result.
  ({int first, int second}) roll2d6() {
    final first = rng.nextInt(6) + 1;
    final second = rng.nextInt(6) + 1;

    state.phase = GamePhase.rolling2d6;
    notifyListeners();

    handle2d6Result(first, second);

    final player = state.players[state.activePlayerIndex];
    if (state.currentTurn != null) {
      player.progressThisSet = state.currentTurn!.liveScore;
    }

    return (first: first, second: second);
  }

  /// Roll the D20 and resolve the pending D20 state.
  int rollD20() {
    final d20 = rng.nextInt(20) + 1;
    handlePendingD20(d20);
    return d20;
  }

  /// Resolve the main 2D6 roll.
  void handle2d6Result(int first, int second) {
    final turn = state.currentTurn;
    if (turn == null) return;

    final result = rules.resolve2d6(first, second);

    // Record the main roll immediately
    turn.rollHistory.add(
      RollEvent(
        d6a: first,
        d6b: second,
        outcomeLabel: result.label,
        normalPointsAwarded: 0,
        trotterBonusAwarded: 0,
      ),
    );

    if (result.pendingD20Type != PendingD20Type.none) {
      turn.pendingD20Type = result.pendingD20Type;
      state.phase = GamePhase.awaitingD20;
      notifyListeners();
      return;
    }

    _applyPoints(
      normalPoints: result.normalPoints,
      trotterBonus: result.trotterBonus,
      d6a: first,
      d6b: second,
      label: result.label,
    );

    _evaluateTurnAfterResolvedRoll();
  }

  /// Resolve the pending D20 action (save or winning chance).
  void handlePendingD20(int d20) {
    final turn = state.currentTurn;
    if (turn == null) return;
    final player = state.players.firstWhere((p) => p.trueId == turn.playerId);
    final pendingType = turn.pendingD20Type;

    switch (pendingType) {
      case PendingD20Type.positiveSave:
        final survived = rules.survivesPositiveSave(d20);

        if (survived) {
          player.savesPassed += 1;
        } else {
          player.savesFailed += 1;
        }

        turn.rollHistory.add(
          RollEvent(
            d20: d20,
            outcomeLabel: survived
                ? 'Positive Save Passed'
                : 'Positive Save Failed',
            survived: survived,
            busted: !survived,
          ),
        );

        if (survived) {
          _applyPoints(
            normalPoints: 1,
            trotterBonus: 1,
            d6a: 2,
            d6b: 2,
            label: 'Trotter (Positive Save)',
          );
          turn.pendingD20Type = PendingD20Type.none;
          _evaluateTurnAfterResolvedRoll();
        } else {
          turn.pendingD20Type = PendingD20Type.none;
          bustOut();
        }
        break;

      case PendingD20Type.negativeSave:
        final survived = rules.survivesNegativeSave(d20);

        if (survived) {
          player.savesPassed += 1;
        } else {
          player.savesFailed += 1;
        }

        turn.rollHistory.add(
          RollEvent(
            d20: d20,
            outcomeLabel: survived
                ? 'Negative Save Passed'
                : 'Negative Save Failed',
            survived: survived,
            busted: !survived,
          ),
        );

        turn.pendingD20Type = PendingD20Type.none;

        if (survived) {
          state.phase = GamePhase.awaitingPlayerAction;
          notifyListeners();
        } else {
          bustOut();
        }
        break;

      case PendingD20Type.winningChance:
        final winsImmediately = rules.winsOnWinningChance(d20);

        // ✅ Track glory stats
        if (winsImmediately) {
          player.gloryWins += 1;
        } else {
          player.gloryFails += 1;
        }

        turn.rollHistory.add(
          RollEvent(
            d20: d20,
            outcomeLabel: winsImmediately
                ? 'Winning Chance Succeeded'
                : 'Winning Chance Failed',
            survived: true,
            busted: false,
          ),
        );

        _applyPoints(
          normalPoints: 1,
          trotterBonus: 3,
          d6a: 6,
          d6b: 6,
          label: 'Trotter (Winning Chance)',
        );

        turn.pendingD20Type = PendingD20Type.none;

        if (winsImmediately || turn.liveScore >= 20) {
          awardRasher(turn.playerId);
        } else {
          state.phase = GamePhase.awaitingPlayerAction;
          notifyListeners();
        }
        break;

      case PendingD20Type.none:
        return;
    }
  }

  /// Player safely banks their newly earned points for the set.
  void waddleOut() {
    final turn = state.currentTurn;
    if (turn == null) return;

    if (!turn.canWaddleOut) return;

    final player = state.players.firstWhere((p) => p.trueId == turn.playerId);
    player.setBankedScore = turn.liveScore;

    // ✅ Bank streak stats only when player safely waddles out
    if (turn.pendingBankedSuperStreak) {
      player.superStreakCount += 1;
    } else if (turn.pendingBankedStreak) {
      player.streakCount += 1;
    }

    _finishTurn();
  }

  /// Player busts and loses only the progress made this turn.
  void bustOut() {
    final turn = state.currentTurn;
    if (turn == null) return;

    final player = state.players.firstWhere((p) => p.trueId == turn.playerId);

    turn.rollHistory.add(
      RollEvent(outcomeLabel: 'Bust', survived: false, busted: true),
    );

    // Revert to the banked score they started this turn with
    player.setBankedScore = turn.turnStartScore;

    _finishTurn();
  }

  /// Award a rasher (set win) to this player.
  void awardRasher(String playerId) {
    final turn = state.currentTurn;
    if (turn == null) return;

    final player = state.players.firstWhere((p) => p.trueId == playerId);

    player.rashersWon += 1;

    player.hasWonCurrentSet = true;

    for (final p in state.players) {
      p.progressThisSet = 0;
    }

    player.totalTrotterBonusPoints += turn.trotterBonusThisTurn;

    state.currentSet.setWinners.add(playerId);

    final isStreakyBacon = turn.turnStartScore == 0 && turn.liveScore >= 20;

    if (isStreakyBacon) {
      player.streakyBaconCount += 1;
    }

    if (!state.currentSet.closingRoundTriggered) {
      state.currentSet.closingRoundTriggered = true;
      state.currentSet.closingRoundNumber = state.currentSet.roundNumber;
    }

    // ✅ If first round, allow everyone one turn
    if (state.currentSet.roundNumber == 1) {
      _finishTurn();
    } else {
      // ✅ Otherwise END THE SET immediately
      state.currentTurn = null;
      advanceToNextPlayer();
      endSet();
    }
  }

  /// Start the next set (all set scores reset to 0).
  void startNewSet() {
    final nextSetNumber = state.currentSet.setNumber + 1;

    for (final player in state.players) {
      player.setBankedScore = 0;
      player.hasWonCurrentSet = false;
    }

    state.currentSet = SetState(setNumber: nextSetNumber);
    state.currentTurn = null;
    state.phase = GamePhase.startSet;

    // ✅ Keep the current activePlayerIndex so the next player in sequence starts
    startTurn();
  }

  /// End the current set and either move to the next set or finish the game.
  void endSet() {
    state.phase = GamePhase.setEnded;

    _checkForMatchEnd();

    if (!state.isGameComplete) {
      startNewSet();
    }

    notifyListeners();
  }

  /// Decide the final winner(s) if one or more players reached 5 rashers.
  void _checkForMatchEnd() {
    final finalists = state.players
        .where((player) => player.rashersWon >= 5)
        .toList();

    if (finalists.isEmpty) {
      return;
    }

    final winners = resolveTopHogWinners(finalists);

    state.isGameComplete = true;
    state.phase = GamePhase.gameEnded;
    state.winnerIds = winners.map((w) => w.trueId).toList();

    for (final player in state.players) {
      if (!state.winnerIds.contains(player.trueId) && player.rashersWon == 0) {
        player.goldenOink = true;
      }
    }
  }

  /// Tie-break based on:
  /// 1) Higher Streaky Bacon count
  /// 2) Higher total Trotter bonus points
  /// 3) If still equal => tie
  List<PlayerInMatch> resolveTopHogWinners(List<PlayerInMatch> players) {
    if (players.isEmpty) return [];

    players.sort((a, b) {
      // ✅ 1. Rashers (highest priority)
      final byRashers = b.rashersWon.compareTo(a.rashersWon);
      if (byRashers != 0) return byRashers;

      // ✅ 2. Super Streaks
      final bySuperStreaks = b.superStreakCount.compareTo(a.superStreakCount);
      if (bySuperStreaks != 0) return bySuperStreaks;

      // ✅ 3. Streaks
      final byStreaks = b.streakCount.compareTo(a.streakCount);
      if (byStreaks != 0) return byStreaks;

      // ✅ 4. Trotter bonus points
      final byTrotters = b.totalTrotterBonusPoints.compareTo(
        a.totalTrotterBonusPoints,
      );
      if (byTrotters != 0) return byTrotters;

      // ✅ 5. Tie
      return 0;
    });

    final best = players.first;

    // ✅ Return all tied winners
    return players.where((player) {
      return player.rashersWon == best.rashersWon &&
          player.superStreakCount == best.superStreakCount &&
          player.streakCount == best.streakCount &&
          player.totalTrotterBonusPoints == best.totalTrotterBonusPoints;
    }).toList();
  }

  void _applyPoints({
    required int normalPoints,
    required int trotterBonus,
    required int d6a,
    required int d6b,
    required String label,
  }) {
    final turn = state.currentTurn!;
    turn.liveScore += normalPoints + trotterBonus;
    turn.normalPointsThisTurn += normalPoints;
    turn.trotterBonusThisTurn += trotterBonus;

    if (trotterBonus > 0) {
      turn.trotterEventsThisTurn += 1;
    }

    final player = state.players.firstWhere((p) => p.trueId == turn.playerId);

    // ✅ Track +1 points only (no trotters)
    if (normalPoints > 0 && trotterBonus == 0) {
      player.basicPointsScored += normalPoints;
    }

    turn.canWaddleOut = turn.liveScore > turn.turnStartScore;

    // ✅ Calculate points gained THIS TURN
    final gainedThisTurn = turn.liveScore - turn.turnStartScore;

    // ✅ Super Streak (20+)

    if (gainedThisTurn >= 20) {
      turn.hasSuperStreakThisTurn = true;
      turn.hasStreakThisTurn = false;
      lastTriggeredEvent = 'superStreak';
    }
    // ✅ Streak (10+ but NOT already super streak)
    else if (!turn.hasStreakThisTurn &&
        !turn.hasSuperStreakThisTurn &&
        gainedThisTurn >= 10) {
      turn.hasStreakThisTurn = true;
      lastTriggeredEvent = 'streak';
    }
    turn.rollHistory.add(
      RollEvent(
        d6a: d6a,
        d6b: d6b,
        outcomeLabel: label,
        normalPointsAwarded: normalPoints,
        trotterBonusAwarded: trotterBonus,
      ),
    );
  }

  void _evaluateTurnAfterResolvedRoll() {
    final turn = state.currentTurn!;
    if (turn.liveScore >= 20) {
      awardRasher(turn.playerId);
      return;
    }

    state.phase = GamePhase.awaitingPlayerAction;
    notifyListeners();
  }

  void _finishTurn() {
    final player = currentPlayer;
    state.currentSet.playersTakenTurnThisRound.add(player.trueId);

    state.currentTurn = null;
    state.phase = GamePhase.turnEnded;

    advanceToNextPlayer();
    _checkRoundCompletion();
  }

  void advanceToNextPlayer() {
    if (state.players.isEmpty) return;

    final totalPlayers = state.players.length;

    for (int i = 1; i <= totalPlayers; i++) {
      final nextIndex = (state.activePlayerIndex + i) % totalPlayers;
      final nextPlayer = state.players[nextIndex];

      if (!nextPlayer.hasWonCurrentSet) {
        state.activePlayerIndex = nextIndex;
        return;
      }
    }
  }

  void _checkRoundCompletion() {
    final eligiblePlayers = state.players
        .where((player) => !player.hasWonCurrentSet)
        .map((player) => player.trueId)
        .toSet();

    final allEligibleTaken = eligiblePlayers.every(
      state.currentSet.playersTakenTurnThisRound.contains,
    );

    if (!allEligibleTaken) {
      startTurn();
      return;
    }

    // Round finished
    state.phase = GamePhase.roundEnded;

    final isClosingRound =
        state.currentSet.closingRoundTriggered &&
        state.currentSet.closingRoundNumber == state.currentSet.roundNumber;

    if (isClosingRound) {
      endSet();
      return;
    }

    // Start next round in same set
    state.currentSet.roundNumber += 1;
    state.currentSet.playersTakenTurnThisRound.clear();

    startTurn();
  }
}
