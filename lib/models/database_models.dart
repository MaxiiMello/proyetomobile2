/// Modelos para armazenamento local de dados de ruas e nós do grafo
library;

class RuaBD {
  final String id;
  final String nome;
  final double lat1;
  final double lon1;
  final double lat2;
  final double lon2;
  final double distanciaMetros;
  final String tipo; // asfalto, terra, paralelepípedo, etc
  final bool temSemafo;
  final int velocidadekmh;
  final bool oneWay;
  final String tileId; // identificador do quadro geográfico

  RuaBD({
    required this.id,
    required this.nome,
    required this.lat1,
    required this.lon1,
    required this.lat2,
    required this.lon2,
    required this.distanciaMetros,
    required this.tipo,
    required this.temSemafo,
    required this.velocidadekmh,
    this.oneWay = false,
    required this.tileId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'lat1': lat1,
      'lon1': lon1,
      'lat2': lat2,
      'lon2': lon2,
      'distanciaMetros': distanciaMetros,
      'tipo': tipo,
      'temSemafo': temSemafo ? 1 : 0,
      'velocidadekmh': velocidadekmh,
      'oneWay': oneWay ? 1 : 0,
      'tileId': tileId,
    };
  }

  factory RuaBD.fromMap(Map<String, dynamic> map) {
    return RuaBD(
      id: map['id'] as String,
      nome: map['nome'] as String,
      lat1: map['lat1'] as double,
      lon1: map['lon1'] as double,
      lat2: map['lat2'] as double,
      lon2: map['lon2'] as double,
      distanciaMetros: map['distanciaMetros'] as double,
      tipo: map['tipo'] as String,
      temSemafo: (map['temSemafo'] as int) == 1,
      velocidadekmh: map['velocidadekmh'] as int,
      oneWay: ((map['oneWay'] as num?) ?? 0).toInt() == 1,
      tileId: map['tileId'] as String,
    );
  }
}

class NoInterseccaoDB {
  final String id;
  final double latitude;
  final double longitude;
  final List<String> ruasConectadas; // IDs das ruas que passam por este nó
  final String tileId;

  NoInterseccaoDB({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.ruasConectadas,
    required this.tileId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'ruasConectadas': ruasConectadas.join(','), // serializar como string
      'tileId': tileId,
    };
  }

  factory NoInterseccaoDB.fromMap(Map<String, dynamic> map) {
    return NoInterseccaoDB(
      id: map['id'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      ruasConectadas:
          (map['ruasConectadas'] as String).split(',').where((r) => r.isNotEmpty).toList(),
      tileId: map['tileId'] as String,
    );
  }
}

class QuadroGeografico {
  final String id; // formato: lat,lon (centro do tile)
  final double latitudeCentro;
  final double longitudeCentro;
  final double raioKm;
  final DateTime dataDownload;
  final bool completo; // se o quadro foi completamente baixado

  QuadroGeografico({
    required this.id,
    required this.latitudeCentro,
    required this.longitudeCentro,
    required this.raioKm,
    required this.dataDownload,
    required this.completo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitudeCentro': latitudeCentro,
      'longitudeCentro': longitudeCentro,
      'raioKm': raioKm,
      'dataDownload': dataDownload.toIso8601String(),
      'completo': completo ? 1 : 0,
    };
  }

  factory QuadroGeografico.fromMap(Map<String, dynamic> map) {
    return QuadroGeografico(
      id: map['id'] as String,
      latitudeCentro: map['latitudeCentro'] as double,
      longitudeCentro: map['longitudeCentro'] as double,
      raioKm: map['raioKm'] as double,
      dataDownload: DateTime.parse(map['dataDownload'] as String),
      completo: (map['completo'] as int) == 1,
    );
  }
}
