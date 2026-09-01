class GameCostPolicy {
  const GameCostPolicy({
    required this.gameId,
    required this.energyCost,
    required this.cleanlinessCost,
  }) : assert(gameId != ''),
       assert(energyCost >= 0.0),
       assert(cleanlinessCost >= 0.0);

  static const GameCostPolicy none = GameCostPolicy(
    gameId: 'none',
    energyCost: 0.0,
    cleanlinessCost: 0.0,
  );

  final String gameId;
  final double energyCost;
  final double cleanlinessCost;

  void validate() {
    if (gameId.trim().isEmpty) {
      throw ArgumentError.value(gameId, 'gameId', 'No puede estar vacío.');
    }
    _validateCost(energyCost, 'energyCost');
    _validateCost(cleanlinessCost, 'cleanlinessCost');
  }

  static void _validateCost(double value, String name) {
    if (!value.isFinite || value < 0.0) {
      throw ArgumentError.value(
        value,
        name,
        'Debe ser un número finito mayor o igual que cero.',
      );
    }
  }
}
