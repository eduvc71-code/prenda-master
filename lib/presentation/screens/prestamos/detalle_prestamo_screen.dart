import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prenda_master/core/constants/app_constants.dart';
import 'package:prenda_master/core/theme/app_theme.dart';
import 'package:prenda_master/providers/database_providers.dart';
import 'package:prenda_master/data/app_database.dart';

class DetallePrestamoScreen extends ConsumerWidget {
  final String prestamoId;

  const DetallePrestamoScreen({
    super.key,
    required this.prestamoId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prestamoAsync = ref.watch(prestamoByIdProvider(int.parse(prestamoId)));
    final prendasAsync = ref.watch(prendasByPrestamoProvider(int.parse(prestamoId)));
    final pagosAsync = ref.watch(pagosByPrestamoProvider(int.parse(prestamoId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Préstamo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Edit prestamo - navigate to edit screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // TODO: Delete prestamo with confirmation
            },
          ),
        ],
      ),
      body: prestamoAsync.when(
        data: (prestamo) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Prenda photo section
              if (prendasAsync.hasValue)
                prendasAsync.when(
                  data: (prendas) {
                    if (prendas.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Foto de la Prenda',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(prendas.first.fotoPath),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, stack) => const SizedBox.shrink(),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información del Préstamo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      _buildDetailRow('ID', prestamo.id.toString()),
                      _buildDetailRow('Monto', '\$ ${prestamo.monto.toStringAsFixed(2)} ${prestamo.moneda}'),
                      _buildDetailRow('Interés Mensual', '${prestamo.interesMensual}%'),
                      _buildDetailRow('Plazo', '${prestamo.plazoDias} días'),
                      _buildDetailRow('Fecha de Inicio', '${prestamo.fechaInicio.day}/${prestamo.fechaInicio.month}/${prestamo.fechaInicio.year}'),
                      _buildDetailRow('Fecha de Vencimiento', '${prestamo.fechaVencimiento.day}/${prestamo.fechaVencimiento.month}/${prestamo.fechaVencimiento.year}'),
                      _buildDetailRow('Estado', prestamo.estado),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Historial de Pagos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      pagosAsync.when(
                        data: (pagos) {
                          if (pagos.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No hay pagos registrados'),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pagos.length,
                            itemBuilder: (context, index) {
                              final pago = pagos[index];
                              return ListTile(
                                leading: const Icon(Icons.check_circle, color: Colors.green),
                                title: Text('\$ ${pago.monto.toStringAsFixed(2)}'),
                                subtitle: Text('${pago.fechaPago.day}/${pago.fechaPago.month}/${pago.fechaPago.year}'),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, stack) => Center(child: Text('Error: $e')),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () {
            // TODO: Register payment - navigate to payment screen
          },
          icon: const Icon(Icons.attach_money),
          label: const Text('Registrar Pago'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}