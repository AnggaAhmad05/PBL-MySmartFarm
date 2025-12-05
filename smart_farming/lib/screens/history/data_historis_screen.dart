import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataHistorisScreen extends StatefulWidget {
  const DataHistorisScreen({super.key});

  @override
  State<DataHistorisScreen> createState() => _DataHistorisScreenState();
}

class _DataHistorisScreenState extends State<DataHistorisScreen> {
  String selectedPeriod = 'Hari'; // Hari, Minggu, Bulan
  String selectedSensor = 'temperature'; // temperature, humidity, lightIntensity

  List<Map<String, dynamic>> sensorData = [];

  @override
  void initState() {
    super.initState();
    fetchSensorData();
  }

  Future<void> fetchSensorData() async {
    QuerySnapshot snapshot;
    if (selectedPeriod == 'Hari') {
      // Ambil data harian
      snapshot = await FirebaseFirestore.instance
          .collection('sensor_history')
          .where('timestamp', isGreaterThan: DateTime.now().subtract(Duration(days: 1)))
          .get();
    } else if (selectedPeriod == 'Minggu') {
      // Ambil data mingguan
      snapshot = await FirebaseFirestore.instance
          .collection('sensor_history')
          .where('timestamp', isGreaterThan: DateTime.now().subtract(Duration(days: 7)))
          .get();
    } else {
      // Ambil data bulanan
      snapshot = await FirebaseFirestore.instance
          .collection('sensor_history')
          .where('timestamp', isGreaterThan: DateTime.now().subtract(Duration(days: 30)))
          .get();
    }

    setState(() {
      sensorData = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

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
                _buildSensorChip('temperature', Icons.thermostat, Colors.orange),
                const SizedBox(width: 8),
                _buildSensorChip('humidity', Icons.water_drop, Colors.blue),
                const SizedBox(width: 8),
                _buildSensorChip('lightIntensity', Icons.wb_sunny, Colors.yellow),
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
                    "${selectedSensor.toUpperCase()} - $selectedPeriod Ini",
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
                                if (value.toInt() >= 0 && value.toInt() < sensorData.length) {
                                  return Text(
                                    DateFormat('HH:mm').format(sensorData[value.toInt()]['timestamp'].toDate()),
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
                            spots: sensorData
                                .asMap()
                                .entries
                                .map((e) {
                                  double? value = double.tryParse(e.value[selectedSensor].toString());
                                  return value != null ? FlSpot(e.key.toDouble(), value) : FlSpot(e.key.toDouble(), 0.0);
                                })
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
                      _buildStatCard("Rata-rata", "${_calculateAverage().toStringAsFixed(1)}", Colors.blue),
                      _buildStatCard("Maksimal", "${_calculateMax().toStringAsFixed(1)}", Colors.red),
                      _buildStatCard("Minimal", "${_calculateMin().toStringAsFixed(1)}", Colors.green),
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
      onTap: () {
        setState(() {
          selectedPeriod = label;
          fetchSensorData();
        });
      },
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
      onTap: () {
        setState(() {
          selectedSensor = label;
          fetchSensorData();
        });
      },
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
              label.toUpperCase(),
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
      case 'temperature':
        return Colors.orange;
      case 'humidity':
        return Colors.blue;
      case 'lightIntensity':
        return Colors.yellow.shade700;
      default:
        return Colors.green;
    }
  }

  double _calculateAverage() {
    if (sensorData.isEmpty) return 0.0;
    double sum = 0.0;
    int validCount = 0;
    for (final data in sensorData) {
      double? value = double.tryParse(data[selectedSensor].toString());
      if (value != null) {
        sum += value;
        validCount++;
      }
    }
    return validCount > 0 ? sum / validCount : 0.0;
  }

  double _calculateMax() {
    if (sensorData.isEmpty) return 0.0;
    double max = double.parse(sensorData[0][selectedSensor].toString());
    for (final data in sensorData) {
      double? value = double.tryParse(data[selectedSensor].toString());
      if (value != null && value > max) {
        max = value;
      }
    }
    return max;
  }

  double _calculateMin() {
    if (sensorData.isEmpty) return 0.0;
    double min = double.parse(sensorData[0][selectedSensor].toString());
    for (final data in sensorData) {
      double? value = double.tryParse(data[selectedSensor].toString());
      if (value != null && value < min) {
        min = value;
      }
    }
    return min;
  }
}
