import 'package:flutter/material.dart';
import '../../domain/models/player_in_match.dart';

class MatchSummaryScreen extends StatelessWidget {
  final List<PlayerInMatch> players;

  const MatchSummaryScreen({super.key, required this.players});

  String _getRankName(int rashers) {
    const ranks = ['Oinker', 'Piglet', 'Porker', 'Boar', 'Hog', 'Top Hog'];
    return ranks[rashers.clamp(0, 5)];
  }

  String _getMedal(int index) {
    switch (index) {
      case 0:
        return '🥇';
      case 1:
        return '🥈';
      case 2:
        return '🥉';
      case 3:
        return '💩';
      default:
        return '#${index + 1}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = [...players];
    sortedPlayers.sort((a, b) => b.rashersWon.compareTo(a.rashersWon));

    return Scaffold(
      appBar: AppBar(title: const Text('Match Summary')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: sortedPlayers.asMap().entries.map((entry) {
          final index = entry.key;
          final p = entry.value;

          return Card(
            color: index == 0
                ? Colors
                      .amber
                      .shade100 // ✅ winner highlight
                : null,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getMedal(index)} ${p.alias} (${_getRankName(p.rashersWon)})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text('🥓 Rashers: ${p.rashersWon}'),
                  Text('🎯 +1 Points: ${p.basicPointsScored}'),
                  Text('🐾 Trotter Points: ${p.totalTrotterBonusPoints}'),
                  Text(
                    '🎲 Saves: ${p.savesPassed} passed / ${p.savesFailed} failed',
                  ),
                  Text(
                    '✨ Chance for Glory: ${p.gloryWins} won / ${p.gloryFails} missed',
                  ),
                  Text('🏆 Streaky Bacon: ${p.streakyBaconCount}'),
                  Text(
                    '🐽 Golden Oink: ${p.goldenOink ? "✅ YES!" : "❌"}',
                    style: TextStyle(
                      fontWeight: p.goldenOink
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: p.goldenOink
                          ? Colors.purple.shade700
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
