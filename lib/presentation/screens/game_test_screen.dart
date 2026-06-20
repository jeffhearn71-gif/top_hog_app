import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../application/game_controller.dart';
import '../../domain/enums/game_phase.dart';
import '../../domain/enums/pending_d20_type.dart';
import '../../domain/models/turn_state.dart';
import 'package:audioplayers/audioplayers.dart';
import 'match_summary_screen.dart';

class GameTestScreen extends StatefulWidget {
  final GameController controller;

  const GameTestScreen({super.key, required this.controller});

  @override
  State<GameTestScreen> createState() => _GameTestScreenState();
}

enum OverlayKind { none, rasher, streak, superStreak, glory, bust, gameWin }

class _GameTestScreenState extends State<GameTestScreen> {
  late final GameController controller;

  @override
  void initState() {
    super.initState();

    controller = widget.controller;
  }

  @override
  void dispose() {
    _rollPlayer.dispose();
    _eventPlayer.dispose();
    super.dispose();
  }

  int? _lastD6A;
  int? _lastD6B;
  int? _lastD20;

  List<String> _feedbackQueue = [];
  bool _showRasherOverlay = false;
  bool _isGloryWin = false;
  bool _isStreakWin = false;
  bool _showGameWinOverlay = false;
  bool _showNewRank = true;
  String? _rankRevealPlayerId;
  double _rankPopScale = 1.0;
  bool _isSuperStreakWin = false;

  final AudioPlayer _rollPlayer = AudioPlayer();
  final AudioPlayer _eventPlayer = AudioPlayer();

  final rankAssets = [
    'assets/icons/rank0_oinker.svg',
    'assets/icons/rank1_piglet.svg',
    'assets/icons/rank2_porker.svg',
    'assets/icons/rank3_boar.svg',
    'assets/icons/rank4_hog.svg',
    'assets/icons/rank5_top_hog.svg',
  ];

  final rankLabels = ['Oinker', 'Piglet', 'Porker', 'Boar', 'Hog', 'Top Hog'];

  OverlayKind _currentOverlayKind() {
    if (_showGameWinOverlay) return OverlayKind.gameWin;
    if (!_showRasherOverlay) return OverlayKind.none;

    switch (controller.lastTriggeredEvent) {
      case 'superStreak':
        return OverlayKind.superStreak;
      case 'streak':
        return OverlayKind.streak;
      case 'glory':
        return OverlayKind.glory;
      case 'bust':
        return OverlayKind.bust;
      case 'rasher':
        return OverlayKind.rasher;
      default:
        return OverlayKind.rasher;
    }
  }

  String _getD20Instruction(TurnState turn) {
    switch (turn.pendingD20Type) {
      case PendingD20Type.positiveSave:
        return 'SAVING THROW: If you roll a 1, 4 or 11 you BUST';

      case PendingD20Type.negativeSave:
        return 'SAVING THROW: Roll a 4, 11 or 20 to SURVIVE';

      case PendingD20Type.winningChance:
        return 'Roll a 20 to win a RASHER!';

      case PendingD20Type.none:
        return '';
    }
  }

  String _getD6Asset(int value) {
    return 'assets/icons/d6_$value.svg';
  }

  Future<void> _playFeedbackQueue() async {
    if (_feedbackQueue.isEmpty) return;

    setState(() {
      _feedbackQueue = [_feedbackQueue.first];
    });
  }

  String _friendlyOutcomeText(
    String outcomeLabel, {
    int? normalPointsAwarded,
    int? trotterBonusAwarded,
  }) {
    final lower = outcomeLabel.toLowerCase();

    // ✅ STANDARD POINT
    if (lower.contains('standard')) {
      return '+1 POINT';
    }

    // ✅ TROTTER CASES
    if (lower.contains('trotter')) {
      // If actual awarded values are available, use them.
      if (normalPointsAwarded != null && trotterBonusAwarded != null) {
        final totalPoints = normalPointsAwarded + trotterBonusAwarded;

        if (totalPoints == 2 && trotterBonusAwarded == 1) {
          return '+2 POINTS (+1 Point, +1 Trotter)';
        }

        if (totalPoints == 3 && trotterBonusAwarded == 2) {
          return '+3 POINTS (+1 Point, +2 Trotters)';
        }

        if (totalPoints == 4 && trotterBonusAwarded == 3) {
          return '+4 POINTS (+1 Point, +3 Trotters)';
        }
      }

      // Fallbacks if older/partial event data is ever encountered
      if (lower.contains('winning')) {
        return '+4 POINTS (+1 Point, +3 Trotters)';
      }

      if (lower.contains('positive') || lower.contains('save')) {
        return '+2 POINTS (+1 Point, +1 Trotter)';
      }

      return '+3 POINTS (+1 Point, +2 Trotters)';
    }

    // ✅ Outcomes
    if (lower.contains('bust')) {
      return 'BUST!';
    }

    if (lower.contains('saved')) {
      return 'SAVED!';
    }

    if (lower.contains('rasher')) {
      return 'RASHER WON!';
    }

    if (lower.contains('glory')) {
      return 'CHANCE FOR GLORY!';
    }

    if (lower.contains('cigar')) {
      return 'CLOSE....BUT NO CIGAR!';
    }

    return outcomeLabel.toUpperCase();
  }

  Color _getFeedbackColor(String message) {
    final lower = message.toLowerCase();

    // ✅ Glory (highest priority)

    if (lower.contains('glory') ||
        lower.contains('rasher') ||
        lower.contains('streak')) {
      return Colors.amber.shade700;
    }

    // ✅ Positive outcomes
    if (lower.contains('saved') || lower.contains('+')) {
      return Colors.green.shade700;
    }

    // ✅ Negative outcomes
    if (lower.contains('bust') || lower.contains('cigar')) {
      return Colors.red.shade700;
    }

    // ✅ Instructions (saving throw)
    if (lower.contains('saving throw')) {
      return Colors.purple.shade700;
    }

    // ✅ Default fallback
    return Colors.black;
  }

  Future<void> _playRollSound(String fileName) async {
    try {
      await _rollPlayer.stop();
      await _rollPlayer.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      debugPrint('Roll sound error: $e');
    }
  }

  Future<void> _playEventSound(String fileName) async {
    try {
      await _eventPlayer.stop();
      await _eventPlayer.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      debugPrint('Event sound error: $e');
    }
  }

  Future<void> _playSuperStreakSound() async {
    try {
      await _eventPlayer.stop();
      await Future.delayed(const Duration(milliseconds: 40));
      await _eventPlayer.play(AssetSource('sounds/win_super_streak.mp3'));
    } catch (e) {
      debugPrint('Super streak sound error: $e');
    }
  }

  void _showPriorityOverlay({
    required OverlayKind kind,
    required Duration hideAfter,
  }) {
    switch (kind) {
      case OverlayKind.superStreak:
        controller.lastTriggeredEvent = 'superStreak';
        _isSuperStreakWin = true;
        _isStreakWin = false;
        _isGloryWin = false;
        break;

      case OverlayKind.streak:
        controller.lastTriggeredEvent = 'streak';
        _isStreakWin = true;
        _isSuperStreakWin = false;
        _isGloryWin = false;
        break;

      default:
        return;
    }

    _showRasherOverlay = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _showRasherOverlay = true;
      });

      if (kind == OverlayKind.superStreak) {
        _playSuperStreakSound();
      } else if (kind == OverlayKind.streak) {
        _playEventSound('win_streak.mp3');
      }
    });

    Future.delayed(hideAfter, () {
      if (!mounted) return;

      setState(() {
        _showRasherOverlay = false;
      });
    });
  }

  void _playGameWinIfNeeded() {
    if (controller.state.isGameComplete) {
      _playEventSound('win_game.mp3');
    }
  }

  void _checkForGameEnd() {
    if (controller.state.isGameComplete && !_showGameWinOverlay) {
      _showGameWinOverlay = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });

      Future.delayed(const Duration(milliseconds: 3500), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  MatchSummaryScreen(players: controller.state.players),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _checkForGameEnd();
    final turn = controller.state.currentTurn;
    final phase = controller.state.phase;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // ✅ pale blue
      appBar: AppBar(title: const Text('Top Hog Test Screen')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'The Pig Pen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Column(
                  children: List.generate(4, (index) {
                    final isActivePlayer =
                        index == controller.state.activePlayerIndex;
                    final playerExists =
                        index < controller.state.players.length;

                    final player = playerExists
                        ? controller.state.players[index]
                        : null;

                    final rashers = player?.rashersWon ?? 0;
                    final name = player?.alias ?? '---';

                    // ✅ Show active player's live score, everyone else's banked score
                    final displayScore = !playerExists
                        ? 0
                        : (turn != null && player!.trueId == turn.playerId)
                        ? turn.liveScore
                        : player!.setBankedScore;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActivePlayer
                            ? Colors.amber.withValues(alpha: 0.25)
                            : Colors.transparent,
                        border: Border.all(
                          color: isActivePlayer
                              ? Colors.orange
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          // ✅ Player name + score
                          SizedBox(
                            width: 100,
                            child: Row(
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: playerExists
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '($displayScore)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: displayScore > 0
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // ✅ Rank slots
                          Expanded(
                            child: Row(
                              children: List.generate(6, (slotIndex) {
                                final isRankRevealPlayer =
                                    playerExists &&
                                    _rankRevealPlayerId == player!.trueId;

                                // ✅ the newly earned icon is the current rashers index
                                final newRankSlot = rashers;

                                final achieved =
                                    playerExists &&
                                    (isRankRevealPlayer
                                        ? (slotIndex < newRankSlot ||
                                              (_showNewRank &&
                                                  slotIndex == newRankSlot))
                                        : slotIndex <= rashers);

                                final isNewlyRevealedRank =
                                    isRankRevealPlayer &&
                                    _showNewRank &&
                                    slotIndex == newRankSlot;

                                return Expanded(
                                  child: Column(
                                    children: [
                                      AnimatedScale(
                                        scale: isNewlyRevealedRank
                                            ? _rankPopScale
                                            : 1.0,
                                        duration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        curve: Curves.easeInOut,
                                        child: SvgPicture.asset(
                                          rankAssets[slotIndex],
                                          height: 26,
                                          colorFilter: achieved
                                              ? null
                                              : const ColorFilter.mode(
                                                  Colors.grey,
                                                  BlendMode.srcIn,
                                                ),
                                        ),
                                      ),

                                      const SizedBox(height: 1),

                                      // ✅ Show label ONLY if achieved
                                      if (achieved)
                                        Text(
                                          rankLabels[slotIndex],
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight:
                                                FontWeight.bold, // ✅ stronger
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),

                // ✅ SCORE GRID (flexible, but controlled)
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          childAspectRatio: 1.3,
                        ),
                    itemCount: 20,
                    itemBuilder: (context, index) {
                      final score = turn?.liveScore ?? 0;
                      final banked = turn?.turnStartScore ?? 0;

                      final isFilled = index < score;
                      final isBanked = index < banked;

                      // ✅ Not reached yet (very faint pig)
                      if (!isFilled) {
                        return Center(
                          child: Opacity(
                            opacity: 0.15,
                            child: SvgPicture.asset(
                              'assets/icons/pig.svg',
                              width: 76,
                              height: 76,
                            ),
                          ),
                        );
                      }

                      // ✅ Banked (bordered)
                      if (isBanked) {
                        return Center(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.green.shade700,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SvgPicture.asset(
                              'assets/icons/pig.svg',
                              width: 76,
                              height: 76,
                            ),
                          ),
                        );
                      }

                      // ✅ Current turn (normal pig)
                      return Center(
                        child: SvgPicture.asset(
                          'assets/icons/pig.svg',
                          width: 76,
                          height: 76,
                        ),
                      );
                    },
                  ),
                ),

                // ✅ Feedback Text
                if (_feedbackQueue.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      _feedbackQueue.first,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getFeedbackColor(_feedbackQueue.first),
                      ),

                      textAlign: TextAlign.center,
                    ),
                  ),

                // ✅ Dice Display Area
                if (_lastD6A != null || _lastD20 != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ✅ D6 Dice
                        if (_lastD6A != null && _lastD6B != null) ...[
                          SvgPicture.asset(
                            _getD6Asset(_lastD6A!),
                            width: 50,
                            height: 50,
                          ),
                          const SizedBox(width: 12),
                          SvgPicture.asset(
                            _getD6Asset(_lastD6B!),
                            width: 50,
                            height: 50,
                          ),
                        ],

                        // ✅ D20 (when used)
                        if (_lastD20 != null) ...[
                          const SizedBox(width: 16),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: 0.15, // ✅ much more faded
                                child: SvgPicture.asset(
                                  'assets/icons/d20.svg',
                                  width: 60,
                                  height: 60,
                                ),
                              ),

                              Text(
                                '$_lastD20',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                // ✅ D20 Instruction Text
                if (turn != null && turn.pendingD20Type != PendingD20Type.none)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: SizedBox(
                      height: 28, // ✅ fixes vertical size
                      child: Center(
                        child: Text(
                          _getD20Instruction(turn),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // ✅ Roll 2D6
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(
                          120,
                          120,
                        ), // ✅ bigger, matches old feel
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 10,
                      ),

                      onPressed: (phase == GamePhase.awaitingPlayerAction)
                          ? () async {
                              _playRollSound('dice_roll.mp3');
                              final actingPlayer = controller.currentPlayer;
                              final rashersBefore = actingPlayer.rashersWon;

                              final isFreshTurn =
                                  (controller
                                              .state
                                              .currentTurn
                                              ?.normalPointsThisTurn ??
                                          0) ==
                                      0 &&
                                  (controller
                                              .state
                                              .currentTurn
                                              ?.trotterBonusThisTurn ??
                                          0) ==
                                      0;

                              setState(() {
                                _lastD6A = null;
                                _lastD6B = null;
                                _lastD20 = null;
                                _feedbackQueue = [];

                                // ✅ Only reset streak flags at the START of a brand-new turn
                                if (isFreshTurn) {
                                  _isStreakWin = false;
                                  _isSuperStreakWin = false;
                                }
                              });

                              await Future.delayed(
                                const Duration(milliseconds: 1000),
                              );

                              final turnBeforeRoll =
                                  controller.state.currentTurn;

                              final result = controller.roll2d6();

                              setState(() {
                                _lastD6A = result.first;
                                _lastD6B = result.second;

                                final updatedTurn =
                                    controller.state.currentTurn ??
                                    turnBeforeRoll;

                                final resolvedTurn =
                                    turnBeforeRoll ?? updatedTurn;

                                final rashersAfter = actingPlayer.rashersWon;

                                final wonRasherThisRoll =
                                    rashersAfter > rashersBefore;

                                List<String> messages = [];
                                String? pendingScoreSound;
                                bool triggeredStreakThisRoll = false;
                                bool triggeredSuperStreakThisRoll = false;

                                // ✅ Direct rasher win by ordinary scoring
                                if (wonRasherThisRoll) {
                                  final safeLastEvent =
                                      (resolvedTurn != null &&
                                          resolvedTurn.rollHistory.isNotEmpty)
                                      ? resolvedTurn.rollHistory.last
                                      : null;

                                  final safeLastOutcome =
                                      safeLastEvent?.outcomeLabel ?? '';

                                  final outcomeLower = safeLastOutcome
                                      .toLowerCase();

                                  if (safeLastOutcome.isNotEmpty &&
                                      !outcomeLower.contains('save') &&
                                      !outcomeLower.contains('saving') &&
                                      !outcomeLower.contains('winning')) {
                                    final friendly = _friendlyOutcomeText(
                                      safeLastOutcome,
                                      normalPointsAwarded:
                                          safeLastEvent?.normalPointsAwarded,
                                      trotterBonusAwarded:
                                          safeLastEvent?.trotterBonusAwarded,
                                    );

                                    messages.add(friendly);

                                    if (friendly.startsWith('+1 POINT')) {
                                      pendingScoreSound = 'score_basic.mp3';
                                    } else if (friendly.startsWith('+2') ||
                                        friendly.startsWith('+3') ||
                                        friendly.startsWith('+4')) {
                                      pendingScoreSound = 'score_trotter.mp3';
                                    } else if (friendly == 'BUST!') {
                                      pendingScoreSound = 'bust.mp3';
                                    }
                                  }

                                  messages.add('RASHER WON!');

                                  _isGloryWin = false;
                                  _showNewRank = false; // ✅ hide rank initially
                                  _rankRevealPlayerId = actingPlayer.trueId;
                                  _rankPopScale = 1.0;
                                  _showRasherOverlay = true;

                                  // ✅ reveal new rank after 1500ms
                                  Future.delayed(
                                    const Duration(milliseconds: 1500),
                                    () {
                                      if (mounted) {
                                        setState(() {
                                          _showNewRank =
                                              true; // appears first at normal size
                                          _rankPopScale = 1.0;
                                        });

                                        // ✅ grow to 1.5 AFTER it appears
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (mounted) {
                                                setState(() {
                                                  _rankPopScale = 1.5;
                                                });
                                              }
                                            });

                                        // ✅ shrink back to 1.0 after 400ms
                                        Future.delayed(
                                          const Duration(milliseconds: 400),
                                          () {
                                            if (mounted) {
                                              setState(() {
                                                _rankPopScale = 1.0;
                                                _rankRevealPlayerId = null;
                                              });
                                            }
                                          },
                                        );
                                      }
                                    },
                                  );

                                  Future.delayed(
                                    const Duration(milliseconds: 3000),
                                    () {
                                      if (mounted) {
                                        setState(() {
                                          _showRasherOverlay = false;
                                        });
                                      }
                                    },
                                  );
                                }
                                // ✅ Winning chance triggered
                                else if (updatedTurn != null &&
                                    updatedTurn.pendingD20Type ==
                                        PendingD20Type.winningChance) {
                                  messages.add('CHANCE FOR GLORY!');
                                  _playEventSound('tension_loop.mp3');
                                }
                                // ✅ Normal save triggered
                                else if (updatedTurn != null &&
                                    updatedTurn.pendingD20Type !=
                                        PendingD20Type.none) {
                                  messages.add('MAKE A SAVING THROW');
                                  _playEventSound('saving_throw.mp3');
                                }
                                // ✅ Standard scoring outcome
                                else {
                                  final safeLastEvent =
                                      (resolvedTurn != null &&
                                          resolvedTurn.rollHistory.isNotEmpty)
                                      ? resolvedTurn.rollHistory.last
                                      : null;

                                  final safeLastOutcome =
                                      safeLastEvent?.outcomeLabel ?? '';

                                  final outcomeLower = safeLastOutcome
                                      .toLowerCase();

                                  if (safeLastOutcome.isNotEmpty &&
                                      !outcomeLower.contains('save') &&
                                      !outcomeLower.contains('saving') &&
                                      !outcomeLower.contains('winning')) {
                                    final friendly = _friendlyOutcomeText(
                                      safeLastOutcome,
                                      normalPointsAwarded:
                                          safeLastEvent?.normalPointsAwarded,
                                      trotterBonusAwarded:
                                          safeLastEvent?.trotterBonusAwarded,
                                    );

                                    messages.add(friendly);

                                    if (friendly == 'BUST!') {
                                      _isGloryWin = false;
                                      _isStreakWin = false;
                                      _isSuperStreakWin = false;

                                      _showRasherOverlay = true;

                                      Future.delayed(
                                        const Duration(milliseconds: 1200),
                                        () {
                                          if (mounted) {
                                            setState(() {
                                              _showRasherOverlay = false;
                                            });
                                          }
                                        },
                                      );
                                    }

                                    if (friendly.startsWith('+1 POINT')) {
                                      pendingScoreSound = 'score_basic.mp3';
                                    } else if (friendly.startsWith('+2') ||
                                        friendly.startsWith('+3') ||
                                        friendly.startsWith('+4')) {
                                      pendingScoreSound = 'score_trotter.mp3';
                                    } else if (friendly == 'BUST!') {
                                      pendingScoreSound = 'bust.mp3';
                                    }
                                  }
                                }

                                // ✅ STREAK DETECTION (LIVE — Super can upgrade normal Streak)
                                if (resolvedTurn != null) {
                                  // 🔥🔥 Super Streak (20+ gained this turn)

                                  if (resolvedTurn.hasSuperStreakThisTurn &&
                                      !_isSuperStreakWin) {
                                    resolvedTurn.pendingBankedSuperStreak =
                                        true;
                                    triggeredSuperStreakThisRoll = true;

                                    messages = ['SUPER STREAK!!!'];

                                    _showPriorityOverlay(
                                      kind: OverlayKind.superStreak,
                                      hideAfter: const Duration(
                                        milliseconds: 1200,
                                      ),
                                    );
                                  }
                                  // 🔥 Normal Streak (10+ gained this turn)
                                  else if (resolvedTurn.hasStreakThisTurn &&
                                      !_isStreakWin &&
                                      !_isSuperStreakWin) {
                                    resolvedTurn.pendingBankedStreak = true;
                                    triggeredStreakThisRoll = true;

                                    messages = ['STREAK!'];

                                    _showPriorityOverlay(
                                      kind: OverlayKind.streak,
                                      hideAfter: const Duration(
                                        milliseconds: 1200,
                                      ),
                                    );
                                  }
                                }

                                if (!triggeredSuperStreakThisRoll &&
                                    !triggeredStreakThisRoll &&
                                    pendingScoreSound != null) {
                                  _playEventSound(pendingScoreSound);
                                }

                                _feedbackQueue = messages;
                                _playGameWinIfNeeded();
                                _playFeedbackQueue();
                              });
                            }
                          : null,

                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/roll_dice.svg',
                            width: 48,
                            height: 48,
                            colorFilter: const ColorFilter.mode(
                              Colors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Roll',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black, // ✅ force black
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ✅ Roll D20
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        minimumSize: const Size(
                          120,
                          120,
                        ), // ✅ bigger, matches old feel
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 10,
                      ),
                      onPressed:
                          (turn != null &&
                              turn.pendingD20Type != PendingD20Type.none &&
                              phase == GamePhase.awaitingD20)
                          ? () async {
                              _playRollSound('d20_roll.mp3');
                              final pendingTypeBeforeRoll = turn.pendingD20Type;
                              final actingPlayer = controller.currentPlayer;
                              final rashersBefore = actingPlayer.rashersWon;

                              final pointsBeforeD20Resolution =
                                  turn.normalPointsThisTurn +
                                  turn.trotterBonusThisTurn;

                              await Future.delayed(
                                const Duration(milliseconds: 1000),
                              );

                              final d20 = controller.rollD20();

                              // ✅ Epic fail on natural 1
                              if (d20 == 1) {
                                _eventPlayer.stop();
                                _playEventSound('epic_fail.mp3');
                              }

                              await Future.delayed(
                                const Duration(milliseconds: 500),
                              );

                              setState(() {
                                _lastD20 = d20;

                                final rashersAfter = actingPlayer.rashersWon;
                                final wonRasherThisRoll =
                                    rashersAfter > rashersBefore;

                                List<String> messages = [];

                                bool bustedOnD20 = false;
                                bool survivedOnD20 = false;
                                bool wonGlory = false;

                                int pointsAwardedByD20Resolution = 0;

                                switch (pendingTypeBeforeRoll) {
                                  case PendingD20Type.negativeSave:
                                    survivedOnD20 =
                                        (d20 == 4 || d20 == 11 || d20 == 20);
                                    bustedOnD20 = !survivedOnD20;
                                    pointsAwardedByD20Resolution = 0;
                                    break;

                                  case PendingD20Type.positiveSave:
                                    bustedOnD20 =
                                        (d20 == 1 || d20 == 4 || d20 == 11);
                                    survivedOnD20 = !bustedOnD20;
                                    pointsAwardedByD20Resolution = survivedOnD20
                                        ? 2
                                        : 0;
                                    break;

                                  case PendingD20Type.winningChance:
                                    wonGlory = (d20 == 20);
                                    pointsAwardedByD20Resolution = 4;
                                    break;

                                  case PendingD20Type.none:
                                    break;
                                }

                                final updatedTurn =
                                    controller.state.currentTurn;

                                final safeLastEvent =
                                    (updatedTurn != null &&
                                        updatedTurn.rollHistory.isNotEmpty)
                                    ? updatedTurn.rollHistory.last
                                    : null;

                                final safeLastOutcome =
                                    safeLastEvent?.outcomeLabel ?? '';

                                final outcomeLower = safeLastOutcome
                                    .toLowerCase();

                                final fallbackPointsAfterResolution =
                                    pointsBeforeD20Resolution +
                                    pointsAwardedByD20Resolution;

                                final triggeredSuperStreak =
                                    updatedTurn?.hasSuperStreakThisTurn ??
                                    (fallbackPointsAfterResolution >= 20);

                                final triggeredStreak =
                                    !triggeredSuperStreak &&
                                    (updatedTurn?.hasStreakThisTurn ??
                                        (fallbackPointsAfterResolution >= 10));

                                // ✅ PRIORITY 1: SUPER STREAK overrides everything
                                if (triggeredSuperStreak &&
                                    !_isSuperStreakWin) {
                                  if (updatedTurn != null) {
                                    updatedTurn.pendingBankedSuperStreak = true;
                                  }

                                  messages = ['SUPER STREAK!!!'];

                                  _showPriorityOverlay(
                                    kind: OverlayKind.superStreak,
                                    hideAfter: const Duration(
                                      milliseconds: 1200,
                                    ),
                                  );
                                }
                                // ✅ PRIORITY 2: Normal streak overrides rasher/save UI
                                else if (triggeredStreak &&
                                    !_isStreakWin &&
                                    !_isSuperStreakWin) {
                                  if (updatedTurn != null) {
                                    updatedTurn.pendingBankedStreak = true;
                                  }

                                  messages = ['STREAK!'];

                                  _showPriorityOverlay(
                                    kind: OverlayKind.streak,
                                    hideAfter: const Duration(
                                      milliseconds: 1200,
                                    ),
                                  );
                                }
                                // ✅ PRIORITY 3: standard D20 result handling
                                else {
                                  switch (pendingTypeBeforeRoll) {
                                    case PendingD20Type.negativeSave:
                                      messages.add(
                                        survivedOnD20 ? 'SAVED!' : 'BUST!',
                                      );

                                      _playEventSound(
                                        survivedOnD20
                                            ? 'save_pass.mp3'
                                            : 'save_fail.mp3',
                                      );

                                      if (!survivedOnD20) {
                                        controller.lastTriggeredEvent = 'bust';

                                        _showRasherOverlay = true;

                                        Future.delayed(
                                          const Duration(milliseconds: 1200),
                                          () {
                                            if (mounted) {
                                              setState(() {
                                                _showRasherOverlay = false;
                                              });
                                            }
                                          },
                                        );
                                      }
                                      break;

                                    case PendingD20Type.positiveSave:
                                      messages.add(
                                        bustedOnD20
                                            ? 'BUST!'
                                            : 'SAVED! +2 POINTS (+1 Point, +1 Trotter)',
                                      );

                                      _playEventSound(
                                        bustedOnD20
                                            ? 'save_fail.mp3'
                                            : 'save_pass.mp3',
                                      );

                                      if (bustedOnD20) {
                                        controller.lastTriggeredEvent = 'bust';

                                        _showRasherOverlay = true;

                                        Future.delayed(
                                          const Duration(milliseconds: 1200),
                                          () {
                                            if (mounted) {
                                              setState(() {
                                                _showRasherOverlay = false;
                                              });
                                            }
                                          },
                                        );
                                      }
                                      break;

                                    case PendingD20Type.winningChance:
                                      messages.add(
                                        wonGlory
                                            ? 'RASHER WON!'
                                            : 'CLOSE....BUT NO CIGAR!',
                                      );

                                      if (wonGlory) {
                                        _isGloryWin = true;
                                        _eventPlayer.stop();
                                        _playEventSound('win_glory.mp3');
                                      } else {
                                        _eventPlayer.stop();
                                        _playEventSound('close_call.mp3');
                                      }
                                      break;

                                    case PendingD20Type.none:
                                      break;
                                  }

                                  if (safeLastOutcome.isNotEmpty &&
                                      !outcomeLower.contains('save') &&
                                      !outcomeLower.contains('saving') &&
                                      !outcomeLower.contains('winning')) {
                                    final friendly = _friendlyOutcomeText(
                                      safeLastOutcome,
                                      normalPointsAwarded:
                                          safeLastEvent?.normalPointsAwarded,
                                      trotterBonusAwarded:
                                          safeLastEvent?.trotterBonusAwarded,
                                    );
                                    messages.add(friendly);

                                    if (friendly.startsWith('+1 POINT')) {
                                      _playEventSound('score_basic.mp3');
                                    } else if (friendly.startsWith('+2') ||
                                        friendly.startsWith('+3') ||
                                        friendly.startsWith('+4')) {
                                      _playEventSound('score_trotter.mp3');
                                    } else if (friendly == 'BUST!') {
                                      _playEventSound('bust.mp3');
                                    }
                                  }

                                  if (wonRasherThisRoll) {
                                    messages.add('RASHER WON!');
                                    controller.lastTriggeredEvent = 'rasher';
                                    _isGloryWin = false;
                                    _rankRevealPlayerId = actingPlayer.trueId;
                                    _showRasherOverlay = true;

                                    Future.delayed(
                                      const Duration(milliseconds: 3000),
                                      () {
                                        if (mounted) {
                                          setState(() {
                                            _showRasherOverlay = false;
                                          });
                                        }
                                      },
                                    );
                                  }
                                }

                                _feedbackQueue = messages;
                                _playGameWinIfNeeded();
                                _playFeedbackQueue();
                              });
                            }
                          : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/d20.svg',
                            width: 48,
                            height: 48,
                            colorFilter: const ColorFilter.mode(
                              Colors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Saving Throw',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black, // ✅ force black
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ✅ Waddle Out (native colours)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(
                          120,
                          120,
                        ), // ✅ bigger, matches old feel
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 10,
                      ),

                      onPressed:
                          (turn != null &&
                              turn.canWaddleOut &&
                              turn.pendingD20Type == PendingD20Type.none &&
                              phase == GamePhase.awaitingPlayerAction)
                          ? () {
                              _playEventSound('waddle_out.mp3');
                              setState(() {
                                controller.waddleOut();
                              });
                            }
                          : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/waddle_out.svg',
                            width: 48,
                            height: 48,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Waddle Out',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black, // ✅ force black
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24), // ✅ spacing
              ],
            ),
          ),

          // ✅ MAIN EVENT OVERLAY
          if (_currentOverlayKind() != OverlayKind.none &&
              _currentOverlayKind() != OverlayKind.gameWin)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    _currentOverlayKind() == OverlayKind.bust
                        ? 'assets/icons/broken_heart.svg'
                        : _currentOverlayKind() == OverlayKind.superStreak
                        ? 'assets/icons/exploding_head.svg'
                        : _currentOverlayKind() == OverlayKind.streak
                        ? 'assets/icons/flame.svg'
                        : _currentOverlayKind() == OverlayKind.glory
                        ? 'assets/icons/cup.svg'
                        : 'assets/icons/rasher.svg',

                    height: _currentOverlayKind() == OverlayKind.superStreak
                        ? 180
                        : _currentOverlayKind() == OverlayKind.streak
                        ? 140
                        : _currentOverlayKind() == OverlayKind.glory
                        ? 180
                        : 120,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _currentOverlayKind() == OverlayKind.bust
                        ? 'BUST!'
                        : _currentOverlayKind() == OverlayKind.superStreak
                        ? 'SUPER STREAK!!!'
                        : _currentOverlayKind() == OverlayKind.streak
                        ? 'STREAK!'
                        : _currentOverlayKind() == OverlayKind.glory
                        ? 'GLORY!!!'
                        : 'RASHER WON!',

                    style: TextStyle(
                      fontSize: _currentOverlayKind() == OverlayKind.superStreak
                          ? 36
                          : _currentOverlayKind() == OverlayKind.streak
                          ? 30
                          : _currentOverlayKind() == OverlayKind.glory
                          ? 40
                          : 28,
                      fontWeight: FontWeight.bold,
                      color: _currentOverlayKind() == OverlayKind.glory
                          ? Colors.amber
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
