class RoadSegment {
  final int? id;
  final int packageId;
  final int fromIntersectionId;
  final int toIntersectionId;
  final String? name;
  final double distanceM;
  final double? speedLimitKmh;
  final bool isOneWay;
  final String surfaceType;
  final int trafficLightCount;
  final double baseWeight;

  RoadSegment({
    this.id,
    required this.packageId,
    required this.fromIntersectionId,
    required this.toIntersectionId,
    this.name,
    required this.distanceM,
    this.speedLimitKmh,
    this.isOneWay = false,
    required this.surfaceType,
    this.trafficLightCount = 0,
    this.baseWeight = 1.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'package_id': packageId,
      'from_intersection_id': fromIntersectionId,
      'to_intersection_id': toIntersectionId,
      'name': name,
      'distance_m': distanceM,
      'speed_limit_kmh': speedLimitKmh,
      'is_one_way': isOneWay ? 1 : 0,
      'surface_type': surfaceType,
      'traffic_light_count': trafficLightCount,
      'base_weight': baseWeight,
    };
  }

  factory RoadSegment.fromMap(Map<String, dynamic> map) {
    return RoadSegment(
      id: map['id'] as int?,
      packageId: map['package_id'] as int,
      fromIntersectionId: map['from_intersection_id'] as int,
      toIntersectionId: map['to_intersection_id'] as int,
      name: map['name'] as String?,
      distanceM: map['distance_m'] as double,
      speedLimitKmh: map['speed_limit_kmh'] as double?,
      isOneWay: (map['is_one_way'] as int) == 1,
      surfaceType: map['surface_type'] as String,
      trafficLightCount: map['traffic_light_count'] as int,
      baseWeight: map['base_weight'] as double,
    );
  }
}