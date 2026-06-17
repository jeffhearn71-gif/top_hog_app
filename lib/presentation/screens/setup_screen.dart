import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';

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
  late List<int> playOrder;

  final defaultNames = ['Jeff', 'Keira', 'Meredith', 'Dan'];
  late List<TextEditingController> controllers;

  String _suffix(int n) {
    if (n == 1) return 'st';
    if (n == 2) return 'nd';
    if (n == 3) return 'rd';
    return 'th';
  }

  @override
  void initState() {
    super.initState();

    // Default play order for up to 4 players.
    playOrder = List.generate(4, (index) => index);

    controllers = List.generate(
      4,
      (index) => TextEditingController(text: defaultNames[index]),
    );
  }

  Future<void> _playEventSound(String fileName) async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      debugPrint('Sound error: $e');
    }
  }

  void _startGame() {
    final players = List.generate(playerCount, (position) {
      final playerIndex = playOrder[position];

      return PlayerInMatch(
        trueId: 'local_${DateTime.now().millisecondsSinceEpoch}_$playerIndex',
        alias: controllers[playerIndex].text.trim().isEmpty
            ? defaultNames[playerIndex]
            : controllers[playerIndex].text.trim(),
        playOrder: position + 1,
      );
    });

    final matchState = MatchState(
      players: players,
      activePlayerIndex: 0,
      phase: GamePhase.startTurn,
      currentSet: SetState(setNumber: 1),
    );

    final controller = GameController(state: matchState);

    // Start the first turn before navigating
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

            Image.asset('assets/icons/app_icon.png', height: 120),

            const SizedBox(height: 16),

            // Player count
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [2, 3, 4].map((count) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: () {
                      _playEventSound('button_click.mp3');

                      setState(() {
                        playerCount = count;

                        // Reset play order to a valid default for the selected player count
                        playOrder = List.generate(count, (index) => index);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: playerCount == count
                          ? Colors.orange
                          : Colors.grey,
                    ),
                    child: Text('$count Players'),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Name inputs
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

            const Text(
              'Choose Playing Order',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            Column(
              children: List.generate(playerCount, (position) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${position + 1}${_suffix(position + 1)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    DropdownButton<int>(
                      value: playOrder[position],
                      items: List.generate(playerCount, (playerIndex) {
                        return DropdownMenuItem<int>(
                          value: playerIndex,
                          child: Text(
                            controllers[playerIndex].text.isEmpty
                                ? 'Player ${playerIndex + 1}'
                                : controllers[playerIndex].text,
                          ),
                        );
                      }),
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          final otherIndex = playOrder.indexOf(value);

                          // If this player is already selected elsewhere → swap
                          if (otherIndex != -1 && otherIndex != position) {
                            final temp = playOrder[position];
                            playOrder[position] = value;
                            playOrder[otherIndex] = temp;
                          } else {
                            playOrder[position] = value;
                          }
                        });
                      },
                    ),
                  ],
                );
              }),
            ),

            const Spacer(),

            // Start button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size.fromHeight(60),
                elevation: 10,
              ),
              onPressed: () {
                _playEventSound('start_button.mp3');
                _startGame();
              },
              child: const Text(
                'START GAME',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
