// lib/screens/notification_history_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  String selectedFilter = 'Semua'; // Semua, Hari Ini, Minggu Ini

  // DUMMY DATA - ganti dengan Firebase
  List<Map<String, dynamic>> notifications = [
    {
      'id': '1',
      'type': 'warning',
      'title': 'Pompa Irigasi Aktif',
      'message': 'Kelembaban tanah di bawah 40%. Pompa otomatis menyala.',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
      'isRead': false,
    },
    {
      'id': '2',
      'type': 'info',
      'title': 'Jadwal Nutrisi',
      'message': 'Waktunya memberikan nutrisi hidroponik (150ml).',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'isRead': true,
    },
    {
      'id': '3',
      'type': 'warning',
      'title': 'Tanah Terlalu Kering',
      'message': 'Kelembaban tanah: 35%. Segera lakukan penyiraman.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'isRead': true,
    },
    {
      'id': '4',
      'type': 'success',
      'title': 'Penyiraman Selesai',
      'message': 'Pompa telah menyiram 20ml air. Kelembaban kembali normal.',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'isRead': true,
    },
    {
      'id': '5',
      'type': 'warning',
      'title': 'Suhu Tinggi',
      'message': 'Suhu mencapai 33°C. Pertimbangkan ventilasi.',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredNotifs = _getFilteredNotifications();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F3),
      appBar: AppBar(
        title: const Text("Riwayat Notifikasi", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _confirmClearAll,
            tooltip: "Hapus Semua",
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('Semua'),
                const SizedBox(width: 8),
                _buildFilterChip('Hari Ini'),
                const SizedBox(width: 8),
                _buildFilterChip('Minggu Ini'),
              ],
            ),
          ),

          // Notification List
          Expanded(
            child: filteredNotifs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          "Tidak ada notifikasi",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNotifs.length,
                    itemBuilder: (context, index) {
                      final notif = filteredNotifs[index];
                      return _buildNotificationCard(notif);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    final type = notif['type'];
    final icon = _getIconForType(type);
    final color = _getColorForType(type);
    final isRead = notif['isRead'];

    return Dismissible(
      key: Key(notif['id']),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        setState(() => notifications.remove(notif));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notifikasi dihapus")),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _markAsRead(notif),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRead ? Colors.grey.shade200 : color.withOpacity(0.3),
              width: isRead ? 1 : 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),

              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif['title'],
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif['message'],
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(notif['timestamp']),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'success':
        return Icons.check_circle;
      case 'info':
      default:
        return Icons.info;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes} menit lalu";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} jam lalu";
    } else if (diff.inDays < 7) {
      return "${diff.inDays} hari lalu";
    } else {
      return DateFormat('dd MMM yyyy').format(timestamp);
    }
  }

  List<Map<String, dynamic>> _getFilteredNotifications() {
    if (selectedFilter == 'Semua') return notifications;

    final now = DateTime.now();
    return notifications.where((notif) {
      final timestamp = notif['timestamp'] as DateTime;
      if (selectedFilter == 'Hari Ini') {
        return timestamp.day == now.day && timestamp.month == now.month && timestamp.year == now.year;
      } else if (selectedFilter == 'Minggu Ini') {
        return now.difference(timestamp).inDays < 7;
      }
      return true;
    }).toList();
  }

  void _markAsRead(Map<String, dynamic> notif) {
    setState(() {
      notif['isRead'] = true;
    });
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Semua Notifikasi?"),
        content: const Text("Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => notifications.clear());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Semua notifikasi dihapus")),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus Semua"),
          ),
        ],
      ),
    );
  }
}