// lib/screens/data_historis_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DataHistorisScreen extends StatefulWidget {
  const DataHistorisScreen({super.key});

  @override
  State<DataHistorisScreen> createState() => _DataHistorisScreenState();
}

class _DataHistorisScreenState extends State<DataHistorisScreen> {
  String selectedPeriod = 'Hari'; // Hari, Minggu, Bulan
  String selectedSensor = 'Suhu'; // Suhu, Kelembaban, Cahaya

  // DUMMY DATA - ganti dengan Firebase nanti
  final List<Map<String, dynamic>> dummyData = [
    {'time': '00:00', 'value': 26.0},
    {'time': '04:00', 'value': 25.0},
    {'time': '08:00', 'value': 28.0},
    {'time': '12:00', 'value': 31.0},
    {'time': '16:00', 'value': 29.0},
    {'time': '20:00', 'value': 27.0},
    {'time': '23:59', 'value': 26.5},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F3),
      appBar: AppBar(
        title: const Text("Data Historis", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Periode
            const Text("Pilih Periode:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildPeriodChip('Hari'),
                const SizedBox(width: 8),
                _buildPeriodChip('Minggu'),
                const SizedBox(width: 8),
                _buildPeriodChip('Bulan'),
              ],
            ),

            const SizedBox(height: 20),

            // Filter Sensor
            const Text("Pilih Sensor:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildSensorChip('Suhu', Icons.thermostat, Colors.orange),
                const SizedBox(width: 8),
                _buildSensorChip('Kelembaban', Icons.water_drop, Colors.blue),
                const SizedBox(width: 8),
                _buildSensorChip('Cahaya', Icons.wb_sunny, Colors.yellow),
              ],
            ),

            const SizedBox(height: 25),

            // Card Grafik
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$selectedSensor - $selectedPeriod Ini",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  Text(
                    "Update: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Grafik
                  SizedBox(
                    height: 250,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 && value.toInt() < dummyData.length) {
                                  return Text(
                                    dummyData[value.toInt()]['time'],
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: dummyData
                                .asMap()
                                .entries
                                .map((e) => FlSpot(e.key.toDouble(), e.value['value']))
                                .toList(),
                            isCurved: true,
                            color: _getSensorColor(),
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: _getSensorColor().withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Statistik
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Statistik", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard("Rata-rata", "27.5°C", Colors.blue),
                      _buildStatCard("Maksimal", "31.0°C", Colors.red),
                      _buildStatCard("Minimal", "25.0°C", Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label) {
    final isSelected = selectedPeriod == label;
    return GestureDetector(
      onTap: () => setState(() => selectedPeriod = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSensorChip(String label, IconData icon, Color color) {
    final isSelected = selectedSensor == label;
    return GestureDetector(
      onTap: () => setState(() => selectedSensor = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getSensorColor() {
    switch (selectedSensor) {
      case 'Suhu':
        return Colors.orange;
      case 'Kelembaban':
        return Colors.blue;
      case 'Cahaya':
        return Colors.yellow.shade700;
      default:
        return Colors.green;
    }
  }
}