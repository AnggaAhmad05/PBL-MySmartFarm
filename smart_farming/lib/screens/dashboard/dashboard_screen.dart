import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../monitoring/tanamanku_screen.dart';
import '../manual_control/smart_control_screen.dart';
import '../settings/profile_page_screen.dart';
import '../dashboard/menu_utama_screen.dart';


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
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              
              // Header
              Text(
                "07:25",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              const Text(
                "Halo,",
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
              Row(
                children: const [
                  Text(
                    "Melonners ",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  Text("👋", style: TextStyle(fontSize: 30)),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    "Polinema, Malang",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Smart Farm Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9F6DC),
                  borderRadius: BorderRadius.circular(16),
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
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Pantau kebunmu secara real-time",
                            style: TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TanamankuScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text("Lihat Tanamanku"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.power_settings_new,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Data Sensor
              const Text(
                "Data Sensor Utama",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Update terakhir: 07.20 WIB",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 12),

              _sensorCard(
                icon: Icons.water_drop,
                title: "Kelembaban Tanah",
                value: "57%",
                status: "Stabil",
                iconColor: Colors.green,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _sensorMiniCard(
                      title: "Suhu",
                      value: "29°C",
                      icon: Icons.thermostat,
                      iconColor: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _sensorMiniCard(
                      title: "Cahaya",
                      value: "740 lux",
                      icon: Icons.wb_sunny,
                      iconColor: Colors.amber,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Kontrol Cepat
              const Text(
                "Kontrol Cepat",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _toggleCard(
                title: "Pompa Air",
                subtitle: "Aktif otomatis jika kelembaban < 40%",
                value: true,
              ),
              const SizedBox(height: 10),
              _toggleCard(
                title: "Lampu Tumbuh",
                subtitle: "Menyala saat cahaya < 600 lux",
                value: false,
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
          _NavItem(
            icon: Icons.apps,
            label: "Menu",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MenuUtamaScreen()),
              );
            },
          ),
          _NavItem(
            icon: Icons.settings_remote,
            label: "Kontrol",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SmartControlScreen()),
              );
            },
          ),
          _NavItem(
            icon: Icons.person,
            label: "Profil",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============ WIDGET HELPERS ============

Widget _sensorCard({
  required IconData icon,
  required String title,
  required String value,
  required String status,
  required Color iconColor,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              status,
              style: TextStyle(
                color: iconColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _sensorMiniCard({
  required String title,
  required String value,
  required IconData icon,
  required Color iconColor,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

Widget _toggleCard({
  required String title,
  required String subtitle,
  required bool value,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: (_) {},
          activeColor: Colors.green,
        ),
      ],
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
          Icon(
            icon,
            color: active ? Colors.green : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.green : Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}