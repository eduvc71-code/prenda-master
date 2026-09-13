
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prenda_master/core/constants/app_constants.dart';

class PagoScreen extends ConsumerStatefulWidget {
  const PagoScreen({super.key});

  @override
  ConsumerState<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends ConsumerState<PagoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppConstants.routeHome);
            }
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pendientes', icon: Icon(Icons.schedule)),
            Tab(text: 'Pagados', icon: Icon(Icons.check_circle)),
            Tab(text: 'Vencidos', icon: Icon(Icons.warning)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar pagos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPagosList('Pendiente'),
                _buildPagosList('Pagado'),
                _buildPagosList('Vencido'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _registrarPago,
        tooltip: 'Registrar pago',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPagosList(String estado) {
    // TODO: Replace with real data from database
    final pagosMock = <_PagoMock>[
      _PagoMock(
        id: '1',
        prestamoId: '1',
        cliente: 'Juan Pérez',
        monto: 500,
        moneda: 'USD',
        fechaProgramada: DateTime.now().add(const Duration(days: 5)),
        fechaPago: null,
        estado: 'Pendiente',
        concepto: 'Cuota mensual',
      ),
      _PagoMock(
        id: '2',
        prestamoId: '1',
        cliente: 'Juan Pérez',
        monto: 500,
        moneda: 'USD',
        fechaProgramada: DateTime.now().subtract(const Duration(days: 10)),
        fechaPago: DateTime.now().subtract(const Duration(days: 10)),
        estado: 'Pagado',
        concepto: 'Cuota mensual',
      ),
      _PagoMock(
        id: '3',
        prestamoId: '2',
        cliente: 'María García',
        monto: 1200,
        moneda: 'MXN',
        fechaProgramada: DateTime.now().subtract(const Duration(days: 3)),
        fechaPago: null,
        estado: 'Vencido',
        concepto: 'Interés mensual',
      ),
      _PagoMock(
        id: '4',
        prestamoId: '3',
        cliente: 'Carlos López',
        monto: 300,
        moneda: 'USD',
        fechaProgramada: DateTime.now().subtract(const Duration(days: 15)),
        fechaPago: null,
        estado: 'Vencido',
        concepto: 'Pago parcial',
      ),
    ];

    final filtered = pagosMock.where((p) {
      final matchesEstado = p.estado == estado;
      final matchesSearch = p.cliente.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.concepto.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.id.contains(_searchQuery);
      return matchesEstado && matchesSearch;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyIcon(estado),
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay pagos $estado',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = filtered[index];
        return _PagoCard(pago: p);
      },
    );
  }

  IconData _getEmptyIcon(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Icons.schedule;
      case 'Pagado':
        return Icons.check_circle_outline;
      case 'Vencido':
        return Icons.warning;
      default:
        return Icons.receipt;
    }
  }

  void _registrarPago() {
    // TODO: Abrir dialog para registrar pago
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _RegistrarPagoSheet(),
    );
  }
}

class _PagoMock {
  final String id;
  final String prestamoId;
  final String cliente;
  final double monto;
  final String moneda;
  final DateTime fechaProgramada;
  final DateTime? fechaPago;
  final String estado;
  final String concepto;

  _PagoMock({
    required this.id,
    required this.prestamoId,
    required this.cliente,
    required this.monto,
    required this.moneda,
    required this.fechaProgramada,
    this.fechaPago,
    required this.estado,
    required this.concepto,
  });
}

class _PagoCard extends StatelessWidget {
  final _PagoMock pago;

  const _PagoCard({required this.pago});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color estadoColor;
    IconData estadoIcon;

    switch (pago.estado) {
      case 'Pendiente':
        estadoColor = Colors.orange;
        estadoIcon = Icons.schedule;
        break;
      case 'Pagado':
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle;
        break;
      case 'Vencido':
        estadoColor = Colors.red;
        estadoIcon = Icons.warning;
        break;
      default:
        estadoColor = Colors.grey;
        estadoIcon = Icons.help;
    }

    final diasDiferencia = pago.fechaProgramada.difference(DateTime.now()).inDays;
    final esHoy = diasDiferencia == 0;
    final esManana = diasDiferencia == 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: estadoColor.withValues(alpha: 0.1),
                  child: Icon(estadoIcon, color: estadoColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pago.cliente,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        pago.concepto,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    pago.estado,
                    style: TextStyle(color: estadoColor, fontWeight: FontWeight.w500, fontSize: 11),
                  ),
                  backgroundColor: estadoColor.withValues(alpha: 0.1),
                  side: BorderSide(color: estadoColor.withValues(alpha: 0.3)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoColumn(
                    label: 'Monto',
                    value: '${pago.moneda} ${pago.monto.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    valueColor: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _InfoColumn(
                    label: 'Programado',
                    value: _formatDate(pago.fechaProgramada),
                    icon: Icons.calendar_today,
                    valueColor: pago.estado == 'Vencido' ? Colors.red : (esHoy || esManana ? Colors.orange : null),
                  ),
                ),
                if (pago.fechaPago != null)
                  Expanded(
                    child: _InfoColumn(
                      label: 'Pagado',
                      value: _formatDate(pago.fechaPago!),
                      icon: Icons.check_circle,
                      valueColor: Colors.green,
                    ),
                  ),
              ],
            ),
            if (pago.estado == 'Pendiente' || pago.estado == 'Vencido') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Registrar pago
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Registrar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Ver detalle del préstamo
                      },
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Ver préstamo'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoColumn({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _RegistrarPagoSheet extends StatefulWidget {
  @override
  State<_RegistrarPagoSheet> createState() => _RegistrarPagoSheetState();
}

class _RegistrarPagoSheetState extends State<_RegistrarPagoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _conceptoController = TextEditingController();
  String _prestamoSeleccionado = '1';

  @override
  void dispose() {
    _montoController.dispose();
    _conceptoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registrar Pago', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _prestamoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Préstamo *',
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
              items: const [
                DropdownMenuItem(value: '1', child: Text('Juan Pérez - Préstamo #1 (USD 5,000)')),
                DropdownMenuItem(value: '2', child: Text('María García - Préstamo #2 (MXN 12,000)')),
                DropdownMenuItem(value: '3', child: Text('Carlos López - Préstamo #3 (USD 3,000)')),
              ],
              onChanged: (value) => setState(() => _prestamoSeleccionado = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _montoController,
              decoration: const InputDecoration(
                labelText: 'Monto *',
                hintText: '0.00',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requerido';
                final m = double.tryParse(value);
                if (m == null || m <= 0) return 'Inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _conceptoController,
              decoration: const InputDecoration(
                labelText: 'Concepto',
                hintText: 'Ej. Cuota mensual, Interés, Abono capital',
                prefixIcon: Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _guardarPago,
                    child: const Text('Registrar Pago'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _guardarPago() {
    if (_formKey.currentState!.validate()) {
      // TODO: Guardar en BD
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago registrado (pendiente implementar BD)')),
      );
    }
  }
}