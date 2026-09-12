import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prenda_master/core/constants/app_constants.dart';
import 'package:prenda_master/core/theme/app_theme.dart';
import 'package:prenda_master/services/auth_service.dart';
import 'package:prenda_master/services/backup_service.dart';
import 'package:prenda_master/services/notification_service.dart';

import 'admin_backup_settings_model.dart';
export 'admin_backup_settings_model.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  static String routeName = 'Backup';
  static String routePath = '/backup';

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  late AdminBackupSettingsModel _model;
  bool _isLoading = false;
  bool _isSignedIn = false;
  List<dynamic> _backups = []; // List of drive.File
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _model = AdminBackupSettingsModel();
    _checkAuthStatus();
    _loadBackups();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    final authService = ref.read(googleAuthServiceProvider);
    setState(() {
      _isSignedIn = authService.isSignedIn();
    });
  }

  Future<void> _loadBackups() async {
    if (!_isSignedIn) return;
    try {
      final backupService = ref.read(backupServiceProvider);
      final backups = await backupService.listBackups();
      setState(() {
        _backups = backups;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading backups: $e';
        _backups = [];
      });
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
        _error = 'Error signing in: $e';
        _isLoading = false;
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
        _error = 'Error signing out: $e';
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
          _success = 'Backup completado exitosamente';
          _error = null;
        });
        await _loadBackups(); // Refresh list
      } else {
        setState(() {
          _error = 'Error en el backup';
          _success = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error en el backup: $e';
        _success = null;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup(dynamic backup) async {
    // TODO: Implement restore functionality
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restauración no implementada aún')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup y Restauración'),
        actions: [
          if (_isSignedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _isLoading ? null : _signOut,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- PARÁMETROS FINANCIEROS ---
                    _SectionHeader(title: 'Parámetros Financieros'),
                    _SettingRow(
                      tone: AppTheme.of(context).primary,
                      icon: Icons.percent_rounded,
                      label: 'Tasa de Interés Mensual',
                      value: _model.tasaInteres != null
                          ? '${_model.tasaInteres!.toString()}%'
                          : '---',
                    ),
                    _SettingRow(
                      tone: AppTheme.of(context).success,
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Máximo Préstamo / Tasación',
                      value: _model.maxLoanPct != null
                          ? '${_model.maxLoanPct!.toString()}%'
                          : '---',
                    ),
                    _SettingRow(
                      tone: AppTheme.of(context).error,
                      icon: Icons.priority_high_rounded,
                      label: 'Interés Moratorio Diario',
                      value: _model.interesMora != null
                          ? '${_model.interesMora!.toString()}%'
                          : '---',
                    ),
                    _SettingRow(
                      tone: AppTheme.of(context).warning,
                      icon: Icons.event_repeat_rounded,
                      label: 'Días de Gracia',
                      value: _model.diasGracia != null
                          ? '${_model.diasGracia!.toString()} días'
                          : '---',
                    ),
                    const SizedBox(height: 16),

                    // --- RESPALDO AUTOMÁTICO ---
                    _SectionHeader(title: 'Respaldo Automático'),
                    _ContainerWithBorder(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Color(0xFFEA4335),
                                  shape: BoxShape.circle,
                                ),
                                alignment: AlignmentDirectional(0, 0),
                                child: Text(
                                  'G',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFFFFFF),
                                  ),
                                ),
                              ),
                              const Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Google Drive Backup',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.0,
                                      fontSize: 14,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  Text(
                                    'Sincronizado: hace 2 horas',
                                    style: TextStyle(
                                      fontSize: 12,
                                      letterSpacing: 0.0,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ).divide(const SizedBox(width: 16)),
                          const Divider(
                            height: 16,
                            thickness: 1,
                            indent: 0,
                            endIndent: 0,
                            color: Color(0xFFE0E0E0),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TextFieldWidget(
                                label: 'Correo Destino',
                                labelPresent: true,
                                hint: 'Type here...',
                                value: _model.gmailBackup,
                                onChange: (_) {},
                                onSubmit: 'form.save_config()',
                                variant: 'filled',
                                error: false,
                              ),
                              const SizedBox(height: 8),
                              _TextFieldWidget(
                                label: 'Hora',
                                labelPresent: true,
                                hint: 'Type here...',
                                value: _model.horaBackup,
                                onChange: (_) {},
                                onSubmit: 'form.save_config()',
                                variant: 'outlined',
                                error: false,
                              ),
                            ],
                          ).divide(const SizedBox(height: 8)),
                          _ButtonWidget(
                            icon: Icons.backup_rounded,
                            iconColor: AppTheme.of(context).primaryText,
                            iconSize: 24,
                            content: 'Realizar Backup Ahora',
                            variant: 'outline',
                            size: 'medium',
                            fullWidth: true,
                            onPressed: _isLoading || !_isSignedIn ? null : _triggerBackup,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- SEGURIDAD Y ACCESO ---
                    _SectionHeader(title: 'Seguridad y Acceso'),
                    _ContainerWithBorder(
                      borderRadius: 12,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.of(context).accent12,
                                borderRadius: BorderRadius.circular(9999),
                                shape: BoxShape.rectangle,
                              ),
                              alignment: AlignmentDirectional(0, 0),
                              child: const Icon(
                                Icons.fingerprint_rounded,
                                color: Color(0xFF888888),
                                size: 20,
                              ),
                            ),
                            const Text(
                              'Autenticación Biométrica',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.0,
                                fontSize: 14,
                                color: Color(0xFF212121),
                              ),
                            ),
                          ].divide(const SizedBox(width: 16)),
                          SwitchComponentWidget(
                            label: '',
                            labelPresent: false,
                            variant: 'iOS',
                            active: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- CATÁLOGOS ---
                    _SectionHeader(title: 'Catálogos'),
                    _SettingRow(
                      tone: AppTheme.of(context).primary,
                      icon: Icons.category_rounded,
                      label: 'Tipos de Prenda',
                      value: '12 activos',
                    ),
                    _SettingRow(
                      tone: AppTheme.of(context).primary,
                      icon: Icons.payments_rounded,
                      label: 'Moneda Local',
                      value: 'BOB (Bs)',
                    ),
                    const SizedBox(height: 16),

                    // --- ZONA DE PELIGRO ---
                    _DangerZone(),
                  ],
                ),
              ),
            ),
    );
  }
}

// Helper widgets for cleaner code

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 8),
      child: Text(
        title,
        style: AppTheme.of(context).titleSmall.copyWith(
          font: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.normal,
          ),
          letterSpacing: 0.0,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.normal,
          lineHeight: 1.4,
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final Color tone;
  final IconData icon;
  final String label;
  final String value;
  const _SettingRow({
    required this.tone,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 8),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppTheme.of(context).primaryText,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTheme.of(context).bodyMedium.copyWith(
                font: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.normal,
                ),
                letterSpacing: 0.0,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.normal,
                color: AppTheme.of(context).primaryText,
              ),
            ),
          ),
          Text(
            value,
            style: AppTheme.of(context).bodyMedium.copyWith(
              font: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.normal,
              ),
              letterSpacing: 0.0,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.normal,
              color: AppTheme.of(context).secondaryText,
            ),
          ),
        ],
      ).divide(const SizedBox(width: 16)),
    );
  }
}

class _ContainerWithBorder extends StatelessWidget {
  final BorderRadius? borderRadius;
  final Widget child;
  const _ContainerWithBorder({
    this.borderRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.of(context).secondaryBackground,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        shape: BoxShape.rectangle,
        border: Border(
          color: AppTheme.of(context).alternate,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _TextFieldWidget extends StatelessWidget {
  final String label;
  final bool labelPresent;
  final String hint;
  final String value;
  final void Function(String?) onChange;
  final String onSubmit;
  final String variant;
  final bool error;
  final IconData? leadingIcon;
  final bool? leadingIconPresent;
  final bool? trailingIconPresent;
  final IconData? trailingIcon;

  const _TextFieldWidget({
    required this.label,
    required this.labelPresent,
    required this.hint,
    required this.value,
    required this.onChange,
    required this.onSubmit,
    required this.variant,
    required this.error,
    this.leadingIcon,
    this.leadingIconPresent,
    this.trailingIconPresent,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFieldWidget(
      label: label,
      labelPresent: labelPresent,
      helper: '',
      helperPresent: false,
      leadingIcon: leadingIcon ?? Icons.mail_rounded,
      leadingIconPresent: leadingIconPresent ?? true,
      trailingIconPresent: trailingIconPresent ?? false,
      hint: hint,
      value: value,
      onChange: onChange,
      onSubmit: onSubmit,
      variant: variant,
      error: error,
    );
  }
}

class _ButtonWidget extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final String content;
  final String variant;
  final String size;
  final bool fullWidth;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _ButtonWidget({
    required this.icon,
    required this.iconColor,
    required this.iconSize,
    required this.content,
    required this.variant,
    required this.size,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ButtonWidget(
      iconPresent: true,
      iconEndPresent: false,
      icon: Icon(icon, color: iconColor, size: iconSize),
      content: content,
      variant: variant,
      size: size,
      fullWidth: fullWidth,
      loading: isLoading,
      disabled: false,
      onPressed: onPressed,
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.of(context).error5,
          borderRadius: BorderRadius.circular(16),
          shape: BoxShape.rectangle,
          border: Border(
            color: AppTheme.of(context).error20,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zona de Peligro',
                style: AppTheme.of(context).titleSmall.copyWith(
                  font: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontStyle: AppTheme.of(context).titleSmall.fontStyle,
                  ),
                  color: AppTheme.of(context).error,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                  fontStyle: AppTheme.of(context).titleSmall.fontStyle,
                  lineHeight: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Al limpiar la base de datos se borrarán todos los clientes, préstamos y fotos de forma permanente.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.0,
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 16),
              _ButtonWidget(
                icon: Icons.delete_forever_rounded,
                iconColor: AppTheme.of(context).primaryText,
                iconSize: 24,
                content: 'Limpiar Base de Datos',
                variant: 'destructive',
                size: 'small',
                fullWidth: false,
                onPressed: () {
                  // TODO: Implement data clearing with confirmation dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función no implementada aún')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}