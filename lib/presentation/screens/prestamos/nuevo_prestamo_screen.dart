import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prenda_master/core/constants/app_constants.dart';
import 'package:prenda_master/providers/database_providers.dart';
import 'package:prenda_master/data/app_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:prenda_master/utils/ocr_service.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class NuevoPrestamoScreen extends ConsumerStatefulWidget {
  const NuevoPrestamoScreen({super.key});

  @override
  ConsumerState<NuevoPrestamoScreen> createState() => _NuevoPrestamoScreenState();
}

class _NuevoPrestamoScreenState extends ConsumerState<NuevoPrestamoScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadStoredInterestRate();
    _fechaController.text = DateFormat('dd/MM/yy').format(DateTime.now());
  }

  Future<void> _loadStoredInterestRate() async {
    const storage = FlutterSecureStorage();
    final tasa = await storage.read(key: 'tasa_interes_mensual');
    if (tasa != null && mounted) {
      setState(() {
        _interesController.text = tasa;
      });
    }
  }

  final _montoController = TextEditingController();
  final _interesController = TextEditingController(text: '3.0');
  final _plazoController = TextEditingController(text: '30');
  final _descripcionController = TextEditingController();
  final _valorTasacionController = TextEditingController();
  final _fechaController = TextEditingController();

  Cliente? _selectedCliente;
  String _selectedMoneda = 'BOLIVIANOS';
  String _selectedCategoria = 'Joyas (Oro/Plata)';
  bool _isLoading = false;
  String _photoPath = '';
  String? _ocrText;
  bool _isOcrProcessing = false;
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  final List<String> _categoriasPrenda = [
    'Joyas (Oro/Plata)',
    'Electrónica / Celulares',
    'Relojes',
    'Herramientas',
    'Electrodomésticos',
    'Vehículos / Motos',
    'Otro'
  ];

  @override
  void dispose() {
    _montoController.dispose();
    _interesController.dispose();
    _plazoController.dispose();
    _descripcionController.dispose();
    _valorTasacionController.dispose();
    _fechaController.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione un cliente')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);
      
      DateTime fechaInicio = DateTime.now();
      try {
        fechaInicio = DateFormat('dd/MM/yy').parse(_fechaController.text);
      } catch (_) {}

      final plazo = int.tryParse(_plazoController.text) ?? 30;

      final prestamoId = await db.insertPrestamo(PrestamosCompanion(
        clienteId: Value(_selectedCliente!.id),
        monto: Value(double.parse(_montoController.text)),
        moneda: Value(_selectedMoneda),
        interesMensual: Value(double.parse(_interesController.text)),
        plazoDias: Value(plazo),
        fechaInicio: Value(fechaInicio),
        fechaVencimiento: Value(fechaInicio.add(Duration(days: plazo))),
        estado: Value('Activo'),
        descripcion: Value(_descripcionController.text.trim().isNotEmpty ? _descripcionController.text.trim() : 'Préstamo de garantía'),
      ));

      if (_photoPath.isNotEmpty) {
        await db.insertPrenda(PrendasCompanion(
          descripcion: Value('[$_selectedCategoria] ${_descripcionController.text.isNotEmpty ? _descripcionController.text : 'Prenda sin descripción'}'),
          fotoPath: Value(_photoPath),
          prestamoId: Value(prestamoId),
        ));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Préstamo creado exitosamente!')),
      );
      context.go(AppConstants.routePrestamos);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar préstamo: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clientesAsync = ref.watch(clientesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Préstamo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppConstants.routePrestamos);
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : clientesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (clientes) {
                return Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Step Indicator Header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: theme.colorScheme.surface,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStepIndicator(0, '1. Cliente'),
                            _buildStepIndicator(1, '2. Prenda'),
                            _buildStepIndicator(2, '3. Cálculo'),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Step Content (Scrollable to prevent overflow)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: _buildCurrentStepContent(clientes),
                        ),
                      ),

                      // Bottom Navigation Buttons for Stepper (Safeguarded against Android native buttons overflow)
                      SafeArea(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_currentStep > 0)
                                OutlinedButton.icon(
                                  onPressed: () => setState(() => _currentStep--),
                                  icon: const Icon(Icons.arrow_back, size: 16),
                                  label: const Text('Anterior'),
                                )
                              else
                                const SizedBox.shrink(),
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (_currentStep < 2) {
                                    if (_currentStep == 0 && _selectedCliente == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Seleccione un cliente para continuar')),
                                      );
                                      return;
                                    }
                                    setState(() => _currentStep++);
                                  } else {
                                    _guardarPrestamo();
                                  }
                                },
                                icon: Icon(_currentStep == 2 ? Icons.check : Icons.arrow_forward, size: 16),
                                label: Text(_currentStep == 2 ? 'Guardar Préstamo' : 'Siguiente'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    final isActive = _currentStep == stepIndex;
    final isCompleted = _currentStep > stepIndex;
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.blue.shade700 : (isCompleted ? Colors.green.shade700 : Colors.grey),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 3,
          width: 80,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : (isCompleted ? Colors.green : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepContent(List<Cliente> clientes) {
    switch (_currentStep) {
      case 0:
        return _buildStepCliente(clientes);
      case 1:
        return _buildStepPrenda();
      case 2:
        return _buildStepCalculo();
      default:
        return Container();
    }
  }

  // STEP 1: CLIENTE
  Widget _buildStepCliente(List<Cliente> clientes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CLIENTE SELECCIONADO',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        if (_selectedCliente != null)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  _selectedCliente!.nombre.isNotEmpty ? _selectedCliente!.nombre[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
              title: Text(
                '${_selectedCliente!.nombre} ${_selectedCliente!.apellido}',
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'Tel: ${_selectedCliente!.telefono}',
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => setState(() => _selectedCliente = null),
                tooltip: 'Cambiar cliente',
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(12),
              color: Colors.blue.shade50.withValues(alpha: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Seleccione un cliente para asociar al préstamo:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                DropdownButtonFormField<Cliente>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar Cliente',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                  ),
                  value: _selectedCliente,
                  items: clientes
                      .map((cliente) => DropdownMenuItem<Cliente>(
                            value: cliente,
                            child: Text(
                              '${cliente.nombre} ${cliente.apellido} (${cliente.telefono})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedCliente = value),
                  validator: (value) => value == null ? 'Seleccione un cliente' : null,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppConstants.routeNuevoCliente),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Registrar Nuevo Cliente'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // STEP 2: PRENDA
  Widget _buildStepPrenda() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DETALLES DE LA PRENDA',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _takePhoto,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _photoPath.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(_photoPath), fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt, color: Colors.blue, size: 20),
                            SizedBox(height: 4),
                            Text('Frontal', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.photo_camera_back, color: Colors.grey, size: 20),
                    SizedBox(height: 4),
                    Text('Lateral', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add, color: Colors.grey, size: 20),
                    SizedBox(height: 4),
                    Text('Añadir', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Categoría de Prenda',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          value: _selectedCategoria,
          items: _categoriasPrenda
              .map((cat) => DropdownMenuItem<String>(value: cat, child: Text(cat)))
              .toList(),
          onChanged: (val) => setState(() => _selectedCategoria = val!),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descripcionController,
          decoration: const InputDecoration(
            labelText: 'Descripción de la Prenda',
            prefixIcon: Icon(Icons.description, size: 20),
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
            isDense: true,
          ),
          maxLines: 2,
        ),
        if (_isOcrProcessing) ...[
          const SizedBox(height: 6),
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ],
        if (_ocrText != null && _ocrText!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('OCR detectado: $_ocrText', style: const TextStyle(color: Colors.green, fontSize: 11)),
        ],
      ],
    );
  }

  // STEP 3: CÁLCULO
  Widget _buildStepCalculo() {
    final monto = double.tryParse(_montoController.text) ?? 0;
    final interes = double.tryParse(_interesController.text) ?? 3.0;
    final interesCalculado = monto * (interes / 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TASACIÓN Y PRÉSTAMO',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _valorTasacionController,
                decoration: const InputDecoration(
                  labelText: 'Valor Tasación',
                  prefixText: 'Bs. ',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) {
                  final t = double.tryParse(val) ?? 0;
                  if (t > 0 && _montoController.text.isEmpty) {
                    setState(() {
                      _montoController.text = (t * 0.7).toStringAsFixed(2);
                    });
                  } else {
                    setState(() {});
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(
                  labelText: 'Monto Préstamo',
                  prefixText: 'Bs. ',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) => setState(() {}),
                validator: (val) => val == null || val.isEmpty ? 'Ingrese monto' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Moneda',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                value: _selectedMoneda,
                items: AppConstants.monedas
                    .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (val) => setState(() => _selectedMoneda = val!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _fechaController,
                decoration: const InputDecoration(
                  labelText: 'Fecha (DD/MM/AA)',
                  border: OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                ),
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _fechaController.text = DateFormat('dd/MM/yy').format(picked);
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _interesController,
                decoration: const InputDecoration(
                  labelText: 'Tasa Mensual (%)',
                  suffixText: '%',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _plazoController,
                decoration: const InputDecoration(
                  labelText: 'Plazo (días)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Calculation Summary Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Resumen del Cálculo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
              const Divider(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tasa Mensual:', style: TextStyle(fontSize: 11)),
                  Text('${_interesController.text}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Interés Estimado:', style: TextStyle(fontSize: 11)),
                  Text('Bs. ${interesCalculado.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total a Pagar:', style: TextStyle(fontSize: 11)),
                  Text('Bs. ${(monto + interesCalculado).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
