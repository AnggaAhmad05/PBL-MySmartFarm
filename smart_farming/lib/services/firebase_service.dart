import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // 🔹 baca semua data sensor
  Stream<Map<String, dynamic>> getSensorData() {
    return _db.child('sensor').onValue.map((event) {
      final data = Map<String, dynamic>.from(
        event.snapshot.value as Map,
      );
      return data;
    });
  }

  // 🔹 update status pompa
  Future<void> updatePompa(bool aktif) async {
    await _db.child('kontrol').update({'pompa': aktif ? 'ON' : 'OFF'});
  }
}
