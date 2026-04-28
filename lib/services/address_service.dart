import 'dart:convert';
import 'package:http/http.dart' as http;

class AddressSuggestion {
  final String displayName;
  final double latitude;
  final double longitude;

  AddressSuggestion({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  factory AddressSuggestion.fromGooglePlace(Map<String, dynamic> json) {
    try {
      final geometry = json['geometry'] ?? {};
      final location = geometry['location'] ?? {};
      
      return AddressSuggestion(
        displayName: json['formatted_address'] ?? '',
        latitude: (location['lat'] ?? 0.0).toDouble(),
        longitude: (location['lng'] ?? 0.0).toDouble(),
      );
    } catch (e) {
      return AddressSuggestion(
        displayName: '',
        latitude: 0,
        longitude: 0,
      );
    }
  }
}

class AddressService {
  static const String _apiKey = 'AIzaSyDwM_q0d1ECZwb5rY8uaLiDMuFhOUpEZM0';
  static const String _geocodingUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
  static const String _placesUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';

  /// Buscar sugestões de lugares enquanto o usuário digita
  Future<List<String>> getPlacePredictions(String input) async {
    if (input.isEmpty) {
      return [];
    }

    try {
      final String url =
          '$_placesUrl?input=$input&key=$_apiKey&language=pt-BR&region=BR&components=country:br';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
        onTimeout: () => http.Response('', 408),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final predictions = json['predictions'] as List<dynamic>? ?? [];
        
        return predictions
            .map((p) => p['description'] as String? ?? '')
            .where((desc) => desc.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting place predictions: $e');
      return [];
    }
  }

  /// Converter endereço/cidade em coordenadas (lat/lng)
  Future<AddressSuggestion?> geocodeAddress(String address) async {
    if (address.isEmpty) {
      return null;
    }

    try {
      final String url =
          '$_geocodingUrl?address=$address&key=$_apiKey&language=pt-BR&region=BR';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
        onTimeout: () => http.Response('', 408),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final results = json['results'] as List<dynamic>? ?? [];

        if (results.isNotEmpty) {
          final firstResult = results[0];
          return AddressSuggestion.fromGooglePlace(firstResult);
        }
      }
      return null;
    } catch (e) {
      print('Error geocoding address: $e');
      return null;
    }
  }
}
