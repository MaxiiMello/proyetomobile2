import '../models/route_models.dart';

class RoutingService {
  final Map<String, NoRota> grafo = {};

  /// Adicionar um nó ao grafo
  void adicionarNo(NoRota no) {
    grafo[no.id] = no;
  }

  /// Conectar dois nós com uma rua bidirecional
  void conectarRua(Rua rua) {
    NoRota? origem = grafo[rua.origem];
    NoRota? destino = grafo[rua.destino];

    if (origem != null && destino != null) {
      origem.conexoes[rua.destino] = rua;
      
      // Criar rua reversa
      Rua ruaReversa = Rua(
        origem: rua.destino,
        destino: rua.origem,
        distancia: rua.distancia,
        tipoVia: rua.tipoVia,
        temSemaforo: rua.temSemaforo,
      );
      destino.conexoes[rua.origem] = ruaReversa;
    }
  }

  /// Heurística para A* - Distância Euclidiana
  double heuristica(String deId, String paraId) {
    NoRota? de = grafo[deId];
    NoRota? para = grafo[paraId];
    
    if (de == null || para == null) return 0;
    return de.distancia(para);
  }

  /// Algoritmo A* para encontrar a rota otimizada
  /// Considera: tipo de via (asfalto/terra), semáforos e distância
  ResultadoRota executarAEstrela(String inicio, String fim) {
    if (!grafo.containsKey(inicio) || !grafo.containsKey(fim)) {
      return ResultadoRota(
        algoritmo: "A*",
        caminhoFinal: [],
        historiaExploracao: [],
        custoTotal: 0,
        semaforosNoCaminho: 0,
        distanciaMetros: 0,
      );
    }

    var gScore = {for (var id in grafo.keys) id: double.infinity};
    var fScore = {for (var id in grafo.keys) id: double.infinity};
    var veioDe = <String, String>{};
    var openSet = {inicio};
    List<PassoExploracao> historia = [];

    gScore[inicio] = 0;
    fScore[inicio] = heuristica(inicio, fim);

    while (openSet.isNotEmpty) {
      // Encontrar o nó com menor fScore
      var atualId = openSet.reduce((a, b) => fScore[a]! < fScore[b]! ? a : b);

      if (atualId == fim) {
        // Rota encontrada!
        List<String> caminho = _reconstruirCaminho(veioDe, fim);
        int semaforosNoCaminho = _contarSemaforosNoCaminho(caminho);
        double distanciaMetros = calcularDistanciaCaminho(caminho);
        
        return ResultadoRota(
          algoritmo: "A*",
          caminhoFinal: caminho,
          historiaExploracao: historia,
          custoTotal: gScore[fim]!,
          semaforosNoCaminho: semaforosNoCaminho,
          distanciaMetros: distanciaMetros,
        );
      }

      openSet.remove(atualId);

      // Explorar vizinhos
      for (var vizinhoId in grafo[atualId]!.conexoes.keys) {
        historia.add(PassoExploracao(atualId, vizinhoId));

        Rua ruaVizinho = grafo[atualId]!.conexoes[vizinhoId]!;
        double tentativagScore = gScore[atualId]! + ruaVizinho.peso;

        if (tentativagScore < gScore[vizinhoId]!) {
          veioDe[vizinhoId] = atualId;
          gScore[vizinhoId] = tentativagScore;
          fScore[vizinhoId] = gScore[vizinhoId]! + heuristica(vizinhoId, fim);
          openSet.add(vizinhoId);
        }
      }
    }

    // Nenhuma rota encontrada
    return ResultadoRota(
      algoritmo: "A*",
      caminhoFinal: [],
      historiaExploracao: historia,
      custoTotal: double.infinity,
      semaforosNoCaminho: 0,
      distanciaMetros: 0,
    );
  }

  /// Reconstruir o caminho completo a partir do mapa de "veio de"
  List<String> _reconstruirCaminho(Map<String, String> veioDe, String atual) {
    if (!veioDe.containsKey(atual) && !veioDe.containsValue(atual)) {
      return [];
    }
    
    List<String> caminho = [atual];
    while (veioDe.containsKey(atual)) {
      atual = veioDe[atual]!;
      caminho.insert(0, atual);
    }
    return caminho;
  }

  /// Contar semáforos no caminho calculado
  int _contarSemaforosNoCaminho(List<String> caminho) {
    int contador = 0;
    for (int i = 0; i < caminho.length - 1; i++) {
      String deId = caminho[i];
      String paraId = caminho[i + 1];
      
      NoRota? de = grafo[deId];
      if (de != null) {
        Rua? rua = de.conexoes[paraId];
        if (rua != null && rua.temSemaforo) {
          contador++;
        }
      }
    }
    return contador;
  }

  /// Calcular distância total do caminho em metros
  double calcularDistanciaCaminho(List<String> caminho) {
    double distanciaTotal = 0;
    for (int i = 0; i < caminho.length - 1; i++) {
      String deId = caminho[i];
      String paraId = caminho[i + 1];
      
      NoRota? de = grafo[deId];
      if (de != null) {
        Rua? rua = de.conexoes[paraId];
        if (rua != null) {
          distanciaTotal += rua.distancia;
        }
      }
    }
    return distanciaTotal;
  }

  /// Limpar o grafo
  void limpar() {
    grafo.clear();
  }
}
