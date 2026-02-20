import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DesempenhoGeralCard extends StatelessWidget {
  final int total;
  final int corretas;
  final int erradas;

  const DesempenhoGeralCard({
    super.key,
    required this.total,
    required this.corretas,
    required this.erradas,
  });

  @override
  Widget build(BuildContext context) {
    final percentCorretas = total == 0 ? 0.0 : corretas / total;
    final percentErradas = total == 0 ? 0.0 : erradas / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            /// GRAFICO
            SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      sectionsSpace: 2,
                      centerSpaceRadius: 34,
                      borderData: FlBorderData(show: false),
                      sections: total == 0
                          ? [
                              PieChartSectionData(
                                value: 1,
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                radius: 20,
                                showTitle: false,
                              ),
                            ]
                          : [
                              PieChartSectionData(
                                value: percentCorretas.clamp(0.0, 1.0),
                                color: const Color(0xFF10B981),
                                radius: 20,
                                showTitle: false,
                              ),
                              PieChartSectionData(
                                value: percentErradas.clamp(0.0, 1.0),
                                color: const Color(0xFFEF4444),
                                radius: 20,
                                showTitle: false,
                              ),
                            ],
                    ),
                  ),
                  Text(
                    "${(percentCorretas * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            /// DADOS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Desempenho Geral",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),

                  const SizedBox(height: 10),

                  Text("Total: $total"),
                  Text(
                    "Corretas: $corretas",
                    style: const TextStyle(color: Color(0xFF10B981)),
                  ),
                  Text(
                    "Erradas: $erradas",
                    style: const TextStyle(color: Color(0xFFEF4444)),
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
