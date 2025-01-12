// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _singleton = StorageService._internal();
  factory StorageService() => _singleton;
  StorageService._internal();

  late SharedPreferences prefs;
  static const String KEY_DEVICE_SETTINGS = 'device_settings';

  Future<void> initializeSorageRepository() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveDeviceSettings(DeviceSettings deviceSetting) async {
    List<String> deviceSettingsList =
        prefs.getStringList(KEY_DEVICE_SETTINGS) ?? [];

    bool found = false;

    // Look for and replace the deviceSettings if found
    for (int i = 0; i < deviceSettingsList.length; i++) {
      Map<String, dynamic> existingDeviceSettingJson =
          Map<String, dynamic>.from(jsonDecode(deviceSettingsList[i]));
      if (existingDeviceSettingJson['deviceId'] == deviceSetting.deviceId) {
        deviceSettingsList[i] = jsonEncode(deviceSetting.toJson());
        found = true;
        break;
      }
    }

    // if we never found device settings, lets add it
    if (!found) {
      deviceSettingsList.add(jsonEncode(deviceSetting.toJson()));
    }

    await prefs.setStringList(KEY_DEVICE_SETTINGS, deviceSettingsList);
  }

  DeviceSettings getDeviceSettings(String deviceId) {
    List<DeviceSettings> deviceSettingsList = getDeviceSettingsList();

    for (DeviceSettings deviceSetting in deviceSettingsList) {
      if (deviceSetting.deviceId == deviceId) {
        return deviceSetting;
      }
    }
    DeviceSettings newDeviceSettings = DeviceSettings(deviceId: deviceId);
    saveDeviceSettings(newDeviceSettings);
    return newDeviceSettings;
  }

  List<DeviceSettings> getDeviceSettingsList() {
    List<String> deviceSettingsList =
        prefs.getStringList(KEY_DEVICE_SETTINGS) ?? [];
    return deviceSettingsList
        .map((deviceSetting) =>
            DeviceSettings.fromJson(jsonDecode(deviceSetting)))
        .toList();
  }
}

class DeviceSettings {
  final String deviceId;
  final bool swapX;
  final bool swapY;
  final int resistorSensitivity;
  final double trimAdjustment;

  static const int DEFAULT_RESISTOR_SENSITIVITY = 5;
  static const double DEFAULT_TRIM_ADJUSTMENT = 0.0;

  DeviceSettings({
    required this.deviceId,
    this.swapX = false,
    this.swapY = false,
    this.resistorSensitivity = DEFAULT_RESISTOR_SENSITIVITY,
    this.trimAdjustment = DEFAULT_TRIM_ADJUSTMENT,
  });

  DeviceSettings copyWith({
    String? deviceId,
    bool? swapX,
    bool? swapY,
    int? resistorSensitivity,
    double? trimAdjustment,
  }) {
    return DeviceSettings(
      deviceId: deviceId ?? this.deviceId,
      swapX: swapX ?? this.swapX,
      swapY: swapY ?? this.swapY,
      resistorSensitivity: resistorSensitivity ?? this.resistorSensitivity,
      trimAdjustment: trimAdjustment ?? this.trimAdjustment,
    );
  }

  DeviceSettings copyWithAndSave({
    String? deviceId,
    bool? swapX,
    bool? swapY,
    int? resistorSensitivity,
    double? trimAdjustment,
  }) {
    DeviceSettings updatedSettings = copyWith(
      deviceId: deviceId,
      swapX: swapX,
      swapY: swapY,
      resistorSensitivity: resistorSensitivity,
      trimAdjustment: trimAdjustment,
    );
    StorageService().saveDeviceSettings(updatedSettings);
    return updatedSettings;
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'swapX': swapX,
        'swapY': swapY,
        'resistorSensitivity': resistorSensitivity,
        'trimAdjustment': trimAdjustment,
      };

  factory DeviceSettings.fromJson(Map<String, dynamic> json) => DeviceSettings(
        deviceId: json['deviceId'],
        swapX: json['swapX'] ?? false,
        swapY: json['swapY'] ?? false,
        resistorSensitivity:
            json['resistorSensitivity'] ?? DEFAULT_RESISTOR_SENSITIVITY,
        trimAdjustment: json['trimAdjustment'] ?? DEFAULT_TRIM_ADJUSTMENT,
      );
}
