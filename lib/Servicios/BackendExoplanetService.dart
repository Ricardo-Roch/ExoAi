import 'package:http/http.dart' as http;
import 'dart:convert';

class ExoplanetData {
  final String name;
  final double? period;
  final double? duration;
  final double? depth;
  final double? radius;
  final double? insolation;
  final double? teff;
  final double? srad;

  ExoplanetData({
    required this.name,
    this.period,
    this.duration,
    this.depth,
    this.radius,
    this.insolation,
    this.teff,
    this.srad,
  });

  factory ExoplanetData.fromJson(String name, Map<String, dynamic> json) {
    return ExoplanetData(
      name: name,
      period: _parseDouble(json['period']),
      duration: _parseDouble(json['duration']),
      depth: _parseDouble(json['depth']),
      radius: _parseDouble(json['radius']),
      insolation: _parseDouble(json['insolation']),
      teff: _parseDouble(json['teff']),
      srad: _parseDouble(json['srad']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'period': period,
      'duration': duration,
      'depth': depth,
      'radius': radius,
      'insolation': insolation,
      'teff': teff,
      'srad': srad,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}

class BackendExoplanetService {
  static const String baseUrl = 'https://back-exoai.onrender.com';

  /// Verifica el estado del backend
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Backend no disponible: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking health: $e');
      rethrow;
    }
  }

  /// Obtiene preview de los datasets
  Future<Map<String, dynamic>> getDatasetPreview({int n = 5}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/datasets/preview?n=$n'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception(
            'Datasets no disponibles. Se requiere descargar datos primero.');
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching preview: $e');
      rethrow;
    }
  }

  /// Descarga y actualiza los datasets
  Future<Map<String, dynamic>> fetchDatasets({bool autoRetrain = false}) async {
    try {
      String url = '$baseUrl/datasets';
      if (autoRetrain) {
        url += '?auto_retrain=true';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching datasets: $e');
      rethrow;
    }
  }

  /// Obtiene el estado del entrenamiento
  Future<Map<String, dynamic>> getTrainStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/train/status'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Error ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching train status: $e');
      rethrow;
    }
  }

  /// Realiza una predicción individual
  Future<Map<String, dynamic>> predictOne(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Modelo no encontrado. Se requiere entrenar primero.');
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error predicting: $e');
      rethrow;
    }
  }

  /// Realiza predicciones en batch
  Future<Map<String, dynamic>> predictBatch(
      List<Map<String, dynamic>> dataList) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dataList),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Modelo no encontrado. Se requiere entrenar primero.');
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error predicting batch: $e');
      rethrow;
    }
  }

  /// Parsea los datos del preview y extrae exoplanetas
  List<ExoplanetData> parseExoplanetsFromPreview(Map<String, dynamic> preview) {
    List<ExoplanetData> exoplanets = [];

    try {
      // El preview viene con estructura: {"cumulative": {"data": [...], "count": N}}
      final cumulative = preview['cumulative'];
      if (cumulative == null) return exoplanets;

      final data = cumulative['data'] as List?;
      if (data == null) return exoplanets;

      for (var row in data) {
        try {
          // Extraer nombre del planeta
          String? name = row['pl_name'];
          if (name == null || name.isEmpty) continue;

          // Crear ExoplanetData con los campos disponibles
          exoplanets.add(ExoplanetData(
            name: name,
            period: _parseDouble(row['pl_orbper']),
            duration: _parseDouble(row['pl_trandur']),
            depth: _parseDouble(row['pl_trandep']),
            radius: _parseDouble(row['pl_rade']),
            insolation: _parseDouble(row['pl_insol']),
            teff: _parseDouble(row['st_teff']),
            srad: _parseDouble(row['st_rad']),
          ));
        } catch (e) {
          print('Error parsing row: $e');
          continue;
        }
      }
    } catch (e) {
      print('Error parsing preview: $e');
    }

    return exoplanets;
  }

  /// Agrupa exoplanetas por nombre
  Map<String, List<ExoplanetData>> groupByName(List<ExoplanetData> exoplanets) {
    Map<String, List<ExoplanetData>> grouped = {};

    for (var exoplanet in exoplanets) {
      if (!grouped.containsKey(exoplanet.name)) {
        grouped[exoplanet.name] = [];
      }
      grouped[exoplanet.name]!.add(exoplanet);
    }

    return grouped;
  }

  /// Exporta a JSON agrupado
  Map<String, Map<String, dynamic>> exportGroupedToJson(
    Map<String, List<ExoplanetData>> grouped,
  ) {
    Map<String, Map<String, dynamic>> result = {};

    grouped.forEach((name, planets) {
      // Tomar el primer planeta si hay duplicados
      final planet = planets.first;
      result[name] = {
        'period': planet.period,
        'duration': planet.duration,
        'depth': planet.depth,
        'radius': planet.radius,
        'insolation': planet.insolation,
        'teff': planet.teff,
        'srad': planet.srad,
      };
    });

    return result;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}

// ========== EJEMPLO DE USO ==========

/// Ejemplo 1: Verificar el estado del backend
Future<void> exampleCheckHealth() async {
  final service = BackendExoplanetService();

  try {
    final health = await service.checkHealth();
    print('Backend Status: ${health['status']}');
    print('Model Ready: ${health['model_ready']}');
    print('Data Available: ${health['data_available']}');
  } catch (e) {
    print('Error: $e');
  }
}

/// Ejemplo 2: Obtener datos de exoplanetas
Future<void> exampleGetExoplanets() async {
  final service = BackendExoplanetService();

  try {
    // 1. Verificar si hay datos disponibles
    final status = await service.getTrainStatus();
    print('Data available: ${status['data_available']}');

    // 2. Si no hay datos, descargarlos
    if (status['data_available'] == false) {
      print('Downloading datasets...');
      await service.fetchDatasets();
    }

    // 3. Obtener preview de los datos
    final preview = await service.getDatasetPreview(n: 50);

    // 4. Parsear exoplanetas
    final exoplanets = service.parseExoplanetsFromPreview(preview);
    print('Found ${exoplanets.length} exoplanets');

    // 5. Agrupar por nombre
    final grouped = service.groupByName(exoplanets);
    print('Unique exoplanets: ${grouped.length}');

    // 6. Exportar a JSON
    final jsonData = service.exportGroupedToJson(grouped);
    print('JSON keys: ${jsonData.keys.take(5).toList()}');

    // 7. Ejemplo de un exoplaneta
    if (jsonData.isNotEmpty) {
      final firstKey = jsonData.keys.first;
      print('\nExample - $firstKey:');
      print(json.encode(jsonData[firstKey]));
    }
  } catch (e) {
    print('Error: $e');
  }
}

/// Ejemplo 3: Hacer una predicción
Future<void> examplePredict() async {
  final service = BackendExoplanetService();

  try {
    final testData = {
      'period': 3.52,
      'duration': 2.8,
      'depth': 4500.0,
      'radius': 2.5,
      'insolation': 150.0,
      'teff': 5800.0,
      'srad': 1.1,
    };

    final result = await service.predictOne(testData);
    print('Prediction: ${result['prediction']}');
  } catch (e) {
    print('Error: $e');
  }
}
