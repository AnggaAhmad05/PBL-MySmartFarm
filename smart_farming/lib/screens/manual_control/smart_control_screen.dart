import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math' as math;

class SmartControlScreen extends StatefulWidget {
  const SmartControlScreen({super.key});

  @override
  State<SmartControlScreen> createState() => _SmartControlScreenState();
}

class _SmartControlScreenState extends State<SmartControlScreen>
    with TickerProviderStateMixin {
  
  // ==================== FIREBASE ====================
  late DatabaseReference _database;
  bool isConnected = false;
  String connectionStatus = 'Connecting...';
  String selectedDeviceId = 'device_001';
  
  // Control Mode
  String controlMode = 'auto';
  bool pumpManual = false;
  
  // Thresholds
  double thresholdLow = 30;
  double thresholdHigh = 60;
  double maxDuration = 300;
  
  // Sensor Data (Real-time dari Firebase)
  double temperature = 0;
  double humidity = 0;
  double soilMoisture = 0;
  double lightIntensity = 0;
  String lastUpdate = '';
  
  // Historical data for chart
  List<double> soilHistory = [];
  
  // Animation Controllers
  AnimationController? _animationController;
  Animation<double>? _pulseAnimation;
  
  // Tab Controller
  TabController? _tabController;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize Tab Controller
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize Animation Controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Initialize pulse animation
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start animation
    _animationController!.repeat(reverse: true);
    
    // ✅ Initialize Firebase
    _initializeFirebase();
  }
  
  // ==================== FIREBASE INITIALIZATION ====================
  void _initializeFirebase() {
    try {
      _database = FirebaseDatabase.instance.ref();
      
      print("✅ Firebase Database initialized");
      print("✅ Database URL: ${FirebaseDatabase.instance.databaseURL}");
      
      // Listen to sensor data
      _listenToSensorData();
      
      // Listen to control settings
      _listenToControlSettings();
      
      // Listen to historical data
      _loadHistoricalData();
      
      if (mounted) {
        setState(() {
          isConnected = true;
          connectionStatus = 'Connected';
        });
      }
    } catch (e) {
      print("❌ Firebase initialization error: $e");
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
      _database
          .child('sensors')
          .child(selectedDeviceId)
          .onValue
          .listen((DatabaseEvent event) {
        print("📡 Sensor data received");
        
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
                lastUpdate = data['timestamp']?.toString() ?? DateTime.now().toString();
                
                // Update soil history
                if (soilMoisture > 0) {
                  soilHistory.add(soilMoisture);
                  if (soilHistory.length > 7) {
                    soilHistory.removeAt(0);
                  }
                }
                
                isConnected = true;
                connectionStatus = 'Connected';
                
                print("✅ Sensor data updated: T=$temperature, H=$humidity, S=$soilMoisture");
              });
            }
          } catch (e) {
            print("❌ Error parsing sensor data: $e");
          }
        } else {
          print("⚠️ No sensor data available");
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
  
  // ==================== LISTEN TO CONTROL SETTINGS ====================
  void _listenToControlSettings() {
    try {
      _database
          .child('control')
          .child(selectedDeviceId)
          .onValue
          .listen((DatabaseEvent event) {
        print("📡 Control settings received");
        
        if (event.snapshot.exists) {
          try {
            Map<dynamic, dynamic> data = 
                event.snapshot.value as Map<dynamic, dynamic>;
            
            if (mounted) {
              setState(() {
                controlMode = data['mode']?.toString() ?? 'auto';
                pumpManual = data['pumpStatus'] == 'ON' || data['pumpStatus'] == true;
                thresholdLow = _parseDouble(data['thresholdLow']) ?? 30;
                thresholdHigh = _parseDouble(data['thresholdHigh']) ?? 60;
                maxDuration = _parseDouble(data['maxDuration']) ?? 300;
                
                print("✅ Control settings updated");
              });
            }
          } catch (e) {
            print("❌ Error parsing control settings: $e");
          }
        }
      }, onError: (error) {
        print("❌ Control settings listener error: $error");
      });
    } catch (e) {
      print("❌ Error setting up control listener: $e");
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
            
            if (item['deviceId'] == selectedDeviceId) {
              double? soil = _parseDouble(item['soilMoisture']);
              if (soil != null && soil > 0) {
                tempHistory.add(soil);
              }
            }
          }
        });
        
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
  
  // ==================== UPDATE CONTROL MODE ====================
  Future<void> _updateControlMode(String mode) async {
    try {
      await _database
          .child('control')
          .child(selectedDeviceId)
          .update({'mode': mode});
      
      print("✅ Control mode updated to: $mode");
      
      if (mounted) {
        setState(() => controlMode = mode);
      }
    } catch (e) {
      print("❌ Error updating control mode: $e");
      _showErrorSnackbar("Failed to update control mode");
    }
  }
  
  // ==================== UPDATE PUMP STATUS ====================
  Future<void> _updatePumpStatus(bool status) async {
    try {
      await _database
          .child('control')
          .child(selectedDeviceId)
          .update({'pumpStatus': status ? 'ON' : 'OFF'});
      
      print("✅ Pump status updated to: ${status ? 'ON' : 'OFF'}");
      
      if (mounted) {
        setState(() => pumpManual = status);
      }
    } catch (e) {
      print("❌ Error updating pump status: $e");
      _showErrorSnackbar("Failed to update pump status");
    }
  }
  
  // ==================== UPDATE THRESHOLDS ====================
  Future<void> _updateThresholds() async {
    try {
      await _database
          .child('control')
          .child(selectedDeviceId)
          .update({
            'thresholdLow': thresholdLow,
            'thresholdHigh': thresholdHigh,
            'maxDuration': maxDuration,
          });
      
      print("✅ Thresholds updated");
      _showSuccessSnackbar("✅ Threshold saved!");
    } catch (e) {
      print("❌ Error updating thresholds: $e");
      _showErrorSnackbar("Failed to save threshold");
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
  
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _tabController?.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF4CAF50).withOpacity(0.1),
              const Color(0xFF2196F3).withOpacity(0.1),
              const Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildModernAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildConnectionStatus(),
                      const SizedBox(height: 16),
                      _buildSensorGrid(),
                      const SizedBox(height: 16),
                      _buildMiniChart(),
                      const SizedBox(height: 16),
                      _buildTabSection(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== MODERN APP BAR ====================
  Widget _buildModernAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF45a049),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🌱 Smart Farm Control',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'ESP32_001 • Online',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          _pulseAnimation != null
              ? AnimatedBuilder(
                  animation: _pulseAnimation!,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation!.value,
                      child: child,
                    );
                  },
                  child: _buildModeBadge(),
                )
              : _buildModeBadge(),
        ],
      ),
    );
  }

  Widget _buildModeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Text(
            controlMode == 'auto' ? '🤖' : '🎮',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            controlMode == 'auto' ? 'AUTO' : 'MANUAL',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SENSOR GRID ====================
  Widget _buildSensorGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildGlassSensorCard(
                  icon: Icons.thermostat_rounded,
                  label: 'Temperature',
                  value: '${temperature.toStringAsFixed(1)}°C',
                  color: const Color(0xFFFF5252),
                  gradient: [const Color(0xFFFF5252), const Color(0xFFFF1744)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGlassSensorCard(
                  icon: Icons.water_drop_rounded,
                  label: 'Humidity',
                  value: '${humidity.toStringAsFixed(1)}%',
                  color: const Color(0xFF2196F3),
                  gradient: [const Color(0xFF2196F3), const Color(0xFF1976D2)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGlassSensorCard(
                  icon: Icons.grass_rounded,
                  label: 'Soil Moisture',
                  value: '${soilMoisture.toStringAsFixed(0)}%',
                  color: const Color(0xFF4CAF50),
                  gradient: [const Color(0xFF4CAF50), const Color(0xFF388E3C)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGlassSensorCard(
                  icon: Icons.wb_sunny_rounded,
                  label: 'Light',
                  value: '${lightIntensity.toStringAsFixed(0)}%',
                  color: const Color(0xFFFF9800),
                  gradient: [const Color(0xFFFF9800), const Color(0xFFF57C00)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassSensorCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient.map((c) => c.withOpacity(0.1)).toList(),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MINI CHART ====================
  Widget _buildMiniChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
                        "Waiting for data...",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    )
                  : CustomPaint(
                      size: Size(
                          MediaQuery.of(context).size.width - 72, 100),
                      painter: LineChartPainter(soilHistory),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB SECTION ====================
  Widget _buildTabSection() {
    if (_tabController == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(8),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.power_settings_new_rounded),
                    text: 'Pump',
                  ),
                  Tab(
                    icon: Icon(Icons.tune_rounded),
                    text: 'Threshold',
                  ),
                  Tab(
                    icon: Icon(Icons.settings_rounded),
                    text: 'Settings',
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 400,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPumpTab(),
                  _buildThresholdTab(),
                  _buildSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PUMP TAB ====================
  Widget _buildPumpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Control Mode',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildNeumorphicButton(
                  label: '🤖 Auto',
                  isSelected: controlMode == 'auto',
                  onTap: () => _updateControlMode('auto'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNeumorphicButton(
                  label: '🎮 Manual',
                  isSelected: controlMode == 'manual',
                  onTap: () => _updateControlMode('manual'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (controlMode == 'manual') ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2196F3).withOpacity(0.1),
                    const Color(0xFF1976D2).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manual Control',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Control pump directly',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Transform.scale(
                        scale: 1.2,
                        child: Switch(
                          value: pumpManual,
                          activeColor: const Color(0xFF4CAF50),
                          onChanged: (value) => _updatePumpStatus(value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: pumpManual
                            ? [const Color(0xFF4CAF50), const Color(0xFF45a049)]
                            : [Colors.grey[300]!, Colors.grey[400]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: pumpManual
                          ? [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.water_drop_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          pumpManual ? '💧 PUMP ON' : '⭕ PUMP OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (controlMode == 'auto') ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4CAF50).withOpacity(0.1),
                    const Color(0xFF388E3C).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.smart_toy_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Automatic Mode Active',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Turn ON when', '< ${thresholdLow.toInt()}%'),
                        const Divider(height: 20),
                        _buildInfoRow('Turn OFF when', '> ${thresholdHigh.toInt()}%'),
                        const Divider(height: 20),
                        _buildInfoRow('Current Soil', '${soilMoisture.toStringAsFixed(0)}%'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  // ==================== THRESHOLD TAB ====================
  Widget _buildThresholdTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSliderSection(
            label: 'Low Threshold',
            emoji: '🔴',
            value: thresholdLow,
            min: 10,
            max: 50,
            color: const Color(0xFFFF5252),
            onChanged: (value) => setState(() => thresholdLow = value),
          ),
          const SizedBox(height: 24),
          _buildSliderSection(
            label: 'High Threshold',
            emoji: '🟢',
            value: thresholdHigh,
            min: 50,
            max: 90,
            color: const Color(0xFF4CAF50),
            onChanged: (value) => setState(() => thresholdHigh = value),
          ),
          const SizedBox(height: 24),
          _buildThresholdVisualizer(),
          const SizedBox(height: 24),
          _buildGradientButton(
            label: '💾 Save Threshold',
            onPressed: _updateThresholds,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSection({
    required String label,
    required String emoji,
    required double value,
    required double min,
    required double max,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  '${value.toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.2),
              thumbColor: color,
              overlayColor: color.withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 12,
              ),
              trackHeight: 6,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) / 5).toInt(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdVisualizer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF5252).withOpacity(0.1),
            const Color(0xFFFFEB3B).withOpacity(0.1),
            const Color(0xFF4CAF50).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dry', style: TextStyle(fontSize: 11, color: Colors.red[700])),
              Text('Watering', style: TextStyle(fontSize: 11, color: Colors.orange[700])),
              Text('Wet', style: TextStyle(fontSize: 11, color: Colors.green[700])),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF5252),
                      Color(0xFFFFEB3B),
                      Color(0xFF4CAF50),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: (MediaQuery.of(context).size.width - 64) *
                    (soilMoisture / 100),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${soilMoisture.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Container(
                      width: 3,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SETTINGS TAB ====================
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSliderSection(
            label: 'Max Duration',
            emoji: '⏱️',
            value: maxDuration,
            min: 60,
            max: 600,
            color: const Color(0xFF2196F3),
            onChanged: (value) => setState(() => maxDuration = value),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange[300]!,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${(maxDuration / 60).floor()}m ${(maxDuration % 60).toInt()}s',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.yellow[100]!,
                  Colors.yellow[50]!,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.yellow[700]!,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    const Text(
                      'Safety Features',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSafetyItem('Auto-stop after max duration'),
                _buildSafetyItem('Sensor error detection'),
                _buildSafetyItem('Hysteresis protection'),
                _buildSafetyItem('Temperature monitoring'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildGradientButton(
            label: '💾 Save Settings',
            onPressed: _updateThresholds,
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.yellow[700],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ==================== CONNECTION STATUS ====================
  Widget _buildConnectionStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isConnected
                ? [
                    const Color(0xFF4CAF50).withOpacity(0.1),
                    const Color(0xFF45a049).withOpacity(0.05),
                  ]
                : [
                    Colors.red.withOpacity(0.1),
                    Colors.red.withOpacity(0.05),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isConnected
                ? const Color(0xFF4CAF50).withOpacity(0.3)
                : Colors.red.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            _pulseAnimation != null
                ? AnimatedBuilder(
                    animation: _pulseAnimation!,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: isConnected ? _pulseAnimation!.value : 1.0,
                        child: child,
                      );
                    },
                    child: _buildStatusIndicator(),
                  )
                : _buildStatusIndicator(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? '✅ Connected to Firebase' : '❌ Disconnected',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isConnected ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                  Text(
                    'Last update: $lastUpdate',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isConnected ? const Color(0xFF4CAF50) : Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isConnected ? Icons.cloud_done : Icons.cloud_off,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isConnected ? const Color(0xFF4CAF50) : Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isConnected
                ? const Color(0xFF4CAF50).withOpacity(0.5)
                : Colors.red.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================
  Widget _buildNeumorphicButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
                )
              : LinearGradient(
                  colors: [Colors.grey[200]!, Colors.grey[300]!],
                ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
