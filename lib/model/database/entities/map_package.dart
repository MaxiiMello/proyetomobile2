class MapPackage {
  final int? id;
  final String cityCode;
  final String cityName;
  final String? regionName;
  final String dataVersion;
  final String mbtilesPath;
  final String graphPath;
  final bool isPremium;
  final DateTime installedAt;
  final DateTime updatedAt;

  MapPackage({
    this.id,
    required this.cityCode,
    required this.cityName,
    this.regionName,
    required this.dataVersion,
    required this.mbtilesPath,
    required this.graphPath,
    this.isPremium = false,
    required this.installedAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'city_code': cityCode,
      'city_name': cityName,
      'region_name': regionName,
      'data_version': dataVersion,
      'mbtiles_path': mbtilesPath,
      'graph_path': graphPath,
      'is_premium': isPremium ? 1 : 0,
      'installed_at': installedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MapPackage.fromMap(Map<String, dynamic> map) {
    return MapPackage(
      id: map['id'] as int?,
      cityCode: map['city_code'] as String,
      cityName: map['city_name'] as String,
      regionName: map['region_name'] as String?,
      dataVersion: map['data_version'] as String,
      mbtilesPath: map['mbtiles_path'] as String,
      graphPath: map['graph_path'] as String,
      isPremium: (map['is_premium'] as int) == 1,
      installedAt: DateTime.parse(map['installed_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}