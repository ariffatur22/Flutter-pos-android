import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_pos_kasir/core/theme/app_theme.dart';
import 'package:flutter_pos_kasir/presentation/providers/report_provider.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});
  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _fmt     = NumberFormat('#,##0', 'id_ID');
  final _dateFmt = DateFormat('dd MMM', 'id_ID');
  final _fullDateFmt = DateFormat('dd/MM/yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(reportProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
            tooltip: 'Export PDF',
            onPressed: () => _exportPdf(),
          ),
          IconButton(
            icon: const Icon(Icons.grid_on, color: Colors.white),
            tooltip: 'Export Excel',
            onPressed: () => _exportExcel(),
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Ringkasan'),
            Tab(text: 'Grafik'),
            Tab(text: 'Transaksi'),
          ],
        ),
      ),
      body: report.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildDateRangeBar(report),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildSummaryTab(report),
                      _buildChartTab(report),
                      _buildTransactionTab(report),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ── Date range picker ────────────────────────────────────────────────────────
  Widget _buildDateRangeBar(ReportState report) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppTheme.surfaceColor,
      child: Row(
        children: [
          const Icon(Icons.date_range, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            '${_fullDateFmt.format(report.startDate)} — ${_fullDateFmt.format(report.endDate)}',
            style: AppTheme.body2.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _pickDateRange(report),
            child: const Text('Ubah Periode'),
          ),
          OutlinedButton.icon(
            onPressed: () => ref.read(reportProvider.notifier).loadReport(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              textStyle: AppTheme.caption,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(ReportState report) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
          start: report.startDate, end: report.endDate),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref.read(reportProvider.notifier).setDateRange(picked.start, picked.end);
    }
  }

  // ── Summary tab ──────────────────────────────────────────────────────────────
  Widget _buildSummaryTab(ReportState report) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // KPI cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width >= 600 ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _kpiCard('Total Penjualan', 'Rp ${_fmt.format(report.totalRevenue)}',
                Icons.payments_outlined, AppTheme.secondaryColor),
            _kpiCard('Transaksi', '${report.totalTransactions}',
                Icons.receipt_long_outlined, AppTheme.primaryColor),
            _kpiCard('Rata-rata', 'Rp ${_fmt.format(report.averageTransaction)}',
                Icons.show_chart, AppTheme.accentColor),
            _kpiCard('Produk Terlaris', report.topProducts.isNotEmpty
                ? report.topProducts.first.name
                : '-',
                Icons.star_outline, AppTheme.errorColor),
          ],
        ),
        const SizedBox(height: 20),
        // Top products list
        Text('Top 5 Produk Terlaris', style: AppTheme.heading3),
        const SizedBox(height: 12),
        ...report.topProducts.asMap().entries.map((e) {
          final i = e.key;
          final p = e.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Text('${i + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(p.name, style: AppTheme.body2.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text('${p.qty} terjual', style: AppTheme.caption),
              trailing: Text('Rp ${_fmt.format(p.revenue)}',
                  style: AppTheme.body2.copyWith(
                      color: AppTheme.secondaryColor, fontWeight: FontWeight.bold)),
            ),
          );
        }),
      ],
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const Spacer(),
            Text(value,
                style: AppTheme.body1.copyWith(
                    fontWeight: FontWeight.bold, color: color),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
            Text(label, style: AppTheme.caption),
          ],
        ),
      ),
    );
  }

  // ── Chart tab ────────────────────────────────────────────────────────────────
  Widget _buildChartTab(ReportState report) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // Line chart
        Text('Grafik Penjualan Harian', style: AppTheme.heading3),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: report.chartData.isEmpty
              ? const Center(child: Text('Tidak ada data'))
              : LineChart(_buildLineChartData(report)),
        ),
        const SizedBox(height: 28),
        // Bar chart
        Text('Top 5 Produk (Qty)', style: AppTheme.heading3),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: report.topProducts.isEmpty
              ? const Center(child: Text('Tidak ada data'))
              : BarChart(_buildBarChartData(report)),
        ),
      ],
    );
  }

  LineChartData _buildLineChartData(ReportState report) {
    final spots = report.chartData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.total / 1000);
    }).toList();

    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppTheme.primaryColor,
          barWidth: 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 4,
              color: AppTheme.primaryColor,
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppTheme.primaryColor.withOpacity(0.12),
          ),
        ),
      ],
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 28,
            getTitlesWidget: (val, meta) {
              final idx = val.toInt();
              if (idx < 0 || idx >= report.chartData.length) return const SizedBox.shrink();
              return Text(_dateFmt.format(report.chartData[idx].date),
                  style: AppTheme.caption.copyWith(fontSize: 10));
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 52,
            getTitlesWidget: (val, meta) => Text(
              '${val.toInt()}K',
              style: AppTheme.caption.copyWith(fontSize: 10),
            ),
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: AppTheme.dividerColor, strokeWidth: 1),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          left: BorderSide(color: AppTheme.dividerColor),
          bottom: BorderSide(color: AppTheme.dividerColor),
        ),
      ),
    );
  }

  BarChartData _buildBarChartData(ReportState report) {
    return BarChartData(
      barGroups: report.topProducts.asMap().entries.map((e) {
        final colors = [
          AppTheme.primaryColor,
          AppTheme.secondaryColor,
          AppTheme.accentColor,
          AppTheme.errorColor,
          const Color(0xFF8B5CF6),
        ];
        return BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(
              toY: e.value.qty.toDouble(),
              color: colors[e.key % colors.length],
              width: 28,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        );
      }).toList(),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (val, meta) {
              final idx = val.toInt();
              if (idx < 0 || idx >= report.topProducts.length) return const SizedBox.shrink();
              final name = report.topProducts[idx].name;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  name.length > 8 ? '${name.substring(0, 8)}..' : name,
                  style: AppTheme.caption.copyWith(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (val, meta) => Text(
              val.toInt().toString(),
              style: AppTheme.caption.copyWith(fontSize: 10),
            ),
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: AppTheme.dividerColor, strokeWidth: 1),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          left: BorderSide(color: AppTheme.dividerColor),
          bottom: BorderSide(color: AppTheme.dividerColor),
        ),
      ),
    );
  }

  // ── Transaction tab ──────────────────────────────────────────────────────────
  Widget _buildTransactionTab(ReportState report) {
    final trxList = report.transactions.take(10).toList();
    if (trxList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text('Tidak ada transaksi', style: AppTheme.body2),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: trxList.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final trx = trxList[i];
        final methodIcon = trx.paymentMethod == 'CASH'
            ? Icons.payments_outlined
            : trx.paymentMethod == 'CARD'
                ? Icons.credit_card
                : Icons.qr_code;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Icon(methodIcon, color: AppTheme.primaryColor, size: 20),
          ),
          title: Text(trx.invoiceNumber,
              style: AppTheme.body2.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${_fullDateFmt.format(trx.createdAt)} • ${trx.totalItems} item',
            style: AppTheme.caption,
          ),
          trailing: Text('Rp ${_fmt.format(trx.total)}',
              style: AppTheme.body1.copyWith(
                  color: AppTheme.secondaryColor, fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  // ── Export actions ───────────────────────────────────────────────────────────
  void _exportPdf() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Export PDF: integrasikan paket pdf atau printing'),
      backgroundColor: AppTheme.primaryColor,
    ));
  }

  void _exportExcel() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Export Excel: integrasikan paket excel'),
      backgroundColor: AppTheme.primaryColor,
    ));
  }
}
