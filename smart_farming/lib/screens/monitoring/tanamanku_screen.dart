import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../detail/detail_tanamanku_page.dart';

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

            // ==========================================================
            // === VARIETAS MELON (DARI FIRESTORE) =====================
            // ==========================================================
            const Text(
              "Pilih Varietas Melon",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            // StreamBuilder untuk mengambil data varietas dari Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('varietas_tanaman')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "Tidak ada varietas tersedia",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                final varietasList = snapshot.data!.docs;

                return Column(
                  children: varietasList.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown';
                    final description = data['description'] ?? ''; 
                    
                    // PENTING: Gunakan doc.id sebagai varietasId
                    final varietasId = doc.id; // <-- INI YANG BENAR
                    
                    final idealTempMin = data['ideal_temp_min'] ?? 0;
                    final idealTempMax = data['ideal_temp_max'] ?? 0;
                    
                    // Warna berbeda untuk setiap varietas
                    final colors = [
                      Colors.yellow.shade100,
                      Colors.green.shade100,
                      Colors.orange.shade100,
                      Colors.teal.shade100,
                    ];
                    final colorIndex = varietasList.indexOf(doc) % colors.length;

                    print("🌱 Varietas: $name | ID: $varietasId"); // Debug

                    return Column(
                      children: [
                        _varietasItem(
                          context, 
                          name, 
                          description, 
                          colors[colorIndex],
                          varietasId, // Kirim doc.id
                          idealTempMin,
                          idealTempMax,
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 30),

            // === GREENHOUSE CARD (DARI FIRESTORE) ===
            const Text(
              "Greenhouse Saya",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('greenhouse')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("Tidak ada data greenhouse");
                }

                // Ambil greenhouse pertama
                final greenhouseDoc = snapshot.data!.docs.first;
                final greenhouseData = greenhouseDoc.data() as Map<String, dynamic>;
                final name = greenhouseData['name'] ?? 'Greenhouse';
                final location = greenhouseData['location'] ?? 'Unknown';
                final greenhouseId = greenhouseData['greenhouse_id'] ?? greenhouseDoc.id;

                return _greenhouseCard(name, location, greenhouseId);
              },
            ),

            const SizedBox(height: 25),

            // === JADWAL PERAWATAN (DARI COLLECTION JADWAL) ===
            const Text(
              "Jadwal Perawatan Hari Ini",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jadwal')
                  .where('greenhouse_id', isEqualTo: 'greenhouse123')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Column(
                    children: [
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
                    ],
                  );
                }

                // Tampilkan jadwal dari Firestore
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final type = data['type'] ?? 'unknown';
                    final waktu = data['waktu'] ?? '00:00';
                    final duration = data['duration'] ?? 0;
                    final hari = data['hari'] ?? '';

                    IconData icon = Icons.schedule;
                    Color color = Colors.blue;
                    String title = type;

                    if (type == 'penyiraman' || type == 'irigrasi') {
                      icon = Icons.water_drop;
                      color = Colors.blue;
                      title = 'Penyiraman otomatis';
                    } else if (type == 'nutrisi') {
                      icon = Icons.energy_savings_leaf;
                      color = Colors.green;
                      title = 'Pemberian nutrisi';
                    }

                    return Column(
                      children: [
                        _scheduleTile(
                          icon: icon,
                          title: title,
                          time: "$waktu · Durasi $duration menit · Hari: $hari",
                          status: "TERJADWAL",
                          color: color,
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 10),

            _scheduleTile(
              icon: Icons.wb_sunny,
              title: "Cek intensitas cahaya",
              time: "18:30 · Penyesuaian lampu tumbuh",
              status: "PENDING",
              color: Colors.grey,
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // WIDGET VARIETAS
  // ==========================================================
  Widget _varietasItem(
    BuildContext context, 
    String title, 
    String subtitle, 
    Color bg,
    String varietasId,
    dynamic idealTempMin,
    dynamic idealTempMax,
  ) {
    return InkWell(
      onTap: () {
        print("🔍 Navigating to detail with varietasId: $varietasId");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailTanamankuPage(
              varietasId: varietasId, // Gunakan doc.id
              tanamanId: "tanaman1",
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.green.shade200, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.eco, size: 30, color: Colors.green),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.thermostat, size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        "Suhu ideal: $idealTempMin°C - $idealTempMax°C",
                        style: TextStyle(
                          fontSize: 12, 
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  // === GREENHOUSE CARD ===
  Widget _greenhouseCard(String name, String location, String greenhouseId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sensor_history')
          .where('userId', isEqualTo: 'Petani77')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        String humidity = "57";
        String temperature = "29";
        String status = "Sehat";

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final sensorData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          humidity = "${sensorData['humidity'] ?? 57}";
          temperature = "${sensorData['temperature'] ?? 29}";
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.home, color: Colors.green.shade700, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Auto-watering: ON",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoChip("Kelembaban", "$humidity%", Colors.green.shade100),
                  _infoChip("Suhu", "$temperature°C", Colors.orange.shade100),
                  _infoChip("Nutrisi", "Cukup", Colors.blue.shade100),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // === CHIP KECIL ===
  Widget _infoChip(String label, String value, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          const SizedBox(height: 4),
          Text(
            label, 
            style: const TextStyle(fontSize: 12),
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  time, 
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
