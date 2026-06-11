import 'package:flutter/material.dart';

import '../../application/game_controller.dart';
import '../../domain/enums/game_phase.dart';
import '../../domain/enums/pending_d20_type.dart';
import '../../domain/models/match_state.dart';
import '../../domain/models/player_in_match.dart';
import '../../domain/models/set_state.dart';

class GameTestScreen extends StatefulWidget {
  const GameTestScreen({super.key});

  @override
  State<GameTestScreen> createState() => _GameTestScreenState();
}

class _GameTestScreenState extends State<GameTestScreen> {
  late final GameController controller;

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

  @override
  Widget build(BuildContext context) {
    final currentPlayer = controller.currentPlayer;
    final turn = controller.state.currentTurn;
    final phase = controller.state.phase;
    final currentSet = controller.state.currentSet;

    return Scaffold(
      appBar: AppBar(title: const Text('Top Hog Test Screen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Current Player: ${currentPlayer.alias}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Text('Phase: ${phase.toString().split('.').last}'),
            Text('Set Number: ${currentSet.setNumber}'),
            Text('Round Number: ${currentSet.roundNumber}'),

            const Divider(height: 32),

            Text('Banked Score: ${currentPlayer.setBankedScore}'),
            Text('Rashers Won: ${currentPlayer.rashersWon}'),
            Text('Streaky Bacon Count: ${currentPlayer.streakyBaconCount}'),
            Text(
              'Total Trotter Bonus Points: ${currentPlayer.totalTrotterBonusPoints}',
            ),
            const Divider(height: 32),

            Text('Live Score: ${turn?.liveScore ?? '-'}'),
            Text('Turn Start Score: ${turn?.turnStartScore ?? '-'}'),
            Text(
              'Normal Points This Turn: ${turn?.normalPointsThisTurn ?? '-'}',
            ),
            Text(
              'Trotter Bonus This Turn: ${turn?.trotterBonusThisTurn ?? '-'}',
            ),
            Text(
              'Trotter Events This Turn: ${turn?.trotterEventsThisTurn ?? '-'}',
            ),
            Text('Can Waddle Out: ${turn?.canWaddleOut ?? false}'),

            Text(
              'Pending D20: ${turn?.pendingD20Type.toString().split('.').last ?? 'none'}',
            ),

            const Divider(height: 32),

            const Text(
              'Players',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final player in controller.state.players)
              Card(
                child: ListTile(
                  title: Text(player.alias),
                  subtitle: Text(
                    'Rashers: ${player.rashersWon} | '
                    'Set Score: ${player.setBankedScore} | '
                    'Won Current Set: ${player.hasWonCurrentSet}',
                  ),
                ),
              ),

            const Divider(height: 32),

            const Text(
              'Roll History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (turn == null || turn.rollHistory.isEmpty)
              const Text('No rolls yet.')
            else
              for (final roll in turn.rollHistory)
                Card(
                  child: ListTile(
                    title: Text(roll.outcomeLabel),
                    subtitle: Text(
                      '2D6: ${roll.d6a ?? '-'}, ${roll.d6b ?? '-'} | '
                      'D20: ${roll.d20 ?? '-'} | '
                      'Normal: ${roll.normalPointsAwarded} | '
                      'Trotter: ${roll.trotterBonusAwarded} | '
                      'Survived: ${roll.survived} | '
                      'Busted: ${roll.busted}',
                    ),
                  ),
                ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed:
                  (turn != null &&
                      turn.pendingD20Type != PendingD20Type.none &&
                      phase == GamePhase.awaitingD20)
                  ? () {
                      setState(() {
                        controller.rollD20();
                      });
                    }
                  : null,
              child: const Text('Roll D20'),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: (turn != null && turn.canWaddleOut)
                  ? () {
                      setState(() {
                        controller.waddleOut();
                      });
                    }
                  : null,
              child: const Text('Waddle Out'),
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
