
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prenda_master/core/constants/app_constants.dart';

class AlertasScreen extends ConsumerStatefulWidget {
  const AlertasScreen({super.key});

  @override
  ConsumerState<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends ConsumerState<AlertasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        title: const Text('Alertas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Próximos', icon: Icon(Icons.schedule)),
            Tab(text: 'Vencidos', icon: Icon(Icons.warning)),
            Tab(text: 'Historial', icon: Icon(Icons.history)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _mostrarConfiguracionAlertas,
            tooltip: 'Configurar alertas',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAlertasList('proximo'),
          _buildAlertasList('vencido'),
          _buildAlertasList('historial'),
        ],
      ),
    );
  }

  Widget _buildAlertasList(String tipo) {
    final theme = Theme.of(context);
    // TODO: Replace with real data from database / notification service
    final alertasMock = <_AlertaMock>[
      _AlertaMock(
        id: '1',
        tipo: 'proximo',
        titulo: 'Pago próximo',
        mensaje: 'Juan Pérez - Cuota de USD 500 vence en 2 días',
        fecha: DateTime.now().add(const Duration(days: 2)),
        prestamoId: '1',
        cliente: 'Juan Pérez',
        leida: false,
      ),
      _AlertaMock(
        id: '2',
        tipo: 'proximo',
        titulo: 'Pago próximo',
        mensaje: 'María García - Interés de MXN 1,200 vence mañana',
        fecha: DateTime.now().add(const Duration(days: 1)),
        prestamoId: '2',
        cliente: 'María García',
        leida: false,
      ),
      _AlertaMock(
        id: '3',
        tipo: 'vencido',
        titulo: 'Pago vencido',
        mensaje: 'Carlos López - Pago de USD 300 vencido hace 3 días',
        fecha: DateTime.now().subtract(const Duration(days: 3)),
        prestamoId: '3',
        cliente: 'Carlos López',
        leida: false,
      ),
      _AlertaMock(
        id: '4',
        tipo: 'vencido',
        titulo: 'Pago vencido',
        mensaje: 'Ana Martínez - Cuota de USD 800 vencida hace 10 días',
        fecha: DateTime.now().subtract(const Duration(days: 10)),
        prestamoId: '4',
        cliente: 'Ana Martínez',
        leida: true,
      ),
      _AlertaMock(
        id: '5',
        tipo: 'historial',
        titulo: 'Pago registrado',
        mensaje: 'Pago de USD 500 recibido de Juan Pérez',
        fecha: DateTime.now().subtract(const Duration(days: 5)),
        prestamoId: '1',
        cliente: 'Juan Pérez',
        leida: true,
      ),
      _AlertaMock(
        id: '6',
        tipo: 'historial',
        titulo: 'Nuevo préstamo creado',
        mensaje: 'Préstamo #5 para Pedro Sánchez por USD 2,000',
        fecha: DateTime.now().subtract(const Duration(days: 7)),
        prestamoId: '5',
        cliente: 'Pedro Sánchez',
        leida: true,
      ),
    ];

    final filtered = alertasMock.where((a) => a.tipo == tipo).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyIcon(tipo),
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin alertas $tipo',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyMessage(tipo),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final a = filtered[index];
        return _AlertaCard(alerta: a);
      },
    );
  }

  IconData _getEmptyIcon(String tipo) {
    switch (tipo) {
      case 'proximo':
        return Icons.schedule;
      case 'vencido':
        return Icons.warning_amber;
      case 'historial':
        return Icons.history;
      default:
        return Icons.notifications_none;
    }
  }

  String _getEmptyMessage(String tipo) {
    switch (tipo) {
      case 'proximo':
        return 'No hay pagos próximos en los próximos días';
      case 'vencido':
        return '¡Excelente! No hay pagos vencidos';
      case 'historial':
        return 'El historial de alertas aparecerá aquí';
      default:
        return 'No hay alertas';
    }
  }

  void _mostrarConfiguracionAlertas() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => _ConfiguracionAlertasSheet(),
    );
  }
}

class _AlertaMock {
  final String id;
  final String tipo;
  final String titulo;
  final String mensaje;
  final DateTime fecha;
  final String prestamoId;
  final String cliente;
  final bool leida;

  _AlertaMock({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.fecha,
    required this.prestamoId,
    required this.cliente,
    required this.leida,
  });
}

class _AlertaCard extends StatelessWidget {
  final _AlertaMock alerta;

  const _AlertaCard({required this.alerta});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color tipoColor;
    IconData tipoIcon;

    switch (alerta.tipo) {
      case 'proximo':
        tipoColor = Colors.orange;
        tipoIcon = Icons.schedule;
        break;
      case 'vencido':
        tipoColor = Colors.red;
        tipoIcon = Icons.warning;
        break;
      case 'historial':
        tipoColor = Colors.blue;
        tipoIcon = Icons.history;
        break;
      default:
        tipoColor = Colors.grey;
        tipoIcon = Icons.notifications;
    }

    return Card(
      color: alerta.leida ? null : theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tipoColor.withValues(alpha: 0.1),
          child: Icon(tipoIcon, color: tipoColor, size: 20),
        ),
        title: Text(
          alerta.titulo,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: alerta.leida ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(alerta.mensaje),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(alerta.fecha),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: !alerta.leida
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          // TODO: Marcar como leída y navegar al préstamo
        },
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) {
      return 'Hoy ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff == 1) {
      return 'Ayer ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff < 7) {
      return 'Hace $diff días';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }
}

class _ConfiguracionAlertasSheet extends StatefulWidget {
  @override
  State<_ConfiguracionAlertasSheet> createState() => _ConfiguracionAlertasSheetState();
}

class _ConfiguracionAlertasSheetState extends State<_ConfiguracionAlertasSheet> {
  bool _alertasPagoProximo = true;
  bool _alertasPagoVencido = true;
  bool _alertasNuevoPrestamo = true;
  bool _alertasPagoRecibido = true;
  int _diasAnticipacion = 3;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Configurar Alertas', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Pagos próximos'),
            subtitle: Text('Avisar $_diasAnticipacion días antes del vencimiento'),
            value: _alertasPagoProximo,
            onChanged: (v) => setState(() => _alertasPagoProximo = v),
          ),
          SwitchListTile(
            title: const Text('Pagos vencidos'),
            subtitle: const Text('Notificar cuando un pago se venza'),
            value: _alertasPagoVencido,
            onChanged: (v) => setState(() => _alertasPagoVencido = v),
          ),
          SwitchListTile(
            title: const Text('Nuevos préstamos'),
            subtitle: const Text('Confirmar creación de préstamos'),
            value: _alertasNuevoPrestamo,
            onChanged: (v) => setState(() => _alertasNuevoPrestamo = v),
          ),
          SwitchListTile(
            title: const Text('Pagos recibidos'),
            subtitle: const Text('Confirmar registro de pagos'),
            value: _alertasPagoRecibido,
            onChanged: (v) => setState(() => _alertasPagoRecibido = v),
          ),
          const Divider(),
          ListTile(
            title: const Text('Días de anticipación'),
            subtitle: Text('$_diasAnticipacion días'),
            trailing: DropdownButton<int>(
              value: _diasAnticipacion,
              items: [1, 2, 3, 5, 7].map((d) => DropdownMenuItem(value: d, child: Text('$d días'))).toList(),
              onChanged: (v) => setState(() => _diasAnticipacion = v!),
            ),
          ),
          const SizedBox(height: 16),
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
                  onPressed: () {
                    // TODO: Guardar configuración en SharedPreferences
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Configuración guardada')),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}