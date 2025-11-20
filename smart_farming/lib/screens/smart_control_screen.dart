import 'package:flutter/material.dart';

class SmartControlScreen extends StatefulWidget {
  const SmartControlScreen({super.key});

  @override
  State<SmartControlScreen> createState() => _SmartControlScreenState();
}

class _SmartControlScreenState extends State<SmartControlScreen> {
  // ==============================
  // DUMMY STATE (bisa diganti Firebase)
  // ==============================

  // Menyiram otomatis
  bool isWateringOn = false;
  double wateringVolume = 20;

  // Monitoring lingkungan
  double suhu = 29;
  double lux = 740;
  double kelembaban = 57;

  // Nutrisi
  bool isNutrisiOn = false;
  double nutrientDose = 150;
  String jadwalNutrisi = "16:00 WIB";

  // pH & kelembaban tanah
  double phTanah = 6.5;

  // Cahaya
  bool isLightOn = false;
  double intensitasCahaya = 70;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F3),
      appBar: AppBar(
        title: const Text(
          "Smart Control",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===========================================
            // 1. MENYIRAM OTOMATIS
            // ===========================================
            _buildCard(
              icon: Icons.local_drink,
              title: "Menyiram Otomatis",
              subtitle: "Atur jadwal penyiraman melon.",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSwitchTile(
                    "Status",
                    isWateringOn,
                    (val) => setState(() => isWateringOn = val),
                  ),
                  const SizedBox(height: 10),
                  Text("Volume Air: ${wateringVolume.toStringAsFixed(0)} ml"),
                  Slider(
                    value: wateringVolume,
                    min: 10,
                    max: 200,
                    onChanged: (v) => setState(() => wateringVolume = v),
                  ),
                ],
              ),
            ),

            // ===========================================
            // 2. Monitoring Lingkungan
            // ===========================================
            _buildCard(
              icon: Icons.thermostat,
              title: "Monitoring Lingkungan",
              subtitle: "Pantau kondisi suhu, cahaya, kelembaban.",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• Suhu: $suhu°C"),
                  Text("• Cahaya: $lux lux"),
                  Text("• Kelembaban Tanah: $kelembaban%"),
                ],
              ),
            ),

            // ===========================================
            // 3. Kontrol Nutrisi
            // ===========================================
            _buildCard(
              icon: Icons.bolt,
              title: "Kontrol Nutrisi",
              subtitle: "Pantau pemberian nutrisi hidroponik.",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSwitchTile(
                    "Status",
                    isNutrisiOn,
                    (val) => setState(() => isNutrisiOn = val),
                  ),
                  const SizedBox(height: 10),
                  Text("Dosis Nutrisi: ${nutrientDose.toStringAsFixed(0)} ml"),
                  Slider(
                    value: nutrientDose,
                    min: 50,
                    max: 300,
                    onChanged: (v) => setState(() => nutrientDose = v),
                  ),
                  const SizedBox(height: 10),
                  Text("Jadwal Nutrisi: $jadwalNutrisi"),
                ],
              ),
            ),

            // ===========================================
            // 4. pH & Kelembaban Tanah
            // ===========================================
            _buildCard(
              icon: Icons.science,
              title: "pH & Kelembaban Tanah",
              subtitle: "Pantau pH dan kelembaban tanah real-time.",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• pH Tanah: $phTanah (Ideal)"),
                  Text("• Kelembaban: $kelembaban%"),
                ],
              ),
            ),

            // ===========================================
            // 5. Kontrol Cahaya
            // ===========================================
            _buildCard(
              icon: Icons.wb_sunny,
              title: "Kontrol Cahaya",
              subtitle: "Kontrol lampu tumbuh (Grow Light).",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSwitchTile(
                    "Lampu",
                    isLightOn,
                    (val) => setState(() => isLightOn = val),
                  ),
                  const SizedBox(height: 10),
                  Text("Intensitas Cahaya: ${intensitasCahaya.toStringAsFixed(0)}%"),
                  Slider(
                    value: intensitasCahaya,
                    min: 0,
                    max: 100,
                    onChanged: (v) => setState(() => intensitasCahaya = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================
  // COMPONENT BUILDERS
  // ===================================================

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green, size: 26),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Switch(
          value: value,
          activeThumbColor: Colors.green,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
