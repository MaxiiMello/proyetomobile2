import 'dart:math';

/// Representa uma rua no grafo da cidade
class Rua {
  final String origem;
  final String destino;
  final double distancia; // em metros
  final String tipoVia; // "asfalto" ou "terra"
  bool temSemaforo; // pode mudar (simulação)
  double peso; // tempo em segundos

  Rua({
    required this.origem,
    required this.destino,
    required this.distancia,
    required this.tipoVia,
    required this.temSemaforo,
  }) : peso = _calcularPeso(
    distancia: distancia,
    tipoVia: tipoVia,
    temSemaforo: temSemaforo,
  );

  /// Calcula o peso (tempo) baseado no tipo de via e semáforo
  static double _calcularPeso({
    required double distancia,
    required String tipoVia,
    bool temSemaforo = false,
  }) {
    // Velocidade em m/s
    double velocidade = tipoVia == "terra" ? 8.3 : 13.9; // 30 km/h ou 50 km/h
    double tempo = distancia / velocidade;
    if (temSemaforo) tempo += 20.0; // segundos de espera média em semáforo
    return tempo;
  }

  /// Recalcula o peso se o estado mudar
  void recalcularPeso() {
    peso = _calcularPeso(
      distancia: distancia,
      tipoVia: tipoVia,
      temSemaforo: temSemaforo,
    );
  }

  /// Retorna a cor da rua para visualização
  int getCor() {
    if (tipoVia == "asfalto") return 0xFF1a1a1a; // Preto
    return 0xFFFFA500; // Laranja
  }
}

/// Representa um nó (cruzamento) no grafo
class NoRota {
  final String id;
  final double latitude;
  final double longitude;
  final Map<String, Rua> conexoes = {};

  NoRota(this.id, this.latitude, this.longitude);

  /// Distância Euclidiana para heurística do A*
  double distancia(NoRota outro) {
    return sqrt(
      pow(latitude - outro.latitude, 2) + pow(longitude - outro.longitude, 2)
    );
  }
}

/// Registro de exploração durante o algoritmo
class PassoExploracao {
  final String deId;
  final String paraId;

  PassoExploracao(this.deId, this.paraId);
}

/// Resultado final da rota calculada
class ResultadoRota {
  final String algoritmo; // "A*" ou "Dijkstra"
  final List<String> caminhoFinal; // IDs dos nós na rota
  final List<PassoExploracao> historiaExploracao; // Nós explorados
  final double custoTotal; // tempo em segundos
  final double tempoMinutos; // tempo em minutos
  final int semaforosNoCaminho; // quantidade de semáforos
  final double distanciaMetros; // distância real em metros

  ResultadoRota({
    required this.algoritmo,
    required this.caminhoFinal,
    required this.historiaExploracao,
    required this.custoTotal,
    required this.semaforosNoCaminho,
    required this.distanciaMetros,
  }) : tempoMinutos = custoTotal / 60.0;

  /// Calcula a distância total em km
  double get distanciaKm => distanciaMetros / 1000;

  bool get temRota => caminhoFinal.isNotEmpty;
}

/// Dados da rota para exibição na UI
class DadosRota {
  final String tempoFormatado; // "2 min 30s"
  final String distancia; // "5.2 km"
  final int semaforosNosCaminho;
  final double custoTotal;
  final List<String> caminhoFinal;

  DadosRota({
    required this.tempoFormatado,
    required this.distancia,
    required this.semaforosNosCaminho,
    required this.custoTotal,
    required this.caminhoFinal,
  });

  factory DadosRota.doResultado(ResultadoRota resultado) {
    int minutos = resultado.tempoMinutos.toInt();
    int segundos = ((resultado.tempoMinutos - minutos) * 60).toInt();
    
    return DadosRota(
      tempoFormatado: '$minutos min ${segundos}s',
      distancia: '${resultado.distanciaKm.toStringAsFixed(1)} km',
      semaforosNosCaminho: resultado.semaforosNoCaminho,
      custoTotal: resultado.custoTotal,
      caminhoFinal: resultado.caminhoFinal,
    );
  }
}
