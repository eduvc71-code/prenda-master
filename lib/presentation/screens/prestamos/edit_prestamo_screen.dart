import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prenda_master/core/constants/app_constants.dart';
import 'package:prenda_master/core/theme/app_theme.dart';
import 'package:prenda_master/providers/database_providers.dart';
import 'package:prenda_master/data/app_database.dart';
import 'package:drift/drift.dart' hide Column;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class EditPrestamoScreen extends ConsumerStatefulWidget {
  final int prestamoId;

  const EditPrestamoScreen({
    super.key,
    required this.prestamoId,
  });

  @override
  ConsumerState<EditPrestamoScreen> createState() => _EditPrestamoScreenState();
}

class _EditPrestamoScreenState extends ConsumerState<EditPrestamoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _interesController = TextEditingController();
  final _plazoController = TextEditingController();
  final _descripcionController = TextEditingController();
  String _selectedCliente = '';
  String _selectedMoneda = AppConstants.monedaDefault;
  bool _isLoading = false;
  String _photoPath = ''; // Path to the taken photo of the prenda
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPrestamoData();
  }

  Future<void> _loadPrestamoData() async {
    final db = ref.read(databaseProvider);
    final prestamo = await db.getPrestamo(widget.prestamoId);
    if (!mounted) return;

    // Set form values
    _montoController.text = prestamo.monto.toString();
    _interesController.text = prestamo.interesMensual.toString();
    _plazoController.text = prestamo.plazoDias.toString();
    _descripcionController.text = prestamo.descripcion ?? '';
    _selectedMoneda = prestamo.moneda;

    // Get client name for dropdown
    final cliente = await db.getCliente(prestamo.clienteId);
    setState(() {
      _selectedCliente = '${cliente.id} ${cliente.nombre} ${cliente.apellido}';
    });
  }

  @override
  void dispose() {
    _montoController.dispose();
    _interesController.dispose();
    _plazoController.dispose();
    _descripcionController.dispose();
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
          });
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

  Future<void> _actualizarPrestamo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);

      // 1. Update the prestamo
      await db.updatePrestamo(widget.prestamoId, PrestamosCompanion(
        id: Value(widget.prestamoId),
        clienteId: Value(int.parse(_selectedCliente.split(' ')[0])),
        monto: Value(double.parse(_montoController.text)),
        moneda: Value(_selectedMoneda),
        interesMensual: Value(double.parse(_interesController.text)),
        plazoDias: Value(int.parse(_plazoController.text)),
        fechaInicio: Value(DateTime.now()), // TODO: keep original or allow edit?
        fechaVencimiento: Value(DateTime.now().add(Duration(days: int.parse(_plazoController.text)))),
        estado: Value('Activo'), // TODO: allow estado change?
        descripcion: Value(_descripcionController.text),
      ));

      // 2. Handle photo - if new photo taken, add it; if not, keep existing
      if (_photoPath != null) {
        await db.insertPrenda(PrendasCompanion(
          descripcion: Value('Prenda para préstamo #${widget.prestamoId} (editada)'),
          fotoPath: Value(_photoPath ?? ''),
          prestamoId: Value(widget.prestamoId),
        ));
      }

      if (!mounted) return;
      context.go('${AppConstants.routeDetallePrestamo}/${widget.prestamoId}');
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
        title: const Text('Editar Préstamo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<List<Cliente>>(
                stream: ref.read(databaseProvider).watchAllClientes(),
                builder: (context, clientSnapshot) {
                  if (clientSnapshot.hasData) {
                    final clientes = clientSnapshot.data!;
                    return Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cliente dropdown
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Cliente',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedCliente.isEmpty ? null : _selectedCliente,
                            items: clientes
                                .map((cliente) => DropdownMenuItem(
                                      value: '${cliente.id} ${cliente.nombre} ${cliente.apellido}',
                                      child: Text('${cliente.nombre} ${cliente.apellido}'),
                                    ))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedCliente = value!),
                            validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'Seleccione un cliente'
                                    : null,
                          ),
                          const SizedBox(height: 16),

                          // Monto
                          TextFormField(
                            controller: _montoController,
                            decoration: const InputDecoration(
                              labelText: 'Monto',
                              prefixText: r'$ ',
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

                          // Moneda
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Moneda',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedMoneda,
                            items: AppConstants.monedas
                                .map((moneda) => DropdownMenuItem(
                                      value: moneda,
                                      child: Text(moneda),
                                    ))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedMoneda = value!),
                          ),
                          const SizedBox(height: 16),

                          // Interés mensual
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

                          // Plazo (días)
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

                          // Descripción (opcional)
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
                                'Foto de la Prenda (opcional - añadir nueva)',
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
                                onPressed: _isLoading ? null : _takePhoto,
                                icon: const Icon(Icons.camera),
                                label: const Text('Tomar Foto'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(40),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ActualizarPréstamo button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _actualizarPrestamo,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              backgroundColor: Colors.orange,
                            ),
                            child: const Text('Actualizar Préstamo'),
                          ),
                        ],
                      ),
                    );
                  }
                  // Si no hay datos, mostrar mensaje de error o widget vacío
                  return const Center(child: Text('Error cargando clientes'));
                },
              ),
            ),
    );
  }
}