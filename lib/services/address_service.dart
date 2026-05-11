import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
}

class AddressService {
  // Usar Geoapify API - Reverse Geocoding gratuito com bom rate limit
  static const String _geoapifyUrl = 'https://api.geoapify.com/v1/geocode';
  static const String _apiKey = '602b6e2908704777bc047e4ebcaba003';
  
  // Cache para endereços já geocodificados
  static final Map<String, AddressSuggestion> _geocodeCache = {};
  
  // Controle de taxa para respeitar rate limiting
  static DateTime? _lastRequestTime;
  static const Duration _requestDelay = Duration(milliseconds: 300); // Geoapify é mais rápido

  /// Aguardar antes de fazer nova requisição (respeita rate limiting)
  Future<void> _respectRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _requestDelay) {
        final waitTime = _requestDelay - timeSinceLastRequest;
        await Future.delayed(waitTime);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  /// Buscar sugestões de lugares usando Geoapify - GRATUITO e SEM RATE LIMIT AGRESSIVO
  Future<List<String>> getPlacePredictions(String input) async {
    if (input.isEmpty) {
      return [];
    }

    try {
      // Aguardar para respeitar rate limiting
      await _respectRateLimit();

      // Usar Geoapify Search API (gratuito com boa cota)
      final String url =
          '$_geoapifyUrl/search?text=$input&apiKey=$_apiKey&countrycodes=br&limit=10';

      debugPrint('📍 Buscando endereços: $input');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'SinalVerde-App/1.0 (Flutter)',
          'Accept-Language': 'pt-BR',
        },
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('❌ Timeout ao buscar endereços');
          return http.Response('', 408);
        },
      );

      debugPrint('✅ Status: ${response.statusCode}');

      // Tratamento de rate limiting
      if (response.statusCode == 429) {
        debugPrint('⚠️ Rate limit atingido. Aguardando antes de tentar novamente...');
        await Future.delayed(const Duration(seconds: 2));
        return [];
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final features = json['features'] as List<dynamic>? ?? [];
        
        final suggestions = features
            .map((feature) {
              try {
                final properties = feature['properties'] as Map<String, dynamic>?;
                if (properties == null) return '';
                
                // Construir nome do endereço a partir das propriedades
                final address = properties['address_line1'] as String? ?? '';
                final city = properties['city'] as String? ?? '';
                final state = properties['state'] as String? ?? '';
                
                final parts = <String>[address, city, state]
                    .where((p) => p.isNotEmpty)
                    .join(', ');
                
                return parts.isEmpty ? '' : parts;
              } catch (e) {
                return '';
              }
            })
            .where((desc) => desc.isNotEmpty)
            .toList();

        debugPrint('✅ Encontrado ${suggestions.length} sugestões');
        return suggestions;
      } else {
        debugPrint('❌ Erro na resposta: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Erro getting place predictions: $e');
      return [];
    }
  }

  /// Converter endereço/cidade em coordenadas (lat/lng) usando Geoapify
  Future<AddressSuggestion?> geocodeAddress(String address) async {
    if (address.isEmpty) {
      return null;
    }

    try {
      // Aguardar para respeitar rate limiting
      await _respectRateLimit();

      // Usar Geoapify Search API (gratuito com boa cota)
      final String url =
          '$_geoapifyUrl/search?text=$address&apiKey=$_apiKey&countrycodes=br&limit=1';

      debugPrint('🔍 Geocodificando: $address');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'SinalVerde-App/1.0 (Flutter)',
          'Accept-Language': 'pt-BR',
        },
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('❌ Timeout ao geocodificar');
          return http.Response('', 408);
        },
      );

      // Tratamento de rate limiting
      if (response.statusCode == 429) {
        debugPrint('⚠️ Rate limit atingido. Aguardando antes de tentar novamente...');
        await Future.delayed(const Duration(seconds: 2));
        return null;
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final features = json['features'] as List<dynamic>? ?? [];

        if (features.isNotEmpty) {
          final firstFeature = features[0];
          final properties = firstFeature['properties'] as Map<String, dynamic>?;
          final geometry = firstFeature['geometry'] as Map<String, dynamic>?;
          
          if (properties != null && geometry != null) {
            final coordinates = geometry['coordinates'] as List<dynamic>?;
            
            if (coordinates != null && coordinates.length >= 2) {
              final lat = (coordinates[1] as num).toDouble();
              final lon = (coordinates[0] as num).toDouble();
              
              final addressLine1 = properties['address_line1'] as String? ?? '';
              final city = properties['city'] as String? ?? '';
              final state = properties['state'] as String? ?? '';
              
              final displayName = <String>[addressLine1, city, state]
                  .where((p) => p.isNotEmpty)
                  .join(', ');

              debugPrint('✅ Geocodificado: $displayName ($lat, $lon)');

              return AddressSuggestion(
                displayName: displayName.isNotEmpty ? displayName : address,
                latitude: lat,
                longitude: lon,
              );
            }
          }
        }
        
        debugPrint('❌ Nenhum resultado encontrado para: $address');
        return null;
      } else {
        debugPrint('❌ Erro na geocodificação: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erro geocoding address: $e');
      return null;
    }
  }

  /// Limpar cache de geocodificação
  void clearCache() {
    _geocodeCache.clear();
    debugPrint('🗑️ Cache de geocodificação limpo');
  }

  /// Obter tamanho do cache
  int getCacheSize() {
    return _geocodeCache.length;
  }

  /// Converter coordenadas em endereço (reverse geocoding) usando Geoapify
  Future<AddressSuggestion?> reverseGeocodeCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Criar chave de cache com precisão de 4 casas decimais (~11m)
      final cacheKey = '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
      
      // Verificar se já está em cache
      if (_geocodeCache.containsKey(cacheKey)) {
        debugPrint('💾 Resultado em cache para: $cacheKey');
        return _geocodeCache[cacheKey];
      }

      // Aguardar para respeitar rate limiting
      await _respectRateLimit();

      // Usar Geoapify Reverse Geocoding API
      final String url =
          '$_geoapifyUrl/reverse?lat=$latitude&lon=$longitude&apiKey=$_apiKey';

      debugPrint('🔄 Reverse Geocoding: ($latitude, $longitude)');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'SinalVerde-App/1.0 (Flutter)',
          'Accept-Language': 'pt-BR',
        },
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('❌ Timeout ao fazer reverse geocoding');
          return http.Response('', 408);
        },
      );

      // Tratamento de rate limiting
      if (response.statusCode == 429) {
        debugPrint('⚠️ Rate limit atingido. Aguardando antes de tentar novamente...');
        await Future.delayed(const Duration(seconds: 2));
        return null;
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final features = json['features'] as List<dynamic>? ?? [];

        if (features.isNotEmpty) {
          final firstFeature = features[0];
          final properties = firstFeature['properties'] as Map<String, dynamic>?;
          
          if (properties != null) {
            final addressLine1 = properties['address_line1'] as String? ?? '';
            final addressLine2 = properties['address_line2'] as String? ?? '';
            
            final displayName = <String>[addressLine1, addressLine2]
                .where((p) => p.isNotEmpty)
                .join(', ');

            if (displayName.isNotEmpty) {
              final suggestion = AddressSuggestion(
                displayName: displayName,
                latitude: latitude,
                longitude: longitude,
              );
              
              // Armazenar em cache
              _geocodeCache[cacheKey] = suggestion;
              
              debugPrint('✅ Reverse Geocodificado: $displayName');
              return suggestion;
            }
          }
        }

        debugPrint('❌ Nenhum endereço encontrado para: ($latitude, $longitude)');
        return null;
      } else {
        debugPrint('❌ Erro no reverse geocoding: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erro reverse geocoding: $e');
      return null;
    }
  }
}
