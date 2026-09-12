// ignore: unused_import
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import 'package:prenda_master/presentation/screens/splash/splash_screen.dart';
import 'package:prenda_master/presentation/screens/login_pin/login_pin_screen.dart';
import 'package:prenda_master/presentation/screens/home/home_screen.dart';
import 'package:prenda_master/presentation/screens/prestamos/prestamos_screen.dart';
import 'package:prenda_master/presentation/screens/prestamos/nuevo_prestamo_screen.dart';
import 'package:prenda_master/presentation/screens/prestamos/detalle_prestamo_screen.dart';
import 'package:prenda_master/presentation/screens/prestamos/edit_prestamo_screen.dart';
import 'package:prenda_master/presentation/screens/clientes/clientes_screen.dart';
import 'package:prenda_master/presentation/screens/clientes/nuevo_cliente_screen.dart';
import 'package:prenda_master/presentation/screens/clientes/edit_cliente_screen.dart';
import 'package:prenda_master/presentation/screens/pagos/pago_screen.dart';
import 'package:prenda_master/presentation/screens/alertas/alertas_screen.dart';
import 'package:prenda_master/presentation/screens/reportes/reportes_screen.dart';
import 'package:prenda_master/presentation/screens/admin/backup_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppConstants.routeSplash,
  routes: [
    GoRoute(
      path: AppConstants.routeSplash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppConstants.routeLoginPin,
      builder: (context, state) => const LoginPinScreen(),
    ),
    GoRoute(
      path: AppConstants.routeHome,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppConstants.routePrestamos,
      builder: (context, state) => const PrestamosScreen(),
    ),
    GoRoute(
      path: AppConstants.routeNuevoPrestamo,
      builder: (context, state) => const NuevoPrestamoScreen(),
    ),
    GoRoute(
      path: AppConstants.routeDetallePrestamo,
      builder: (context, state) {
        final prestamoId = state.pathParameters['id'] ?? '';
        return DetallePrestamoScreen(prestamoId: prestamoId);
      },
    ),
    GoRoute(
      path: '${AppConstants.routePrestamos}/:id/edit',
      builder: (context, state) {
        final prestamoId = int.parse(state.pathParameters['id']!);
        return EditPrestamoScreen(prestamoId: prestamoId);
      },
    ),
    GoRoute(
      path: AppConstants.routeClientes,
      builder: (context, state) => const ClientesScreen(),
    ),
    GoRoute(
      path: AppConstants.routeNuevoCliente,
      builder: (context, state) => const NuevoClienteScreen(),
    ),
    GoRoute(
      path: '${AppConstants.routeClientes}/:id/edit',
      builder: (context, state) {
        final clienteId = int.parse(state.pathParameters['id']!);
        return EditClienteScreen(clienteId: clienteId);
      },
    ),
    GoRoute(
      path: AppConstants.routePagos,
      builder: (context, state) => const PagoScreen(),
    ),
    GoRoute(
      path: AppConstants.routeAlertas,
      builder: (context, state) => const AlertasScreen(),
    ),
    GoRoute(
      path: AppConstants.routeReportes,
      builder: (context, state) => const ReportesScreen(),
    ),
    GoRoute(
      path: AppConstants.routeBackup,
      builder: (context, state) => const BackupScreen(),
    ),
  ],
);