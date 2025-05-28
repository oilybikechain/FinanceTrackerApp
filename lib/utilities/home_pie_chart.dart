import 'package:finance_tracker/services/transactions_provider.dart';
import 'package:finance_tracker/utilities/formatted_value.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class homePieChart extends StatelessWidget {
  const homePieChart({
    super.key,
    required this.title,
    required this.pieData,
    required this.totalValue,
  });

  final String title;
  final List<PieChartSectionDataWrapper> pieData;
  final double totalValue;

  @override
  Widget build(BuildContext context) {
    if (pieData.isEmpty) {
      return SizedBox(
        height: 150,
        width: MediaQuery.of(context).size.width / 2,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              "No ${title.toLowerCase()} data for this period.",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Generate PieChartSectionData for fl_chart
    List<PieChartSectionData> sections =
        pieData.map((data) {
          final radius = 10.0;

          return PieChartSectionData(
            color: data.color,
            value: data.value,
            title:
                '%${data.percentage.toStringAsFixed(0)}', // Show percentage on slice
            radius: radius,
            titleStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            titlePositionPercentageOffset: 2.2,
          );
        }).toList();

    return SizedBox(
      height: 150,
      width: MediaQuery.of(context).size.width / 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),

            SizedBox(height: 4),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      scrollDirection:
                          Axis.vertical, // Or horizontal if preferred
                      child: Column(
                        children:
                            pieData.map((data) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    color: data.color,
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      '${data.title}: \$${formattedValue(data.value)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: PieChart(
                        PieChartData(
                          titleSunbeamLayout: false,
                          pieTouchData: PieTouchData(
                            touchCallback: (
                              FlTouchEvent event,
                              pieTouchResponse,
                            ) {
                              // setState(() { // For touch interaction feedback if needed
                              //   if (!event.isInterestedForInteractions ||
                              //       pieTouchResponse == null ||
                              //       pieTouchResponse.touchedSection == null) {
                              //     touchedIndex = -1;
                              //     return;
                              //   }
                              //   touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              // });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 4, // Space between slices
                          centerSpaceRadius: 25, // Radius of the center hole
                          sections: sections,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
