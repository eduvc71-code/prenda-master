import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prenda_master/core/constants/app_constants.dart';
import 'package:prenda_master/core/theme/app_theme.dart';
import 'package:prenda_master/providers/database_providers.dart';
import 'package:prenda_master/data/app_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:prenda_master/utils/ocr_service.dart';
import 'package:drift/drift.dart' hide Column;

class NuevoPrestamoScreen extends ConsumerStatefulWidget {
  const NuevoPrestamoScreen({super.key});

  @override
  ConsumerState<NuevoPrestamoScreen> createState() => _NuevoPrestamoScreenState();
}

class _NuevoPrestamoScreenState extends ConsumerState<NuevoPrestamoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _interesController = TextEditingController();
  final _plazoController = TextEditingController();
  final _descripcionController = TextEditingController();
  Cliente? _selectedCliente;
  String _selectedMoneda = AppConstants.monedaDefault;
  bool _isLoading = false;
  String _photoPath = ''; // Path to the taken photo of the prenda
  String? _ocrText; // Recognized text from the photo
  bool _isOcrProcessing = false;
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  @override
  void dispose() {
    _montoController.dispose();
    _interesController.dispose();
    _plazoController.dispose();
    _descripcionController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1024,
        );
        if (photo != null && mounted) {
          setState(() {
            _photoPath = photo.path;
            _ocrText = null;
          });
          // Run OCR on the image - pass the file path
          _processOcrFile(photo.path);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de cámara denegado')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al tomar foto: $e')),
        );
      }
    }
  }

  Future<void> _processOcrFile(String imagePath) async {
      if (!mounted) return;
      setState(() => _isOcrProcessing = true);
      try {
        final text = await _ocrService.recognizeText(imagePath);
        if (mounted) {
          setState(() {
            _ocrText = text;
            // Optionally auto-fill descripcion if empty
            if (_descripcionController.text.isEmpty) {
              _descripcionController.text = text;
            }
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error en OCR: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isOcrProcessing = false);
      }
    }

  Future<void> _guardarPrestamo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCliente == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un cliente')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);
      
      // 1. Insert the prestamo
      final prestamoId = await db.insertPrestamo(PrestamosCompanion(
        clienteId: Value(_selectedCliente!.id),
        monto: Value(double.parse(_montoController.text)),
        moneda: Value(_selectedMoneda),
        interesMensual: Value(double.parse(_interesController.text)),
        plazoDias: Value(int.parse(_plazoController.text)),
        fechaInicio: Value(DateTime.now()),
        fechaVencimiento: Value(DateTime.now().add(Duration(days: int.parse(_plazoController.text)))),
        estado: Value('Activo'),
      ));

      // 2. If a photo was taken, insert a prenda record
      if (_photoPath != null) {
        await db.insertPrenda(PrendasCompanion(
          descripcion: Value(_descripcionController.text.isNotEmpty
              ? _descripcionController.text
              : 'Prenda para préstamo #$prestamoId'),
          fotoPath: Value(_photoPath),
          prestamoId: Value(prestamoId),
        ));
      }

      if (!mounted) return;
      context.go(AppConstants.routePrestamos);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Préstamo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AsyncValueWrapper<Cliente>(
                value: ref.watch(clientesProvider),
                onData: (clientes) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<Cliente>(
                          decoration: const InputDecoration(
                            labelText: 'Cliente',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedCliente,
                          items: clientes
                              .map((cliente) => DropdownMenuItem<Cliente>(
                                    value: cliente,
                                    child: Text('${cliente.nombre} ${cliente.apellido}'),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedCliente = value),
                          validator: (value) =>
                              value == null ? 'Seleccione un cliente' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _montoController,
                          decoration: const InputDecoration(
                            labelText: 'Monto',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese el monto';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Ingrese un número válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Moneda',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedMoneda,
                          items: AppConstants.monedas
                              .map((moneda) => DropdownMenuItem<String>(
                                    value: moneda,
                                    child: Text(moneda),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedMoneda = value!),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _interesController,
                          decoration: const InputDecoration(
                            labelText: 'Interés mensual (%)',
                            suffixText: '%',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese el interés';
                            }
                            final double? val = double.tryParse(value);
                            if (val == null) {
                              return 'Ingrese un número válido';
                            }
                            if (val < 0 || val > 100) {
                              return 'El interés debe estar entre 0 y 100';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _plazoController,
                          decoration: const InputDecoration(
                            labelText: 'Plazo (días)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingrese el plazo';
                            }
                            final int? val = int.tryParse(value);
                            if (val == null) {
                              return 'Ingrese un número válido';
                            }
                            if (val <= 0) {
                              return 'El plazo debe ser mayor a 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descripcionController,
                          decoration: const InputDecoration(
                            labelText: 'Descripción (opcional)',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        // Photo section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Foto de la Prenda (opcional)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _photoPath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_photoPath),
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    width: double.infinity,
                                    height: 200,
                                    color: Colors.grey.shade200,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_alt,
                                          size: 48,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Tome una foto de la prenda',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _isLoading || _isOcrProcessing ? null : _takePhoto,
                              icon: const Icon(Icons.camera),
                              label: const Text('Tomar Foto'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(40),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_ocrText != null && _ocrText!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.indigo),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Texto reconocido:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _ocrText!,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),
                            if (_isOcrProcessing)
                              const Center(child: CircularProgressIndicator()),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _guardarPrestamo,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('Guardar Préstamo'),
                        ),
                      ],
                    ),
                  );
                },
                onLoading: () => const Center(child: CircularProgressIndicator()),
                onError: (Object e, StackTrace _) => Center(child: Text('Error: $e')),
              ),
            ),
    );
  }
}

// Helper widget to handle AsyncValue<T>
class AsyncValueWrapper<T> extends ConsumerWidget {
  const AsyncValueWrapper({
    super.key,
    required this.value,
    required this.onData,
    this.onLoading,
    this.onError,
  });

  final AsyncValue<List<T>> value;
  final Widget Function(List<T>) onData;
  final Widget Function()? onLoading;
  final Widget Function(Object, StackTrace)? onError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return value.when(
      data: onData,
      loading: onLoading ?? () => const Center(child: CircularProgressIndicator()),
      error: onError ?? (Object e, StackTrace _) => Center(child: Text('Error: $e')),
    );
  }
}