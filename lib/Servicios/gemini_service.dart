import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// =========================================================================
// 1. CLASE DEL SERVICIO GEMINI
// =========================================================================
class GeminiService {
  // ATENCIÓN DE SEGURIDAD:
  // NUNCA dejes la clave de la API de esta manera en una aplicación de producción.
  // Utiliza variables de entorno o un backend proxy para mantener la clave segura.
  static const String _apiKey = 'AIzaSyBiaHywzlI71EHYyU61_RhxAKXrqnMUALI';

  Future<String> analyzeSpaceLaunch(Map<String, dynamic> launch) async {
    // El prompt sigue tu estructura, asegurando una respuesta concisa y en español.
    final prompt = '''
Eres un experto en lanzamientos espaciales y misiones de exoplanetas. Analiza este lanzamiento:

Nombre: ${launch['nombre']}
Proveedor: ${launch['proveedor']}
Misión: ${launch['missionName']}
Descripción: ${launch['missionDescription']}
Estado: ${launch['status']}

Proporciona un análisis en español, de forma concisa (máximo 60 palabras), cubriendo:
1. Contexto histórico y motivación.
2. ¿Para qué sirve exactamente esta misión?
3. Beneficios a la humanidad y la ciencia.
4. Si es misión de exoplanetas, explica su importancia en la búsqueda de vida.
''';

    try {
      // FIX 404: Cambiamos el alias del modelo de 'gemini-1.5-flash-latest' a 'gemini-2.5-flash'.
      // Este es un alias más estable y confiable en la API REST, y sigue siendo gratuito.
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Extrae el texto de la respuesta del modelo
        return data['candidates'][0]['content']['parts'][0]['text'] ??
            'No se pudo generar análisis. Respuesta incompleta.';
      } else {
        // En caso de error de API (ej. clave no válida, límite de cuota)
        return 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      // Error de red o parseo
      return 'Error de conexión: $e';
    }
  }
}

// =========================================================================
// 2. APLICACIÓN FLUTTER CON INTERFAZ DE USUARIO
// =========================================================================

void main() {
  // Asegúrate de añadir la dependencia 'http: ^latest' en tu pubspec.yaml
  runApp(const SpaceLaunchApp());
}

class SpaceLaunchApp extends StatelessWidget {
  const SpaceLaunchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini Space Analyzer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const LaunchAnalyzerScreen(),
    );
  }
}

class LaunchAnalyzerScreen extends StatefulWidget {
  const LaunchAnalyzerScreen({super.key});

  @override
  State<LaunchAnalyzerScreen> createState() => _LaunchAnalyzerScreenState();
}

class _LaunchAnalyzerScreenState extends State<LaunchAnalyzerScreen> {
  final GeminiService _geminiService = GeminiService();
  Future<String>? _analysisFuture;
  final TextEditingController _launchNameController =
      TextEditingController(text: 'James Webb Space Telescope Launch (JWST)');
  String _currentLaunchName = '';

  // Datos de lanzamiento de ejemplo (puedes cambiarlos)
  final Map<String, dynamic> _dummyLaunchData = {
    'nombre': 'James Webb Space Telescope Launch (JWST)',
    'proveedor': 'NASA / ESA / CSA',
    'missionName': 'Primary Mirror Deployment & Calibration',
    'missionDescription':
        'El telescopio espacial más grande y potente jamás construido, diseñado para observar la luz de las primeras galaxias formadas en el universo.',
    'status': 'Éxito',
  };

  void _startAnalysis() {
    // Actualiza el nombre de la misión en los datos antes de la llamada
    _dummyLaunchData['nombre'] = _launchNameController.text;

    // Verificamos si el widget está montado antes de llamar a setState()
    if (mounted) {
      setState(() {
        _currentLaunchName = _launchNameController.text;
        _analysisFuture = _geminiService.analyzeSpaceLaunch(_dummyLaunchData);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛰️ Analizador Espacial Gemini'),
        backgroundColor: Colors.deepPurple.shade100,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Input para el nombre de la misión
            TextField(
              controller: _launchNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Misión a Analizar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                prefixIcon: Icon(Icons.rocket_launch),
              ),
            ),
            const SizedBox(height: 20),
            // Botón de Análisis
            ElevatedButton.icon(
              onPressed: _startAnalysis,
              icon: const Icon(Icons.travel_explore),
              label: const Text('Generar Análisis con Gemini',
                  style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              _currentLaunchName.isNotEmpty
                  ? 'Resultados del Análisis para: $_currentLaunchName'
                  : 'Presiona el botón para iniciar el análisis.',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700),
            ),
            const Divider(height: 20, thickness: 1),

            // Muestra el resultado de la llamada a la API
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.shade200),
              ),
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<String>(
                future: _analysisFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: Column(
                      children: [
                        SizedBox(height: 20),
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text('Analizando misión con Gemini...',
                            style: TextStyle(fontStyle: FontStyle.italic)),
                        SizedBox(height: 20),
                      ],
                    ));
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red));
                  } else if (snapshot.hasData) {
                    // El texto generado por Gemini
                    return SelectableText(
                      snapshot.data!,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    );
                  } else {
                    return const Text('Análisis listo para ser generado.');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
