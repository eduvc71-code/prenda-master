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

  void _mostrarConfiguracionAlertas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración de Alertas'),
        content: const Text('Aquí puede configurar los días de anticipación para las notificaciones de préstamos próximos a vencer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
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
        mensaje: 'Juan Pérez - Cuota de Bs 500 vence en 2 días',
        fecha: DateTime.now().add(const Duration(days: 2)),
        prestamoId: '1',
        cliente: 'Juan Pérez',
        leida: false,
      ),
      _AlertaMock(
        id: '2',
        tipo: 'proximo',
        titulo: 'Pago próximo',
        mensaje: 'María García - Interés de Bs 1,200 vence mañana',
        fecha: DateTime.now().add(const Duration(days: 1)),
        prestamoId: '2',
        cliente: 'María García',
        leida: false,
      ),
      _AlertaMock(
        id: '3',
        tipo: 'vencido',
        titulo: 'Pago vencido',
        mensaje: 'Carlos López - Pago de Bs 300 vencido hace 3 días',
        fecha: DateTime.now().subtract(const Duration(days: 3)),
        prestamoId: '3',
        cliente: 'Carlos López',
        leida: false,
      ),
      _AlertaMock(
        id: '4',
        tipo: 'vencido',
        titulo: 'Pago vencido',
        mensaje: 'Ana Martínez - Cuota de Bs 800 vencida hace 10 días',
        fecha: DateTime.now().subtract(const Duration(days: 10)),
        prestamoId: '4',
        cliente: 'Ana Martínez',
        leida: true,
      ),
      _AlertaMock(
        id: '5',
        tipo: 'historial',
        titulo: 'Pago registrado',
        mensaje: 'Pago de Bs 500 recibido de Juan Pérez',
        fecha: DateTime.now().subtract(const Duration(days: 5)),
        prestamoId: '1',
        cliente: 'Juan Pérez',
        leida: true,
      ),
      _AlertaMock(
        id: '6',
        tipo: 'historial',
        titulo: 'Nuevo préstamo creado',
        mensaje: 'Se creó el préstamo #1001 para Juan Pérez',
        fecha: DateTime.now().subtract(const Duration(days: 15)),
        prestamoId: '1',
        cliente: 'Juan Pérez',
        leida: true,
      ),
    ];

    final filtradas = alertasMock.where((a) => a.tipo == tipo).toList();

    if (filtradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('No hay alertas en esta categoría', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtradas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final alerta = filtradas[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: alerta.tipo == 'vencido' 
                  ? Colors.red.shade100 
                  : (alerta.tipo == 'proximo' ? Colors.orange.shade100 : Colors.blue.shade100),
              child: Icon(
                alerta.tipo == 'vencido' 
                    ? Icons.warning_rounded 
                    : (alerta.tipo == 'proximo' ? Icons.schedule_rounded : Icons.info_outline_rounded),
                color: alerta.tipo == 'vencido' 
                    ? Colors.red 
                    : (alerta.tipo == 'proximo' ? Colors.orange : Colors.blue),
              ),
            ),
            title: Text(alerta.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(alerta.mensaje),
                const SizedBox(height: 4),
                Text(
                  '${alerta.fecha.day}/${alerta.fecha.month}/${alerta.fecha.year}',
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {
                context.go('${AppConstants.routePrestamos}/${alerta.prestamoId}');
              },
            ),
          ),
        );
      },
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
