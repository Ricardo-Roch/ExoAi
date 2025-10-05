import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

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

  bool _isProcessing = false;
  Map<String, dynamic>? _prediction;
  String? _errorMessage;

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

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Respuesta vacía del servidor');
        }

        final data = jsonDecode(response.body);

        if (data == null) {
          throw Exception('Datos inválidos recibidos');
        }

        setState(() {
          _prediction = data;
          _isProcessing = false;
        });
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException catch (_) {
      setState(() {
        _errorMessage = 'Timeout: El servidor tardó demasiado en responder';
        _isProcessing = false;
      });
    } on FormatException catch (e) {
      setState(() {
        _errorMessage = 'Error al parsear respuesta: ${e.message}';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al realizar la predicción: $e';
        _isProcessing = false;
      });
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
  Widget build(BuildContext context) {
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  IconButton(
                    onPressed: _loadExampleData,
                    icon: const Icon(Icons.file_copy, color: Colors.white),
                    tooltip: 'Cargar ejemplo',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
                        onPressed: _isProcessing ? null : _sendPrediction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
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
              if (_prediction != null) ...[
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
                        '${_prediction!['confidence_percentage']?.toStringAsFixed(1) ?? '0'}%',
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
                        ...(_prediction!['probabilities'] as Map).entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildProbabilityBar(
                                  entry.key,
                                  (entry.value as num).toDouble() / 100,
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
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
