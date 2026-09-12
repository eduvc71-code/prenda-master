import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prenda_master/core/constants/app_constants.dart';
import 'package:prenda_master/presentation/widgets/custom_header.dart';
import 'package:prenda_master/presentation/widgets/filter_chip_group.dart';
import 'package:prenda_master/presentation/widgets/loan_card.dart';

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
    
    // Datos mock para demostración
    final prestamosMock = [
      {'number': 1001, 'client': 'Juan Pérez', 'amount': 1500.0, 'status': 'Activo', 'dueDate': DateTime.now().add(const Duration(days: 15))},
      {'number': 1002, 'client': 'María García', 'amount': 800.0, 'status': 'Vencido', 'dueDate': DateTime.now().subtract(const Duration(days: 5))},
      {'number': 1003, 'client': 'Carlos López', 'amount': 2400.0, 'status': 'Activo', 'dueDate': DateTime.now().add(const Duration(days: 30))},
      {'number': 1004, 'client': 'Ana Martínez', 'amount': 500.0, 'status': 'Pagado', 'dueDate': DateTime.now().subtract(const Duration(days: 10))},
      {'number': 1005, 'client': 'Pedro Sánchez', 'amount': 3000.0, 'status': 'Pendiente', 'dueDate': DateTime.now().add(const Duration(days: 7))},
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Header personalizado
          CustomHeader(
            title: 'Gestión de Préstamos',
            subtitle: 'Control de cartera y garantías',
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
                  // Filtros
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
          
          // Lista de préstamos
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: prestamosMock.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final prestamo = prestamosMock[index];
                return LoanCard(
                  loanNumber: prestamo['number'] as int,
                  clientName: prestamo['client'] as String,
                  amount: prestamo['amount'] as double,
                  status: prestamo['status'] as String,
                  dueDate: prestamo['dueDate'] as DateTime,
                  onTap: () {
                    // TODO: Navegar al detalle del préstamo
                    print('Préstamo seleccionado: #${prestamo['number']}');
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