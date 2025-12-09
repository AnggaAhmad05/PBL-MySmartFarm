import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math' as math;

import '../monitoring/tanamanku_screen.dart';
import '../manual_control/smart_control_screen.dart';
import '../settings/profile_page_screen.dart';
import '../dashboard/menu_utama_screen.dart';
import '../notifications/notification_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String uid;
  const DashboardScreen({super.key, required this.uid});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Firebase Database Reference
  late DatabaseReference _database;
  
  // Sensor Data
  double temperature = 0;
  double humidity = 0;
  double soilMoisture = 0;
  double lightIntensity = 0;
  String timestamp = '';
  String deviceName = 'Loading...';
  String greenhouseLocation = 'Loading...';
  bool isLoading = true;
  String errorMessage = '';

  // Historical data for chart
  List<double> soilHistory = [];
  
  // Selected device
  String selectedDeviceId = 'device_001';

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  void _initializeDatabase() {
  try {
    _database = FirebaseDatabase.instance.ref();
    
    print("✅ Database initialized successfully");
    
    _listenToSensorData();
    _listenToDeviceInfo();
    _loadHistoricalData();
    
  } catch (e) {
    print("❌ Error: $e");
    setState(() {
      errorMessage = "Database Error: ${e.toString()}";
      isLoading = false;
    });
  }
}


  // ==================== LISTEN TO REAL-TIME SENSOR DATA ====================
  void _listenToSensorData() {
    try {
      _database
          .child('sensors')
          .child(selectedDeviceId)
          .onValue
          .listen((DatabaseEvent event) {
        if (event.snapshot.exists) {
          try {
            Map<dynamic, dynamic> data = 
                event.snapshot.value as Map<dynamic, dynamic>;
            
            if (mounted) {
              setState(() {
                temperature = _parseDouble(data['temperature']) ?? 0;
                humidity = _parseDouble(data['humidity']) ?? 0;
                soilMoisture = _parseDouble(data['soilMoisture']) ?? 0;
                lightIntensity = _parseDouble(data['lightIntensity']) ?? 0;
                timestamp = data['timestamp']?.toString() ?? '';
                isLoading = false;
                errorMessage = '';
                
                // Update soil history
                if (soilMoisture > 0) {
                  soilHistory.add(soilMoisture);
                  if (soilHistory.length > 7) {
                    soilHistory.removeAt(0);
                  }
                }
              });
              
              print("✅ Sensor data updated: T=$temperature, H=$humidity");
            }
          } catch (e) {
            print("❌ Error parsing sensor data: $e");
            if (mounted) {
              setState(() {
                errorMessage = "Error parsing sensor data";
              });
            }
          }
        } else {
          print("⚠️ No sensor data found");
          if (mounted) {
            setState(() {
              isLoading = false;
              errorMessage = "No sensor data available";
            });
          }
        }
      }, onError: (error) {
        print("❌ Error listening to sensor data: $error");
        if (mounted) {
          setState(() {
            errorMessage = "Connection Error: $error";
            isLoading = false;
          });
        }
      });
    } catch (e) {
      print("❌ Error setting up sensor listener: $e");
      if (mounted) {
        setState(() {
          errorMessage = "Setup Error: $e";
          isLoading = false;
        });
      }
    }
  }

  // ==================== LISTEN TO DEVICE INFO ====================
  void _listenToDeviceInfo() {
    try {
      _database
          .child('devices')
          .child(selectedDeviceId)
          .onValue
          .listen((DatabaseEvent event) {
        if (event.snapshot.exists) {
          try {
            Map<dynamic, dynamic> data = 
                event.snapshot.value as Map<dynamic, dynamic>;
            
            if (mounted) {
              setState(() {
                deviceName = data['name']?.toString() ?? 'Unknown Device';
                greenhouseLocation = data['location']?.toString() ?? 'Unknown Location';
              });
              
              print("✅ Device info updated: $deviceName");
            }
          } catch (e) {
            print("❌ Error parsing device info: $e");
          }
        }
      }, onError: (error) {
        print("❌ Error listening to device info: $error");
      });
    } catch (e) {
      print("❌ Error setting up device listener: $e");
    }
  }

  // ==================== LOAD HISTORICAL DATA ====================
  void _loadHistoricalData() async {
    try {
      DataSnapshot snapshot = 
          await _database.child('history/sensor_history').get();
      
      if (snapshot.exists) {
        Map<dynamic, dynamic> data = 
            snapshot.value as Map<dynamic, dynamic>;
        
        List<double> tempHistory = [];
        
        data.forEach((key, value) {
          if (value is Map) {
            Map<String, dynamic> item = Map<String, dynamic>.from(value);
            
            // Filter by selected device
            if (item['deviceId'] == selectedDeviceId) {
              double? soil = _parseDouble(item['soilMoisture']);
              if (soil != null && soil > 0) {
                tempHistory.add(soil);
              }
            }
          }
        });
        
        // Ambil 7 data terbaru
        if (tempHistory.length > 7) {
          tempHistory = tempHistory.sublist(tempHistory.length - 7);
        }
        
        if (mounted) {
          setState(() {
            soilHistory = tempHistory;
          });
        }
        
        print("✅ Historical data loaded: ${soilHistory.length} points");
      }
    } catch (e) {
      print("❌ Error loading historical data: $e");
    }
  }

  // ==================== HELPER FUNCTION ====================
  double? _parseDouble(dynamic value) {
    try {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      if (value is num) return value.toDouble();
      return null;
    } catch (e) {
      print("Error parsing double: $e");
      return null;
    }
  }

  String _getStatusText(String sensorType, double value) {
    switch (sensorType) {
      case 'humidity':
        if (value > 70) return "Tinggi";
        if (value > 50) return "Stabil";
        return "Rendah";
      case 'temperature':
        if (value > 30) return "Panas";
        if (value > 25) return "Normal";
        return "Dingin";
      case 'lightIntensity':
        return value > 70 ? "Bagus" : "Kurang";
      case 'soilMoisture':
        if (value > 60) return "Basah";
        if (value > 30) return "Optimal";
        return "Kering";
      default:
        return "Normal";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF2D7A3E),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text("Connecting to Firebase..."),
                  ],
                ),
              )
            : errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                              errorMessage = '';
                            });
                            _initializeDatabase();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D7A3E),
                          ),
                          child: const Text("Coba Lagi"),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // ==================== HEADER SALAM ====================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Text("Hi, ",
                                        style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87)),
                                    Text("Melonners!",
                                        style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2D7A3E))),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 14, color: Color(0xFF2D7A3E)),
                                    const SizedBox(width: 4),
                                    Text(greenhouseLocation,
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),

                            // ==================== ICON NOTIFIKASI + PROFIL ====================
                            Row(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFFE8F0EB),
                                            width: 1.4),
                                        boxShadow: [
                                          BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.07),
                                              blurRadius: 7,
                                              offset: const Offset(0, 3))
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                            Icons.notifications_outlined,
                                            size: 22,
                                            color: Color(0xFF2D7A3E)),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const NotificationHistoryScreen()),
                                          );
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(width: 10),

                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const ProfilePage()));
                                  },
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                            colors: [
                                          Color(0xFF2D7A3E),
                                          Color(0xFF4CAF50)
                                        ]),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.15),
                                              blurRadius: 7,
                                              offset: const Offset(0, 3))
                                        ]),
                                    child: const Icon(Icons.person,
                                        color: Colors.white, size: 22),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ==================== SMARTFARM MELON (HEADER) ====================
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2D7A3E), Color(0xFF45B659)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.green.withOpacity(0.32),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6))
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("SmartFarm Melon RS",
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text("📍 $deviceName",
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13))
                                  ]),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const TanamankuScreen()));
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.green.shade700,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                child: const Text("Lihat"),
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ==================== DATA SENSOR (REALTIME) ====================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Data Sensor Utama",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                            Row(
                              children: [
                                Icon(Icons.circle,
                                    size: 8,
                                    color: Colors.green.shade400),
                                const SizedBox(width: 6),
                                Text("Live",
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500))
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 16),

                        GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.1,
                          children: [
                            _sensorGridCard(
                                title: "Kelembaban",
                                value: "${humidity.toStringAsFixed(1)}%",
                                status: _getStatusText('humidity', humidity),
                                icon: Icons.water_drop,
                                iconColor: const Color(0xFF00B4D8)),
                            _sensorGridCard(
                                title: "Suhu",
                                value: "${temperature.toStringAsFixed(1)}°C",
                                status:
                                    _getStatusText('temperature', temperature),
                                icon: Icons.thermostat,
                                iconColor: const Color(0xFFFF9500)),
                            _sensorGridCard(
                                title: "Cahaya",
                                value: "${lightIntensity.toStringAsFixed(0)} lx",
                                status:
                                    _getStatusText('lightIntensity', lightIntensity),
                                icon: Icons.wb_sunny,
                                iconColor: const Color(0xFFFFB300)),
                            _sensorGridCard(
                                title: "Kelembaban Tanah",
                                value: "${soilMoisture.toStringAsFixed(0)}%",
                                status:
                                    _getStatusText('soilMoisture', soilMoisture),
                                icon: Icons.science,
                                iconColor: const Color(0xFF8B5CF6)),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // ==================== MINI CHART ====================
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '📊 Soil Moisture Trend',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Last ${soilHistory.isEmpty ? 0 : soilHistory.length} updates',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF4CAF50),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 100,
                                child: soilHistory.isEmpty
                                    ? Center(
                                        child: Text(
                                          "Menunggu data...",
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      )
                                    : CustomPaint(
                                        size: Size(
                                            MediaQuery.of(context).size.width -
                                                72,
                                            100),
                                        painter: LineChartPainter(soilHistory),
                                      ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // ==================== FITUR ====================
                        const Text("Fitur Pilihan",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        const SizedBox(height: 16),

                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            _featureIcon(
                                icon: Icons.grass,
                                label: "Tanamanku",
                                color: const Color(0xFF2D7A3E),
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const TanamankuScreen()));
                                }),
                            _featureIcon(
                                icon: Icons.settings_remote,
                                label: "Kontrol",
                                color: const Color(0xFF00B4D8),
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const SmartControlScreen()));
                                }),
                            _featureIcon(
                                icon: Icons.apps,
                                label: "Menu",
                                color: const Color(0xFF8B5CF6),
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const MenuUtamaScreen()));
                                }),
                          ],
                        ),

                        const SizedBox(height: 35),
                      ],
                    ),
                  ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// ==================== REUSABLE COMPONENTS ====================
Widget _sensorGridCard({
  required String title,
  required String value,
  required String status,
  required IconData icon,
  required Color iconColor,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: iconColor.withOpacity(0.15), width: 1.6),
      boxShadow: [
        BoxShadow(
            color: iconColor.withOpacity(0.20),
            blurRadius: 10,
            offset: const Offset(0, 4))
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 26),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          Text(status,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: iconColor))
        ])
      ],
    ),
  );
}

Widget _featureIcon({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        )
      ],
    ),
  );
}

// ==================== CUSTOM CHART PAINTER ====================
class LineChartPainter extends CustomPainter {
  final List<double> data;

  LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF4CAF50).withOpacity(0.3),
          const Color(0xFF4CAF50).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (data.length - 1);
    final maxValue = data.reduce(math.max);
    final minValue = data.reduce(math.min);
    final range = maxValue - minValue;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = range > 0 ? (data[i] - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height * 0.8) - 10;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = const Color(0xFF4CAF50)
          ..style = PaintingStyle.fill,
      );
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
