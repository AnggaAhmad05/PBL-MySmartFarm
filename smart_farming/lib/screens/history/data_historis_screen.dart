import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBDK6LPxkmpFtW7VFD1PzRrtOrQbNSQSrs",
      appId: "1:YOUR_APP_ID",
      messagingSenderId: "YOUR_SENDER_ID",
      projectId: "smartfarming-a2834",
      databaseURL: "https://smartfarming-a2834-default-rtdb.asia-southeast1.firebasedatabase.app/",
      storageBucket: "smartfarming-a2834.appspot.com",
    ),
  );
  runApp(MaterialApp(home: DataHistorisScreen()));
}

class DataHistorisScreen extends StatefulWidget {
  const DataHistorisScreen({super.key});

  @override
  State<DataHistorisScreen> createState() => _DataHistorisScreenState();
}

class _DataHistorisScreenState extends State<DataHistorisScreen> {
  String selectedPeriod = 'Hari';
  String selectedSensor = 'temperature';
  late DatabaseReference _database;
  bool isDatabaseInitialized = false;
  
  List<Map<String, dynamic>> sensorData = [];
  List<Map<String, dynamic>> chartData = [];
  bool isLoading = true;
  String selectedDevice = 'device_001';

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  void _initializeDatabase() async {
    try {
      _database = FirebaseDatabase(
        databaseURL: "https://smartfarming-a2834-default-rtdb.asia-southeast1.firebasedatabase.app/",
      ).ref();
      
      print("Database initialized successfully");
      setState(() {
        isDatabaseInitialized = true;
      });
      
      fetchSensorData();
    } catch (e) {
      print("Error initializing database: $e");
      try {
        _database = FirebaseDatabase.instance.ref();
        print("Using default database instance");
        setState(() {
          isDatabaseInitialized = true;
        });
        fetchSensorData();
      } catch (e2) {
        print("Error with default instance: $e2");
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchSensorData() async {
    if (!isDatabaseInitialized) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      Query query;
      
      print("Fetching data for period: $selectedPeriod for device: $selectedDevice");
      
      // Ambil semua data dari history/sensor_history
      query = _database.child('history/sensor_history');
      print("Path: history/sensor_history");

      // Tidak menggunakan limit di query karena kita akan filter di client side
      // query = query.limitToLast(100); // Jika perlu batasi jumlah data

      DataSnapshot snapshot = await query.get();
      
      if (snapshot.exists) {
        Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          print("Raw data found: ${data.length} records");
          List<Map<String, dynamic>> tempData = [];
          
          data.forEach((key, value) {
            if (value is Map) {
              Map<String, dynamic> item = Map<String, dynamic>.from(value);
              item['key'] = key.toString();
              
              // Filter berdasarkan deviceId di client side
              if (item['deviceId'] != selectedDevice) {
                return; // Skip jika bukan device yang dipilih
              }
              
              // Parse timestamp
              if (item.containsKey('timestamp')) {
                String timestampStr = item['timestamp'].toString();
                try {
                  DateFormat format = DateFormat('yyyy-MM-dd HH:mm:ss');
                  item['dateTime'] = format.parse(timestampStr);
                } catch (e) {
                  print("Error parsing timestamp: $e");
                  item['dateTime'] = DateTime.now();
                }
              } else if (item.containsKey('time') && item.containsKey('date')) {
                // Alternatif jika ada time dan date terpisah
                try {
                  String dateStr = item['date'].toString();
                  String timeStr = item['time'].toString();
                  DateFormat format = DateFormat('yyyy-MM-dd HH:mm');
                  item['dateTime'] = format.parse('$dateStr $timeStr');
                } catch (e) {
                  print("Error parsing date/time: $e");
                  item['dateTime'] = DateTime.now();
                }
              } else {
                item['dateTime'] = DateTime.now();
              }
              
              tempData.add(item);
            }
          });
          
          // Filter berdasarkan periode
          tempData = _filterByPeriod(tempData);
          
          // Urutkan berdasarkan timestamp (terbaru ke terlama untuk tampilan)
          tempData.sort((a, b) {
            DateTime? dateA = a['dateTime'];
            DateTime? dateB = b['dateTime'];
            if (dateA != null && dateB != null) {
              return dateB.compareTo(dateA);
            }
            return 0;
          });
          
          print("Filtered data: ${tempData.length} records for device $selectedDevice");
          
          setState(() {
            sensorData = tempData;
            prepareChartData();
          });
        } else {
          print("Data is null");
          setState(() {
            sensorData = [];
            chartData = [];
          });
        }
      } else {
        print("No data found at path");
        setState(() {
          sensorData = [];
          chartData = [];
        });
      }
    } catch (error) {
      print('Error fetching data: $error');
      print('Error details: ${error.toString()}');
      setState(() {
        sensorData = [];
        chartData = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _filterByPeriod(List<Map<String, dynamic>> data) {
    DateTime now = DateTime.now();
    
    switch (selectedPeriod) {
      case 'Hari':
        DateTime yesterday = now.subtract(const Duration(days: 1));
        return data.where((item) {
          DateTime? dateTime = item['dateTime'];
          return dateTime != null && dateTime.isAfter(yesterday);
        }).toList();
        
      case 'Minggu':
        DateTime weekAgo = now.subtract(const Duration(days: 7));
        return data.where((item) {
          DateTime? dateTime = item['dateTime'];
          return dateTime != null && dateTime.isAfter(weekAgo);
        }).toList();
        
      case 'Bulan':
        DateTime monthAgo = now.subtract(const Duration(days: 30));
        return data.where((item) {
          DateTime? dateTime = item['dateTime'];
          return dateTime != null && dateTime.isAfter(monthAgo);
        }).toList();
        
      default:
        return data;
    }
  }

  void prepareChartData() {
    List<Map<String, dynamic>> tempChartData = [];
    
    print("Preparing chart data for sensor: $selectedSensor");
    
    // Urutkan data untuk chart (terlama ke terbaru)
    List<Map<String, dynamic>> sortedData = List.from(sensorData);
    sortedData.sort((a, b) {
      DateTime? dateA = a['dateTime'];
      DateTime? dateB = b['dateTime'];
      if (dateA != null && dateB != null) {
        return dateA.compareTo(dateB);
      }
      return 0;
    });
    
    for (int i = 0; i < sortedData.length; i++) {
      var data = sortedData[i];
      dynamic rawValue;
      double? value;
      
      switch (selectedSensor) {
        case 'temperature':
          rawValue = data['temperature'];
          break;
        case 'humidity':
          rawValue = data['humidity'];
          break;
        case 'lightIntensity':
          rawValue = data['lightIntensity'];
          break;
        case 'soilMoisture':
          rawValue = data['soilMoisture'];
          break;
      }
      
      // Konversi ke double
      if (rawValue != null) {
        if (rawValue is int) {
          value = rawValue.toDouble();
        } else if (rawValue is double) {
          value = rawValue;
        } else if (rawValue is String) {
          value = double.tryParse(rawValue);
        } else if (rawValue is num) {
          value = rawValue.toDouble();
        }
      }
      
      if (value != null) {
        tempChartData.add({
          'index': i.toDouble(),
          'value': value,
          'time': data['dateTime'] ?? DateTime.now(),
          'label': _getTimeLabel(data['dateTime'] ?? DateTime.now()),
        });
      }
    }
    
    print("Chart data prepared: ${tempChartData.length} points");
    
    setState(() {
      chartData = tempChartData;
    });
  }

  String _getTimeLabel(DateTime dateTime) {
    if (selectedPeriod == 'Hari') {
      return DateFormat('HH:mm').format(dateTime);
    } else if (selectedPeriod == 'Minggu') {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
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
      body: !isDatabaseInitialized
          ? const Center(child: CircularProgressIndicator())
          : isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Device Selection
                      const Text("Pilih Device:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      _buildDeviceSelector(),
                      
                      const SizedBox(height: 20),

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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSensorChip('temperature', Icons.thermostat, Colors.orange, '°C'),
                          _buildSensorChip('humidity', Icons.water_drop, Colors.blue, '%'),
                          _buildSensorChip('lightIntensity', Icons.wb_sunny, Colors.yellow, '%'),
                          _buildSensorChip('soilMoisture', Icons.grass, Colors.green, '%'),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // Info Data
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${_getSensorName(selectedSensor)} - $selectedPeriod Ini",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  "${sensorData.length} data ditemukan (${_getDeviceName(selectedDevice)})",
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: fetchSensorData,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Card Grafik
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Grafik ${_getSensorName(selectedSensor)} - ${_getDeviceName(selectedDevice)}",
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
                              child: chartData.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.show_chart, size: 50, color: Colors.grey),
                                          const SizedBox(height: 10),
                                          const Text(
                                            "Tidak ada data untuk ditampilkan",
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                          TextButton(
                                            onPressed: fetchSensorData,
                                            child: const Text("Coba Muat Ulang"),
                                          ),
                                        ],
                                      ),
                                    )
                                  : LineChart(
                                      LineChartData(
                                        minX: 0,
                                        maxX: chartData.length > 1 ? (chartData.length - 1).toDouble() : 1,
                                        minY: _calculateMin() - 5,
                                        maxY: _calculateMax() + 5,
                                        gridData: FlGridData(
                                          show: true,
                                          drawHorizontalLine: true,
                                          drawVerticalLine: false,
                                          getDrawingHorizontalLine: (value) {
                                            return FlLine(
                                              color: Colors.grey.withOpacity(0.1),
                                              strokeWidth: 1,
                                            );
                                          },
                                        ),
                                        titlesData: FlTitlesData(
                                          show: true,
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 40,
                                              interval: _calculateInterval(),
                                              getTitlesWidget: (value, meta) {
                                                return Padding(
                                                  padding: const EdgeInsets.only(right: 8),
                                                  child: Text(
                                                    value.toStringAsFixed(1),
                                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 20,
                                              interval: _calculateBottomInterval(),
                                              getTitlesWidget: (value, meta) {
                                                int index = value.toInt();
                                                if (index >= 0 && index < chartData.length && index % _calculateLabelInterval() == 0) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(top: 8),
                                                    child: Text(
                                                      chartData[index]['label'],
                                                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                                                    ),
                                                  );
                                                }
                                                return const Text('');
                                              },
                                            ),
                                          ),
                                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        ),
                                        borderData: FlBorderData(
                                          show: true,
                                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                        ),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: chartData
                                                .map((data) => FlSpot(data['index'], data['value']))
                                                .toList(),
                                            isCurved: true,
                                            color: _getSensorColor(),
                                            barWidth: 3,
                                            dotData: FlDotData(
                                              show: chartData.length < 50,
                                              getDotPainter: (spot, percent, barData, index) {
                                                return FlDotCirclePainter(
                                                  radius: 3,
                                                  color: _getSensorColor(),
                                                  strokeWidth: 2,
                                                  strokeColor: Colors.white,
                                                );
                                              },
                                            ),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              color: _getSensorColor().withOpacity(0.1),
                                            ),
                                            gradient: LinearGradient(
                                              colors: [
                                                _getSensorColor(),
                                                _getSensorColor().withOpacity(0.5),
                                              ],
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Statistik", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatCard("Rata-rata", "${_calculateAverage().toStringAsFixed(1)}${_getSensorUnit(selectedSensor)}", Colors.blue),
                                _buildStatCard("Maksimal", "${_calculateMax().toStringAsFixed(1)}${_getSensorUnit(selectedSensor)}", Colors.red),
                                _buildStatCard("Minimal", "${_calculateMin().toStringAsFixed(1)}${_getSensorUnit(selectedSensor)}", Colors.green),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Tabel Data Historis
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Data Terbaru", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                Text(
                                  "Total: ${sensorData.length} data",
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 300,
                              child: sensorData.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.data_usage, size: 50, color: Colors.grey),
                                          const SizedBox(height: 10),
                                          const Text(
                                            "Tidak ada data historis",
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                          TextButton(
                                            onPressed: fetchSensorData,
                                            child: const Text("Refresh Data"),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: sensorData.length,
                                      itemBuilder: (context, index) {
                                        var data = sensorData[index];
                                        return _buildDataRow(data, index);
                                      },
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

  Widget _buildDeviceSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Device:", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            _getDeviceName(selectedDevice),
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
        ],
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
          border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300),
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

  Widget _buildSensorChip(String label, IconData icon, Color color, String unit) {
    final isSelected = selectedSensor == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSensor = label;
          prepareChartData();
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              _getSensorName(label),
              style: TextStyle(
                color: isSelected ? color : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              "($unit)",
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(Map<String, dynamic> data, int index) {
    DateTime? dateTime = data['dateTime'];
    String timeStr = dateTime != null 
        ? DateFormat('HH:mm').format(dateTime)
        : '--:--';
    
    String dateStr = dateTime != null
        ? DateFormat('dd/MM/yyyy').format(dateTime)
        : '--/--/----';
    
    String formatValue(dynamic value) {
      if (value == null) return '--';
      if (value is int) return value.toString();
      if (value is double) return value.toStringAsFixed(1);
      if (value is String) {
        double? parsed = double.tryParse(value);
        return parsed?.toStringAsFixed(1) ?? value;
      }
      if (value is num) return value.toStringAsFixed(1);
      return value.toString();
    }
    
    String temperatureStr = formatValue(data['temperature']);
    String humidityStr = formatValue(data['humidity']);
    String lightStr = formatValue(data['lightIntensity']);
    String soilStr = formatValue(data['soilMoisture']);
    bool? pumpStatus = data['pumpStatus'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeStr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                dateStr,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDataItem(Icons.thermostat, '$temperatureStr°C', Colors.orange),
                _buildDataItem(Icons.water_drop, '$humidityStr%', Colors.blue),
                _buildDataItem(Icons.wb_sunny, '$lightStr%', Colors.yellow.shade700),
                _buildDataItem(Icons.grass, '$soilStr%', Colors.green),
                _buildDataItem(
                  Icons.water_drop,
                  pumpStatus == true ? 'ON' : 'OFF',
                  pumpStatus == true ? Colors.green : Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataItem(IconData icon, String text, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Helper functions
  String _getSensorName(String sensor) {
    switch (sensor) {
      case 'temperature':
        return 'Suhu';
      case 'humidity':
        return 'Kelembaban';
      case 'lightIntensity':
        return 'Cahaya';
      case 'soilMoisture':
        return 'Tanah';
      default:
        return sensor;
    }
  }

  String _getDeviceName(String deviceId) {
    switch (deviceId) {
      case 'device_001':
        return 'Node Sensor Utama';
      default:
        return deviceId;
    }
  }

  String _getSensorUnit(String sensor) {
    switch (sensor) {
      case 'temperature':
        return '°C';
      case 'humidity':
      case 'lightIntensity':
      case 'soilMoisture':
        return '%';
      default:
        return '';
    }
  }

  Color _getSensorColor() {
    switch (selectedSensor) {
      case 'temperature':
        return Colors.orange;
      case 'humidity':
        return Colors.blue;
      case 'lightIntensity':
        return Colors.yellow.shade700;
      case 'soilMoisture':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  double _calculateAverage() {
    if (sensorData.isEmpty) return 0.0;
    double sum = 0.0;
    int validCount = 0;
    
    for (final data in sensorData) {
      dynamic rawValue = data[selectedSensor];
      double? value;
      
      if (rawValue != null) {
        if (rawValue is int) {
          value = rawValue.toDouble();
        } else if (rawValue is double) {
          value = rawValue;
        } else if (rawValue is String) {
          value = double.tryParse(rawValue);
        } else if (rawValue is num) {
          value = rawValue.toDouble();
        }
      }
      
      if (value != null) {
        sum += value;
        validCount++;
      }
    }
    
    return validCount > 0 ? sum / validCount : 0.0;
  }

  double _calculateMax() {
    if (sensorData.isEmpty) return 0.0;
    double max = double.negativeInfinity;
    
    for (final data in sensorData) {
      dynamic rawValue = data[selectedSensor];
      double? value;
      
      if (rawValue != null) {
        if (rawValue is int) {
          value = rawValue.toDouble();
        } else if (rawValue is double) {
          value = rawValue;
        } else if (rawValue is String) {
          value = double.tryParse(rawValue);
        } else if (rawValue is num) {
          value = rawValue.toDouble();
        }
      }
      
      if (value != null && value > max) {
        max = value;
      }
    }
    
    return max.isFinite ? max : 0.0;
  }

  double _calculateMin() {
    if (sensorData.isEmpty) return 0.0;
    double min = double.infinity;
    
    for (final data in sensorData) {
      dynamic rawValue = data[selectedSensor];
      double? value;
      
      if (rawValue != null) {
        if (rawValue is int) {
          value = rawValue.toDouble();
        } else if (rawValue is double) {
          value = rawValue;
        } else if (rawValue is String) {
          value = double.tryParse(rawValue);
        } else if (rawValue is num) {
          value = rawValue.toDouble();
        }
      }
      
      if (value != null && value < min) {
        min = value;
      }
    }
    
    return min.isFinite ? min : 0.0;
  }

  double _calculateInterval() {
    double max = _calculateMax();
    double min = _calculateMin();
    double range = max - min;
    
    if (range <= 0) return 10;
    if (range <= 10) return 2;
    if (range <= 50) return 10;
    return 20;
  }

  double _calculateBottomInterval() {
    if (chartData.length <= 10) return 1;
    if (chartData.length <= 20) return 2;
    return chartData.length / 5;
  }

  int _calculateLabelInterval() {
    if (chartData.length <= 10) return 1;
    if (chartData.length <= 20) return 2;
    if (chartData.length <= 50) return 5;
    return 10;
  }
}