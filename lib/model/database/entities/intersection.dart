class Intersection {
  final int? id;
  final int packageId;
  final double latitude;
  final double longitude;
  final bool hasTrafficLight;
  final double trafficLightPenalty;

  Intersection({
    this.id,
    required this.packageId,
    required this.latitude,
    required this.longitude,
    this.hasTrafficLight = false,
    this.trafficLightPenalty = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'package_id': packageId,
      'latitude': latitude,
      'longitude': longitude,
      'has_traffic_light': hasTrafficLight ? 1 : 0,
      'traffic_light_penalty': trafficLightPenalty,
    };
  }

  factory Intersection.fromMap(Map<String, dynamic> map) {
    return Intersection(
      id: map['id'] as int?,
      packageId: map['package_id'] as int,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      hasTrafficLight: (map['has_traffic_light'] as int) == 1,
      trafficLightPenalty: map['traffic_light_penalty'] as double,
    );
  }
}