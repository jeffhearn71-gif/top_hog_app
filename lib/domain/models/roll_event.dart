class RollEvent {
  final int? d6a;
  final int? d6b;
  final int? d20;

  final String outcomeLabel;

  final int normalPointsAwarded;
  final int trotterBonusAwarded;

  final bool survived;
  final bool busted;

  RollEvent({
    this.d6a,
    this.d6b,
    this.d20,
    required this.outcomeLabel,
    this.normalPointsAwarded = 0,
    this.trotterBonusAwarded = 0,
    this.survived = true,
    this.busted = false,
  });
}
