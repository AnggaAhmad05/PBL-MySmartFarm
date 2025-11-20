import 'package:flutter/material.dart';

class IoTFeaturesScreen extends StatelessWidget {
  const IoTFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5FAF6),
      appBar: AppBar(
        title: const Text(
          "Smart Farm Features",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xffF5FAF6),
        elevation: 0,
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ======= REALTIME MONITORING =======
            const Text(
              "Monitoring Lingkungan",
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 10),

            _sensorTile(
              icon: Icons.thermostat,
              title: "Suhu Udara",
              value: "29°C",
              description: "Ideal 24° – 30°C",
              color: Colors.orange,
            ),

            const SizedBox(height: 12),

            _sensorTile(
              icon: Icons.water_drop,
              title: "Kelembaban Tanah",
              value: "57%",
              description: "Ideal 40% – 70%",
              color: Colors.green,
            ),

            const SizedBox(height: 12),

            _sensorTile(
              icon: Icons.air,
              title: "Kelembaban Udara",
              value: "62%",
              description: "Ideal 50% – 70%",
              color: Colors.blue,
            ),

            const SizedBox(height: 12),

            _sensorTile(
              icon: Icons.wb_sunny,
              title: "Cahaya",
              value: "740 lux",
              description: "Ideal 600 – 900 lux",
              color: Colors.yellow,
            ),

            const SizedBox(height: 25),

            // ======= PH & NUTRISI =======
            const Text(
              "Nutrisi & Media Tanam",
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 10),

            _sensorTile(
              icon: Icons.science,
              title: "pH Tanah",
              value: "6.2",
              description: "Ideal 5.5 – 6.5",
              color: Colors.purple,
            ),

            const SizedBox(height: 12),

            _sensorTile(
              icon: Icons.eco,
              title: "Kadar Nutrisi",
              value: "Cukup",
              description: "Stabil untuk tanaman melon",
              color: Colors.teal,
            ),

            const SizedBox(height: 25),

            // ======= CONTROL =======
            const Text(
              "Kontrol Otomatis",
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 10),

            _switchCard(
              title: "Pompa Air",
              subtitle: "Aktif otomatis jika kelembaban < 40%",
              value: true,
            ),

            const SizedBox(height: 12),

            _switchCard(
              title: "Lampu Tumbuh",
              subtitle: "Menyala saat cahaya < 600 lux",
              value: false,
            ),

            const SizedBox(height: 12),

            _switchCard(
              title: "Penyiraman Otomatis",
              subtitle: "Mode otomatis ON",
              value: true,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ================= WIDGETS ===================

  Widget _sensorTile({
    required IconData icon,
    required String title,
    required String value,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold
                  )),
                Text(description, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchCard({
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
                    fontSize: 16, fontWeight: FontWeight.bold
                  )),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Switch(value: value, onChanged: (v) {}),
        ],
      ),
    );
  }
}
