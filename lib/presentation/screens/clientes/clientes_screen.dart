import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prenda_master/core/constants/app_constants.dart';
import 'package:prenda_master/presentation/widgets/custom_header.dart';
import 'package:prenda_master/presentation/widgets/filter_chip_group.dart';
import 'package:prenda_master/presentation/widgets/client_card.dart';
import 'package:prenda_master/providers/database_providers.dart';
import 'package:prenda_master/data/app_database.dart';

class ClientesScreen extends ConsumerStatefulWidget {
  const ClientesScreen({super.key});

  @override
  ConsumerState<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends ConsumerState<ClientesScreen> {
  String _selectedFilter = 'Todos';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _determineClientStatus(int clienteId, List<Prestamo> prestamos) {
    final clientLoans = prestamos.where((p) => p.clienteId == clienteId).toList();
    if (clientLoans.isEmpty) {
      return 'Inactivo';
    }
    // Check if any loan is overdue or > 61 days without paying
    bool isMoroso = clientLoans.any((p) {
      if (p.estado.toLowerCase() == 'vencido') return true;
      final daysOverdue = DateTime.now().difference(p.fechaVencimiento).inDays;
      return p.estado.toLowerCase() != 'pagado' && daysOverdue > 61;
    });

    if (isMoroso) return 'Moroso';

    bool hasActive = clientLoans.any((p) => p.estado.toLowerCase() == 'activo' || p.estado.toLowerCase() == 'pendiente');
    if (hasActive) return 'Activo';

    return 'Inactivo';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clientesAsync = ref.watch(clientesProvider);
    final prestamosAsync = ref.watch(prestamosProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Header limpio sin la palabra "Reales"
          CustomHeader(
            title: 'Clientes',
            subtitle: 'Gestión de clientes y contactos',
            onLeadingPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppConstants.routeHome);
              }
            },
            actions: [
              InkWell(
                onTap: () => context.go(AppConstants.routeNuevoCliente),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.person_add_rounded,
                    size: 18,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          
          // Sección de búsqueda y filtros
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.rectangle,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Campo de búsqueda
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Buscar cliente...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filtros
                  FilterChipGroup(
                    options: const ['Todos', 'Activos', 'Inactivos', 'Morosos'],
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
          
          // Lista de clientes desde Base de Datos
          Expanded(
            child: clientesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (clientes) {
                return prestamosAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (prestamos) {
                    final query = _searchController.text.trim().toLowerCase();
                    
                    final filtrados = clientes.where((c) {
                      final fullName = '${c.nombre} ${c.apellido} ${c.cedula}'.toLowerCase();
                      if (query.isNotEmpty && !fullName.contains(query)) {
                        return false;
                      }

                      final status = _determineClientStatus(c.id, prestamos);
                      if (_selectedFilter == 'Todos') return true;
                      if (_selectedFilter == 'Activos' && status == 'Activo') return true;
                      if (_selectedFilter == 'Inactivos' && status == 'Inactivo') return true;
                      if (_selectedFilter == 'Morosos' && status == 'Moroso') return true;
                      return false;
                    }).toList();

                    if (filtrados.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('No se encontraron clientes', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtrados.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final client = filtrados[index];
                        final clientLoans = prestamos.where((p) => p.clienteId == client.id).toList();
                        final activeLoansCount = clientLoans.where((p) => p.estado.toLowerCase() != 'pagado').length;
                        final totalDebt = clientLoans.where((p) => p.estado.toLowerCase() != 'pagado').fold(0.0, (sum, p) => sum + p.monto);
                        final status = _determineClientStatus(client.id, prestamos);

                        return ClientCard(
                          name: '${client.nombre} ${client.apellido} ($status)',
                          phone: client.telefono.isNotEmpty ? client.telefono : 'Sin teléfono',
                          email: client.email,
                          activeLoans: activeLoansCount,
                          totalDebt: totalDebt,
                          onTap: () {
                            print('Cliente seleccionado: ${client.nombre}');
                          },
                        );
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
