import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:prenda_master/core/constants/app_constants.dart';
import 'package:prenda_master/services/auth_service.dart';
import 'package:prenda_master/services/backup_service.dart';

final appSettingsStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isLoading = false;
  bool _isSignedIn = false;
  List<dynamic> _backups = [];
  String? _error;
  String? _success;
  
  String _tasaInteres = '3.0';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkAuthStatus();
    _loadBackups();
  }

  Future<void> _loadSettings() async {
    final storage = ref.read(appSettingsStorageProvider);
    final tasa = await storage.read(key: 'tasa_interes_mensual');
    if (tasa != null && mounted) {
      setState(() => _tasaInteres = tasa);
    }
  }

  Future<void> _saveTasaInteres(String nuevaTasa) async {
    final storage = ref.read(appSettingsStorageProvider);
    await storage.write(key: 'tasa_interes_mensual', value: nuevaTasa);
    setState(() => _tasaInteres = nuevaTasa);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Tasa de interés actualizada con éxito!')),
    );
  }

  Future<void> _showEditTasaDialog() async {
    final controller = TextEditingController(text: _tasaInteres);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Tasa de Interés Mensual'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Tasa (%)',
            suffixText: '%',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _saveTasaInteres(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAuthStatus() async {
    final authService = ref.read(googleAuthServiceProvider);
    if (mounted) {
      setState(() {
        _isSignedIn = authService.isSignedIn();
      });
    }
  }

  Future<void> _loadBackups() async {
    if (!_isSignedIn) return;
    try {
      final backupService = ref.read(backupServiceProvider);
      final backups = await backupService.listBackups();
      if (mounted) {
        setState(() {
          _backups = backups;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar respaldos: $e';
          _backups = [];
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(googleAuthServiceProvider);
      await authService.signIn();
      if (!mounted) return;
      setState(() {
        _isSignedIn = true;
        _error = null;
      });
      await _loadBackups();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al iniciar sesión: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(googleAuthServiceProvider);
      await authService.signOut();
      if (!mounted) return;
      setState(() {
        _isSignedIn = false;
        _backups = [];
        _error = null;
        _success = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cerrar sesión: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _triggerBackup() async {
    setState(() => _isLoading = true);
    try {
      final backupService = ref.read(backupServiceProvider);
      final success = await backupService.backupDatabase();
      if (!mounted) return;
      if (success) {
        setState(() {
          _success = '¡Respaldo en Google Drive completado!';
          _error = null;
        });
        await _loadBackups();
      } else {
        setState(() {
          _error = 'No se pudo completar el respaldo';
          _success = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error en el respaldo: $e';
        _success = null;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración y Backup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppConstants.routeHome);
            }
          },
        ),
        actions: [
          if (_isSignedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión Google',
              onPressed: _isLoading ? null : _signOut,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Google Drive Backup Section (Ultra compact)
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEA4335),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'G',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Google Drive Backup',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      _isSignedIn ? 'Conectado' : 'Desconectado',
                                      style: TextStyle(
                                        color: _isSignedIn ? Colors.green : Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_error != null)
                            Container(
                              padding: const EdgeInsets.all(6),
                              margin: const EdgeInsets.only(bottom: 8),
                              color: Colors.red.shade50,
                              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                            ),
                          if (_success != null)
                            Container(
                              padding: const EdgeInsets.all(6),
                              margin: const EdgeInsets.only(bottom: 8),
                              color: Colors.green.shade50,
                              child: Text(_success!, style: const TextStyle(color: Colors.green, fontSize: 12)),
                            ),
                          if (!_isSignedIn)
                            OutlinedButton.icon(
                              onPressed: _signInWithGoogle,
                              icon: const Icon(Icons.login, size: 16),
                              label: const Text('Conectar Google'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(40),
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _triggerBackup,
                              icon: const Icon(Icons.backup, size: 16),
                              label: const Text('Respaldar Ahora'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(40),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Financial Parameters Section
                  const Text(
                    'PARÁMETROS FINANCIEROS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.percent, size: 20),
                          title: const Text('Tasa de Interés Mensual', style: TextStyle(fontSize: 13)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$_tasaInteres%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit, size: 14, color: Colors.blue),
                            ],
                          ),
                          onTap: _showEditTasaDialog,
                        ),
                        const Divider(height: 1),
                        const ListTile(
                          dense: true,
                          leading: Icon(Icons.account_balance_wallet, size: 20),
                          title: Text('Máximo Préstamo / Tasación', style: TextStyle(fontSize: 13)),
                          subtitle: Text('Informativo (No afecta cálculo)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          trailing: Text('70.0%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        const Divider(height: 1),
                        const ListTile(
                          dense: true,
                          leading: Icon(Icons.priority_high, size: 20),
                          title: Text('Interés Moratorio Diario', style: TextStyle(fontSize: 13)),
                          subtitle: Text('Informativo (Sin cálculo activo)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          trailing: Text('0.5%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Danger Zone Section (Ultra compact)
                  Card(
                    color: Colors.red.shade50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Zona de Peligro',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Borra permanentemente clientes, préstamos y fotos.',
                            style: TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Acción protegida en modo demo')),
                              );
                            },
                            icon: const Icon(Icons.delete_forever, color: Colors.red, size: 16),
                            label: const Text('Limpiar Base de Datos', style: TextStyle(color: Colors.red, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              minimumSize: const Size.fromHeight(36),
                            ),
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
