class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);
}

class RoadGeometry {
  final String id;
  final String name;
  final List<GeoPoint> coordinates;
  final String surfaceType;
  final bool oneWay;
  final int speedLimitKmh;
  final bool hasTrafficLight;

  const RoadGeometry({
    required this.id,
    required this.name,
    required this.coordinates,
    this.surfaceType = 'asfalto',
    this.oneWay = false,
    this.speedLimitKmh = 50,
    this.hasTrafficLight = false,
  });
}
