import 'package:finance_tracker/services/transactions_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class homePageBarChart extends StatelessWidget {
  const homePageBarChart({
    super.key,
    required this.maxYValueForChart,
    required this.chartPoints,
  });

  final double maxYValueForChart;
  final List<ChartDataPoint> chartPoints;

  @override
  Widget build(BuildContext context) {
    if (chartPoints.isEmpty) {
      return SizedBox(
        height: 150,
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              "No data for this period.",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    double chartwidth = chartPoints.length * 50;
    final screenwidth = MediaQuery.of(context).size.width;
    if (chartwidth < screenwidth) {
      chartwidth = screenwidth;
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        height: 150,
        width: chartwidth,
        child: BarChart(
          BarChartData(
            maxY: maxYValueForChart,
            minY: 0,
            groupsSpace: 50,
            gridData: FlGridData(show: false),
            barGroups:
                chartPoints.asMap().entries.map((entry) {
                  int index = entry.key;
                  ChartDataPoint dataPoint = entry.value;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: dataPoint.income,
                        color: Colors.green,
                      ),
                      BarChartRodData(
                        toY: dataPoint.expense,
                        color: Colors.red,
                      ),
                    ],
                  );
                }).toList(),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final int pointIndex = value.toInt();
                    ChartDataPoint? currentPoint;
                    currentPoint = chartPoints[pointIndex];

                    if (currentPoint == null) {
                      return SideTitleWidget(meta: meta, child: const Text(''));
                    }
                    String periodLabel = currentPoint.label;
                    double netChangeValue = currentPoint.netChange;
                    String netChangeString = '';
                    Color netChangeColor = Colors.grey;

                    if (netChangeValue != 0) {
                      netChangeColor =
                          netChangeValue >= 0 ? Colors.green : Colors.red;
                      String netChangeSign = netChangeValue >= 0 ? '+' : '-';
                      netChangeString =
                          '$netChangeSign\$${netChangeValue.abs().toStringAsFixed(0)}';
                    }

                    return SideTitleWidget(
                      meta: meta,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(periodLabel),
                          Text(
                            netChangeString,
                            style: TextStyle(color: netChangeColor),
                          ),
                        ],
                      ),
                    );
                    // String text = '';
                    // if (value.toInt() >= 0 &&
                    //     value.toInt() < chartPoints.length) {
                    //   text = chartPoints[value.toInt()].label;
                    // }
                    // return SideTitleWidget(
                    //   meta: meta,
                    //   child: Text(text, style: const TextStyle(fontSize: 10)),
                    // );
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => Colors.transparent,
                tooltipPadding: EdgeInsets.zero,
                tooltipMargin: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
