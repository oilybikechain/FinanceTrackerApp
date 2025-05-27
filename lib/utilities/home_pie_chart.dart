import 'package:finance_tracker/services/transactions_provider.dart';
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
      return Expanded(
        child: Center(child: Text("No $title data for this period.")),
      );
    }

    // Generate PieChartSectionData for fl_chart
    List<PieChartSectionData> sections =
        pieData.map((data) {
          final isTouched = false; // You can add touch interaction state later
          final fontSize = isTouched ? 18.0 : 14.0;
          final radius = isTouched ? 60.0 : 50.0;
          final shadows = [const Shadow(color: Colors.black26, blurRadius: 2)];

          return PieChartSectionData(
            color: data.color,
            value: data.value,
            title:
                '${data.percentage.toStringAsFixed(0)}%', // Show percentage on slice
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xffffffff), // White text on slice
              shadows: shadows,
            ),
            // Optional: Add a badge (e.g., category icon)
            // badgeWidget: _Badge(category.icon, size: widget.size, borderColor: widget.borderColor),
            // badgePositionPercentageOffset: .98,
          );
        }).toList();

    return Expanded(
      child: Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(
            '\$${totalValue.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Expanded(
            // Allow PieChart to take available space
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
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
                sectionsSpace: 2, // Space between slices
                centerSpaceRadius: 30, // Radius of the center hole
                sections: sections,
              ),
              swapAnimationDuration: const Duration(milliseconds: 250),
              swapAnimationCurve: Curves.easeInOut,
            ),
          ),
          const SizedBox(height: 8),
          // --- Legend ---
          SizedBox(
            // Constrain legend height if it gets too long
            height: 60, // Adjust as needed, or make it flexible
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical, // Or horizontal if preferred
              child: Wrap(
                // Or Column/Row
                spacing: 8.0,
                runSpacing: 4.0,
                alignment: WrapAlignment.center,
                children:
                    pieData.map((data) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 10, height: 10, color: data.color),
                          const SizedBox(width: 4),
                          Text(
                            '${data.title} (${data.percentage.toStringAsFixed(0)}%)',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
