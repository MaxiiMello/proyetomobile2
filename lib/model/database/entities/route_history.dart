class RouteHistory {
  final int? id;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final double originLat;
  final double originLng;
  final double destinationLat;
  final double destinationLng;
  final double totalDistanceM;
  final double? totalEstimatedMinutes;
  final double totalScore;
  final int? packageId;

  RouteHistory({
    this.id,
    required this.startedAt,
    this.finishedAt,
    required this.originLat,
    required this.originLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.totalDistanceM,
    this.totalEstimatedMinutes,
    required this.totalScore,
    this.packageId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'started_at': startedAt.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
      'origin_lat': originLat,
      'origin_lng': originLng,
      'destination_lat': destinationLat,
      'destination_lng': destinationLng,
      'total_distance_m': totalDistanceM,
      'total_estimated_minutes': totalEstimatedMinutes,
      'total_score': totalScore,
      'package_id': packageId,
    };
  }

  factory RouteHistory.fromMap(Map<String, dynamic> map) {
    return RouteHistory(
      id: map['id'] as int?,
      startedAt: DateTime.parse(map['started_at'] as String),
      finishedAt: map['finished_at'] != null 
          ? DateTime.parse(map['finished_at'] as String) 
          : null,
      originLat: map['origin_lat'] as double,
      originLng: map['origin_lng'] as double,
      destinationLat: map['destination_lat'] as double,
      destinationLng: map['destination_lng'] as double,
      totalDistanceM: map['total_distance_m'] as double,
      totalEstimatedMinutes: map['total_estimated_minutes'] as double?,
      totalScore: map['total_score'] as double,
      packageId: map['package_id'] as int?,
    );
  }
}