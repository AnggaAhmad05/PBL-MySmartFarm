// lib/screens/device_management_screen.dart

import 'package:flutter/material.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  // DUMMY DATA - ganti dengan Firebase
  List<Map<String, dynamic>> devices = [
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

            const Text(
              "Perangkat Terdaftar (${3})",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // List Devices
            ...devices.map((device) => _buildDeviceCard(device)).toList(),

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

  Widget _buildDeviceCard(Map<String, dynamic> device) {
    final isActive = device['status'] == 'Aktif';
    final statusColor = isActive ? Colors.green : (device['status'] == 'Standby' ? Colors.orange : Colors.grey);

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
                child: Icon(device['icon'], color: statusColor, size: 28),
              ),

              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          device['type'],
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Text("•", style: TextStyle(color: Colors.grey.shade400)),
                        const SizedBox(width: 8),
                        Text(
                          device['id'],
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
                  device['status'],
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
                    "Update: ${device['lastUpdate']}",
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
    final nameController = TextEditingController();
    final idController = TextEditingController();
    String selectedType = 'Sensor Node';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Perangkat Baru"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Nama Perangkat",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: "ID Perangkat (contoh: NODE_004)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: "Tipe Perangkat",
                border: OutlineInputBorder(),
              ),
              items: ['Sensor Node', 'Actuator', 'Controller']
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (val) => selectedType = val!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Tambahkan ke Firebase
              setState(() {
                devices.add({
                  'id': idController.text,
                  'name': nameController.text,
                  'type': selectedType,
                  'status': 'Standby',
                  'lastUpdate': 'Baru saja',
                  'icon': Icons.devices,
                });
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Perangkat berhasil ditambahkan!")),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Tambah"),
          ),
        ],
      ),
    );
  }

  void _showDeviceDetails(Map<String, dynamic> device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(device['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow("ID", device['id']),
            _detailRow("Tipe", device['type']),
            _detailRow("Status", device['status']),
            _detailRow("Update Terakhir", device['lastUpdate']),
          ],
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
          Text(value),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Perangkat?"),
        content: Text("Yakin ingin menghapus ${device['name']}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => devices.remove(device));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Perangkat berhasil dihapus")),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }
}