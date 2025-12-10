import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  // ==================== FIREBASE ====================
  late DatabaseReference _database;
  bool isConnected = false;
  String connectionStatus = 'Connecting...';
  
  // Filter & Data
  String selectedFilter = 'Semua'; // Semua, Hari Ini, Minggu Ini, Bulan Ini
  int selectedMonth = DateTime.now().month;
  List<MapEntry<String, Map<String, dynamic>>> notifications = [];
  List<MapEntry<String, Map<String, dynamic>>> filteredNotifications = [];
  
  // Notification Preferences
  Map<String, dynamic> notificationPreferences = {};
  
  // Loading state
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  // ==================== FIREBASE INITIALIZATION ====================
  void _initializeFirebase() {
    try {
      _database = FirebaseDatabase.instance.ref();
      
      print("✅ Firebase Database initialized");
      print("✅ Database URL: ${FirebaseDatabase.instance.databaseURL}");
      
      // Listen to notification preferences
      _listenToNotificationPreferences();
      
      // Listen to notifications from history
      _listenToNotificationsFromHistory();
      
      if (mounted) {
        setState(() {
          isConnected = true;
          connectionStatus = 'Connected';
          errorMessage = '';
        });
      }
    } catch (e) {
      print("❌ Firebase initialization error: $e");
      if (mounted) {
        setState(() {
          isConnected = false;
          connectionStatus = 'Connection Error';
          errorMessage = e.toString();
        });
      }
    }
  }

  // ==================== LISTEN TO NOTIFICATION PREFERENCES ====================
  void _listenToNotificationPreferences() {
    try {
      print("📡 Setting up notification preferences listener...");
      
      _database
          .child('settings')
          .child('notification_preferences')
          .onValue
          .listen((DatabaseEvent event) {
        print("📡 Notification preferences received");
        
        if (event.snapshot.exists) {
          try {
            Map<dynamic, dynamic> data = 
                event.snapshot.value as Map<dynamic, dynamic>;
            
            if (mounted) {
              setState(() {
                notificationPreferences = Map<String, dynamic>.from(data);
                isConnected = true;
                connectionStatus = 'Connected';
                errorMessage = '';
                
                print("✅ Notification preferences loaded");
                print("   Battery Low Alert: ${notificationPreferences['battery_low']}");
                print("   Device Offline Alert: ${notificationPreferences['device_offline']}");
                print("   Pump Activation Alert: ${notificationPreferences['pump_activation']}");
              });
            }
          } catch (e) {
            print("❌ Error parsing preferences: $e");
            if (mounted) {
              setState(() {
                errorMessage = "Error parsing preferences: $e";
              });
            }
          }
        }
      }, onError: (error) {
        print("❌ Preferences listener error: $error");
        if (mounted) {
          setState(() {
            isConnected = false;
            connectionStatus = 'Connection Error';
            errorMessage = error.toString();
          });
        }
      });
    } catch (e) {
      print("❌ Error setting up preferences listener: $e");
      if (mounted) {
        setState(() {
          errorMessage = "Setup error: $e";
        });
      }
    }
  }

  // ==================== LISTEN TO NOTIFICATIONS FROM HISTORY ====================
  void _listenToNotificationsFromHistory() {
    try {
      print("📡 Setting up notifications listener from history...");
      
      _database
          .child('history')
          .child('sensor_history')
          .onValue
          .listen((DatabaseEvent event) {
        print("📡 History data received");
        
        if (event.snapshot.exists) {
          try {
            Map<dynamic, dynamic> data = 
                event.snapshot.value as Map<dynamic, dynamic>;
            
            List<MapEntry<String, Map<String, dynamic>>> allNotifications = [];
            
            // Convert history to notifications
            data.forEach((key, value) {
              if (value is Map) {
                Map<String, dynamic> historyData = 
                    Map<String, dynamic>.from(value);
                
                // Buat notifikasi dari data history
                Map<String, dynamic> notification = {
                  'type': _getNotificationType(historyData),
                  'title': _getNotificationTitle(historyData),
                  'message': _getNotificationMessage(historyData),
                  'isRead': false,
                  'createAt': historyData['timestamp'] ?? DateTime.now().toString(),
                  'greenhouse_id': historyData['greenhouseId'] ?? 'Unknown',
                  'deviceId': historyData['deviceId'] ?? 'Unknown',
                  'data': historyData,
                };
                
                allNotifications.add(
                  MapEntry(key, notification),
                );
              }
            });
            
            // Sort by timestamp (newest first)
            allNotifications.sort((a, b) {
              DateTime dateA = _parseTimestamp(a.value['createAt']);
              DateTime dateB = _parseTimestamp(b.value['createAt']);
              return dateB.compareTo(dateA);
            });
            
            if (mounted) {
              setState(() {
                notifications = allNotifications;
                isConnected = true;
                connectionStatus = 'Connected';
                errorMessage = '';
                _applyFilter();
              });
            }
            
            print("✅ Notifications loaded from history: ${allNotifications.length} items");
          } catch (e) {
            print("❌ Error parsing history: $e");
            if (mounted) {
              setState(() {
                errorMessage = "Error parsing history: $e";
              });
            }
          }
        } else {
          print("⚠️ No history data available");
          if (mounted) {
            setState(() {
              notifications = [];
              filteredNotifications = [];
              errorMessage = "No history data available";
            });
          }
        }
      }, onError: (error) {
        print("❌ History listener error: $error");
        if (mounted) {
          setState(() {
            isConnected = false;
            connectionStatus = 'Connection Error';
            errorMessage = error.toString();
          });
        }
      });
    } catch (e) {
      print("❌ Error setting up history listener: $e");
      if (mounted) {
        setState(() {
          errorMessage = "Setup error: $e";
        });
      }
    }
  }

  // ==================== GET NOTIFICATION TYPE ====================
  String _getNotificationType(Map<String, dynamic> historyData) {
    final soilMoisture = _parseDouble(historyData['soilMoisture']) ?? 0;
    final temperature = _parseDouble(historyData['temperature']) ?? 0;
    final humidity = _parseDouble(historyData['humidity']) ?? 0;
    final pumpStatus = historyData['pumpStatus'] ?? false;
    
    // Determine notification type based on data
    if (soilMoisture < 30) {
      return 'alert'; // Tanah kering
    } else if (temperature > 35) {
      return 'warning'; // Suhu tinggi
    } else if (humidity > 80) {
      return 'warning'; // Kelembaban tinggi
    } else if (pumpStatus == true) {
      return 'success'; // Pompa aktif
    } else {
      return 'info'; // Info normal
    }
  }

  // ==================== GET NOTIFICATION TITLE ====================
  String _getNotificationTitle(Map<String, dynamic> historyData) {
    final soilMoisture = _parseDouble(historyData['soilMoisture']) ?? 0;
    final temperature = _parseDouble(historyData['temperature']) ?? 0;
    final humidity = _parseDouble(historyData['humidity']) ?? 0;
    final pumpStatus = historyData['pumpStatus'] ?? false;
    
    if (soilMoisture < 30) {
      return '🚨 Tanah Kering';
    } else if (temperature > 35) {
      return '🌡️ Suhu Tinggi';
    } else if (humidity > 80) {
      return '💧 Kelembaban Tinggi';
    } else if (pumpStatus == true) {
      return '💧 Pompa Aktif';
    } else {
      return '📊 Update Sensor';
    }
  }

  // ==================== GET NOTIFICATION MESSAGE ====================
  String _getNotificationMessage(Map<String, dynamic> historyData) {
    final soilMoisture = _parseDouble(historyData['soilMoisture']) ?? 0;
    final temperature = _parseDouble(historyData['temperature']) ?? 0;
    final humidity = _parseDouble(historyData['humidity']) ?? 0;
    final pumpStatus = historyData['pumpStatus'] ?? false;
    
    if (soilMoisture < 30) {
      return 'Kelembaban tanah ${soilMoisture.toStringAsFixed(0)}% - Segera siram tanaman!';
    } else if (temperature > 35) {
      return 'Suhu mencapai ${temperature.toStringAsFixed(1)}°C - Perhatian diperlukan';
    } else if (humidity > 80) {
      return 'Kelembaban udara ${humidity.toStringAsFixed(1)}% - Tingkat tinggi';
    } else if (pumpStatus == true) {
      return 'Pompa telah dinyalakan - Tanah: ${soilMoisture.toStringAsFixed(0)}%';
    } else {
      return 'Suhu: ${temperature.toStringAsFixed(1)}°C, Kelembaban: ${humidity.toStringAsFixed(1)}%, Tanah: ${soilMoisture.toStringAsFixed(0)}%';
    }
  }

  // ==================== PARSE TIMESTAMP ====================
  DateTime _parseTimestamp(dynamic timestamp) {
    try {
      if (timestamp == null) return DateTime.now();
      
      if (timestamp is String) {
        // Format: "2025-12-07 13:47:23"
        try {
          return DateFormat('yyyy-MM-dd HH:mm:ss').parse(timestamp);
        } catch (e) {
          return DateTime.now();
        }
      }
      
      if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      
      if (timestamp is double) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
      }
      
      return DateTime.now();
    } catch (e) {
      print("❌ Error parsing timestamp: $e");
      return DateTime.now();
    }
  }

  // ==================== PARSE DOUBLE ====================
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

  // ==================== APPLY FILTER ====================
  void _applyFilter() {
    final now = DateTime.now();
    
    filteredNotifications = notifications.where((entry) {
      final notif = entry.value;
      final timestamp = _parseTimestamp(notif['createAt']);
      
      if (selectedFilter == 'Semua') {
        return true;
      } else if (selectedFilter == 'Hari Ini') {
        return timestamp.day == now.day &&
            timestamp.month == now.month &&
            timestamp.year == now.year;
      } else if (selectedFilter == 'Minggu Ini') {
        return now.difference(timestamp).inDays < 7;
      } else if (selectedFilter == 'Bulan Ini') {
        return timestamp.month == selectedMonth && 
            timestamp.year == now.year;
      }
      return true;
    }).toList();
    
    print("✅ Filter applied: ${filteredNotifications.length} notifications");
  }

  // ==================== UPDATE NOTIFICATION PREFERENCE ====================
  Future<void> _updateNotificationPreference(
    String key,
    dynamic value,
  ) async {
    try {
      print("🔄 Updating notification preference: $key = $value");
      
      await _database
          .child('settings')
          .child('notification_preferences')
          .update({key: value});
      
      print("✅ Preference updated");
      _showSuccessSnackbar("Preferensi notifikasi diperbarui");
    } catch (e) {
      print("❌ Error updating preference: $e");
      _showErrorSnackbar("Gagal memperbarui preferensi");
    }
  }

  // ==================== DELETE NOTIFICATION ====================
  Future<void> _deleteNotification(String docId) async {
    try {
      print("🔄 Deleting notification: $docId");
      
      await _database
          .child('history')
          .child('sensor_history')
          .child(docId)
          .remove();
      
      print("✅ Notification deleted");
      _showSuccessSnackbar("Notifikasi dihapus");
    } catch (e) {
      print("❌ Error deleting notification: $e");
      _showErrorSnackbar("Gagal menghapus notifikasi");
    }
  }

  // ==================== HELPER FUNCTIONS ====================
  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes} menit lalu";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} jam lalu";
    } else if (diff.inDays < 7) {
      return "${diff.inDays} hari lalu";
    } else {
      return DateFormat('dd MMM yyyy').format(timestamp);
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'success':
        return Icons.check_circle;
      case 'alert':
        return Icons.error_rounded;
      case 'info':
      default:
        return Icons.info;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'alert':
        return Colors.red;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F3),
      appBar: AppBar(
        title: const Text("Riwayat Notifikasi",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showNotificationSettings,
            tooltip: "Pengaturan Notifikasi",
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status
          if (!isConnected)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.red.withOpacity(0.1),
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

          // Error Banner
          if (errorMessage.isNotEmpty && isConnected)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded, 
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Semua'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Hari Ini'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Minggu Ini'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Bulan Ini'),
                  const SizedBox(width: 8),
                  _buildMonthPicker(),
                ],
              ),
            ),
          ),

          // Notification List
          Expanded(
            child: filteredNotifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off,
                            size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          "Tidak ada notifikasi",
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final entry = filteredNotifications[index];
                      return _buildNotificationCard(entry.key, entry.value);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD FILTER CHIP ====================
  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
          _applyFilter();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey.shade200,
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

  // ==================== BUILD MONTH PICKER ====================
  Widget _buildMonthPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButton<int>(
        value: selectedMonth,
        underline: const SizedBox(),
        items: List.generate(12, (index) => index + 1).map((month) {
          return DropdownMenuItem<int>(
            value: month,
            child: Text(DateFormat('MMM').format(DateTime(2000, month))),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              selectedMonth = value;
              _applyFilter();
            });
          }
        },
      ),
    );
  }

  // ==================== BUILD NOTIFICATION CARD ====================
  Widget _buildNotificationCard(
    String docId,
    Map<String, dynamic> notif,
  ) {
    final type = notif['type'] ?? 'info';
    final icon = _getIconForType(type);
    final color = _getColorForType(type);
    final title = notif['title'] ?? 'Notifikasi';
    final message = notif['message'] ?? '';
    final timestamp = _parseTimestamp(notif['createAt']);

    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        _deleteNotification(docId);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
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

  // ==================== SHOW NOTIFICATION SETTINGS ====================
  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pengaturan Notifikasi"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPreferenceSwitch(
                'Baterai Rendah',
                'battery_low',
                notificationPreferences['battery_low'] ?? true,
              ),
              _buildPreferenceSwitch(
                'Device Offline',
                'device_offline',
                notificationPreferences['device_offline'] ?? true,
              ),
              _buildPreferenceSwitch(
                'Kelembaban Alert',
                'humidity_alert',
                notificationPreferences['humidity_alert'] ?? true,
              ),
              _buildPreferenceSwitch(
                'Tanah Kering Alert',
                'soil_dry_alert',
                notificationPreferences['soil_dry_alert'] ?? true,
              ),
              _buildPreferenceSwitch(
                'Suhu Alert',
                'temperature_alert',
                notificationPreferences['temperature_alert'] ?? true,
              ),
              _buildPreferenceSwitch(
                'Aktivasi Pompa',
                'pump_activation',
                notificationPreferences['pump_activation'] ?? true,
              ),
              _buildPreferenceSwitch(
                'Kontrol Manual',
                'manual_control',
                notificationPreferences['manual_control'] ?? true,
              ),
              _buildPreferenceSwitch(
                'Laporan Harian',
                'daily_report',
                notificationPreferences['daily_report'] ?? true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD PREFERENCE SWITCH ====================
  Widget _buildPreferenceSwitch(
    String label,
    String key,
    bool value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Switch(
            value: value,
            onChanged: (newValue) {
              _updateNotificationPreference(key, newValue);
              setState(() {
                notificationPreferences[key] = newValue;
              });
            },
          ),
        ],
      ),
    );
  }
}
