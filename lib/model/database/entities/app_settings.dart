class AppSettings {
  final int? id;
  final String routeMode;
  final double trafficLightPenalty;
  final double dirtRoadPenalty;
  final double cobblestonePenalty;
  final double asphaltBonus;
  final DateTime updatedAt;

  AppSettings({
    this.id = 1,
    this.routeMode = 'smooth',
    this.trafficLightPenalty = 35.0,
    this.dirtRoadPenalty = 20.0,
    this.cobblestonePenalty = 10.0,
    this.asphaltBonus = 15.0,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'route_mode': routeMode,
      'traffic_light_penalty': trafficLightPenalty,
      'dirt_road_penalty': dirtRoadPenalty,
      'cobblestone_penalty': cobblestonePenalty,
      'asphalt_bonus': asphaltBonus,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'] as int?,
      routeMode: map['route_mode'] as String,
      trafficLightPenalty: map['traffic_light_penalty'] as double,
      dirtRoadPenalty: map['dirt_road_penalty'] as double,
      cobblestonePenalty: map['cobblestone_penalty'] as double,
      asphaltBonus: map['asphalt_bonus'] as double,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}