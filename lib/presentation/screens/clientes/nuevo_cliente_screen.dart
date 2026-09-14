import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prenda_master/core/constants/app_constants.dart';
import 'package:prenda_master/presentation/widgets/custom_header.dart';
import 'package:prenda_master/presentation/widgets/custom_text_field.dart';
import 'package:prenda_master/providers/database_providers.dart';
import 'package:prenda_master/data/app_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:prenda_master/utils/ocr_service.dart';
import 'package:drift/drift.dart' hide Column;

class NuevoClienteScreen extends ConsumerStatefulWidget {
  const NuevoClienteScreen({super.key});

  @override
  ConsumerState<NuevoClienteScreen> createState() => _NuevoClienteScreenState();
}

class _NuevoClienteScreenState extends ConsumerState<NuevoClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();
  
  bool _isLoading = false;
  String _idCardFrontPath = '';
  String _idCardBackPath = '';

  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _cedulaController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _captureIdCard(bool isFront) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isFront ? 'Carnet - Anverso (Frente)' : 'Carnet - Reverso (Dorso)'),
        content: const Text('Elija el origen de la imagen:'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _processCamera(isFront);
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Cámara'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _processGallery(isFront);
            },
            icon: const Icon(Icons.photo_library),
            label: const Text('Subir Archivo (Galería)'),
          ),
        ],
      ),
    );
  }

  Future<void> _processCamera(bool isFront) async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de cámara denegado')),
          );
        }
        return;
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
      );

      if (photo != null && mounted) {
        setState(() {
          if (isFront) {
            _idCardFrontPath = photo.path;
          } else {
            _idCardBackPath = photo.path;
          }
        });

        final extractedText = await _ocrService.recognizeText(photo.path);
        if (mounted) {
          setState(() {
            _parseOcrTextDirect(extractedText, isFront);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isFront ? '¡Anverso capturado con éxito!' : '¡Reverso capturado con éxito!')),
          );

          if (isFront) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('AHORA SUBA EL REVERSO DEL C.I.'),
                duration: Duration(seconds: 2),
              ),
            );
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) _captureIdCard(false);
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al capturar con cámara: $e')),
        );
      }
    }
  }

  Future<void> _processGallery(bool isFront) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1536,
      );

      if (photo != null && mounted) {
        setState(() {
          if (isFront) {
            _idCardFrontPath = photo.path;
          } else {
            _idCardBackPath = photo.path;
          }
        });

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => GalleryOcrValidationScreen(
              imagePath: photo.path,
              isFront: isFront,
              ocrService: _ocrService,
            ),
          ),
        );

        if (result != null && result is Map<String, String> && mounted) {
          setState(() {
            if (isFront) {
              if (result['nombre'] != null && result['nombre']!.isNotEmpty) {
                _nombreController.text = result['nombre']!;
              }
              if (result['apellido'] != null && result['apellido']!.isNotEmpty) {
                _apellidoController.text = result['apellido']!;
              }
              if (result['cedula'] != null && result['cedula']!.isNotEmpty) {
                _cedulaController.text = result['cedula']!;
              }
            } else {
              if (result['direccion'] != null && result['direccion']!.isNotEmpty) {
                _direccionController.text = result['direccion']!;
              }
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Datos validados y aplicados correctamente!')),
          );

          if (isFront) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('AHORA SUBA EL REVERSO DEL C.I.'),
                duration: Duration(seconds: 2),
              ),
            );
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) _processGallery(false);
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir archivo: $e')),
        );
      }
    }
  }

  void _parseOcrTextDirect(String text, bool isFront) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (isFront) {
      int apellidosIdx = -1;
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final lineUpper = line.toUpperCase();
        if (lineUpper.contains('N°') || lineUpper.contains('NO') || lineUpper.contains('Nº')) {
          final digits = line.replaceAll(RegExp(r'[^0-9]'), '');
          if (digits.length >= 4) _cedulaController.text = digits;
        }
        if (lineUpper.contains('APELLIDO')) {
          apellidosIdx = i;
        }
      }
      if (apellidosIdx != -1) {
        for (int i = apellidosIdx + 1; i < lines.length; i++) {
          String c = lines[i];
          if (c.toUpperCase().startsWith('NOMBRES:')) c = c.substring(8).trim();
          if (c.toUpperCase().startsWith('NOMBRES')) c = c.substring(7).trim();
          if (c.startsWith(':')) c = c.substring(1).trim();
          if (!_isHeaderOrNoise(c) && !RegExp(r'^[0-9]+$').hasMatch(c) && c.length > 1) {
            _nombreController.text = c;
            if (i + 1 < lines.length) {
              String cLast = lines[i + 1];
              if (cLast.toUpperCase().startsWith('APELLIDOS:')) cLast = cLast.substring(10).trim();
              if (cLast.toUpperCase().startsWith('APELLIDOS')) cLast = cLast.substring(9).trim();
              if (cLast.startsWith(':')) cLast = cLast.substring(1).trim();
              if (!_isHeaderOrNoise(cLast) && !RegExp(r'^[0-9]+$').hasMatch(cLast) && cLast.length > 1) {
                _apellidoController.text = cLast;
              }
            }
            break;
          }
        }
      }
    } else {
      int domicilioIdx = -1;
      for (int i = 0; i < lines.length; i++) {
        final u = lines[i].toUpperCase();
        if (u.contains('DOMICILIO') || u.contains('DOMICLIO') || u.contains('DOHCO') || u.contains('DOMI')) {
          domicilioIdx = i;
          break;
        }
      }
      if (domicilioIdx == -1) {
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].toUpperCase().contains('NACIMIENTO') || lines[i].toUpperCase().contains('LA PAZ')) {
            domicilioIdx = i + 2;
            break;
          }
        }
      }
      if (domicilioIdx != -1) {
        final addressParts = <String>[];
        for (int i = domicilioIdx + 1; i < lines.length; i++) {
          String c = lines[i];
          if (c.toUpperCase().startsWith('DOMICILIO:') || c.toUpperCase().startsWith('DOHCO.:')) {
            c = c.substring(c.indexOf(':') + 1).trim();
          }
          final u = c.toUpperCase();
          if (u.contains('OCUPACI') || u.contains('OCUPACION') || u.contains('GOMERCIANTE') || u.contains('ESTADO') || u.contains('SOLTERO') || u.contains('CASADO') || u.contains('BOL') || u.contains('PATRO') || u.contains('PULGAR') || u.contains('ECTHRA') || u.contains('AECUT')) {
            break;
          }
          if (!_isHeaderOrNoise(c) && c.length > 2 && !u.contains('OCUPACI') && !u.contains('OCUPACION') && !u.contains('GOMERCIANTE')) {
            addressParts.add(c);
          }
        }
        if (addressParts.isNotEmpty) {
          String joined = addressParts.join(' ');
          joined = joined.replaceAll(RegExp(r',\s*$'), '').trim();
          _direccionController.text = joined;
        }
      }
    }
  }

  bool _isHeaderOrNoise(String text) {
    final u = text.toUpperCase();
    return u.contains('SERIE') || u.contains('SECCIÓN') || u.contains('BIO') || 
           u.contains('FECHA') || u.contains('EMISION') || u.contains('EXPIRACION') || 
           u.contains('ESTADO') || u.contains('BOLIVIA') || u.contains('IDENTIFICACION') ||
           u.contains('NACIMIENTO') || u.contains('FIRMA') || u.contains('REPUBLICA') ||
           u.contains('ESTUDIANTE') || u.contains('SANGUINEO') || u.contains('DIRECTORA') ||
           u.contains('OCUPACI') || u.contains('OCUPACION') || u.contains('GOMERCIANTE') ||
           u == 'NOMBRE' || u == 'NOMBRES' || u == 'APELLIDO' || u == 'APELLIDOS' || u == 'DOMICILIO' || u.contains('NOMBRES:') || u.contains('APELLIDOS:');
  }

  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);
      await db.insertCliente(ClientesCompanion(
        nombre: Value(_nombreController.text.trim()),
        apellido: Value(_apellidoController.text.trim()),
        cedula: Value(_cedulaController.text.trim()),
        telefono: Value(_telefonoController.text.trim()),
        email: Value(_emailController.text.trim()),
        direccion: Value(_direccionController.text.trim()),
      ));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Cliente registrado exitosamente!')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppConstants.routeClientes);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar cliente: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          CustomHeader(
            title: 'Nuevo Cliente',
            subtitle: 'Registro y Carnet OCR',
            onLeadingPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppConstants.routeHome);
              }
            },
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    primary: false,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Sección: Carnet OCR (Compacto)
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.document_scanner_rounded, size: 10, color: theme.colorScheme.primary),
                                      const SizedBox(width: 4),
                                      Text('Carnet (OCR)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _captureIdCard(true),
                                          child: Container(
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: _idCardFrontPath.isNotEmpty
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Image.file(File(_idCardFrontPath), fit: BoxFit.cover, width: double.infinity),
                                                  )
                                                : Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: const [
                                                      Icon(Icons.camera_alt, size: 10, color: Colors.blue),
                                                      Text('Anverso', style: TextStyle(fontSize: 7, color: Colors.blue)),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _captureIdCard(false),
                                          child: Container(
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: _idCardBackPath.isNotEmpty
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Image.file(File(_idCardBackPath), fit: BoxFit.cover, width: double.infinity),
                                                  )
                                                : Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: const [
                                                      Icon(Icons.photo_library, size: 10, color: Colors.green),
                                                      Text('Reverso', style: TextStyle(fontSize: 7, color: Colors.green)),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Sección: Información Personal (Ultra minimalista, ajustada)
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.badge_rounded, size: 10, color: theme.colorScheme.primary),
                                      const SizedBox(width: 4),
                                      Text('Información Personal', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  CustomTextField(
                                    label: 'Nombres',
                                    hint: 'Nombre',
                                    controller: _nombreController,
                                    validator: (value) => value == null || value.isEmpty ? 'Ingrese nombre' : null,
                                  ),
                                  const SizedBox(height: 2),
                                  CustomTextField(
                                    label: 'Apellidos',
                                    hint: 'Apellido',
                                    controller: _apellidoController,
                                    validator: (value) => value == null || value.isEmpty ? 'Ingrese apellido' : null,
                                  ),
                                  const SizedBox(height: 2),
                                  CustomTextField(
                                    label: 'No. C.I.',
                                    hint: 'Cédula de Identidad',
                                    controller: _cedulaController,
                                    validator: (value) => value == null || value.isEmpty ? 'Ingrese C.I.' : null,
                                  ),
                                  const SizedBox(height: 2),
                                  CustomTextField(
                                    label: 'Teléfono',
                                    hint: 'Teléfono',
                                    controller: _telefonoController,
                                    keyboardType: TextInputType.phone,
                                    validator: (value) => value == null || value.isEmpty ? 'Ingrese teléfono' : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 2),
                          
                          // Sección: Información de Contacto (Ultra minimalista, ajustada)
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.contact_mail_outlined, size: 10, color: theme.colorScheme.secondary),
                                      const SizedBox(width: 4),
                                      Text('Contacto', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  CustomTextField(
                                    label: 'Email (opcional)',
                                    hint: 'Email',
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 2),
                                  CustomTextField(
                                    label: 'Domicilio',
                                    hint: 'Domicilio',
                                    controller: _direccionController,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // Botón Guardar
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _guardarCliente,
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text('Guardar Cliente'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(34),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PROFESSIONAL FULL-SCREEN LANDSCAPE GALLERY OCR VALIDATION SCREEN
// -----------------------------------------------------------------------------
class GalleryOcrValidationScreen extends StatefulWidget {
  const GalleryOcrValidationScreen({
    super.key,
    required this.imagePath,
    required this.isFront,
    required this.ocrService,
  });

  final String imagePath;
  final bool isFront;
  final OcrService ocrService;

  @override
  State<GalleryOcrValidationScreen> createState() => _GalleryOcrValidationScreenState();
}

class _GalleryOcrValidationScreenState extends State<GalleryOcrValidationScreen> {
  bool _isProcessing = false;
  String _previewNombre = '';
  String _previewApellido = '';
  String _previewCedula = '';
  String _previewDireccion = '';
  bool _hasCaptured = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  String _cleanValue(String input, String prefix) {
    var v = input.trim();
    final u = v.toUpperCase();
    final p = prefix.toUpperCase();
    if (u.startsWith(p)) {
      v = v.substring(prefix.length).trim();
    }
    if (v.startsWith(':')) {
      v = v.substring(1).trim();
    }
    return v;
  }

  Future<void> _capturarDatos() async {
    setState(() => _isProcessing = true);
    try {
      final text = await widget.ocrService.recognizeText(widget.imagePath);
      final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

      if (widget.isFront) {
        int apellidosIdx = -1;
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          final lineUpper = line.toUpperCase();

          if (lineUpper.contains('N°') || lineUpper.contains('NO') || lineUpper.contains('Nº')) {
            final digits = line.replaceAll(RegExp(r'[^0-9]'), '');
            if (digits.length >= 4) {
              _previewCedula = digits;
            } else if (i + 1 < lines.length) {
              final nextDigits = lines[i + 1].replaceAll(RegExp(r'[^0-9]'), '');
              if (nextDigits.length >= 4) {
                _previewCedula = nextDigits;
              }
            }
          }
          if (lineUpper.contains('APELLIDO')) {
            apellidosIdx = i;
          }
        }

        if (apellidosIdx != -1) {
          for (int i = apellidosIdx + 1; i < lines.length; i++) {
            String candidate = lines[i];
            if (!_isHeaderOrNoise(candidate) && !RegExp(r'^[0-9]+$').hasMatch(candidate) && candidate.length > 1) {
              _previewNombre = candidate;
              if (i + 1 < lines.length) {
                String candidateLast = lines[i + 1];
                if (!_isHeaderOrNoise(candidateLast) && !RegExp(r'^[0-9]+$').hasMatch(candidateLast) && candidateLast.length > 1) {
                  _previewApellido = candidateLast;
                }
              }
              break;
            }
          }
        }

        if (_previewCedula.isEmpty) {
          for (final line in lines) {
            final digits = line.replaceAll(RegExp(r'[^0-9]'), '');
            if (digits.length >= 5 && digits.length <= 9 && digits != '21333' && digits != '11222' && digits != '42442' && digits != '42443') {
              _previewCedula = digits;
              break;
            }
          }
        }
      } else {
        int domicilioIdx = -1;
        for (int i = 0; i < lines.length; i++) {
          final u = lines[i].toUpperCase();
          if (u.contains('DOMICILIO') || u.contains('DOMICLIO') || u.contains('DOHCO') || u.contains('DOMI')) {
            domicilioIdx = i;
            break;
          }
        }
        if (domicilioIdx == -1) {
          for (int i = 0; i < lines.length; i++) {
            if (lines[i].toUpperCase().contains('NACIMIENTO') || lines[i].toUpperCase().contains('LA PAZ')) {
              domicilioIdx = i + 2;
              break;
            }
          }
        }
        if (domicilioIdx != -1) {
          final addressParts = <String>[];
          for (int i = domicilioIdx + 1; i < lines.length; i++) {
            String c = lines[i];
            c = _cleanValue(c, 'DOMICILIO:');
            c = _cleanValue(c, 'DOMICILIO');
            c = _cleanValue(c, 'DOMICLIO:');
            c = _cleanValue(c, 'DOMICLIO');
            c = _cleanValue(c, 'DOHCO.:');
            c = _cleanValue(c, 'DOHCO.');
            
            final u = c.toUpperCase();
            if (u.contains('OCUPACI') || u.contains('OCUPACION') || u.contains('GOMERCIANTE') || u.contains('ESTADO') || u.contains('SOLTERO') || u.contains('CASADO') || u.contains('BOL') || u.contains('PATRO') || u.contains('PULGAR') || u.contains('ECTHRA') || u.contains('AECUT')) {
              break;
            }
            if (!_isHeaderOrNoise(c) && c.length > 2 && !u.contains('OCUPACI') && !u.contains('OCUPACION') && !u.contains('GOMERCIANTE')) {
              addressParts.add(c);
            }
          }
          if (addressParts.isNotEmpty) {
            String joined = addressParts.join(' ');
            joined = joined.replaceAll(RegExp(r',\s*$'), '').trim();
            _previewDireccion = joined;
          }
        }
      }
      setState(() => _hasCaptured = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al capturar datos: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  bool _isHeaderOrNoise(String text) {
    final u = text.toUpperCase();
    return u.contains('SERIE') || u.contains('SECCIÓN') || u.contains('BIO') || 
           u.contains('FECHA') || u.contains('EMISION') || u.contains('EXPIRACION') || 
           u.contains('ESTADO') || u.contains('BOLIVIA') || u.contains('IDENTIFICACION') ||
           u.contains('NACIMIENTO') || u.contains('FIRMA') || u.contains('REPUBLICA') ||
           u.contains('ESTUDIANTE') || u.contains('SANGUINEO') || u.contains('DIRECTORA') ||
           u.contains('OCUPACI') || u.contains('OCUPACION') || u.contains('GOMERCIANTE') ||
           u == 'NOMBRE' || u == 'NOMBRES' || u == 'APELLIDO' || u == 'APELLIDOS' || u == 'DOMICILIO' || u.contains('NOMBRES:') || u.contains('APELLIDOS:');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          children: [
            // Left side: Large interactive zoomable image maximizing space (NO APPBAR)
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.grey.shade100,
                child: InteractiveViewer(
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 0.5,
                  maxScale: 6.0,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.file(File(widget.imagePath), fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ),
            
            // Right side: Compact button, preview, and action buttons
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Compact button centered and sized to text and icon
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _capturarDatos,
                        icon: _isProcessing 
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.document_scanner, size: 16),
                        label: const Text('CAPTURAR DATOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'PREVIEW DE DATOS CAPTURADOS:',
                      style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.isFront) ...[
                                Text(
                                  'NOMBRES: ${_previewNombre.isNotEmpty ? _previewNombre : '---'}',
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'APELLIDOS: ${_previewApellido.isNotEmpty ? _previewApellido : '---'}',
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'N°: ${_previewCedula.isNotEmpty ? _previewCedula : '---'}',
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ] else ...[
                                Text(
                                  'DOMICILIO: ${_previewDireccion.isNotEmpty ? _previewDireccion : '---'}',
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Cancelar', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _hasCaptured ? () {
                              Navigator.pop(context, {
                                'nombre': _previewNombre,
                                'apellido': _previewApellido,
                                'cedula': _previewCedula,
                                'direccion': _previewDireccion,
                              });
                            } : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Confirmar y Usar', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
