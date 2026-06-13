import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../application/game_controller.dart';
import '../../domain/enums/game_phase.dart';
import '../../domain/enums/pending_d20_type.dart';
import '../../domain/models/match_state.dart';
import '../../domain/models/player_in_match.dart';
import '../../domain/models/set_state.dart';
import '../../domain/models/turn_state.dart';

class GameTestScreen extends StatefulWidget {
  const GameTestScreen({super.key});

  @override
  State<GameTestScreen> createState() => _GameTestScreenState();
}

class _GameTestScreenState extends State<GameTestScreen> {
  late final GameController controller;

  int? _lastD6A;
  int? _lastD6B;
  int? _lastD20;

  @override
  void initState() {
    super.initState();

    final players = [
      PlayerInMatch(trueId: '1', alias: 'Jeff', playOrder: 1),
      PlayerInMatch(trueId: '2', alias: 'Sam', playOrder: 2),
    ];

    final matchState = MatchState(
      players: players,
      activePlayerIndex: 0,
      phase: GamePhase.startTurn,
      currentSet: SetState(setNumber: 1),
    );

    controller = GameController(state: matchState);
    controller.startTurn();
  }

  final rankAssets = [
    'assets/icons/rank0_oinker.svg',
    'assets/icons/rank1_piglet.svg',
    'assets/icons/rank2_porker.svg',
    'assets/icons/rank3_boar.svg',
    'assets/icons/rank4_hog.svg',
    'assets/icons/rank5_top_hog.svg',
  ];

  final rankLabels = ['Oinker', 'Piglet', 'Porker', 'Boar', 'Hog', 'Top Hog'];

  String _getD20Instruction(TurnState turn) {
    switch (turn.pendingD20Type) {
      case PendingD20Type.positiveSave:
        return 'Make a saving throw: If you roll a 4 or 11 you BUST';

      case PendingD20Type.negativeSave:
        return 'Make a saving throw: Roll a 4 or 11 to SURVIVE';

      case PendingD20Type.winningChance:
        return 'Winning Chance! Roll a 20 to win a Rasher!';

      case PendingD20Type.none:
        return '';
    }
  }

  String _getD6Asset(int value) {
    return 'assets/icons/d6_$value.svg';
  }

  @override
  Widget build(BuildContext context) {
    final turn = controller.state.currentTurn;
    final phase = controller.state.phase;

    return Scaffold(
      appBar: AppBar(title: const Text('Top Hog Test Screen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'The Pig Sty',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Column(
              children: List.generate(4, (index) {
                final isActivePlayer =
                    index == controller.state.activePlayerIndex;
                final playerExists = index < controller.state.players.length;

                final player = playerExists
                    ? controller.state.players[index]
                    : null;

                final rashers = player?.rashersWon ?? 0;
                final name = player?.alias ?? '---';

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),

                  decoration: BoxDecoration(
                    color: isActivePlayer
                        ? Colors.yellow.shade100
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
                      // ✅ Player name
                      SizedBox(
                        width: 60,
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: playerExists ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // ✅ Rank slots
                      Expanded(
                        child: Row(
                          children: List.generate(6, (slotIndex) {
                            final achieved =
                                playerExists && slotIndex <= rashers;

                            return Expanded(
                              child: Column(
                                children: [
                                  SvgPicture.asset(
                                    rankAssets[slotIndex],
                                    height: 28,
                                    colorFilter: achieved
                                        ? null
                                        : const ColorFilter.mode(
                                            Colors.grey,
                                            BlendMode.srcIn,
                                          ),
                                  ),

                                  const SizedBox(height: 2),

                                  // ✅ Show label ONLY if achieved
                                  if (achieved)
                                    Text(
                                      rankLabels[slotIndex],
                                      style: const TextStyle(
                                        fontSize: 10,
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
                padding: const EdgeInsets.only(top: 4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1.2,
                ),
                itemCount: 20,
                itemBuilder: (context, index) {
                  final score = turn?.liveScore ?? 0;
                  final banked = turn?.turnStartScore ?? 0;

                  final isFilled = index < score;
                  final isBanked = index < banked;

                  // ✅ Not reached yet (very faint, keep original image detail)
                  if (!isFilled) {
                    return Center(
                      child: Opacity(
                        opacity: 0.15, // ✅ very washed out
                        child: SvgPicture.asset(
                          'assets/icons/pig.svg',
                          width: 76,
                          height: 76,
                        ),
                      ),
                    );
                  }

                  // ✅ Banked (full strength)
                  if (isBanked) {
                    return Center(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.green.shade700, // ✅ strong indicator
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // ✅ soften edges
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/pig.svg',
                          width: 76,
                          height: 76,
                        ),
                      ),
                    );
                  }

                  // ✅ Current turn
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

            // ✅ Dice Display Area
            if (_lastD6A != null || _lastD20 != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
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
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _getD20Instruction(turn),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),

                  textAlign: TextAlign.center,
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
                      ? () {
                          setState(() {
                            final result = controller.roll2d6();
                            _lastD6A = result.first;
                            _lastD6B = result.second;
                            _lastD20 = null; // clear previous D20 until needed
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
                      ? () {
                          setState(() {
                            final d20 = controller.rollD20();
                            _lastD20 = d20;
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

            const SizedBox(height: 24),

            if (controller.state.isGameComplete)
              Card(
                color: Colors.green.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Game Complete! Winner IDs: ${controller.state.winnerIds.join(', ')}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
