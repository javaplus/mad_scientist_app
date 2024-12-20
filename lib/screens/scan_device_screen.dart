// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mad_scientist_app/screens/controls_screen.dart';
import 'package:mad_scientist_app/services/bluetooth_service.dart';
import 'package:universal_ble/universal_ble.dart';

class ScanDeviceScreen extends StatefulWidget {
  const ScanDeviceScreen({super.key, this.deviceName = ""});

  final String deviceName;

  @override
  State<ScanDeviceScreen> createState() => _ScanDeviceScreenState();
}

class _ScanDeviceScreenState extends State<ScanDeviceScreen>
    with SingleTickerProviderStateMixin {
  static const _maxScanTime = 10;

  bool isScanning = true;
  List<BleDevice> scanResults = [];

  late AnimationController _animationController;
  late Animation<double> _animation;
  late Future _scanTimeoutFuture;

  @override
  void initState() {
    _scanForDevices();

    // TODO: Timer, if no results after _maxScanTime return to failed results...
    //or screen with retry? or go back to homepage?
    super.initState();

    _animationController = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this)
      ..repeat();

    _animation =
        Tween<double>(begin: 0.0, end: 2 * pi).animate(_animationController);
  }

  _scanForDevices() async {
    debugPrint('Scanning for devices with name ${widget.deviceName}');

    setState(() {
      isScanning = true;
      scanResults.clear();
    });
    MyBluetoothService().startScanning();

    UniversalBle.onScanResult = (BleDevice bleDevice) {
      // Add any new devices to the list
      String bleDeviceName = bleDevice.name ?? "Unknown Device...";
      if (bleDeviceName
              .toLowerCase()
              .contains(widget.deviceName.toLowerCase()) &&
          !scanResults.any((existingDevice) =>
              existingDevice.deviceId == bleDevice.deviceId)) {
        setState(() {
          debugPrint('Found device: $bleDevice');
          scanResults.add(bleDevice);
        });
      }
    };

    // Wait x amount of time and stop scan
    _scanTimeoutFuture =
        Future.delayed(Duration(seconds: _maxScanTime)).then((onValue) {
      setState(() {
        UniversalBle.stopScan();
        isScanning = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mad Scientist Devices'),
        centerTitle: true,
        actions: [
          isScanning
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AnimatedBuilder(
                      animation: _animation,
                      builder: (BuildContext context, Widget? child) {
                        return Transform.rotate(
                          angle: _animation.value,
                          child: const Icon(
                            Icons.refresh,
                            color: Colors.grey,
                          ),
                        );
                      }),
                )
              : IconButton(
                  icon: const Icon(
                    Icons.refresh,
                  ),
                  onPressed: () {
                    _scanForDevices();
                  },
                ),
        ],
        shape: const Border(
          bottom: BorderSide(
            color: Color.fromARGB(255, 215, 215, 215),
            width: 1,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Builder(
                builder: (BuildContext context) {
                  if (scanResults.isEmpty) {
                    if (isScanning) {
                      return Container(
                        alignment: Alignment.topCenter,
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      );
                    }
                    // TODO:
                    // - Display the filter name,
                    // - offer to remove the filter if one exists
                    // - offer a rescan button
                    return Container(
                        alignment: Alignment.topCenter,
                        padding: EdgeInsets.all(20),
                        child: Text('No devices found....'));
                  }

                  return _buildDeviceList();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    return ListView.separated(
      itemBuilder: (context, index) {
        BleDevice bleDevice = scanResults[index];
        return Container(
            padding: const EdgeInsets.only(top: 12, left: 20, right: 20),
            child: Row(children: [
              Text(bleDevice.name ?? "Unknown device..."),
              const Expanded(child: SizedBox()),
              ElevatedButton(
                child: Text('Connect'),
                onPressed: () async => await _connectToDevice(bleDevice),
              )
            ]));
      },
      separatorBuilder: (context, int index) {
        return const Divider();
      },
      itemCount: scanResults.length,
    );
  }

  _connectToDevice(BleDevice bleDevice) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ControlsScreen(deviceToConnect: bleDevice),
      ),
    );
  }

  @override
  void dispose() {
    _scanTimeoutFuture.ignore();
    _animationController.dispose();
    UniversalBle.stopScan();
    super.dispose();
  }
}
