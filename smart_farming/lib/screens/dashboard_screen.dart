import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tanamanku_screen.dart';
import 'smart_control_screen.dart';
import 'data_historis_screen.dart';
import 'settings_screen.dart';
import 'device_management_screen.dart';
import 'notification_history_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String uid;
  const DashboardScreen({super.key, required this.uid});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                "07:25",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              const Text(
                "Halo,",
                style: TextStyle(fontSize: 20, color: Colors.black54),
              ),
              Row(
                children: const [
                  Text(
                    "Melonners ",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text("👋", style: TextStyle(fontSize: 30)),
                ],
              ),
              const Text(
                "Polinema, Malang",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              // Smart Farm Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xffD9F6DC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Smart Farm Melon 🥭",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Pantau kebunmu secara real-time dari mana saja, kapan saja.",
                            style: TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const TanamankuScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Lihat Tanamanku"),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.power_settings_new,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Data Sensor Utama",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Update terakhir: 07.20 WIB",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 10),

              _sensorCard(
                icon: Icons.water_drop,
                title: "Kelembaban Tanah",
                subtitle: "Ideal untuk melon: 40% – 70%",
                value: "57%",
                status: "• Stabil",
                iconColor: Colors.green,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _sensorMiniCard(
                      title: "Suhu",
                      range: "24° – 30°C",
                      value: "29°C",
                      icon: Icons.thermostat,
                      iconColor: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _sensorMiniCard(
                      title: "Cahaya",
                      range: "600 – 900 lux",
                      value: "740 lux",
                      icon: Icons.wb_sunny,
                      iconColor: Colors.yellow,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              const Text(
                "Jadwal Hari Ini",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Reminder penyiraman nutrisi melon",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 10),

              _scheduleCard(
                title: "Water Hidroponik",
                time: "10 – 20 ml · 09.00 WIB",
                status: "Belum dilakukan",
                statusColor: Colors.green,
              ),
              const SizedBox(height: 10),

              _scheduleCard(
                title: "Nutrisi Vertikultur",
                time: "150 – 200 gram · 16.00 WIB",
                status: "Terjadwal",
                statusColor: Colors.grey,
              ),

              const SizedBox(height: 25),

              const Text(
                "Kontrol Cepat",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              _toggleTile(
                title: "Pompa Air",
                subtitle: "Aktif otomatis jika kelembaban < 40%",
                value: true,
              ),
              const SizedBox(height: 10),
              _toggleTile(
                title: "Lampu Tumbuh",
                subtitle: "Menyala saat intensitas cahaya < 600 lux",
                value: false,
              ),

              // ========================================
              // 🔥 BAGIAN BARU - MENU TAMBAHAN
              // ========================================
              const SizedBox(height: 25),

              const Text(
                "Menu Fitur",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Baris 1: Data Historis & Pengaturan
              Row(
                children: [
                  Expanded(
                    child: _menuCard(
                      context,
                      icon: Icons.bar_chart,
                      title: "Data Historis",
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => DataHistorisScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _menuCard(
                      context,
                      icon: Icons.settings,
                      title: "Pengaturan",
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => SettingsScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Baris 2: Manajemen Perangkat & Notifikasi
              Row(
                children: [
                  Expanded(
                    child: _menuCard(
                      context,
                      icon: Icons.devices_other,
                      title: "Manajemen\nPerangkat",
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => DeviceManagementScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _menuCard(
                      context,
                      icon: Icons.notifications_active,
                      title: "Riwayat\nNotifikasi",
                      color: Colors.red,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  NotificationHistoryScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home,
              label: "Beranda",
              active: true,
              onTap: () {},
            ),
            _NavItem(
              icon: Icons.grass,
              label: "Tanamanku",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TanamankuScreen()),
                );
              },
            ),
            _NavItem(icon: Icons.store, label: "Market"),
            _NavItem(
              icon: Icons.settings_remote,
              label: "Smart Control",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SmartControlScreen()),
                );
              },
            ),
            _NavItem(icon: Icons.person, label: "Profil"),
          ],
        ),
      ),
    );
  }
}

// ---------------- Widget Helpers -----------------

Widget _sensorCard({
  required IconData icon,
  required String title,
  required String subtitle,
  required String value,
  required String status,
  required Color iconColor,
}) {
  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              Text(subtitle, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        Column(
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(status, style: const TextStyle(color: Colors.green)),
          ],
        )
      ],
    ),
  );
}

Widget _sensorMiniCard({
  required String title,
  required String range,
  required String value,
  required IconData icon,
  required Color iconColor,
}) {
  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(range, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

Widget _scheduleCard({
  required String title,
  required String time,
  required String status,
  required Color statusColor,
}) {
  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Icon(Icons.check_circle, color: statusColor, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text(time, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _toggleTile({
  required String title,
  required String subtitle,
  required bool value,
}) {
  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: (_) {},
        ),
      ],
    ),
  );
}

// 🔥 WIDGET BARU UNTUK MENU CARD
Widget _menuCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            maxLines: 2,
          ),
        ],
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: active ? Colors.green : Colors.grey),
          Text(label,
              style: TextStyle(
                  color: active ? Colors.green : Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}