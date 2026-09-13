import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prenda_master/core/constants/app_constants.dart';
import 'package:prenda_master/presentation/widgets/custom_header.dart';
import 'package:prenda_master/presentation/widgets/filter_chip_group.dart';
import 'package:prenda_master/presentation/widgets/loan_card.dart';
import 'package:prenda_master/providers/database_providers.dart';
import 'package:prenda_master/data/app_database.dart';

class PrestamosScreen extends ConsumerStatefulWidget {
  const PrestamosScreen({super.key});

  @override
  ConsumerState<PrestamosScreen> createState() => _PrestamosScreenState();
}

class _PrestamosScreenState extends ConsumerState<PrestamosScreen> {
  String _selectedFilter = 'Todos';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prestamosAsync = ref.watch(prestamosProvider);
    final clientesAsync = ref.watch(clientesProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Header personalizado con botón atrás
          CustomHeader(
            title: 'Gestión de Préstamos',
            subtitle: 'Control de cartera y garantías',
            onLeadingPressed: () => context.go(AppConstants.routeHome),
            actions: [
              InkWell(
                onTap: () => context.go(AppConstants.routeNuevoPrestamo),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_card_rounded,
                    size: 24,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          
          // Sección de filtros
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.rectangle,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  FilterChipGroup(
                    options: ['Todos', 'Activos', 'Vencidos', 'Pendientes', 'Pagados'],
                    selectedOption: _selectedFilter,
                    onSelected: (option) {
                      setState(() {
                        _selectedFilter = option;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Lista de préstamos real desde Base de Datos
          Expanded(
            child: prestamosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (prestamos) {
                final clientesMap = <int, Cliente>{};
                clientesAsync.maybeWhen(
                  data: (clientes) {
                    for (var c in clientes) {
                      clientesMap[c.id] = c;
                    }
                  },
                  orElse: () {},
                );

                final filtrados = prestamos.where((p) {
                  if (_selectedFilter == 'Todos') return true;
                  if (_selectedFilter == 'Activos' && p.estado.toLowerCase() == 'activo') return true;
                  if (_selectedFilter == 'Vencidos' && p.estado.toLowerCase() == 'vencido') return true;
                  if (_selectedFilter == 'Pendientes' && p.estado.toLowerCase() == 'pendiente') return true;
                  if (_selectedFilter == 'Pagados' && p.estado.toLowerCase() == 'pagado') return true;
                  return false;
                }).toList();

                if (filtrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('No hay préstamos en esta categoría', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: filtrados.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = filtrados[index];
                    final cliente = clientesMap[p.clienteId];
                    final clientName = cliente != null ? '${cliente.nombre} ${cliente.apellido}' : 'Cliente #${p.clienteId}';
                    return LoanCard(
                      loanNumber: p.id,
                      clientName: clientName,
                      amount: p.monto,
                      currency: p.moneda,
                      status: p.estado,
                      dueDate: p.fechaVencimiento,
                      onTap: () {
                        print('Préstamo seleccionado: #${p.id}');
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
