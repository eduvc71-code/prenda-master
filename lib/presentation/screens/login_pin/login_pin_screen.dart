import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prenda_master/core/constants/app_constants.dart';
import 'package:prenda_master/core/theme/app_theme.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

final storageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final authProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

class LoginPinScreen extends ConsumerStatefulWidget {
  const LoginPinScreen({super.key});

  @override
  ConsumerState<LoginPinScreen> createState() => _LoginPinScreenState();
}

class _LoginPinScreenState extends ConsumerState<LoginPinScreen> {
  final _pinController = TextEditingController();
  String _enteredPin = '';
  bool _isLoading = false;
  bool _canUseBiometrics = false;
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      if (canCheckBiometrics) {
        final List<BiometricType> availableBiometrics =
            await _auth.getAvailableBiometrics();
        if (availableBiometrics.isNotEmpty) {
          setState(() => _canUseBiometrics = true);
        }
      }
    } catch (e) {
      // Biometrics not available
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final bool authenticated = await _auth.authenticate(
        localizedReason: 'Escanea tu huella para acceder a PrendaMaster',
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );
      if (authenticated && mounted) {
        context.go(AppConstants.routeHome);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de autenticación: $e')),
        );
      }
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);
    try {
      final storage = ref.read(storageProvider);
      final storedPin = await storage.read(key: AppConstants.prefsKeyPin);
      if (_enteredPin == storedPin) {
        _enteredPin = '';
        _pinController.clear();
        if (!mounted) return;
        context.go(AppConstants.routeHome);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN incorrecto')),
        );
        _enteredPin = '';
        _pinController.clear();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < AppConstants.pinLength && !_isLoading) {
      setState(() {
        _enteredPin += digit;
        _pinController.text = _enteredPin;
      });
      if (_enteredPin.length == AppConstants.pinLength) {
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty && !_isLoading) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _pinController.text = _enteredPin;
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock,
                size: 64,
                color: Colors.indigo,
              ),
              const SizedBox(height: 32),
              Text(
                'Ingresa tu PIN',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Para acceder a PrendaMaster',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 40),
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  AppConstants.pinLength,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _enteredPin.length
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Numeric keypad
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                crossAxisCount: 3,
                children: [
                  for (int i = 1; i <= 9; i++)
                    _buildKeyButton(
                      i.toString(),
                      onPressed: () => _onDigitPressed(i.toString()),
                    ),
                  _buildKeyButton(
                    '',
                    onPressed: () {},
                  ),
                  _buildKeyButton(
                    '0',
                    onPressed: () => _onDigitPressed('0'),
                  ),
                  _buildKeyButton(
                    Icons.backspace,
                    isIcon: true,
                    onPressed: _onDeletePressed,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Biometric option
              if (_canUseBiometrics)
                TextButton.icon(
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Usar huella'),
                  onPressed: _isLoading ? null : _authenticateWithBiometrics,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyButton(
    dynamic label, {
    bool isIcon = false,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isIcon
          ? Icon(label, size: 24)
          : Text(
              label,
              style: const TextStyle(fontSize: 20),
            ),
    );
  }
}