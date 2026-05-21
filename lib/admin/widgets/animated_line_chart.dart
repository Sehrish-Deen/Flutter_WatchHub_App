import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnimatedLineChart extends StatefulWidget {
  const AnimatedLineChart({super.key});

  @override
  State<AnimatedLineChart> createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<AnimatedLineChart> {
  double progress = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      for (int i = 0; i <= 100; i++) {
        await Future.delayed(const Duration(milliseconds: 15));
        setState(() {
          progress = i / 100;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "Growth Overview",
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(),
                            style: const TextStyle(color: Colors.white70, fontSize: 12));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text("Day ${value.toInt()}",
                            style: const TextStyle(color: Colors.white70, fontSize: 12));
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 6,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 1),
                      FlSpot(2, 4),
                      FlSpot(3, 2),
                      FlSpot(4, 5),
                      FlSpot(5, 3.5),
                      FlSpot(6, 4.5),
                    ],
                    isCurved: true,
                    gradient: const LinearGradient(
                        colors: [Colors.deepOrangeAccent, Colors.orangeAccent]),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                          colors: [Colors.deepOrangeAccent.withOpacity(0.3), Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter),
                    ),
                    dotData: FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 2),
                      FlSpot(1, 2.5),
                      FlSpot(2, 3),
                      FlSpot(3, 3.5),
                      FlSpot(4, 4),
                      FlSpot(5, 4.8),
                      FlSpot(6, 5.2),
                    ],
                    isCurved: true,
                    gradient: const LinearGradient(colors: [Colors.lightBlueAccent, Colors.blueAccent]),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                          colors: [Colors.blueAccent.withOpacity(0.3), Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter),
                    ),
                    dotData: FlDotData(show: false),
                  ),
                ].map((bar) {
                  final cutOff = (bar.spots.length * progress).clamp(0, bar.spots.length.toDouble());
                  return LineChartBarData(
                    spots: bar.spots.sublist(0, cutOff.floor() > 0 ? cutOff.floor() : 1),
                    isCurved: bar.isCurved,
                    gradient: bar.gradient,
                    barWidth: bar.barWidth,
                    isStrokeCapRound: bar.isStrokeCapRound,
                    belowBarData: bar.belowBarData,
                    dotData: bar.dotData,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LegendItem(color: Colors.deepOrangeAccent, text: "Users"),
              SizedBox(width: 20),
              _LegendItem(color: Colors.blueAccent, text: "Orders"),
            ],
          )
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
