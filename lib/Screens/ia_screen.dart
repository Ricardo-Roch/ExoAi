import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../Servicios/gemini_service.dart';

class IAScreen extends StatefulWidget {
  const IAScreen({Key? key}) : super(key: key);

  @override
  State<IAScreen> createState() => _IAScreenState();
}

class _IAScreenState extends State<IAScreen> {
  final TextEditingController _periodController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _depthController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();
  final TextEditingController _insolationController = TextEditingController();
  final TextEditingController _teffController = TextEditingController();
  final TextEditingController _sradController = TextEditingController();

  final GeminiService _geminiService = GeminiService();

  bool _isProcessing = false;
  Map<String, dynamic>? _prediction;
  List<Map<String, dynamic>>? _batchPredictions;
  String? _errorMessage;
  bool _isBatchMode = false;

  @override
  void dispose() {
    _periodController.dispose();
    _durationController.dispose();
    _depthController.dispose();
    _radiusController.dispose();
    _insolationController.dispose();
    _teffController.dispose();
    _sradController.dispose();
    super.dispose();
  }

  Future<void> _sendPrediction() async {
    if (_periodController.text.trim().isEmpty ||
        _durationController.text.trim().isEmpty ||
        _depthController.text.trim().isEmpty ||
        _radiusController.text.trim().isEmpty ||
        _insolationController.text.trim().isEmpty ||
        _teffController.text.trim().isEmpty ||
        _sradController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Por favor completa todos los campos';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _prediction = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse('https://back-exoai.onrender.com/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'period': double.parse(_periodController.text),
              'duration': double.parse(_durationController.text),
              'depth': double.parse(_depthController.text),
              'radius': double.parse(_radiusController.text),
              'insolation': double.parse(_insolationController.text),
              'teff': double.parse(_teffController.text),
              'srad': double.parse(_sradController.text),
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _prediction = data;
          _isProcessing = false;
        });
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al realizar la predicción: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickAndProcessCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        setState(() {
          _isProcessing = true;
          _errorMessage = null;
          _batchPredictions = null;
          _isBatchMode = true;
        });

        // Leer el archivo
        final bytes = result.files.first.bytes;
        if (bytes == null) {
          throw Exception('No se pudo leer el archivo');
        }

        final csvString = utf8.decode(bytes);
        final rows = csvString.split('\n');

        if (rows.length < 2) {
          throw Exception('El CSV debe tener al menos una fila de datos');
        }

        // Parsear headers
        final headers =
            rows[0].split(',').map((e) => e.trim().toLowerCase()).toList();

        // Encontrar índices de columnas requeridas
        final periodIdx = headers.indexWhere((h) => h.contains('period'));
        final durationIdx = headers.indexWhere((h) => h.contains('duration'));
        final depthIdx = headers.indexWhere((h) => h.contains('depth'));
        final radiusIdx = headers
            .indexWhere((h) => h.contains('radius') || h.contains('rade'));
        final insolationIdx = headers.indexWhere((h) => h.contains('insol'));
        final teffIdx = headers.indexWhere((h) => h.contains('teff'));
        final sradIdx = headers
            .indexWhere((h) => h.contains('srad') || h.contains('st_rad'));

        if (periodIdx == -1 ||
            durationIdx == -1 ||
            depthIdx == -1 ||
            radiusIdx == -1 ||
            insolationIdx == -1 ||
            teffIdx == -1 ||
            sradIdx == -1) {
          throw Exception(
              'El CSV debe contener las columnas: period, duration, depth, radius, insolation, teff, srad');
        }

        // Procesar filas
        List<Map<String, dynamic>> predictions = [];

        for (int i = 1; i < rows.length && i <= 11; i++) {
          // Máximo 10 registros
          if (rows[i].trim().isEmpty) continue;

          final values = rows[i].split(',');
          if (values.length < headers.length) continue;

          try {
            final data = {
              'period': double.parse(values[periodIdx].trim()),
              'duration': double.parse(values[durationIdx].trim()),
              'depth': double.parse(values[depthIdx].trim()),
              'radius': double.parse(values[radiusIdx].trim()),
              'insolation': double.parse(values[insolationIdx].trim()),
              'teff': double.parse(values[teffIdx].trim()),
              'srad': double.parse(values[sradIdx].trim()),
            };

            // Hacer predicción individual
            final response = await http
                .post(
                  Uri.parse('https://back-exoai.onrender.com/predict'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(data),
                )
                .timeout(const Duration(seconds: 30));

            if (response.statusCode == 200) {
              final predictionData = jsonDecode(response.body);
              predictions.add({
                'rowNumber': i,
                'input': data,
                'prediction': predictionData['prediction'],
                'confidence': predictionData['confidence'],
                'probabilities': predictionData['probabilities'],
              });
            }
          } catch (e) {
            print('Error procesando fila $i: $e');
          }
        }

        setState(() {
          _batchPredictions = predictions;
          _isProcessing = false;
        });

        if (predictions.isEmpty) {
          throw Exception('No se pudo procesar ningún registro del CSV');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al procesar CSV: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _analyzePrediction() async {
    if (_prediction == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF60A5FA)),
            const SizedBox(height: 16),
            Text(
              'Analizando predicción con Gemini AI...',
              style: TextStyle(color: Colors.grey[300]),
            ),
          ],
        ),
      ),
    );

    try {
      final prompt = '''
Eres un experto en exoplanetas. Analiza esta predicción de clasificación de exoplaneta:

Predicción: ${_prediction!['prediction']}
Confianza: ${((_prediction!['confidence'] ?? 0) * 100).toStringAsFixed(2)}%

Parámetros del exoplaneta:
- Período orbital: ${_periodController.text} días
- Duración de tránsito: ${_durationController.text} horas
- Profundidad: ${_depthController.text}
- Radio: ${_radiusController.text} R⊕
- Insolación: ${_insolationController.text} S⊕
- Temperatura estelar: ${_teffController.text} K
- Radio estelar: ${_sradController.text} R☉

Proporciona un análisis breve (máximo 100 palabras) en español explicando:
1. Qué significa esta clasificación
2. Por qué el modelo lo clasificó así basándose en los parámetros
3. Características destacables de este exoplaneta
4. Comparación con planetas conocidos si es relevante
''';

      final response = await _geminiService.analyzeSpaceLaunch({
        'nombre': 'Exoplaneta Predicho',
        'proveedor': 'ML Model',
        'missionName': 'Classification Analysis',
        'missionDescription': prompt,
        'status': 'Analyzed',
      });

      if (!mounted) return;
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E293B),
                  Color(0xFF0F172A),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF60A5FA),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF60A5FA).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF60A5FA).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFF60A5FA),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Análisis Gemini AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Interpretación de predicción',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      response,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 15,
                        height: 1.8,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al analizar: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _loadExampleData() {
    _periodController.text = '5.23';
    _durationController.text = '2.5';
    _depthController.text = '0.0013';
    _radiusController.text = '1.2';
    _insolationController.text = '1.05';
    _teffController.text = '5778';
    _sradController.text = '1.0';
  }

  @override
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF172554),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: Column(
          children: [
            // Header con logo
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/Logo-02.png',
                    height: 40,
                    width: 40,
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF60A5FA),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF1E293B),
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? const Icon(
                              Icons.person,
                              size: 20,
                              color: Color(0xFF60A5FA),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            // Contenido con scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Predicción de Exoplanetas',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Análisis con IA avanzada',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Botones reubicados debajo del título
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _loadExampleData,
                            icon: const Icon(Icons.file_copy, size: 18),
                            label: const Text('Ejemplo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickAndProcessCSV,
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('Cargar CSV'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (!_isBatchMode) ...[
                      // Formulario individual
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1E293B),
                              Color(0xFF0F172A),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF334155),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.public, color: Color(0xFF60A5FA)),
                                SizedBox(width: 8),
                                Text(
                                  'Parámetros del Exoplaneta',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildInputField(
                              controller: _periodController,
                              label: 'Período (días)',
                              hint: 'Ej: 5.23',
                              icon: Icons.rotate_right,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _durationController,
                              label: 'Duración (horas)',
                              hint: 'Ej: 2.5',
                              icon: Icons.access_time,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _depthController,
                              label: 'Profundidad',
                              hint: 'Ej: 0.0013',
                              icon: Icons.vertical_align_center,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _radiusController,
                              label: 'Radio (R⊕)',
                              hint: 'Ej: 1.2',
                              icon: Icons.circle_outlined,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _insolationController,
                              label: 'Insolación',
                              hint: 'Ej: 1.05',
                              icon: Icons.wb_sunny,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _teffController,
                              label: 'Temperatura Efectiva (K)',
                              hint: 'Ej: 5778',
                              icon: Icons.thermostat,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _sradController,
                              label: 'Radio Estelar (R☉)',
                              hint: 'Ej: 1.0',
                              icon: Icons.star,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _isProcessing ? null : _sendPrediction,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isProcessing
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.rocket_launch),
                                          SizedBox(width: 8),
                                          Text(
                                            'Realizar Predicción',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[900]?.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[600]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[300]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red[100]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_prediction != null && !_isBatchMode) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue[900]!.withOpacity(0.3),
                              Colors.purple[900]!.withOpacity(0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF60A5FA),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.analytics, color: Color(0xFF60A5FA)),
                                SizedBox(width: 8),
                                Text(
                                  'Resultado de Predicción',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildResultCard(
                              'Clasificación',
                              _prediction!['prediction']?.toString() ?? 'N/A',
                              Icons.category,
                              Colors.blue,
                            ),
                            const SizedBox(height: 12),
                            _buildResultCard(
                              'Confianza',
                              '${((_prediction!['confidence'] ?? 0) * 100).toStringAsFixed(2)}%',
                              Icons.percent,
                              Colors.green,
                            ),
                            if (_prediction!['probabilities'] != null) ...[
                              const SizedBox(height: 24),
                              const Text(
                                'Probabilidades por clase:',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...(_prediction!['probabilities'] as Map)
                                  .entries
                                  .map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: _buildProbabilityBar(
                                        entry.key,
                                        (entry.value as num).toDouble(),
                                      ),
                                    ),
                                  ),
                            ],
                            const SizedBox(height: 24),

                            // Botón de Gemini para predicción individual
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _analyzePrediction,
                                icon: const Icon(Icons.auto_awesome, size: 20),
                                label: const Text(
                                  'Analizar con Gemini AI',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF60A5FA),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 4,
                                  shadowColor:
                                      const Color(0xFF60A5FA).withOpacity(0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_batchPredictions != null) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Resultados del CSV',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isBatchMode = false;
                                _batchPredictions = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Cerrar'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF60A5FA),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._batchPredictions!.map((pred) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1E293B),
                                  Color(0xFF0F172A),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF334155),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Registro ${pred['rowNumber']}',
                                      style: const TextStyle(
                                        color: Color(0xFF60A5FA),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[600],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        pred['prediction'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Confianza: ${((pred['confidence'] ?? 0) * 100).toStringAsFixed(2)}%',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Radio: ${pred['input']['radius']} R⊕ | Período: ${pred['input']['period']} días',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: Icon(icon, color: const Color(0xFF60A5FA)),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityBar(String label, double value) {
    final percentage = (value * 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$percentage%',
              style: const TextStyle(
                color: Color(0xFF60A5FA),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: const Color(0xFF334155),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF60A5FA)),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
