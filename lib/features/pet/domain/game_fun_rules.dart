class GameFunRules {
  const GameFunRules({
    required this.mediumScoreThreshold,
    required this.highScoreThreshold,
    this.completionReward = 1.0,
    this.mediumBonus = 1.0,
    this.highBonus = 2.0,
    this.maximumReward = 3.0,
  }) : assert(mediumScoreThreshold >= 0),
       assert(highScoreThreshold > mediumScoreThreshold),
       assert(completionReward >= 0.0),
       assert(mediumBonus >= 0.0),
       assert(highBonus >= mediumBonus),
       assert(maximumReward >= 0.0);

  final int mediumScoreThreshold;
  final int highScoreThreshold;
  final double completionReward;
  final double mediumBonus;
  final double highBonus;
  final double maximumReward;
}
