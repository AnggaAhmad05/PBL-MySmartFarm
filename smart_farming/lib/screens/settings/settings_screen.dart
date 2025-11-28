// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Threshold Otomatis
  double minHumidity = 40;
  double maxHumidity = 70;
  double minTemperature = 24;
  double maxTemperature = 30;

  // Notifikasi
  bool notifWatering = true;
  bool notifNutrient = true;
  bool notifTemperature = true;
  bool notifHumidity = true;

  // Mode Otomatis
  bool autoWatering = true;
  bool autoNutrient = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F3),
      appBar: AppBar(
        title: const Text("Pengaturan", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===========================================
            // 1. AMBANG BATAS KELEMBABAN
            // ===========================================
            _buildSectionCard(
              icon: Icons.water_drop,
              title: "Ambang Batas Kelembaban",
              subtitle: "Untuk mode otomatis penyiraman",
              child: Column(
                children: [
                  _buildRangeInfo("Kelembaban Minimum", minHumidity, "%"),
                  Slider(
                    value: minHumidity,
                    min: 20,
                    max: 60,
                    divisions: 40,
                    label: "${minHumidity.toInt()}%",
                    onChanged: (v) => setState(() => minHumidity = v),
                  ),
                  const SizedBox(height: 10),
                  _buildRangeInfo("Kelembaban Maksimum", maxHumidity, "%"),
                  Slider(
                    value: maxHumidity,
                    min: 50,
                    max: 90,
                    divisions: 40,
                    label: "${maxHumidity.toInt()}%",
                    onChanged: (v) => setState(() => maxHumidity = v),
                  ),
                ],
              ),
            ),

            // ===========================================
            // 2. AMBANG BATAS SUHU
            // ===========================================
            _buildSectionCard(
              icon: Icons.thermostat,
              title: "Ambang Batas Suhu",
              subtitle: "Notifikasi jika suhu di luar rentang",
              child: Column(
                children: [
                  _buildRangeInfo("Suhu Minimum", minTemperature, "°C"),
                  Slider(
                    value: minTemperature,
                    min: 15,
                    max: 30,
                    divisions: 15,
                    label: "${minTemperature.toInt()}°C",
                    onChanged: (v) => setState(() => minTemperature = v),
                  ),
                  const SizedBox(height: 10),
                  _buildRangeInfo("Suhu Maksimum", maxTemperature, "°C"),
                  Slider(
                    value: maxTemperature,
                    min: 25,
                    max: 40,
                    divisions: 15,
                    label: "${maxTemperature.toInt()}°C",
                    onChanged: (v) => setState(() => maxTemperature = v),
                  ),
                ],
              ),
            ),

            // ===========================================
            // 3. PREFERENSI NOTIFIKASI
            // ===========================================
            _buildSectionCard(
              icon: Icons.notifications,
              title: "Preferensi Notifikasi",
              subtitle: "Atur notifikasi yang ingin diterima",
              child: Column(
                children: [
                  _buildSwitchTile(
                    "Notifikasi Penyiraman",
                    "Pengingat jadwal penyiraman",
                    notifWatering,
                    (v) => setState(() => notifWatering = v),
                  ),
                  _buildSwitchTile(
                    "Notifikasi Nutrisi",
                    "Pengingat jadwal pemberian nutrisi",
                    notifNutrient,
                    (v) => setState(() => notifNutrient = v),
                  ),
                  _buildSwitchTile(
                    "Notifikasi Suhu",
                    "Peringatan suhu tidak normal",
                    notifTemperature,
                    (v) => setState(() => notifTemperature = v),
                  ),
                  _buildSwitchTile(
                    "Notifikasi Kelembaban",
                    "Peringatan kelembaban kritis",
                    notifHumidity,
                    (v) => setState(() => notifHumidity = v),
                  ),
                ],
              ),
            ),

            // ===========================================
            // 4. MODE OTOMATIS
            // ===========================================
            _buildSectionCard(
              icon: Icons.auto_awesome,
              title: "Mode Otomatis",
              subtitle: "Kontrol otomatis berdasarkan sensor",
              child: Column(
                children: [
                  _buildSwitchTile(
                    "Penyiraman Otomatis",
                    "Aktifkan pompa saat kelembaban < ${minHumidity.toInt()}%",
                    autoWatering,
                    (v) => setState(() => autoWatering = v),
                  ),
                  _buildSwitchTile(
                    "Nutrisi Otomatis",
                    "Berikan nutrisi sesuai jadwal",
                    autoNutrient,
                    (v) => setState(() => autoNutrient = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Simpan Pengaturan",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildRangeInfo(String label, double value, String unit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(
          "${value.toInt()}$unit",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.green,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    // TODO: Simpan ke Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Pengaturan berhasil disimpan!"),
        backgroundColor: Colors.green,
      ),
    );
  }
}