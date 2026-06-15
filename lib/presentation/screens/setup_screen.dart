import 'package:flutter/material.dart';
import '../../application/game_controller.dart';
import '../../domain/enums/game_phase.dart';
import '../../domain/models/match_state.dart';
import '../../domain/models/player_in_match.dart';
import '../../domain/models/set_state.dart';
import 'game_test_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int playerCount = 2;
  int startingPlayerIndex = 0;

  final defaultNames = ['Jeff', 'Keira', 'Meredith', 'Dan'];
  late List<TextEditingController> controllers;

  @override
  void initState() {
    super.initState();

    controllers = List.generate(
      4,
      (index) => TextEditingController(text: defaultNames[index]),
    );
  }

  void _startGame() {
    final players = List.generate(playerCount, (index) {
      return PlayerInMatch(
        trueId: '${index + 1}',
        alias: controllers[index].text.trim().isEmpty
            ? defaultNames[index]
            : controllers[index].text.trim(),
        playOrder: index + 1,
      );
    });

    final matchState = MatchState(
      players: players,
      activePlayerIndex: startingPlayerIndex,
      phase: GamePhase.startTurn,
      currentSet: SetState(setNumber: 1),
    );

    final controller = GameController(state: matchState);

    // ✅ Start the first turn before navigating
    controller.startTurn();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GameTestScreen(controller: controller)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Top Hog')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Game Setup',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // ✅ Player count
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [2, 3, 4].map((count) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        playerCount = count;
                        if (startingPlayerIndex >= playerCount) {
                          startingPlayerIndex = 0;
                        }
                      });
                    },
                    child: Text('$count Players'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: playerCount == count
                          ? Colors.orange
                          : Colors.grey,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // ✅ Name inputs
            Column(
              children: List.generate(playerCount, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: TextField(
                    controller: controllers[index],
                    decoration: InputDecoration(
                      labelText: 'Player ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // ✅ Who goes first
            const Text(
              'Who goes first?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            Column(
              children: List.generate(playerCount, (index) {
                return RadioListTile<int>(
                  title: Text('Player ${index + 1}'),
                  value: index,
                  groupValue: startingPlayerIndex,
                  onChanged: (value) {
                    setState(() {
                      startingPlayerIndex = value!;
                    });
                  },
                );
              }),
            ),

            const Spacer(),

            // ✅ Start button
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              child: const Text('START GAME', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
