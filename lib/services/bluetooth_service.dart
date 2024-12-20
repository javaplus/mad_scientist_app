import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_ble/universal_ble.dart';

class MyBluetoothService {
  static MyBluetoothService? _singleton;
  factory MyBluetoothService() {
    return _singleton ??= MyBluetoothService._internal();
  }
  MyBluetoothService._internal() {
    UniversalBle.onAvailabilityChange = (state) {
      debugPrint("BLE State receieved: $state");
      if (bleStateCallback != null) {
        bleStateCallback!(MyBleState.fromAvailabilityState(state));
      }
    };
    UniversalBle.onConnectionChange =
        (String deviceId, bool isConnected, String? error) {
      debugPrint(
          'BLE OnConnectionChange $deviceId, $isConnected Error: $error');
    };
  }

  static const String SERVICE_UUID = '181A';
  static const String CHARACTERISTIC_UUID = '2A6E';

  // callback for whenever the ble module changes state
  Function(MyBleState)? bleStateCallback;

  // ble device we are currently connected to
  BleDevice? device;
  List<BleService> services = [];

  /// Attempt to connect to and enable the bluetooth adapter.
  /// Must be done before any bluetooth capabilities can be used.
  /// callback can be supplied for when the availability changes.
  Future<void> initBLE(Function(MyBleState) callback) async {
    bleStateCallback = callback;

    // Check for android permissions...

    // Android is lame, and needs special code and permission request... :(
    if (Platform.isAndroid) {
      if (!await Permission.bluetoothScan.request().isGranted) {
        return callback(MyBleState.unauthorized);
      }
      if (!await Permission.bluetoothConnect.request().isGranted) {
        return callback(MyBleState.unauthorized);
      }
      try {
        await UniversalBle.enableBluetooth();
      } catch (e) {
        debugPrint("Failed to enable Android bluetooth: $e");
      }
    }
    AvailabilityState state = await getBluetoothAvailability();
    callback(MyBleState.fromAvailabilityState(state));
  }

  /// Return the current state of the bluetooth adapter.
  Future<AvailabilityState> getBluetoothAvailability() async {
    return await UniversalBle.getBluetoothAvailabilityState();
  }

  Future<void> startScanning() async {
    await UniversalBle.startScan(
      scanFilter: ScanFilter(
        withServices: [SERVICE_UUID],
      ),
    );
  }

  Future<List<BleService>> connect(BleDevice bleDevice) async {
    await UniversalBle.connect(bleDevice.deviceId);
    device = bleDevice;
    services = await UniversalBle.discoverServices(device!.deviceId);
    debugPrint('Services: $services');
    debugPrint('Characteristics: ${services.first.characteristics}');
    return services;
  }

  Future<void> writeData(
    String value, {
    String serviceUUID = SERVICE_UUID,
    String characteristicUUID = CHARACTERISTIC_UUID,
  }) async {
    await UniversalBle.writeValue(
      device!.deviceId,
      BleUuidParser.string(serviceUUID),
      BleUuidParser.string(characteristicUUID),
      utf8.encode(value),
      BleOutputProperty.withResponse,
    );
  }

  Future<void> disconnect() async {
    debugPrint("Disconnecting device ${device?.deviceId}");
    try {
      UniversalBle.disconnect(device!.deviceId);
    } catch (e) {
      Logger().e("Failed to cleanly disconnect from device $device", error: e);
    }
  }
}

enum MyBleState {
  unknown,
  resetting,
  unsupported,
  unauthorized,
  poweredOff,
  poweredOn;

  const MyBleState();

  factory MyBleState.fromAvailabilityState(AvailabilityState state) {
    switch (state) {
      case AvailabilityState.poweredOn:
        return poweredOn;
      case AvailabilityState.poweredOff:
        return poweredOff;
      case AvailabilityState.unauthorized:
        return unauthorized;
      case AvailabilityState.unsupported:
        return unsupported;
      default:
        return unknown;
    }
  }
}
