// lib/screens/device_management_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  // Firebase Database Reference
  final DatabaseReference _devicesRef = FirebaseDatabase.instance.ref('devices');
  final DatabaseReference _pendingRef = FirebaseDatabase.instance.ref('device_management/pending_devices');
  final DatabaseReference _registeredRef = FirebaseDatabase.instance.ref('device_management/registered_devices');
  
  // Untuk form input
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _macController = TextEditingController();
  String _selectedType = 'sensor_node';
  String _selectedLocation = 'Greenhouse A';
  String _selectedGreenhouse = 'greenhouse_001';

  // Dummy data fallback (jika Firebase belum terisi)
  List<Map<String, dynamic>> get _fallbackDevices => [
    {
      'id': 'NODE_001',
      'name': 'Sensor Utama Hidroponik',
      'type': 'Sensor Node',
      'status': 'Aktif',
      'lastUpdate': '2 menit lalu',
      'icon': Icons.sensors,
    },
    {
      'id': 'NODE_002',
      'name': 'Pompa Air Otomatis',
      'type': 'Actuator',
      'status': 'Standby',
      'lastUpdate': '5 menit lalu',
      'icon': Icons.water_damage,
    },
    {
      'id': 'NODE_003',
      'name': 'Lampu Tumbuh LED',
      'type': 'Actuator',
      'status': 'Mati',
      'lastUpdate': '1 jam lalu',
      'icon': Icons.lightbulb,
    },
  ];

  // Map icon berdasarkan type
  IconData _getIconByType(String type) {
    switch (type.toLowerCase()) {
      case 'sensor_node':
        return Icons.sensors;
      case 'actuator':
        return Icons.settings_input_component;
      case 'pump':
        return Icons.water_damage;
      case 'light':
        return Icons.lightbulb;
      case 'controller':
        return Icons.memory;
      default:
        return Icons.devices;
    }
  }

  // Format status
  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Aktif';
      case 'standby':
        return 'Standby';
      case 'offline':
        return 'Mati';
      case 'pending':
        return 'Menunggu';
      default:
        return status;
    }
  }

  // Format type
  String _formatType(String type) {
    switch (type.toLowerCase()) {
      case 'sensor_node':
        return 'Sensor Node';
      case 'actuator':
        return 'Actuator';
      case 'controller':
        return 'Controller';
      default:
        return type;
    }
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'standby':
        return Colors.orange;
      case 'offline':
        return Colors.grey;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F3),
      appBar: AppBar(
        title: const Text("Manajemen Perangkat", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Kelola perangkat IoT yang terhubung ke sistem smart farming Anda",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // List Devices dari Firebase
            StreamBuilder<DatabaseEvent>(
              stream: _devicesRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  // Jika Firebase kosong, gunakan fallback data
                  return _buildDeviceList(_fallbackDevices);
                }

                final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                final devices = <Map<String, dynamic>>[];

                data.forEach((key, value) {
                  if (value is Map) {
                    final device = Map<String, dynamic>.from(value);
                    device['id'] = key;
                    devices.add(device);
                  }
                });

                return _buildDeviceList(devices);
              },
            ),

            const SizedBox(height: 20),

            // Tombol Tambah Perangkat
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showAddDeviceDialog,
                icon: const Icon(Icons.add),
                label: const Text("Tambah Perangkat Baru"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList(List<Map<String, dynamic>> devices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Perangkat Terdaftar (${devices.length})",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // List Devices
        ...devices.map((device) => _buildDeviceCard(device)).toList(),
      ],
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> device) {
    final status = device['status']?.toString() ?? 'offline';
    final formattedStatus = _formatStatus(status);
    final statusColor = _getStatusColor(status);
    final type = device['type']?.toString() ?? 'unknown';
    final formattedType = _formatType(type);
    final icon = _getIconByType(type);
    final name = device['name']?.toString() ?? 'Unknown Device';
    final deviceId = device['id']?.toString() ?? 'N/A';
    final macAddress = device['macAddress']?.toString() ?? 'N/A';
    
    // Last seen calculation
    String lastUpdate = 'Tidak diketahui';
    if (device['lastSeen'] != null) {
      final lastSeen = int.tryParse(device['lastSeen'].toString()) ?? 0;
      if (lastSeen < 60) {
        lastUpdate = '$lastSeen detik lalu';
      } else if (lastSeen < 3600) {
        lastUpdate = '${lastSeen ~/ 60} menit lalu';
      } else {
        lastUpdate = '${lastSeen ~/ 3600} jam lalu';
      }
    } else if (device['heartbeat'] != null && device['heartbeat'] is Map) {
      final heartbeat = device['heartbeat'] as Map;
      if (heartbeat['timestamp'] != null) {
        lastUpdate = 'Baru saja';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: statusColor, size: 28),
              ),

              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          formattedType,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Text("•", style: TextStyle(color: Colors.grey.shade400)),
                        const SizedBox(width: 8),
                        Text(
                          deviceId,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  formattedStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 20),

          // Last Update & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 5),
                  Text(
                    "Update: $lastUpdate",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),

              Row(
                children: [
                  IconButton(
                    onPressed: () => _showDeviceDetails(device),
                    icon: const Icon(Icons.info_outline),
                    color: Colors.blue,
                    iconSize: 22,
                  ),
                  IconButton(
                    onPressed: () => _confirmDelete(device),
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    iconSize: 22,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddDeviceDialog() {
    // Reset controllers
    _nameController.clear();
    _idController.clear();
    _macController.clear();
    _selectedType = 'sensor_node';
    _selectedLocation = 'Greenhouse A';
    _selectedGreenhouse = 'greenhouse_001';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Perangkat Baru"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nama Perangkat",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: "ID Perangkat (contoh: device_002)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _macController,
                decoration: const InputDecoration(
                  labelText: "MAC Address",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: "Tipe Perangkat",
                  border: OutlineInputBorder(),
                ),
                items: [
                  'sensor_node',
                  'actuator',
                  'pump',
                  'light',
                  'controller'
                ].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_formatType(type)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: const InputDecoration(
                  labelText: "Lokasi",
                  border: OutlineInputBorder(),
                ),
                items: [
                  'Greenhouse A',
                  'Greenhouse B',
                  'Nursery',
                  'Outdoor Field'
                ].map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedLocation = val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedGreenhouse,
                decoration: const InputDecoration(
                  labelText: "Greenhouse ID",
                  border: OutlineInputBorder(),
                ),
                items: [
                  'greenhouse_001',
                  'greenhouse_002',
                  'greenhouse_003'
                ].map((gh) {
                  return DropdownMenuItem(
                    value: gh,
                    child: Text(gh),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedGreenhouse = val!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: _addDeviceToFirebase,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Tambah"),
          ),
        ],
      ),
    );
  }

  void _addDeviceToFirebase() {
    if (_nameController.text.isEmpty || 
        _idController.text.isEmpty || 
        _macController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi semua field!")),
      );
      return;
    }

    final deviceId = _idController.text.trim();
    final newDevice = {
      'name': _nameController.text.trim(),
      'type': _selectedType,
      'status': 'pending',
      'macAddress': _macController.text.trim(),
      'location': _selectedLocation,
      'greenhouseId': _selectedGreenhouse,
      'owner': 'user_001', // Default user
      'registeredAt': DateTime.now().millisecondsSinceEpoch,
      'approved': false,
      'approvedBy': '',
      'approvedAt': 0,
      'firmwareVersion': '1.0',
      'lastSeen': 0,
      'ipAddress': '',
    };

    // Simpan ke Firebase
    _devicesRef.child(deviceId).set(newDevice).then((_) {
      // Update registered devices
      _registeredRef.child(deviceId).set(true);
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perangkat berhasil ditambahkan!")),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error")),
      );
    });
  }

  void _showDeviceDetails(Map<String, dynamic> device) {
    final status = _formatStatus(device['status']?.toString() ?? 'offline');
    final type = _formatType(device['type']?.toString() ?? 'unknown');
    final mac = device['macAddress']?.toString() ?? 'N/A';
    final location = device['location']?.toString() ?? 'N/A';
    final greenhouse = device['greenhouseId']?.toString() ?? 'N/A';
    final firmware = device['firmwareVersion']?.toString() ?? 'N/A';
    final owner = device['owner']?.toString() ?? 'N/A';
    
    // Last seen calculation
    String lastUpdate = 'Tidak diketahui';
    if (device['lastSeen'] != null) {
      final lastSeen = int.tryParse(device['lastSeen'].toString()) ?? 0;
      lastUpdate = '$lastSeen detik yang lalu';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(device['name']?.toString() ?? 'Unknown Device'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow("ID", device['id']?.toString() ?? 'N/A'),
              _detailRow("Tipe", type),
              _detailRow("Status", status),
              _detailRow("MAC Address", mac),
              _detailRow("Lokasi", location),
              _detailRow("Greenhouse", greenhouse),
              _detailRow("Firmware", firmware),
              _detailRow("Pemilik", owner),
              _detailRow("Update Terakhir", lastUpdate),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> device) {
    final deviceId = device['id']?.toString();
    final deviceName = device['name']?.toString() ?? 'Perangkat ini';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Perangkat?"),
        content: Text("Yakin ingin menghapus $deviceName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (deviceId != null) {
                // Hapus dari Firebase
                _devicesRef.child(deviceId).remove().then((_) {
                  _registeredRef.child(deviceId).remove();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Perangkat berhasil dihapus")),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $error")),
                  );
                });
              } else {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _macController.dispose();
    super.dispose();
  }
}