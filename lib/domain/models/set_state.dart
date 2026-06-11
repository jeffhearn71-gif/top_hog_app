class SetState {
  int setNumber;
  int roundNumber;

  bool closingRoundTriggered;
  int? closingRoundNumber;

  Set<String> setWinners;
  Set<String> playersTakenTurnThisRound;

  SetState({
    required this.setNumber,
    this.roundNumber = 1,
    this.closingRoundTriggered = false,
    this.closingRoundNumber,
    Set<String>? setWinners,
    Set<String>? playersTakenTurnThisRound,
  }) : setWinners = setWinners ?? {},
       playersTakenTurnThisRound = playersTakenTurnThisRound ?? {};
}
