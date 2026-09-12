import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prenda_master/core/constants/app_constants.dart';
import 'package:prenda_master/presentation/widgets/custom_header.dart';
import 'package:prenda_master/presentation/widgets/custom_text_field.dart';

class NuevoClienteScreen extends ConsumerStatefulWidget {
  const NuevoClienteScreen({super.key});

  @override
  ConsumerState<NuevoClienteScreen> createState() => _NuevoClienteScreenState();
}

class _NuevoClienteScreenState extends ConsumerState<NuevoClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      // TODO: Save to database via provider
      await Future.delayed(const Duration(seconds: 2)); // Simulate save
      if (!mounted) return;
      context.go(AppConstants.routeClientes);
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
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Header personalizado
          CustomHeader(
            title: 'Nuevo Cliente',
            subtitle: 'Registro de información personal',
            onLeadingPressed: () => context.pop(),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    primary: false,
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Sección: Información Personal
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.badge_rounded,
                                          size: 20,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Información Personal',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    label: 'Nombre',
                                    hint: 'Ingrese el nombre',
                                    controller: _nombreController,
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Ingrese el nombre'
                                            : null,
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    label: 'Apellido',
                                    hint: 'Ingrese el apellido',
                                    controller: _apellidoController,
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Ingrese el apellido'
                                            : null,
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    label: 'Teléfono',
                                    hint: 'Ingrese el teléfono',
                                    controller: _telefonoController,
                                    keyboardType: TextInputType.phone,
                                    prefixIcon: Icon(
                                      Icons.phone_outlined,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Ingrese el teléfono'
                                            : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Sección: Información de Contacto
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.secondaryContainer,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.contact_mail_outlined,
                                          size: 20,
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Información de Contacto',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    label: 'Email (opcional)',
                                    hint: 'correo@ejemplo.com',
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    label: 'Dirección (opcional)',
                                    hint: 'Dirección completa',
                                    controller: _direccionController,
                                    maxLines: 3,
                                    prefixIcon: Icon(
                                      Icons.location_on_outlined,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Botón Guardar
                          InkWell(
                            onTap: _isLoading ? null : _guardarCliente,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary.withOpacity(0.8),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.save_rounded,
                                    color: theme.colorScheme.onPrimary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Guardar Cliente',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ],
                              ),
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