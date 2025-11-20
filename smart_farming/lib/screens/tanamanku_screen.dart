import 'package:flutter/material.dart';
import '../detail/detail_tanamanku_page.dart';

class TanamankuScreen extends StatelessWidget {
  const TanamankuScreen({super.key});

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
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // === GREENHOUSE CARD ===
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Melon Greenhouse",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Status: Sehat · Auto-watering ON\n3 sensor aktif · 1 pompa · 1 lampu tumbuh",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoChip("Kelembaban", "57%", Colors.green.shade100),
                      _infoChip("Suhu", "29°C", Colors.orange.shade100),
                      _infoChip("Nutrisi", "Cukup", Colors.blue.shade100),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 25),

            // === TITLE ===
            const Text(
              "Jadwal perawatan hari ini",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // === SCHEDULES ===
            _scheduleTile(
              icon: Icons.water_drop,
              title: "Penyiraman otomatis",
              time: "09:00 · Durasi 10 menit",
              status: "AKTIF",
              color: Colors.green,
            ),
            const SizedBox(height: 10),

            _scheduleTile(
              icon: Icons.energy_savings_leaf,
              title: "Pemberian nutrisi",
              time: "16:00 · 150–200 ml",
              status: "TERJADWAL",
              color: Colors.orange,
            ),
            const SizedBox(height: 10),

            _scheduleTile(
              icon: Icons.wb_sunny,
              title: "Cek intensitas cahaya",
              time: "18:30 · Penyesuaian lampu tumbuh",
              status: "PENDING",
              color: Colors.grey,
            ),

            const SizedBox(height: 25),

            // === BUTTON: NAVIGASI DETAIL ===
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DetailTanamankuPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "Lihat detail tanaman",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // === CHIP ===
  Widget _infoChip(String label, String value, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // === TILE ===
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
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(time, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
