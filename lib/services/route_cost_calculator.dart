import '../models/app_routing_settings.dart';

class RouteCostCalculator {
  static double segmentCost({
    required double distanceMeters,
    required String surfaceType,
    required int trafficLightCount,
    required AppRoutingSettings settings,
  }) {
    var score = distanceMeters;

    if (surfaceType == 'dirt') {
      score += settings.dirtRoadPenalty;
    } else if (surfaceType == 'cobblestone') {
      score += settings.cobblestonePenalty;
    } else if (surfaceType == 'asphalt') {
      score -= settings.asphaltBonus;
    }

    score += trafficLightCount * settings.trafficLightPenalty;

    if (score < 0) {
      return 0;
    }
    return score;
  }
}
