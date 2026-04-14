class AppRoutingSettings {
  const AppRoutingSettings({
    required this.routeMode,
    required this.trafficLightPenalty,
    required this.dirtRoadPenalty,
    required this.cobblestonePenalty,
    required this.asphaltBonus,
    required this.updatedAt,
  });

  final String routeMode;
  final double trafficLightPenalty;
  final double dirtRoadPenalty;
  final double cobblestonePenalty;
  final double asphaltBonus;
  final DateTime updatedAt;

  factory AppRoutingSettings.fromMap(Map<String, Object?> map) {
    return AppRoutingSettings(
      routeMode: map['route_mode'] as String,
      trafficLightPenalty: (map['traffic_light_penalty'] as num).toDouble(),
      dirtRoadPenalty: (map['dirt_road_penalty'] as num).toDouble(),
      cobblestonePenalty: (map['cobblestone_penalty'] as num).toDouble(),
      asphaltBonus: (map['asphalt_bonus'] as num).toDouble(),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
