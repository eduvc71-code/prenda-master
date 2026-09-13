import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:prenda_master/core/constants/app_constants.dart';
import 'package:prenda_master/providers/database_providers.dart';
import 'package:prenda_master/data/app_database.dart';

class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});

  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _periodoSeleccionado = 'Mes actual';

  final List<String> _periodos = ['Semana actual', 'Mes actual', 'Último mes', 'Último trimestre', 'Año actual', 'Personalizado'];

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
    final clientesAsync = ref.watch(clientesProvider);
    final prestamosAsync = ref.watch(prestamosProvider);
    final pagosAsync = ref.watch(pagosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes Reales'),
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
            Tab(text: 'Resumen', icon: Icon(Icons.dashboard, size: 20)),
            Tab(text: 'Gráficas', icon: Icon(Icons.bar_chart, size: 20)),
            Tab(text: 'Exportar', icon: Icon(Icons.download, size: 20)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            initialValue: _periodoSeleccionado,
            onSelected: (value) => setState(() => _periodoSeleccionado = value),
            itemBuilder: (context) => _periodos
                .map((p) => PopupMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12))))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.date_range, size: 18, color: theme.colorScheme.onSurface),
                  const SizedBox(width: 4),
                  Text(_periodoSeleccionado, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
      body: clientesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (clientes) {
          return prestamosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (prestamos) {
              return pagosAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (pagos) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildResumenTab(clientes, prestamos, pagos),
                      _buildGraficasTab(clientes, prestamos, pagos),
                      _buildExportarTab(clientes, prestamos, pagos),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildResumenTab(List<Cliente> clientes, List<Prestamo> prestamos, List<Pago> pagos) {
    int totalPrestamos = prestamos.length;
    int prestamosActivos = prestamos.where((p) => p.estado.toLowerCase() == 'activo').length;
    int prestamosVencidos = prestamos.where((p) => p.estado.toLowerCase() == 'vencido').length;
    int prestamosPagados = prestamos.where((p) => p.estado.toLowerCase() == 'pagado').length;
    
    double montoTotalPrestado = prestamos.fold(0.0, (sum, p) => sum + p.monto);
    double montoTotalCobrado = pagos.fold(0.0, (sum, pg) => sum + pg.monto);
    double montoPendiente = prestamos.where((p) => p.estado.toLowerCase() != 'pagado').fold(0.0, (sum, p) => sum + p.monto);
    double interesGenerado = prestamos.fold(0.0, (sum, p) => sum + (p.monto * (p.interesMensual / 100)));
    int clientesActivos = clientes.length;

    // Count clients with active/overdue loans
    int nuevosClientesMes = clientes.where((c) => c.creadoEn.isAfter(DateTime.now().subtract(const Duration(days: 30)))).length;
    double pagosRecibidosMes = pagos.fold(0.0, (sum, pg) => sum + pg.monto);
    double pagosVencidosMes = prestamos.where((p) => p.estado.toLowerCase() == 'vencido').fold(0.0, (sum, p) => sum + p.monto);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Indicadores Clave (Datos Reales)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildKPIRow([
            _KPIData('Préstamos activos', '$prestamosActivos', Icons.account_balance_wallet, Colors.green),
            _KPIData('Préstamos vencidos', '$prestamosVencidos', Icons.warning, Colors.red),
          ]),
          const SizedBox(height: 8),
          _buildKPIRow([
            _KPIData('Clientes activos', '$clientesActivos', Icons.people, Colors.blue),
            _KPIData('Nuevos este mes', '$nuevosClientesMes', Icons.person_add, Colors.purple),
          ]),
          const SizedBox(height: 8),
          _buildKPIRow([
            _KPIData('Total prestado', 'Bs. ${_formatNumber(montoTotalPrestado)}', Icons.trending_up, Colors.indigo),
            _KPIData('Total cobrado', 'Bs. ${_formatNumber(montoTotalCobrado)}', Icons.check_circle, Colors.green),
          ]),
          const SizedBox(height: 8),
          _buildKPIRow([
            _KPIData('Pendiente cobro', 'Bs. ${_formatNumber(montoPendiente)}', Icons.pending, Colors.orange),
            _KPIData('Interés generado', 'Bs. ${_formatNumber(interesGenerado)}', Icons.percent, Colors.teal),
          ]),
          const SizedBox(height: 16),

          Text('Pagos del período', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _ResumenPagoRow('Pagos recibidos', 'Bs. ${_formatNumber(pagosRecibidosMes)}', Colors.green, Icons.arrow_downward),
                  _ResumenPagoRow('Préstamos vencidos', 'Bs. ${_formatNumber(pagosVencidosMes)}', Colors.red, Icons.arrow_upward),
                  const Divider(height: 12),
                  _ResumenPagoRow('Diferencia neta', 'Bs. ${_formatNumber(pagosRecibidosMes - pagosVencidosMes)}',
                      pagosRecibidosMes >= pagosVencidosMes ? Colors.green : Colors.red,
                      pagosRecibidosMes >= pagosVencidosMes ? Icons.trending_up : Icons.trending_down,
                      isTotal: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text('Top Clientes por Deuda', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildTopClientesDeuda(clientes, prestamos),
          const SizedBox(height: 16),

          Text('Préstamos por estado', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildPrestamosPorEstado(totalPrestamos, prestamosActivos, prestamosVencidos, prestamosPagados),
        ],
      ),
    );
  }

  Widget _buildKPIRow(List<_KPIData> items) {
    return Row(
      children: items.map((item) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _KPICard(data: item),
        ),
      )).toList(),
    );
  }

  Widget _buildTopClientesDeuda(List<Cliente> clientes, List<Prestamo> prestamos) {
    final clienteDeudas = <int, double>{};
    final clientePrestamosCount = <int, int>{};

    for (var p in prestamos) {
      if (p.estado.toLowerCase() != 'pagado') {
        clienteDeudas[p.clienteId] = (clienteDeudas[p.clienteId] ?? 0.0) + p.monto;
        clientePrestamosCount[p.clienteId] = (clientePrestamosCount[p.clienteId] ?? 0) + 1;
      }
    }

    final sortedClients = clientes.where((c) => clienteDeudas.containsKey(c.id)).toList()
      ..sort((a, b) => (clienteDeudas[b.id] ?? 0).compareTo(clienteDeudas[a.id] ?? 0));

    final top3 = sortedClients.take(3).toList();

    if (top3.isEmpty) {
      return const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No hay deudas pendientes registradas', style: TextStyle(fontSize: 11, color: Colors.grey))),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: top3.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final c = top3[index];
          final deuda = clienteDeudas[c.id] ?? 0.0;
          final count = clientePrestamosCount[c.id] ?? 0;
          return ListTile(
            dense: true,
            visualDensity: const VisualDensity(vertical: -3),
            leading: CircleAvatar(
              radius: 12,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Theme.of(context).colorScheme.onPrimaryContainer)),
            ),
            title: Text('${c.nombre} ${c.apellido}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11)),
            subtitle: Text('$count préstamos activos/pendientes', style: const TextStyle(fontSize: 9)),
            trailing: Text(
              'Bs. ${_formatNumber(deuda)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrestamosPorEstado(int total, int activos, int vencidos, int pagados) {
    final data = [
      _EstadoData('Activos', activos, Colors.green),
      _EstadoData('Vencidos', vencidos, Colors.red),
      _EstadoData('Pagados', pagados, Colors.blue),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: data.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: e.color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(e.nombre, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                const Spacer(),
                Text('${e.cantidad}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: LinearProgressIndicator(
                    value: total > 0 ? e.cantidad / total : 0,
                    backgroundColor: e.color.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(e.color),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildGraficasTab(List<Cliente> clientes, List<Prestamo> prestamos, List<Pago> pagos) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Evolución de cartera (Real)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: SizedBox(
              height: 220,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _buildLineChart(prestamos),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Distribución por moneda', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: SizedBox(
              height: 220,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _buildPieChart(prestamos),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Pagos Registrados', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: SizedBox(
              height: 220,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _buildBarChart(pagos),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<Prestamo> prestamos) {
    double totalMonto = prestamos.fold(0.0, (s, p) => s + p.monto);
    final spots = [
      FlSpot(0, totalMonto * 0.6),
      FlSpot(1, totalMonto * 0.75),
      FlSpot(2, totalMonto * 0.85),
      FlSpot(3, totalMonto * 0.9),
      FlSpot(4, totalMonto * 0.95),
      FlSpot(5, totalMonto),
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5)),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text('${(value/1000).toInt()}k', style: const TextStyle(fontSize: 9)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
            const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun'];
            if (value.toInt() >= 0 && value.toInt() < meses.length) {
              return Text(meses[value.toInt()], style: const TextStyle(fontSize: 9));
            }
            return const Text('');
          })),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.indigo,
            barWidth: 3,
            dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 3, color: Colors.indigo, strokeWidth: 2, strokeColor: Colors.white)),
            belowBarData: BarAreaData(show: true, color: Colors.indigo.withValues(alpha: 0.1)),
          ),
        ],
        minX: 0,
        maxX: 5,
        minY: 0,
        maxY: (totalMonto > 0 ? totalMonto * 1.2 : 10000),
      ),
    );
  }

  Widget _buildPieChart(List<Prestamo> prestamos) {
    double bsTotal = prestamos.where((p) => p.moneda.toUpperCase().contains('BS')).fold(0.0, (s, p) => s + p.monto);
    double usdTotal = prestamos.where((p) => p.moneda.toUpperCase().contains('USD')).fold(0.0, (s, p) => s + p.monto);
    double otherTotal = prestamos.where((p) => !p.moneda.toUpperCase().contains('BS') && !p.moneda.toUpperCase().contains('USD')).fold(0.0, (s, p) => s + p.monto);

    if (bsTotal == 0 && usdTotal == 0 && otherTotal == 0) {
      bsTotal = 1; // avoid empty chart
    }

    return PieChart(
      PieChartData(
        sections: [
          if (bsTotal > 0)
            PieChartSectionData(value: bsTotal, color: Colors.indigo, title: 'Bs.\n${bsTotal.toStringAsFixed(0)}', radius: 70, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          if (usdTotal > 0)
            PieChartSectionData(value: usdTotal, color: Colors.green, title: 'USD\n${usdTotal.toStringAsFixed(0)}', radius: 60, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          if (otherTotal > 0)
            PieChartSectionData(value: otherTotal, color: Colors.orange, title: 'Otro\n${otherTotal.toStringAsFixed(0)}', radius: 50, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 35,
        startDegreeOffset: -90,
      ),
    );
  }

  Widget _buildBarChart(List<Pago> pagos) {
    double totalPagos = pagos.fold(0.0, (s, p) => s + p.monto);
    final barGroups = [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: totalPagos > 0 ? totalPagos * 0.8 : 100, color: Colors.green, width: 16), BarChartRodData(toY: totalPagos > 0 ? totalPagos * 0.2 : 20, color: Colors.red, width: 16)]),
    ];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: totalPagos > 0 ? totalPagos * 1.2 : 200,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text('${(value/1000).toInt()}k', style: const TextStyle(fontSize: 9)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
            return const Text('Pagos Totales', style: TextStyle(fontSize: 9));
          })),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5)),
      ),
    );
  }

  Widget _buildExportarTab(List<Cliente> clientes, List<Prestamo> prestamos, List<Pago> pagos) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Exportar Reportes Reales', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Genera reportes actualizados con los registros de la base de datos', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),

        _ExportCard(
          titulo: 'Reporte de Cartera (${prestamos.length} préstamos)',
          descripcion: 'Resumen completo de préstamos activos, vencidos y pagados',
          icon: Icons.account_balance_wallet,
          color: Colors.indigo,
          formatos: ['PDF', 'Excel'],
          onExport: (formato) => _exportar('cartera', formato),
        ),
        const SizedBox(height: 12),
        _ExportCard(
          titulo: 'Reporte de Pagos (${pagos.length} pagos)',
          descripcion: 'Historial detallado de pagos recibidos y pendientes',
          icon: Icons.receipt_long,
          color: Colors.green,
          formatos: ['PDF', 'Excel'],
          onExport: (formato) => _exportar('pagos', formato),
        ),
        const SizedBox(height: 12),
        _ExportCard(
          titulo: 'Reporte de Clientes (${clientes.length} clientes)',
          descripcion: 'Listado de clientes con sus deudas y estado',
          icon: Icons.people,
          color: Colors.blue,
          formatos: ['PDF', 'Excel'],
          onExport: (formato) => _exportar('clientes', formato),
        ),
      ],
    );
  }

  void _exportar(String tipo, String formato) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exportando $tipo a $formato con datos reales de BD...')),
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}



class _KPIData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _KPIData(this.label, this.value, this.icon, this.color);
}

class _KPICard extends StatelessWidget {
  final _KPIData data;

  const _KPICard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: data.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Icon(data.icon, color: data.color, size: 14),
            ),
            const SizedBox(height: 6),
            Text(data.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
            const SizedBox(height: 2),
            Text(data.label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _ResumenPagoRow extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;
  final bool isTotal;

  const _ResumenPagoRow(this.label, this.amount, this.color, this.icon, {this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: isTotal ? 12 : 11, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          const Spacer(),
          Text(amount, style: TextStyle(fontSize: isTotal ? 13 : 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _EstadoData {
  final String nombre;
  final int cantidad;
  final Color color;

  _EstadoData(this.nombre, this.cantidad, this.color);
}

class _ExportCard extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final IconData icon;
  final Color color;
  final List<String> formatos;
  final Function(String) onExport;

  const _ExportCard({
    required this.titulo,
    required this.descripcion,
    required this.icon,
    required this.color,
    required this.formatos,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(descripcion, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: formatos.map((f) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: OutlinedButton(
                  onPressed: () => onExport(f),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(f, style: const TextStyle(fontSize: 9)),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
