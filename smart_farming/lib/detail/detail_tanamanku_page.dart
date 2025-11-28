import 'package:flutter/material.dart';

class DetailTanamankuPage extends StatefulWidget {
  final String varietas; // <-- DITAMBAHKAN

  const DetailTanamankuPage({
    super.key,
    required this.varietas, // <-- WAJIB
  });

  @override
  State<DetailTanamankuPage> createState() => _DetailTanamankuPageState();
}

class _DetailTanamankuPageState extends State<DetailTanamankuPage> {

  // DUMMY DATA
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
        title: Text(
          "Detail ${widget.varietas}",   // <-- DIUBAH SESUAI VARIETAS
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
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
                image: const DecorationImage(
                  image: AssetImage("assets/melon_greenhouse.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==== NAMA VARIETAS ====
            Text(
              widget.varietas,    // <-- MENAMPILKAN VARIETAS
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Pertumbuhan 65% · Perkiraan panen 21 hari lagi",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 25),

            // ==== STATUS SENSOR ====
            _statusBox(),

            const SizedBox(height: 30),

            const Text(
              "Riwayat Aktivitas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _historyItem("Penyiraman otomatis", "09:00 hari ini"),
            _historyItem("Pemberian nutrisi", "Kemarin 16:00"),
            _historyItem("Penyesuaian lampu tumbuh", "2 hari lalu"),

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
                onPressed: () {
                  // nanti ganti ke firebase atau realtime database
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Jadwal berhasil disimpan!")),
                  );
                },
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
      ),
    );
  }

  // ==== STATUS SENSOR ====
  Widget _statusBox() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statusChip("Kelembaban", "57%", Colors.green.shade100),
          _statusChip("Suhu", "29°C", Colors.orange.shade100),
          _statusChip("Nutrisi", "Cukup", Colors.blue.shade100),
        ],
      ),
    );
  }

  Widget _statusChip(String title, String value, Color bg) {
    return Container(
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
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // ==== RIWAYAT ====
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text(time, style: const TextStyle(color: Colors.grey)),
            ],
          )
        ],
      ),
    );
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
            activeThumbColor: Colors.green,
            onChanged: (value) {
              setState(() => autoMode = value);
            },
          )
        ],
      ),
    );
  }
}
