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

  DeviceSettings({
    required this.deviceId,
    this.swapX = false,
    this.swapY = false,
  });

  DeviceSettings copyWith({
    String? deviceId,
    bool? swapX,
    bool? swapY,
  }) {
    return DeviceSettings(
      deviceId: deviceId ?? this.deviceId,
      swapX: swapX ?? this.swapX,
      swapY: swapY ?? this.swapY,
    );
  }

  DeviceSettings copyWithAndSave({
    String? deviceId,
    bool? swapX,
    bool? swapY,
  }) {
    DeviceSettings updatedSettings = copyWith(
      deviceId: deviceId,
      swapX: swapX,
      swapY: swapY,
    );
    StorageService().saveDeviceSettings(updatedSettings);
    return updatedSettings;
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'swapX': swapX,
        'swapY': swapY,
      };

  factory DeviceSettings.fromJson(Map<String, dynamic> json) => DeviceSettings(
        deviceId: json['deviceId'],
        swapX: json['swapX'],
        swapY: json['swapY'],
      );
}
