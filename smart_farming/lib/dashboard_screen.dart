import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatelessWidget {
  final String uid;
  const DashboardScreen({super.key, required this.uid});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Setelah logout, kembali ke halaman login
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Farming Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Selamat datang di Smart Farming!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'User ID: ',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              uid,
              style: const TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pertemuan berikutnya:\n- Integrasi data sensor\n- Rekomendasi berbasis kondisi',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
