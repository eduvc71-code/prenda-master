
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:prenda_master/core/constants/app_constants.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Resumen', icon: Icon(Icons.dashboard)),
            Tab(text: 'Gráficas', icon: Icon(Icons.bar_chart)),
            Tab(text: 'Exportar', icon: Icon(Icons.download)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            initialValue: _periodoSeleccionado,
            onSelected: (value) => setState(() => _periodoSeleccionado = value),
            itemBuilder: (context) => _periodos
                .map((p) => PopupMenuItem(value: p, child: Text(p)))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.date_range, size: 20, color: theme.colorScheme.onSurface),
                  const SizedBox(width: 4),
                  Text(_periodoSeleccionado, style: theme.textTheme.bodyMedium),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResumenTab(),
          _buildGraficasTab(),
          _buildExportarTab(),
        ],
      ),
    );
  }

  Widget _buildResumenTab() {
    // TODO: Replace with real data from database
    final resumen = _ResumenMock(
      totalPrestamos: 24,
      prestamosActivos: 18,
      prestamosVencidos: 3,
      prestamosPagados: 3,
      montoTotalPrestado: 125000,
      montoTotalCobrado: 89000,
      montoPendiente: 36000,
      interesGenerado: 12500,
      clientesActivos: 15,
      nuevosClientesMes: 3,
      pagosRecibidosMes: 45000,
      pagosVencidosMes: 8500,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPIs principales
          Text('Indicadores Clave', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _buildKPIRow([
            _KPIData('Préstamos activos', '${resumen.prestamosActivos}', Icons.account_balance_wallet, Colors.green),
            _KPIData('Préstamos vencidos', '${resumen.prestamosVencidos}', Icons.warning, Colors.red),
            _KPIData('Clientes activos', '${resumen.clientesActivos}', Icons.people, Colors.blue),
            _KPIData('Nuevos este mes', '${resumen.nuevosClientesMes}', Icons.person_add, Colors.purple),
          ]),
          const SizedBox(height: 16),
          _buildKPIRow([
            _KPIData('Total prestado', '${resumen.monedaDefault} ${_formatNumber(resumen.montoTotalPrestado)}', Icons.trending_up, Colors.indigo),
            _KPIData('Total cobrado', '${resumen.monedaDefault} ${_formatNumber(resumen.montoTotalCobrado)}', Icons.check_circle, Colors.green),
            _KPIData('Pendiente cobro', '${resumen.monedaDefault} ${_formatNumber(resumen.montoPendiente)}', Icons.pending, Colors.orange),
            _KPIData('Interés generado', '${resumen.monedaDefault} ${_formatNumber(resumen.interesGenerado)}', Icons.percent, Colors.teal),
          ]),
          const SizedBox(height: 24),

          // Resumen de pagos del período
          Text('Pagos del período', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ResumenPagoRow('Pagos recibidos', '${resumen.monedaDefault} ${_formatNumber(resumen.pagosRecibidosMes)}', Colors.green, Icons.arrow_downward),
                  _ResumenPagoRow('Pagos vencidos', '${resumen.monedaDefault} ${_formatNumber(resumen.pagosVencidosMes)}', Colors.red, Icons.arrow_upward),
                  const Divider(),
                  _ResumenPagoRow('Diferencia neta', '${resumen.monedaDefault} ${_formatNumber(resumen.pagosRecibidosMes - resumen.pagosVencidosMes)}',
                      resumen.pagosRecibidosMes >= resumen.pagosVencidosMes ? Colors.green : Colors.red,
                      resumen.pagosRecibidosMes >= resumen.pagosVencidosMes ? Icons.trending_up : Icons.trending_down,
                      isTotal: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Top clientes por deuda
          Text('Top 5 clientes por deuda', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _buildTopClientesDeuda(),
          const SizedBox(height: 24),

          // Préstamos por estado
          Text('Préstamos por estado', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _buildPrestamosPorEstado(resumen),
        ],
      ),
    );
  }

  Widget _buildKPIRow(List<_KPIData> items) {
    return Row(
      children: items.map((item) => Expanded(child: _KPICard(data: item))).toList(),
    );
  }

  Widget _buildTopClientesDeuda() {
    final topClientes = <_ClienteDeudaMock>[
      _ClienteDeudaMock('Juan Pérez', 'USD', 8500, 2),
      _ClienteDeudaMock('María García', 'MXN', 12000, 1),
      _ClienteDeudaMock('Carlos López', 'USD', 3000, 1),
      _ClienteDeudaMock('Ana Martínez', 'USD', 3000, 1),
      _ClienteDeudaMock('Pedro Sánchez', 'USD', 2000, 1),
    ];

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: topClientes.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final c = topClientes[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
            ),
            title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text('${c.prestamosActivos} préstamos activos'),
            trailing: Text(
              '${c.moneda} ${_formatNumber(c.deudaTotal)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrestamosPorEstado(_ResumenMock resumen) {
    final data = [
      _EstadoData('Activos', resumen.prestamosActivos, Colors.green),
      _EstadoData('Vencidos', resumen.prestamosVencidos, Colors.red),
      _EstadoData('Pagados', resumen.prestamosPagados, Colors.blue),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: data.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: e.color, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Text(e.nombre, style: Theme.of(context).textTheme.bodyLarge),
                const Spacer(),
                Text('${e.cantidad}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                SizedBox(
                  width: 100,
                  child: LinearProgressIndicator(
                    value: resumen.totalPrestamos > 0 ? e.cantidad / resumen.totalPrestamos : 0,
                    backgroundColor: e.color.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(e.color),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildGraficasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Evolución de cartera', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: SizedBox(
              height: 250,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildLineChart(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Distribución por moneda', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: SizedBox(
              height: 250,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildPieChart(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Pagos: Recibidos vs Vencidos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: SizedBox(
              height: 250,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildBarChart(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    // Mock data: cartera últimos 6 meses
    final spots = [
      FlSpot(0, 80000),
      FlSpot(1, 95000),
      FlSpot(2, 110000),
      FlSpot(3, 105000),
      FlSpot(4, 120000),
      FlSpot(5, 125000),
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5)),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 60, getTitlesWidget: (value, meta) => Text('${(value/1000).toInt()}k', style: const TextStyle(fontSize: 10)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
            const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun'];
            if (value.toInt() >= 0 && value.toInt() < meses.length) {
              return Text(meses[value.toInt()], style: const TextStyle(fontSize: 10));
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
            dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: Colors.indigo, strokeWidth: 2, strokeColor: Colors.white)),
            belowBarData: BarAreaData(show: true, color: Colors.indigo.withValues(alpha: 0.1)),
          ),
        ],
        minX: 0,
        maxX: 5,
        minY: 70000,
        maxY: 135000,
      ),
    );
  }

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(value: 85000, color: Colors.indigo, title: 'USD\n68%', radius: 80, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(value: 25000, color: Colors.green, title: 'MXN\n20%', radius: 70, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(value: 15000, color: Colors.orange, title: 'EUR\n12%', radius: 60, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        startDegreeOffset: -90,
      ),
    );
  }

  Widget _buildBarChart() {
    final barGroups = [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 45000, color: Colors.green, width: 20), BarChartRodData(toY: 8500, color: Colors.red, width: 20)]),
      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 38000, color: Colors.green, width: 20), BarChartRodData(toY: 12000, color: Colors.red, width: 20)]),
      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 52000, color: Colors.green, width: 20), BarChartRodData(toY: 5000, color: Colors.red, width: 20)]),
      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 41000, color: Colors.green, width: 20), BarChartRodData(toY: 9000, color: Colors.red, width: 20)]),
    ];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 60000,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, getTitlesWidget: (value, meta) => Text('${(value/1000).toInt()}k', style: const TextStyle(fontSize: 10)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
            const labels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
            if (value.toInt() >= 0 && value.toInt() < labels.length) {
              return Text(labels[value.toInt()], style: const TextStyle(fontSize: 10));
            }
            return const Text('');
          })),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5)),
      ),
    );
  }

  Widget _buildExportarTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Exportar Reportes', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('Genera reportes en PDF o Excel para compartir o archivar', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),

        _ExportCard(
          titulo: 'Reporte de Cartera',
          descripcion: 'Resumen completo de préstamos activos, vencidos y pagados',
          icon: Icons.account_balance_wallet,
          color: Colors.indigo,
          formatos: ['PDF', 'Excel'],
          onExport: (formato) => _exportar('cartera', formato),
        ),
        const SizedBox(height: 16),
        _ExportCard(
          titulo: 'Reporte de Pagos',
          descripcion: 'Historial detallado de pagos recibidos y pendientes',
          icon: Icons.receipt_long,
          color: Colors.green,
          formatos: ['PDF', 'Excel'],
          onExport: (formato) => _exportar('pagos', formato),
        ),
        const SizedBox(height: 16),
        _ExportCard(
          titulo: 'Reporte de Clientes',
          descripcion: 'Listado de clientes con sus deudas y estado',
          icon: Icons.people,
          color: Colors.blue,
          formatos: ['PDF', 'Excel'],
          onExport: (formato) => _exportar('clientes', formato),
        ),
        const SizedBox(height: 16),
        _ExportCard(
          titulo: 'Reporte Financiero',
          descripcion: 'Ingresos, intereses, morosidad y rentabilidad',
          icon: Icons.analytics,
          color: Colors.purple,
          formatos: ['PDF', 'Excel'],
          onExport: (formato) => _exportar('financiero', formato),
        ),
        const SizedBox(height: 24),

        // Backup section
        Text('Respaldo de Datos', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.backup, color: Theme.of(context).colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Backup automático', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          Text('Último backup: Hace 2 horas • Google Drive', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.cloud_download), label: const Text('Restaurar'))),
                    const SizedBox(width: 12),
                    Expanded(child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.cloud_upload), label: const Text('Backup ahora'))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _exportar(String tipo, String formato) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exportando $tipo a $formato... (pendiente implementar)')),
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

class _ResumenMock {
  final int totalPrestamos;
  final int prestamosActivos;
  final int prestamosVencidos;
  final int prestamosPagados;
  final double montoTotalPrestado;
  final double montoTotalCobrado;
  final double montoPendiente;
  final double interesGenerado;
  final int clientesActivos;
  final int nuevosClientesMes;
  final double pagosRecibidosMes;
  final double pagosVencidosMes;
  final String monedaDefault = 'USD';

  _ResumenMock({
    required this.totalPrestamos,
    required this.prestamosActivos,
    required this.prestamosVencidos,
    required this.prestamosPagados,
    required this.montoTotalPrestado,
    required this.montoTotalCobrado,
    required this.montoPendiente,
    required this.interesGenerado,
    required this.clientesActivos,
    required this.nuevosClientesMes,
    required this.pagosRecibidosMes,
    required this.pagosVencidosMes,
  });
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: data.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(data.icon, color: data.color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(data.value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: data.color)),
            const SizedBox(height: 4),
            Text(data.label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ResumenPagoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isTotal;

  const _ResumenPagoRow(this.label, this.value, this.color, this.icon, {this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal))),
          Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _ClienteDeudaMock {
  final String nombre;
  final String moneda;
  final double deudaTotal;
  final int prestamosActivos;

  _ClienteDeudaMock(this.nombre, this.moneda, this.deudaTotal, this.prestamosActivos);
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
  final void Function(String) onExport;

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(descripcion, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Row(
              children: formatos.map((f) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: OutlinedButton(
                  onPressed: () => onExport(f),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                    minimumSize: const Size(70, 36),
                  ),
                  child: Text(f),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}