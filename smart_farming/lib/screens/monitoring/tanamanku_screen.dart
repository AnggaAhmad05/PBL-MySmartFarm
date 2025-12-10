import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../detail/detail_tanamanku_page.dart';

class TanamankuScreen extends StatefulWidget {
  const TanamankuScreen({super.key});

  @override
  State<TanamankuScreen> createState() => _TanamankuScreenState();
}

class _TanamankuScreenState extends State<TanamankuScreen> {
  // ==================== FIREBASE REALTIME DB ====================
  late DatabaseReference _realtimeDb;
  bool isConnected = false;
  String connectionStatus = 'Connecting...';
  
  // Data dari Realtime Database (Sensor)
  Map<String, dynamic> sensorData = {};
  Map<String, dynamic> pumpData = {};
  Map<String, dynamic> deviceData = {};
  Map<String, dynamic> settingsData = {};

  @override
  void initState() {
    super.initState();
    _initializeRealtimeDatabase();
  }

  // ==================== REALTIME DATABASE INITIALIZATION ====================
  void _initializeRealtimeDatabase() {
    try {
      _realtimeDb = FirebaseDatabase.instance.ref();
      
      print("✅ Firebase Realtime Database initialized");
      print("✅ Database URL: ${FirebaseDatabase.instance.databaseURL}");
      
      // Listen to sensor data only
      _listenToSensorData();
      _listenToPumpData();
      _listenToDeviceData();
      _listenToSettings();
      
      if (mounted) {
        setState(() {
          isConnected = true;
          connectionStatus = 'Connected';
        });
      }
    } catch (e) {
      print("❌ Realtime Database initialization error: $e");
      if (mounted) {
        setState(() {
          isConnected = false;
          connectionStatus = 'Connection Error';
        });
      }
    }
  }

  // ==================== LISTEN TO SENSOR DATA ====================
  void _listenToSensorData() {
    try {
      print("📡 Setting up sensor listener...");
      
      _realtimeDb
          .child('sensors')
          .child('device_001')
          .onValue
          .listen((DatabaseEvent event) {
        print("📡 Sensor data received");
        
        if (event.snapshot.exists) {
          try {
            Map<dynamic, dynamic> data = 
                event.snapshot.value as Map<dynamic, dynamic>;
            
            if (mounted) {
              setState(() {
                sensorData = Map<String, dynamic>.from(data);
                isConnected = true;
                connectionStatus = 'Connected';
                print("✅ Sensor data updated: $sensorData");
              });
            }
          } catch (e) {
            print("❌ Error parsing sensor data: $e");
          }
        }
      }, onError: (error) {
        print("❌ Sensor listener error: $error");
        if (mounted) {
          setState(() {
            isConnected = false;
            connectionStatus = 'Connection Error';
          });
        }
      });
    } catch (e) {
      print("❌ Error setting up sensor listener: $e");
    }
  }

  // ==================== LISTEN TO PUMP DATA ====================
  void _listenToPumpData() {
    try {
      print("📡 Setting up pump listener...");
      
      _realtimeDb
          .child('pumps')
          .child('pump_001')
          .onValue
          .listen((DatabaseEvent event) {
        print("📡 Pump data received");
        
        if (event.snapshot.exists) {
          try {
            Map<dynamic, dynamic> data = 
                event.snapshot.value as Map<dynamic, dynamic>;
            
            if (mounted) {
              setState(() {
                pumpData = Map<String, dynamic>.from(data);
                print("✅ Pump data updated");
              });
            }
          } catch (e) {
            print("❌ Error parsing pump data: $e");
          }
        }
      }, onError: (error) {
        print("❌ Pump listener error: $error");
      });
    } catch (e) {
      print("❌ Error setting up pump listener: $e");
    }
  }

  // ==================== LISTEN TO DEVICE DATA ====================
  void _listenToDeviceData() {
    try {
      print("📡 Setting up device listener...");
      
      _realtimeDb
          .child('devices')
          .child('device_001')
          .onValue
          .listen((DatabaseEvent event) {
        print("📡 Device data received");
        
        if (event.snapshot.exists) {
          try {
            Map<dynamic, dynamic> data = 
                event.snapshot.value as Map<dynamic, dynamic>;
            
            if (mounted) {
              setState(() {
                deviceData = Map<String, dynamic>.from(data);
                print("✅ Device data updated");
              });
            }
          } catch (e) {
            print("❌ Error parsing device data: $e");
          }
        }
      }, onError: (error) {
        print("❌ Device listener error: $error");
      });
    } catch (e) {
      print("❌ Error setting up device listener: $e");
    }
  }

  // ==================== LISTEN TO SETTINGS ====================
  void _listenToSettings() {
    try {
      print("📡 Setting up settings listener...");
      
      _realtimeDb
          .child('settings')
          .child('auto_mode')
          .onValue
          .listen((DatabaseEvent event) {
        print("📡 Settings data received");
        
        if (event.snapshot.exists) {
          try {
            Map<dynamic, dynamic> data = 
                event.snapshot.value as Map<dynamic, dynamic>;
            
            if (mounted) {
              setState(() {
                settingsData = Map<String, dynamic>.from(data);
                print("✅ Settings data updated");
              });
            }
          } catch (e) {
            print("❌ Error parsing settings: $e");
          }
        }
      }, onError: (error) {
        print("❌ Settings listener error: $error");
      });
    } catch (e) {
      print("❌ Error setting up settings listener: $e");
    }
  }

  // ==================== HELPER FUNCTIONS ====================
  double? _parseDouble(dynamic value) {
    try {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      if (value is num) return value.toDouble();
      return null;
    } catch (e) {
      return null;
    }
  }

  bool _isSensorHealthy() {
    final temp = _parseDouble(sensorData['temperature']) ?? 0;
    final humidity = _parseDouble(sensorData['humidity']) ?? 0;
    final soil = _parseDouble(sensorData['soilMoisture']) ?? 0;
    
    // Cek apakah dalam range ideal
    final tempMin = _parseDouble(settingsData['temperatureThreshold']) ?? 25;
    final humidityMax = _parseDouble(settingsData['humidityThreshold']) ?? 80;
    final soilMin = _parseDouble(settingsData['soilMoistureThreshold']) ?? 30;
    
    return temp >= 15 && temp <= 40 && 
           humidity >= 40 && humidity <= humidityMax && 
           soil >= soilMin;
  }

  String _getHealthStatus() {
    if (!isConnected) return 'Offline';
    if (_isSensorHealthy()) return 'Sehat';
    return 'Perhatian';
  }

  Color _getHealthColor() {
    final status = _getHealthStatus();
    if (status == 'Sehat') return Colors.green;
    if (status == 'Perhatian') return Colors.orange;
    return Colors.red;
  }

  String _getPumpSchedule() {
    final mode = pumpData['mode'] ?? 'auto';
    final duration = pumpData['duration'] ?? 0;
    
    if (mode == 'auto') {
      return "Mode Otomatis · Durasi: ${duration}s";
    } else {
      return "Mode Manual · Status: ${pumpData['status'] ?? 'OFF'}";
    }
  }

  String _getPumpStatus() {
    final status = pumpData['status'] ?? 'OFF';
    final mode = pumpData['mode'] ?? 'auto';
    
    if (status == 'ON') {
      return 'AKTIF';
    } else if (mode == 'auto') {
      return 'TERJADWAL';
    } else {
      return 'MANUAL';
    }
  }

  String _getAutoModeInfo() {
    final enabled = settingsData['enabled'] ?? false;
    final soilThreshold = _parseDouble(settingsData['soilMoistureThreshold']) ?? 30;
    final tempThreshold = _parseDouble(settingsData['temperatureThreshold']) ?? 35;
    
    if (enabled) {
      return "Aktif · Tanah: <$soilThreshold% · Suhu: <$tempThreshold°C";
    } else {
      return "Nonaktif";
    }
  }

  String _getAutoModeStatus() {
    final enabled = settingsData['enabled'] ?? false;
    return enabled ? 'AKTIF' : 'NONAKTIF';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5FAF6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xffF5FAF6),
        title: const Text(
          "Tanamanku",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: _buildConnectionIndicator(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status Banner
            if (!isConnected)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        connectionStatus,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ==========================================================
            // === VARIETAS MELON (DARI FIRESTORE) =====================
            // ==========================================================
            const Text(
              "Pilih Varietas Melon",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // StreamBuilder untuk mengambil data varietas dari Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('varietas_tanaman')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "Tidak ada varietas tersedia",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                final varietasList = snapshot.data!.docs;

                return Column(
                  children: varietasList.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown';
                    final description = data['description'] ?? '';
                    
                    // PENTING: Gunakan doc.id sebagai varietasId
                    final varietasId = doc.id;
                    
                    final idealTempMin = data['ideal_temp_min'] ?? 0;
                    final idealTempMax = data['ideal_temp_max'] ?? 0;
                    
                    // Warna berbeda untuk setiap varietas
                    final colors = [
                      Colors.yellow.shade100,
                      Colors.green.shade100,
                      Colors.orange.shade100,
                      Colors.teal.shade100,
                    ];
                    final colorIndex = varietasList.indexOf(doc) % colors.length;

                    print("🌱 Varietas: $name | ID: $varietasId");

                    return Column(
                      children: [
                        _varietasItem(
                          context,
                          name,
                          description,
                          colors[colorIndex],
                          varietasId,
                          idealTempMin,
                          idealTempMax,
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 30),

            // === GREENHOUSE CARD (DARI REALTIME DB) ===
            const Text(
              "Greenhouse Saya",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            _greenhouseCard(),

            const SizedBox(height: 25),

            // === JADWAL PERAWATAN (DARI FIRESTORE) ===
            const Text(
              "Jadwal Perawatan Hari Ini",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jadwal')
                  .where('greenhouse_id', isEqualTo: 'greenhouse123')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Column(
                    children: [
                      _scheduleTile(
                        icon: Icons.water_drop,
                        title: "Penyiraman otomatis",
                        time: _getPumpSchedule(),
                        status: _getPumpStatus(),
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 10),
                      _scheduleTile(
                        icon: Icons.energy_savings_leaf,
                        title: "Mode Otomatis",
                        time: _getAutoModeInfo(),
                        status: _getAutoModeStatus(),
                        color: Colors.green,
                      ),
                      const SizedBox(height: 10),
                      _scheduleTile(
                        icon: Icons.wb_sunny,
                        title: "Monitoring Cahaya",
                        time: "Intensitas: ${_parseDouble(sensorData['lightIntensity'])?.toStringAsFixed(0) ?? '0'}%",
                        status: "AKTIF",
                        color: Colors.orange,
                      ),
                    ],
                  );
                }

                // Tampilkan jadwal dari Firestore
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final type = data['type'] ?? 'unknown';
                    final waktu = data['waktu'] ?? '00:00';
                    final duration = data['duration'] ?? 0;
                    final hari = data['hari'] ?? '';

                    IconData icon = Icons.schedule;
                    Color color = Colors.blue;
                    String title = type;

                    if (type == 'penyiraman' || type == 'irigrasi') {
                      icon = Icons.water_drop;
                      color = Colors.blue;
                      title = 'Penyiraman otomatis';
                    } else if (type == 'nutrisi') {
                      icon = Icons.energy_savings_leaf;
                      color = Colors.green;
                      title = 'Pemberian nutrisi';
                    }

                    return Column(
                      children: [
                        _scheduleTile(
                          icon: icon,
                          title: title,
                          time: "$waktu · Durasi $duration menit · Hari: $hari",
                          status: "TERJADWAL",
                          color: color,
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 10),

            _scheduleTile(
              icon: Icons.wb_sunny,
              title: "Cek intensitas cahaya",
              time: "18:30 · Penyesuaian lampu tumbuh",
              status: "PENDING",
              color: Colors.grey,
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ==================== CONNECTION INDICATOR ====================
  Widget _buildConnectionIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? Colors.green : Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isConnected ? Colors.green : Colors.red).withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? 'Connected' : 'Offline',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isConnected ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== VARIETAS ITEM ====================
  Widget _varietasItem(
    BuildContext context,
    String title,
    String subtitle,
    Color bg,
    String varietasId,
    dynamic idealTempMin,
    dynamic idealTempMax,
  ) {
    return InkWell(
      onTap: () {
        print("🔍 Navigating to detail with varietasId: $varietasId");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailTanamankuPage(
              varietasId: varietasId,
              tanamanId: "tanaman1",
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.green.shade200, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.eco, size: 30, color: Colors.green),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.thermostat,
                          size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        "Suhu ideal: $idealTempMin°C - $idealTempMax°C",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  // ==================== GREENHOUSE CARD ====================
  Widget _greenhouseCard() {
    final temperature = _parseDouble(sensorData['temperature']) ?? 24;
    final humidity = _parseDouble(sensorData['humidity']) ?? 40;
    final soilMoisture = _parseDouble(sensorData['soilMoisture']) ?? 100;
    final location = deviceData['location'] ?? 'Greenhouse A';
    final name = deviceData['name'] ?? 'Node Sensor Utama';
    final status = _getHealthStatus();
    final statusColor = _getHealthColor();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.home, color: Colors.green.shade700, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      location,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                "Auto-watering: ${pumpData['mode'] == 'auto' ? 'ON' : 'OFF'}",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoChip("Kelembaban", "${humidity.toStringAsFixed(0)}%",
                  Colors.green.shade100),
              _infoChip("Suhu", "${temperature.toStringAsFixed(1)}°C",
                  Colors.orange.shade100),
              _infoChip("Tanah", "${soilMoisture.toStringAsFixed(0)}%",
                  Colors.blue.shade100),
            ],
          )
        ],
      ),
    );
  }

  // ==================== INFO CHIP ====================
  Widget _infoChip(String label, String value, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ==================== SCHEDULE TILE ====================
  Widget _scheduleTile({
    required IconData icon,
    required String title,
    required String time,
    required String status,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
