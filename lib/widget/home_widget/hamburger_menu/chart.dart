import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/models/statistics.dart';
import 'package:admin/provider/statistics.dart';
import 'package:admin/widget/shared_widgets/appbar_icon.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Chart extends StatefulWidget {
  static const String routeName = '/chart';
  const Chart({super.key});

  @override
  State<Chart> createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  static const Color _accentStart = Color(0xFF6366F1);
  static const Color _accentEnd = Color(0xFF8B5CF6);

  Map<int, double> completedMap = {};
  late Future<Map<String, dynamic>> _statisticsFuture;
  late Future<List<Statistics>> _statisticsDayFuture;

  final ValueNotifier<int> _currentPage = ValueNotifier<int>(0);

  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now().month;
    _selectedYear = DateTime.now().year;

    _statisticsFuture = context.read<StatisticsProvider>().getAllStatistics();
    _statisticsDayFuture = context
        .read<StatisticsProvider>()
        .getStatisticsDayOfMonth(_monthKey(_selectedYear, _selectedMonth));
  }

  @override
  void dispose() {
    _currentPage.dispose();
    super.dispose();
  }

  String _monthKey(int year, int month) =>
      '${year}_${month.toString().padLeft(2, '0')}';

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : "";
  }

  String _formatMoney(double value) {
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}K";
    }
    return value.toInt().toString();
  }

  void _onMonthBarTapped(int month) {
    setState(() {
      _selectedMonth = month;
      _selectedYear = DateTime.now().year;
      _statisticsDayFuture = context
          .read<StatisticsProvider>()
          .getStatisticsDayOfMonth(_monthKey(_selectedYear, _selectedMonth));
    });
    _currentPage.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: AppbarIcon(),
        title: const Text(
          "Thống kê doanh thu",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.dark,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 90),
            child: ValueListenableBuilder<int>(
              valueListenable: _currentPage,
              builder: (context, page, _) {
                return page == 0 ? _buildDayChart() : _buildMonthChart();
              },
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ValueListenableBuilder<int>(
              valueListenable: _currentPage,
              builder: (context, value, _) {
                return FloatingTopBar(
                  currentIndex: value,
                  onTap: (index) => _currentPage.value = index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChart() {
    return FutureBuilder<List<Statistics>>(
      future: _statisticsDayFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: LoadingAnimationWidget.waveDots(
              color: _accentStart,
              size: 60,
            ),
          );
        }

        int daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
        completedMap.clear();
        final statistics = snapshot.data!;

        for (int i = 1; i <= daysInMonth; i++) {
          completedMap[i] = 0;
        }

        for (var e in statistics) {
          final parts = e.id.split("_");
          if (parts.length < 3) continue;

          final m = int.tryParse(parts[2].trim());
          if (m != null) {
            completedMap[m] = (completedMap[m] ?? 0) + e.completedOrder.revenue;
          }
        }

        final sorted = completedMap.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        final totalRevenue = sorted.fold<double>(0, (sum, e) => sum + e.value);
        final isCurrentMonth = _selectedMonth == DateTime.now().month &&
            _selectedYear == DateTime.now().year;

        double chartWidth = sorted.length * 40;

        return _ChartCard(
          title: "Doanh thu theo ngày",
          subtitle:
              "Tháng ${_selectedMonth.toString().padLeft(2, '0')}/$_selectedYear",
          totalLabel: "${_formatMoney(totalRevenue)}đ",
          trailing: isCurrentMonth
              ? null
              : _ResetChip(
                  label: "Về tháng hiện tại",
                  onTap: () => _onMonthBarTapped(DateTime.now().month),
                ),
          child: Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                child: SfCartesianChart(
                  enableSideBySideSeriesPlacement: true,
                  plotAreaBorderWidth: 0,
                  primaryYAxis: const NumericAxis(
                    isVisible: false,
                    majorGridLines: MajorGridLines(width: 0),
                    axisLine: AxisLine(width: 0),
                  ),
                  primaryXAxis: const CategoryAxis(
                    majorTickLines: MajorTickLines(size: 0),
                    interval: 1,
                    axisLine: AxisLine(width: 0),
                    majorGridLines: MajorGridLines(width: 0),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      color: AppColors.iconDisabled,
                    ),
                  ),
                  tooltipBehavior: TooltipBehavior(
                    enable: true,
                    color: AppColors.dark,
                    textStyle: const TextStyle(color: AppColors.surface),
                  ),
                  series: <CartesianSeries>[
                    ColumnSeries<MapEntry<int, double>, String>(
                      dataSource: sorted,
                      xValueMapper: (data, _) => data.key.toString(),
                      yValueMapper: (data, _) => data.value,
                      width: 0.6,
                      spacing: 0.4,
                      animationDuration: 800,
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [_accentStart, _accentEnd],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      dataLabelSettings: DataLabelSettings(
                        isVisible: true,
                        builder:
                            (data, point, series, pointIndex, seriesIndex) {
                          final entry = data as MapEntry<int, double>;
                          return Text(
                            entry.value == 0 ? "" : _formatMoney(entry.value),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthChart() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statisticsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: LoadingAnimationWidget.waveDots(
              color: _accentStart,
              size: 60,
            ),
          );
        }
        completedMap.clear();

        final year = snapshot.data!['year'] as Statistics?;
        final month = snapshot.data!['month'] as List<Statistics>;
        for (int i = 1; i <= 12; i++) {
          completedMap[i] = 0;
        }

        for (var e in month) {
          final parts = e.id.split("_");
          if (parts.length < 2) continue;

          final m = int.tryParse(parts[1].trim());
          if (m != null) {
            completedMap[m] = (completedMap[m] ?? 0) + e.completedOrder.revenue;
          }
        }

        final sorted = completedMap.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        double chartWidth = sorted.length * 40;

        return _ChartCard(
          title: "Tổng doanh thu năm",
          subtitle: "Chạm vào cột để xem chi tiết theo ngày",
          totalLabel: "${_formatMoney(year?.completedOrder.revenue ?? 0)}đ",
          child: Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                child: SfCartesianChart(
                  enableSideBySideSeriesPlacement: true,
                  plotAreaBorderWidth: 0,
                  primaryYAxis: const NumericAxis(
                    isVisible: false,
                    majorGridLines: MajorGridLines(width: 0),
                    axisLine: AxisLine(width: 0),
                  ),
                  primaryXAxis: const CategoryAxis(
                    majorTickLines: MajorTickLines(size: 0),
                    interval: 1,
                    axisLine: AxisLine(width: 0),
                    majorGridLines: MajorGridLines(width: 0),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      color: AppColors.iconDisabled,
                    ),
                  ),
                  tooltipBehavior: TooltipBehavior(
                    enable: true,
                    color: AppColors.dark,
                    textStyle: const TextStyle(color: AppColors.surface),
                  ),
                  series: <CartesianSeries>[
                    ColumnSeries<MapEntry<int, double>, String>(
                      dataSource: sorted,
                      xValueMapper: (data, _) => _getMonthName(data.key),
                      yValueMapper: (data, _) => data.value,
                      width: 0.6,
                      spacing: 0.4,
                      animationDuration: 800,
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [_accentStart, _accentEnd],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      selectionBehavior: SelectionBehavior(
                        enable: true,
                        selectedColor: _accentEnd.withValues(alpha: 0.85),
                        unselectedColor: _accentStart,
                      ),
                      // Nhấn cột tháng -> chuyển sang xem theo Ngày của tháng đó
                      onPointTap: (ChartPointDetails details) {
                        final index = details.pointIndex;
                        if (index == null || index >= sorted.length) return;
                        final tappedMonth = sorted[index].key;
                        _onMonthBarTapped(tappedMonth);
                      },
                      dataLabelSettings: DataLabelSettings(
                        isVisible: true,
                        builder:
                            (data, point, series, pointIndex, seriesIndex) {
                          final entry = data as MapEntry<int, double>;
                          return Text(
                            entry.value == 0 ? "" : _formatMoney(entry.value),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String totalLabel;
  final Widget child;
  final Widget? trailing;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.totalLabel,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      padding: const EdgeInsets.symmetric(vertical: 16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.iconDisabled,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalLabel,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.iconDisabled.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ResetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ResetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh, size: 13, color: Color(0xFF6366F1)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FloatingTopBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingTopBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      width: 180,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _BottomItem(
            text: "Ngày",
            index: 0,
            currentIndex: currentIndex,
            onTap: onTap,
          ),
          _BottomItem(
            text: 'Tháng',
            index: 1,
            currentIndex: currentIndex,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final String text;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomItem({
    required this.text,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.translucent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : AppColors.iconDisabled,
            ),
          ),
        ),
      ),
    );
  }
}
