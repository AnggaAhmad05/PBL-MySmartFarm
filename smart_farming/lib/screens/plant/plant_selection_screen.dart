
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';

class PlantSelectionScreen extends StatelessWidget {
  final String uid;
  const PlantSelectionScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Jenis Tanaman')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('plants').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final plants = snapshot.data!.docs;

          if (plants.isEmpty) {
            return const Center(
              child: Text('Belum ada data tanaman di Firestore'),
            );
          }

          return ListView(
            children: plants.map((doc) {
              final plant = doc.data() as Map<String, dynamic>;
              final name = plant['name'] ?? 'Tanaman';
              final min = plant['ideal_moisture_min'] ?? 0;
              final max = plant['ideal_moisture_max'] ?? 0;
              final temp = plant['temperature'] ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Kelembapan ideal: $min–$max%\nSuhu ideal: $temp°C'),
                  onTap: () async {
                    // Simpan pilihan tanaman ke koleksi 'farms'
                    await FirebaseFirestore.instance
                        .collection('farms')
                        .doc(uid)
                        .set({
                      'selected_plant_id': doc.id,
                      'selected_plant_name': name,
                      'created_at': FieldValue.serverTimestamp(),
                    });

                    // Arahkan ke Dashboard
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DashboardScreen(uid: uid),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
