import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prenda_master/core/constants/app_constants.dart';
import 'package:prenda_master/presentation/widgets/custom_header.dart';
import 'package:prenda_master/presentation/widgets/filter_chip_group.dart';
import 'package:prenda_master/presentation/widgets/client_card.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Datos mock para demostración
    final clientesMock = [
      {'name': 'Juan Pérez', 'phone': '+591 777 12345', 'email': 'juan@email.com', 'loans': 2, 'debt': 1500.0},
      {'name': 'María García', 'phone': '+591 666 98765', 'email': 'maria@email.com', 'loans': 1, 'debt': 800.0},
      {'name': 'Carlos López', 'phone': '+591 700 11223', 'email': '', 'loans': 3, 'debt': 2400.0},
      {'name': 'Ana Martínez', 'phone': '+591 755 44556', 'email': 'ana@email.com', 'loans': 0, 'debt': 0.0},
      {'name': 'Pedro Sánchez', 'phone': '+591 600 33445', 'email': 'pedro@email.com', 'loans': 1, 'debt': 500.0},
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Header personalizado
          CustomHeader(
            title: 'Directorio de Clientes',
            subtitle: 'Gestión de clientes y contactos',
            actions: [
              InkWell(
                onTap: () => context.go(AppConstants.routeNuevoCliente),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person_add_rounded,
                    size: 24,
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
              padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Campo de búsqueda
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar cliente...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filtros
                  FilterChipGroup(
                    options: ['Todos', 'Activos', 'Inactivos', 'Morosos'],
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
          
          // Lista de clientes
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: clientesMock.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final cliente = clientesMock[index];
                return ClientCard(
                  name: cliente['name'] as String,
                  phone: cliente['phone'] as String,
                  email: cliente['email'] as String?,
                  activeLoans: cliente['loans'] as int,
                  totalDebt: cliente['debt'] as double,
                  onTap: () {
                    // TODO: Navegar al detalle del cliente
                    print('Cliente seleccionado: ${cliente['name']}');
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