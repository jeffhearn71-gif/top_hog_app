import '../enums/pending_d20_type.dart';

class RollResolution {
  final int normalPoints;
  final int trotterBonus;
  final PendingD20Type pendingD20Type;
  final bool immediateBust;
  final bool immediateWinCheck;
  final String label;

  const RollResolution({
    required this.normalPoints,
    required this.trotterBonus,
    required this.pendingD20Type,
    required this.immediateBust,
    required this.immediateWinCheck,
    required this.label,
  });

  int get totalPoints => normalPoints + trotterBonus;
}

class TopHogRuleEngine {
  RollResolution resolve2d6(int first, int second) {
    final key = '$first.$second';

    switch (key) {
      // ✅ Trotters

      case '1.1':
        return const RollResolution(
          normalPoints: 1,
          trotterBonus: 1,
          pendingD20Type: PendingD20Type.none,
          immediateBust: false,
          immediateWinCheck: false,
          label: 'Trotter',
        );

      case '2.2':
        return const RollResolution(
          normalPoints: 1,
          trotterBonus: 1,
          pendingD20Type: PendingD20Type.positiveSave,
          immediateBust: false,
          immediateWinCheck: false,
          label: 'Trotter (Positive Save)',
        );

      case '3.3':
      case '4.4':
        return const RollResolution(
          normalPoints: 1,
          trotterBonus: 2,
          pendingD20Type: PendingD20Type.none,
          immediateBust: false,
          immediateWinCheck: false,
          label: 'Trotter',
        );

      case '5.5':
        return const RollResolution(
          normalPoints: 1,
          trotterBonus: 3,
          pendingD20Type: PendingD20Type.none,
          immediateBust: false,
          immediateWinCheck: false,
          label: 'Trotter',
        );

      case '6.6':
        return const RollResolution(
          normalPoints: 1,
          trotterBonus: 3,
          pendingD20Type: PendingD20Type.winningChance,
          immediateBust: false,
          immediateWinCheck: true,
          label: 'Trotter (Winning Chance)',
        );

      // ✅ Bust cases

      case '1.3':
      case '3.1':
      case '5.6':
      case '6.5':
        return const RollResolution(
          normalPoints: 0,
          trotterBonus: 0,
          pendingD20Type: PendingD20Type.negativeSave,
          immediateBust: false,
          immediateWinCheck: false,
          label: 'Bust',
        );

      // ✅ Default = 1 point

      default:
        return const RollResolution(
          normalPoints: 1,
          trotterBonus: 0,
          pendingD20Type: PendingD20Type.none,
          immediateBust: false,
          immediateWinCheck: false,
          label: 'Standard point',
        );
    }
  }

  // ✅ Saving throws

  bool survivesNegativeSave(int d20) => d20 == 4 || d20 == 11 || d20 == 20;

  bool survivesPositiveSave(int d20) => d20 != 1 && d20 != 4 && d20 != 11;

  bool winsOnWinningChance(int d20) {
    return d20 == 20;
  }
}
