import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DetailTanamankuPage extends StatefulWidget {
  final String varietasId;
  final String tanamanId;

  const DetailTanamankuPage({
    super.key,
    required this.varietasId,
    required this.tanamanId,
  });

  @override
  State<DetailTanamankuPage> createState() => _DetailTanamankuPageState();
}

class _DetailTanamankuPageState extends State<DetailTanamankuPage> {

  // DUMMY DATA (akan diupdate dari Firestore)
  TimeOfDay penyiramanTime = const TimeOfDay(hour: 9, minute: 0);
  int durasiPenyiraman = 10;

  TimeOfDay nutrisiTime = const TimeOfDay(hour: 16, minute: 0);
  int volumeNutrisi = 150;

  bool autoMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5FAF6),
      appBar: AppBar(
        backgroundColor: const Color(0xffF5FAF6),
        elevation: 0,
        title: const Text(
          "Detail Tanaman",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('varietas_tanaman')
            .doc(widget.varietasId)
            .snapshots(),
        builder: (context, varietasSnapshot) {
          // Loading state
          if (varietasSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error handling
          if (varietasSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text("Error: ${varietasSnapshot.error}"),
                ],
              ),
            );
          }

          // Check if document exists
          if (!varietasSnapshot.hasData || 
              varietasSnapshot.data == null || 
              !varietasSnapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("Data varietas tidak ditemukan"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Kembali"),
                  ),
                ],
              ),
            );
          }

          // Get varietas data
          final varietasData = varietasSnapshot.data!.data() as Map<String, dynamic>?;
          
          if (varietasData == null) {
            return const Center(child: Text("Data varietas kosong"));
          }

          final varietasName = varietasData['name'] ?? 'Unknown';
          final description = varietasData['decription'] ?? ''; // typo di database
          final idealTempMin = varietasData['ideal_temp_min'] ?? 0;
          final idealTempMax = varietasData['ideal_temp_max'] ?? 0;
          final idealHumidityMin = varietasData['ideal_humidity_min'] ?? 0;
          final idealHumidityMax = varietasData['ideal_humidity_max'] ?? 0;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tanaman')
                .where('varietasId', isEqualTo: widget.varietasId)
                .snapshots(),
            builder: (context, tanamanSnapshot) {
              Map<String, dynamic>? tanamanData;
              
              if (tanamanSnapshot.hasData && 
                  tanamanSnapshot.data!.docs.isNotEmpty) {
                tanamanData = tanamanSnapshot.data!.docs.first.data() as Map<String, dynamic>?;
              }

              final jumlahTanaman = tanamanData?['jumlah_tanaman'] ?? 0;
              final umurTanam = tanamanData?['umur_tanam'] ?? 0;
              final tanggalTanam = tanamanData?['tanggal_tanam'] as Timestamp?;
              final greenhouseId = tanamanData?['greenhouse_id'] ?? '';

              // Hitung perkiraan panen (90 hari dari tanam)
              num hariSisaPanen = 90 - umurTanam;
              if (hariSisaPanen < 0) hariSisaPanen = 0;

              // Hitung persentase pertumbuhan
              int persentasePertumbuhan = ((umurTanam / 90) * 100).toInt();
              if (persentasePertumbuhan > 100) persentasePertumbuhan = 100;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ==== FOTO TANAMAN ====
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.green.shade200,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.eco,
                              size: 80,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              varietasName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==== NAMA VARIETAS ====
                    Text(
                      varietasName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    if (description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          description,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      "Pertumbuhan $persentasePertumbuhan% · Perkiraan panen $hariSisaPanen hari lagi",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (umurTanam > 0)
                      Text(
                        "Umur tanaman: $umurTanam hari",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    if (jumlahTanaman > 0)
                      Text(
                        "Jumlah tanaman: $jumlahTanaman",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    if (tanggalTanam != null)
                      Text(
                        "Tanggal tanam: ${DateFormat('dd MMM yyyy').format(tanggalTanam.toDate())}",
                        style: const TextStyle(color: Colors.grey),
                      ),

                    const SizedBox(height: 25),

                    // ==== STATUS SENSOR (REAL-TIME DARI SENSOR_HISTORY) ====
                    _sensorStatusBox(greenhouseId),

                    const SizedBox(height: 25),

                    // ==== KONDISI IDEAL ====
                    _kondisiIdealBox(idealTempMin, idealTempMax, idealHumidityMin, idealHumidityMax),

                    const SizedBox(height: 30),

                    // ==== RIWAYAT AKTIVITAS (DARI SENSOR_HISTORY) ====
                    const Text(
                      "Riwayat Aktivitas",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    _riwayatAktivitas(greenhouseId),

                    const SizedBox(height: 35),

                    // ==== FORM ATUR JADWAL ====
                    const Text(
                      "Atur Jadwal Tanaman",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),

                    _aturPenyiramanBox(),
                    const SizedBox(height: 20),
                    _aturNutrisiBox(),
                    const SizedBox(height: 20),
                    _aturModeOtomatis(),
                    const SizedBox(height: 30),

                    Center(
                      child: ElevatedButton(
                        onPressed: () => _simpanJadwal(tanamanData),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "Simpan Jadwal",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ==== STATUS SENSOR REAL-TIME ====
  Widget _sensorStatusBox(String greenhouseId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sensor_history')
          .where('userId', isEqualTo: 'Petani77') // Sesuaikan dengan user yang login
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text("Tidak ada data sensor"),
            ),
          );
        }

        final sensorData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final temperature = sensorData['temperature'] ?? 0;
        final humidity = sensorData['humidity'] ?? 0;
        final soilMoisture = sensorData['soilMoisture'] ?? 0;
        final lightIntensity = sensorData['lightIntensity'] ?? 0;
        final pumpStatus = sensorData['pumpStatus'] ?? false;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Status Sensor Real-Time",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        const Text("LIVE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statusChip("Suhu", "$temperature°C", Colors.orange.shade100),
                  _statusChip("Kelembaban", "$humidity%", Colors.green.shade100),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statusChip("Tanah", "$soilMoisture%", Colors.brown.shade100),
                  _statusChip("Cahaya", "$lightIntensity%", Colors.yellow.shade100),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    pumpStatus ? Icons.water_drop : Icons.water_drop_outlined,
                    color: pumpStatus ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Pompa: ${pumpStatus ? 'Aktif' : 'Mati'}",
                    style: TextStyle(
                      color: pumpStatus ? Colors.blue : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==== KONDISI IDEAL ====
  Widget _kondisiIdealBox(dynamic tempMin, dynamic tempMax, dynamic humidityMin, dynamic humidityMax) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Kondisi Ideal",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statusChip("Kelembaban", "$humidityMin-$humidityMax%", Colors.green.shade100),
              _statusChip("Suhu", "$tempMin-$tempMax°C", Colors.orange.shade100),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String title, String value, Color bg) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title, 
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ==== RIWAYAT AKTIVITAS DARI SENSOR_HISTORY ====
  Widget _riwayatAktivitas(String greenhouseId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sensor_history')
          .where('userId', isEqualTo: 'Petani77') // Sesuaikan dengan user yang login
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("Tidak ada riwayat aktivitas");
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] as Timestamp?;
            final pumpStatus = data['pumpStatus'] ?? false;
            final temperature = data['temperature'] ?? 0;
            final humidity = data['humidity'] ?? 0;

            String timeAgo = "Baru saja";
            if (timestamp != null) {
              final date = timestamp.toDate();
              final now = DateTime.now();
              final difference = now.difference(date);

              if (difference.inDays > 0) {
                timeAgo = "${difference.inDays} hari lalu";
              } else if (difference.inHours > 0) {
                timeAgo = "${difference.inHours} jam lalu";
              } else if (difference.inMinutes > 0) {
                timeAgo = "${difference.inMinutes} menit lalu";
              }
            }

            String activity = pumpStatus 
                ? "Penyiraman otomatis aktif" 
                : "Monitoring sensor";

            return _historyItem(
              activity,
              "$timeAgo · Suhu: $temperature°C, Kelembaban: $humidity%",
            );
          }).toList(),
        );
      },
    );
  }

  // ==== RIWAYAT ITEM ====
  Widget _historyItem(String title, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 10),
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
          )
        ],
      ),
    );
  }

  // ==== SIMPAN JADWAL KE FIRESTORE ====
  Future<void> _simpanJadwal(Map<String, dynamic>? tanamanData) async {
    try {
      // Simpan ke collection jadwal
      await FirebaseFirestore.instance.collection('jadwal').add({
        'greenhouse_id': 'greenhouse123',
        'jadwal_id': 'jadwal_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'penyiraman',
        'hari': DateFormat('EEEE').format(DateTime.now()).toLowerCase(),
        'waktu': '${penyiramanTime.hour.toString().padLeft(2, '0')}:${penyiramanTime.minute.toString().padLeft(2, '0')}',
        'duration': durasiPenyiraman,
        'createAt': Timestamp.now(),
      });

      // Update data tanaman jika ada
      if (tanamanData != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('tanaman')
            .where('varietasId', isEqualTo: widget.varietasId)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          await querySnapshot.docs.first.reference.update({
            'jadwal_penyiraman': {
              'waktu': '${penyiramanTime.hour}:${penyiramanTime.minute.toString().padLeft(2, '0')}',
              'durasi': durasiPenyiraman,
            },
            'jadwal_nutrisi': {
              'waktu': '${nutrisiTime.hour}:${nutrisiTime.minute.toString().padLeft(2, '0')}',
              'volume': volumeNutrisi,
            },
            'mode_otomatis': autoMode,
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Jadwal berhasil disimpan!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==== FORM PENGATURAN PENYIRAMAN ====
  Widget _aturPenyiramanBox() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Penyiraman",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          // Pilih Waktu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Waktu penyiraman"),
              TextButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                      context: context, initialTime: penyiramanTime);
                  if (picked != null) {
                    setState(() => penyiramanTime = picked);
                  }
                },
                child: Text(penyiramanTime.format(context)),
              ),
            ],
          ),

          // Durasi penyiraman
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Durasi (menit)"),
              DropdownButton<int>(
                value: durasiPenyiraman,
                items: [5, 10, 15, 20]
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text("$e menit")))
                    .toList(),
                onChanged: (value) {
                  setState(() => durasiPenyiraman = value!);
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  // ==== FORM PENGATURAN NUTRISI ====
  Widget _aturNutrisiBox() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pemberian Nutrisi",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          // Waktu nutrisi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Waktu pemberian"),
              TextButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                      context: context, initialTime: nutrisiTime);
                  if (picked != null) {
                    setState(() => nutrisiTime = picked);
                  }
                },
                child: Text(nutrisiTime.format(context)),
              ),
            ],
          ),

          // Volume nutrisi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Volume nutrisi"),
              DropdownButton<int>(
                value: volumeNutrisi,
                items: [100, 150, 200, 250]
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text("$e ml")))
                    .toList(),
                onChanged: (value) {
                  setState(() => volumeNutrisi = value!);
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  // ==== MODE OTOMATIS ====
  Widget _aturModeOtomatis() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Mode Otomatis",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Switch(
            value: autoMode,
            activeColor: Colors.green,
            onChanged: (value) {
              setState(() => autoMode = value);
            },
          )
        ],
      ),
    );
  }
}
