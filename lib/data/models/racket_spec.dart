class RacketSpec {
  const RacketSpec({
    required this.productId,
    required this.weightClass,
    required this.balance,
    required this.shaft,
    required this.maxTensionLbs,
    required this.playerLevel,
    required this.playStyle,
  });

  final int productId;
  final String weightClass;
  final String balance;
  final String shaft;
  final int maxTensionLbs;
  final String playerLevel;
  final String playStyle;

  factory RacketSpec.fromMap(Map<String, Object?> map) {
    return RacketSpec(
      productId: map['product_id'] as int,
      weightClass: map['weight_class'] as String,
      balance: map['balance'] as String,
      shaft: map['shaft'] as String,
      maxTensionLbs: map['max_tension_lbs'] as int,
      playerLevel: map['player_level'] as String,
      playStyle: map['play_style'] as String,
    );
  }
}
