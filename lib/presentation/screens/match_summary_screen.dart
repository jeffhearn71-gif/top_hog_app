import 'package:flutter/material.dart';
import '../../domain/models/player_in_match.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MatchSummaryScreen extends StatelessWidget {
  final List<PlayerInMatch> players;

  const MatchSummaryScreen({super.key, required this.players});

  String _getRankName(int rashers) {
    const ranks = ['Oinker', 'Piglet', 'Porker', 'Boar', 'Hog', 'Top Hog'];
    return ranks[rashers.clamp(0, 5)];
  }

  String _getRankAsset(int rashers) {
    final index = rashers.clamp(0, 5);

    const assets = [
      'assets/icons/rank0_oinker.svg',
      'assets/icons/rank1_piglet.svg',
      'assets/icons/rank2_porker.svg',
      'assets/icons/rank3_boar.svg',
      'assets/icons/rank4_hog.svg',
      'assets/icons/rank5_top_hog.svg',
    ];

    return assets[index];
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
                  Row(
                    children: [
                      Text(
                        _getMedal(index),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),

                      SvgPicture.asset(_getRankAsset(p.rashersWon), height: 22),

                      const SizedBox(width: 6),

                      Text(
                        '${p.alias} (${_getRankName(p.rashersWon)})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      children: [
                        const TextSpan(text: '🥓 Rashers: '),
                        TextSpan(
                          text: '${p.rashersWon}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      children: [
                        const TextSpan(text: '🎯 +1 Points: '),
                        TextSpan(
                          text: '${p.basicPointsScored}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      children: [
                        const TextSpan(text: '🐾 Trotter Points: '),
                        TextSpan(
                          text: '${p.totalTrotterBonusPoints}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      children: [
                        const TextSpan(text: '🎲 Saving Throws Won: '),
                        TextSpan(
                          text:
                              '${p.savesPassed} of ${p.savesPassed + p.savesFailed}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      children: [
                        const TextSpan(text: '✨ Chances for Glory Won: '),
                        TextSpan(
                          text:
                              '${p.gloryWins} of ${p.gloryWins + p.gloryFails}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      children: [
                        const TextSpan(text: '🏆 Streaky Bacon: '),
                        TextSpan(
                          text: '${p.streakyBaconCount}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      children: [
                        const TextSpan(text: '🐽 Golden Oink: '),
                        TextSpan(
                          text: p.goldenOink ? '✅' : '❌',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
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
