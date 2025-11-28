// lib/models/sensor_data.dart

class SensorData {
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double light;
  final double ph;

  SensorData({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.light,
    required this.ph,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      timestamp: DateTime.parse(json['timestamp']),
      temperature: (json['temperature'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? 0).toDouble(),
      light: (json['light'] ?? 0).toDouble(),
      ph: (json['ph'] ?? 6.5).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'temperature': temperature,
      'humidity': humidity,
      'light': light,
      'ph': ph,
    };
  }
}