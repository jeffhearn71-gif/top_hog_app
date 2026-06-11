class PlayerInMatch {
  final String trueId;
  String alias;

  int playOrder;

  // Rashers (sets)
  int rashersWon;

  // Current set progress
  int setBankedScore;
  bool hasWonCurrentSet;

  // Tiebreak + stats
  int streakyBaconCount;
  int totalTrotterBonusPoints;

  // Negative achievement
  bool goldenOink;

  PlayerInMatch({
    required this.trueId,
    required this.alias,
    required this.playOrder,
    this.rashersWon = 0,
    this.setBankedScore = 0,
    this.hasWonCurrentSet = false,
    this.streakyBaconCount = 0,
    this.totalTrotterBonusPoints = 0,
    this.goldenOink = false,
  });
}
