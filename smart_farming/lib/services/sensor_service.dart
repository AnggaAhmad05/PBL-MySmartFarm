import 'package:flutter/material.dart';

class SensorData {
  final double temperature;
  final double humidity;
  final double soilMoisture;
  final double lightIntensity;
  final String timestamp;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.lightIntensity,
    required this.timestamp,
  });
}

class SensorService extends ChangeNotifier {
  // Sensor Data
  double _temperature = 28.5;
  double _humidity = 65.2;
  double _soilMoisture = 45;
  double _lightIntensity = 75;
  String _timestamp = '';

  // Getters
  double get temperature => _temperature;
  double get humidity => _humidity;
  double get soilMoisture => _soilMoisture;
  double get lightIntensity => _lightIntensity;
  String get timestamp => _timestamp;

  SensorData get sensorData => SensorData(
    temperature: _temperature,
    humidity: _humidity,
    soilMoisture: _soilMoisture,
    lightIntensity: _lightIntensity,
    timestamp: _timestamp,
  );

  SensorService() {
    _simulateSensorData();
  }

  void updateSensorData({
    required double temperature,
    required double humidity,
    required double soilMoisture,
    required double lightIntensity,
  }) {
    _temperature = temperature;
    _humidity = humidity;
    _soilMoisture = soilMoisture;
    _lightIntensity = lightIntensity;
    _timestamp = TimeOfDay.now().format(null as BuildContext);
    notifyListeners();
  }

  void _simulateSensorData() {
    Future.delayed(const Duration(seconds: 3), () {
      _temperature = 25 + (DateTime.now().millisecond % 100) / 10;
      _humidity = 60 + (DateTime.now().millisecond % 200) / 10;
      _soilMoisture = 30 + (DateTime.now().millisecond % 400) / 10;
      _lightIntensity = 50 + (DateTime.now().millisecond % 500) / 10;
      _timestamp = DateTime.now().toString().split('.')[0];
      notifyListeners();
      _simulateSensorData();
    });
  }
}
