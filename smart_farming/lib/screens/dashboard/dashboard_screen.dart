import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  // Sensor Data
  double temperature = 28.5;
  double humidity = 65.2;
  double soilMoisture = 45;
  double lightIntensity = 75;
  String timestamp = '';

  // Historical data for chart
  List<double> soilHistory = [35, 38, 42, 45, 43, 40, 45];

  @override
  void initState() {
    super.initState();
    _initializeTimestamp();
    _simulateSensorData();
  }

  void _initializeTimestamp() {
    final now = DateTime.now();
    timestamp =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  void _simulateSensorData() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          temperature = 25 + (DateTime.now().millisecond % 100) / 10;
          humidity = 60 + (DateTime.now().millisecond % 200) / 10;
          soilMoisture = 30 + (DateTime.now().millisecond % 400) / 10;
          lightIntensity = 50 + (DateTime.now().millisecond % 500) / 10;

          // Update soil history
          soilHistory.add(soilMoisture);
          if (soilHistory.length > 7) soilHistory.removeAt(0);

          _initializeTimestamp();
        });
        _simulateSensorData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
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
                          Text("Polinema, Malang",
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13)),
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
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFE8F0EB), width: 1.4),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 7,
                                    offset: const Offset(0, 3))
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.notifications_outlined,
                                  size: 22, color: Color(0xFF2D7A3E)),
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
                                  color: Colors.red, shape: BoxShape.circle),
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
                                  builder: (_) => const ProfilePage()));
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [Color(0xFF2D7A3E), Color(0xFF4CAF50)]),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
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
                        children: const [
                          Text("SmartFarm Melon RS",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text("📍 Greenhouse Polinema - 01",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13))
                        ]),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TanamankuScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green.shade700,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      child: const Text("Lihat"),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ==================== DATA SENSOR (DINAMIS) ====================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Data Sensor Utama",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  Text(timestamp,
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.w500))
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
                      status: humidity > 70
                          ? "Tinggi"
                          : humidity > 50
                              ? "Stabil"
                              : "Rendah",
                      icon: Icons.water_drop,
                      iconColor: const Color(0xFF00B4D8)),
                  _sensorGridCard(
                      title: "Suhu",
                      value: "${temperature.toStringAsFixed(1)}°C",
                      status: temperature > 30
                          ? "Panas"
                          : temperature > 25
                              ? "Normal"
                              : "Dingin",
                      icon: Icons.thermostat,
                      iconColor: const Color(0xFFFF9500)),
                  _sensorGridCard(
                      title: "Cahaya",
                      value: "${lightIntensity.toStringAsFixed(0)} lx",
                      status: lightIntensity > 70 ? "Bagus" : "Kurang",
                      icon: Icons.wb_sunny,
                      iconColor: const Color(0xFFFFB300)),
                  _sensorGridCard(
                      title: "Kelembaban Tanah",
                      value: "${soilMoisture.toStringAsFixed(0)}%",
                      status: soilMoisture > 60
                          ? "Basah"
                          : soilMoisture > 30
                              ? "Optimal"
                              : "Kering",
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Last 7 updates',
                            style: TextStyle(
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
                      child: CustomPaint(
                        size: Size(MediaQuery.of(context).size.width - 72, 100),
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
                                builder: (_) => const TanamankuScreen()));
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
                                builder: (_) => const MenuUtamaScreen()));
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
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color, size: 28)),
      const SizedBox(height: 8),
      Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))
    ]),
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
