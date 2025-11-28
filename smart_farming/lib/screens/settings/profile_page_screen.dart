import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = _authService.currentUser;
      print('Current user: ${user?.uid}');
      
      if (user == null) {
        setState(() {
          _errorMessage = 'User tidak ditemukan. Silakan login kembali.';
          _isLoading = false;
        });
        return;
      }

      print('Fetching user data from Firestore...');
      final doc = await _firestore.collection('users').doc(user.uid).get();
      print('Document exists: ${doc.exists}');
      
      if (doc.exists) {
        print('User data: ${doc.data()}');
        setState(() {
          _userData = doc.data();
          _isLoading = false;
        });
      } else {
        // 🔥 FITUR BARU: Jika user belum ada, tampilkan opsi create profile
        setState(() {
          _errorMessage = 'DATA_NOT_FOUND';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // 🔥 FITUR BARU: Create User Profile
  Future<void> _createUserProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;

    // Dialog untuk input data
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final locationController = TextEditingController();
    bool isFarmer = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Lengkapi Profile Anda'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'No. Telepon',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi Kebun',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Saya adalah Petani'),
                  value: isFarmer,
                  onChanged: (value) {
                    setDialogState(() {
                      isFarmer = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama harus diisi')),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        // Tampilkan loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Create user document di Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'userId': user.uid,
          'email': user.email ?? '',
          'name': nameController.text.trim(),
          'phoneNumber': phoneController.text.trim(),
          'farmLocation': locationController.text.trim(),
          'isfarmer': isFarmer,
          'photoUrl': '',
          'createAt': FieldValue.serverTimestamp(),
          'updateAt': FieldValue.serverTimestamp(),
        });

        // Tutup loading
        Navigator.pop(context);

        // Reload data
        await _loadUserData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profile berhasil dibuat!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Tutup loading
        Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5FAF6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xffF5FAF6),
        title: const Text(
          "Profil Saya",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadUserData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat data profil...'),
                ],
              ),
            )
          : _errorMessage == 'DATA_NOT_FOUND'
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person_add,
                          size: 80,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Profile Belum Dibuat',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Anda perlu melengkapi data profile terlebih dahulu',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _createUserProfile,
                          icon: const Icon(Icons.add),
                          label: const Text('Buat Profile Sekarang'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadUserData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba Lagi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _userData == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.person_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text('Data tidak ditemukan'),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _loadUserData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // === PROFILE HEADER ===
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Colors.green.shade100,
                                      backgroundImage: _userData!['photoUrl'] != null &&
                                              _userData!['photoUrl'].toString().isNotEmpty
                                          ? NetworkImage(_userData!['photoUrl'])
                                          : null,
                                      child: _userData!['photoUrl'] == null ||
                                              _userData!['photoUrl'].toString().isEmpty
                                          ? const Icon(Icons.person,
                                              size: 50, color: Colors.green)
                                          : null,
                                    ),
                                    const SizedBox(height: 15),

                                    // Name
                                    Text(
                                      _userData!['name'] ?? 'Nama Pengguna',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),

                                    // Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _userData!['isfarmer'] == true
                                            ? Colors.green.shade100
                                            : Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _userData!['isfarmer'] == true
                                                ? Icons.agriculture
                                                : Icons.person,
                                            size: 16,
                                            color: _userData!['isfarmer'] == true
                                                ? Colors.green
                                                : Colors.blue,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            _userData!['isfarmer'] == true
                                                ? 'Petani'
                                                : 'Pengguna',
                                            style: TextStyle(
                                              color: _userData!['isfarmer'] == true
                                                  ? Colors.green
                                                  : Colors.blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // === INFORMASI AKUN ===
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
                                      "Informasi Akun",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 15),

                                    _infoTile(
                                      icon: Icons.email,
                                      label: "Email",
                                      value: _userData!['email'] ?? '-',
                                    ),
                                    const Divider(height: 25),

                                    _infoTile(
                                      icon: Icons.phone,
                                      label: "No. Telepon",
                                      value: _userData!['phoneNumber'] ?? '-',
                                    ),
                                    const Divider(height: 25),

                                    _infoTile(
                                      icon: Icons.location_on,
                                      label: "Lokasi Kebun",
                                      value: _userData!['farmLocation'] ?? '-',
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // === INFORMASI TAMBAHAN ===
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
                                      "Informasi Tambahan",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 15),

                                    _infoTile(
                                      icon: Icons.calendar_today,
                                      label: "Bergabung Sejak",
                                      value: _formatDate(_userData!['createAt']),
                                    ),
                                    const Divider(height: 25),

                                    _infoTile(
                                      icon: Icons.update,
                                      label: "Terakhir Diperbarui",
                                      value: _formatDate(_userData!['updateAt']),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // === MENU ACTIONS ===
                              _menuButton(
                                icon: Icons.edit,
                                label: "Edit Profil",
                                color: Colors.blue,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Fitur edit profil segera hadir'),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 10),

                              _menuButton(
                                icon: Icons.settings,
                                label: "Pengaturan",
                                color: Colors.grey,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Fitur pengaturan segera hadir'),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 10),

                              _menuButton(
                                icon: Icons.logout,
                                label: "Logout",
                                color: Colors.red,
                                onTap: _signOut,
                              ),

                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
    );
  }

  // === WIDGET HELPERS ===

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _menuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '-';
    
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return '-';
      }

      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '-';
    }
  }
}