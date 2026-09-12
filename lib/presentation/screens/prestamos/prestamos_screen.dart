import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prenda_master/core/constants/app_constants.dart';
import 'package:prenda_master/core/theme/app_theme.dart';
import 'package:prenda_master/providers/database_providers.dart';
import 'package:prenda_master/data/app_database.dart';

class PrestamosScreen extends ConsumerWidget {
  const PrestamosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prestamosAsync = ref.watch(prestamosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Préstamos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go(AppConstants.routeNuevoPrestamo),
          ),
        ],
      ),
      body: prestamosAsync.when(
        data: (prestamos) {
          if (prestamos.isEmpty) {
            return const Center(
              child: Text('No hay préstamos registrados'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prestamos.length,
            itemBuilder: (context, index) {
              final prestamo = prestamos[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: Text('Préstamo #${prestamo.id}'),
                  subtitle: Text('Cliente ID: ${prestamo.clienteId} - \$${prestamo.monto.toStringAsFixed(2)} ${prestamo.moneda}'),
                  trailing: Text(
                    prestamo.estado,
                    style: TextStyle(
                      color: prestamo.estado == 'Vencido' ? Colors.red : Colors.green,
                    ),
                  ),
                  onTap: () => context.go('${AppConstants.routeDetallePrestamo}/${prestamo.id}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(
          child: Text('Error: $e'),
        ),
      ),
    );
  }
}