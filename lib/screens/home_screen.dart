// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mad_scientist_app/screens/controls_screen.dart';
import 'package:mad_scientist_app/services/bluetooth_service.dart';
import 'package:universal_ble/universal_ble.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _deviceNameController = TextEditingController();
  static final Color blueToothBlue = Color.fromRGBO(0, 130, 252, 1);
  static final Duration scanTimeout = Duration(seconds: 30);

  // Widget States
  // 1. Bluetooth is initializing
  // 2. Bluetooth is ready
  // 3. Bluetooth is scanning for devices
  bool _bluetoothInitiating = true;
  bool _isBluetoothReady = false;
  bool _isScanning = false;
  bool _scanTimedOut = false;
  late Timer _scanTimeoutTimer;

  List<BleDevice> scanResults = [];
  List<BleDevice> filteredScanResults = [];
  String deviceName = "";

  @override
  void initState() {
    // Initialize the bluetooth service and obtain a callback for when the state changes
    MyBluetoothService().initBLE((MyBleState state) {
      setState(() {
        _bluetoothInitiating = false;
        _isBluetoothReady = (state == MyBleState.poweredOn);
      });
      if (_isBluetoothReady) {
        _scanForDevices();
      }
    });

    UniversalBle.onScanResult = (BleDevice bleDevice) {
      _scanTimeoutTimer.cancel(); // clear the timeout for scanning
      _scanTimedOut = false;
      if (!scanResults.any(
          (existingDevice) => existingDevice.deviceId == bleDevice.deviceId)) {
        setState(() {
          debugPrint('Found device: $bleDevice');
          scanResults.add(bleDevice);
        });
      }
    };

    super.initState();

    _setupAnimations();

    // listen for changes to input text for device name filter
    _deviceNameController.addListener(
      () => setState(() => deviceName = _deviceNameController.text),
    );

    // setup callback for timer
    _startScanTimer().cancel();
  }

  @override
  Widget build(BuildContext context) {
    filteredScanResults = scanResults
        .where((element) =>
            element.name?.toLowerCase().contains(deviceName.toLowerCase()) ??
            false)
        .toList();
    String bluetoothModuleFailedMessage =
        'This device does not support bluetooth or the required permissions are missing... Please enable bluetooth permissions in settings and re-launch the app.';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mad Scientist Controller'),
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(
            color: Color.fromARGB(255, 215, 215, 215),
            width: 1,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: _bluetoothInitiating
            ? _buildBluetoothLoading()
            : _isBluetoothReady
                ? _buildScanner()
                : _bluetoothFailed(bluetoothModuleFailedMessage),
      ),
    );
  }

  Widget _buildBluetoothLoading() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: const Text('Bluetooth Module Loading...'),
    );
  }

  Widget _bluetoothFailed(String bluetoothModuleFailedMessage) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Text(bluetoothModuleFailedMessage),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        // INPUT: Scan for devices
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            border: Border(
              bottom: BorderSide(
                  width: 1,
                  color: Theme.of(context).colorScheme.shadow.withAlpha(100)),
            ),
          ),
          padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
          child: Column(
            children: [
              Row(
                children: [
                  _isScanning
                      ? AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform(
                              transform: Matrix4.rotationY(
                                  _animationController.value * 2 * pi),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.bluetooth,
                                color: blueToothBlue,
                              ),
                            );
                          },
                        )
                      : Icon(
                          Icons.bluetooth,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withAlpha(100),
                        ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 2),
                    child: Text(
                      'Scan for devices',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(child: SizedBox.shrink()),
                  CupertinoSwitch(
                    activeTrackColor: blueToothBlue,
                    value: _isScanning,
                    onChanged: (bool value) {
                      setState(() {
                        if (value) {
                          _scanForDevices();
                        } else {
                          _stopScan();
                        }
                      });
                    },
                  ),
                ],
              ),
              // INPUT: Find device by name
              Container(
                padding: const EdgeInsets.only(
                  left: 0,
                  right: 3,
                  bottom: 16,
                  top: 6,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        autofocus: false,
                        controller: _deviceNameController,
                        decoration: InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                          border: OutlineInputBorder(),
                          hintText: 'Filter by device name',
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerLowest,
                          filled: true,
                          suffixIcon: _deviceNameController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () =>
                                      _deviceNameController.clear(),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (scanResults.isEmpty && _scanTimedOut)
          Container(
              alignment: Alignment.topCenter,
              padding: EdgeInsets.all(20),
              child: Text(
                  'No devices found... \n\nSwitch the Shark Rover on and verify the light is blinking blue.\n\nVerify \'Scan for devices\' is toggled on above.')),

        _buildDeviceList(),
      ],
    );
  }

  Widget _buildDeviceList() {
    return Expanded(child: Builder(builder: (BuildContext context) {
      return ListView.separated(
        padding: EdgeInsets.only(
            top: 8), // matches half the default size of Divider()
        itemBuilder: (context, index) {
          // The loading indicator last
          if (index == filteredScanResults.length) {
            if (_isScanning) {
              return _buildScanningForDevices();
            } else {
              return SizedBox();
            }
          } else {
            BleDevice bleDevice = filteredScanResults[index];
            return Container(
                padding: const EdgeInsets.only(top: 0, left: 20, right: 20),
                child: Row(children: [
                  Text(bleDevice.name ?? "Unknown device..."),
                  const Expanded(child: SizedBox()),
                  ElevatedButton(
                    child: Text('Connect'),
                    onPressed: () async => await _connectToDevice(bleDevice),
                  )
                ]));
          }
        },
        separatorBuilder: (context, int index) {
          if (filteredScanResults.length == index) {
            return SizedBox.fromSize();
          }
          return const Divider();
        },
        itemCount: filteredScanResults.length + 1,
      );
    }));
  }

  Container _buildScanningForDevices() {
    bool foundDevice = filteredScanResults.isNotEmpty;
    Color textColor = foundDevice
        ? Theme.of(context).colorScheme.onSurface.withAlpha(120)
        : blueToothBlue;

    return Container(
      padding: const EdgeInsets.only(top: 18, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              foundDevice
                  ? '${filteredScanResults.length} rover${filteredScanResults.length == 1 ? '' : 's'} found, scanning for more'
                  : 'Scanning for shark rovers',
              style: TextStyle(
                color: textColor,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  return Transform.translate(
                    offset: Offset(
                      5,
                      -4.5 +
                          -3 *
                              sin(
                                _animationController.value * 2 * pi -
                                    (index * pi / 3),
                              ),
                    ),
                    child: Text(
                      '.',
                      style: TextStyle(
                        fontSize: 20,
                        color: textColor,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  _scanForDevices() async {
    debugPrint('Scanning for devices with name $deviceName');
    setState(() {
      _isScanning = true;
      _startScanTimer();
      scanResults.clear();
    });
    MyBluetoothService().startScanning();
  }

  _connectToDevice(BleDevice bleDevice) async {
    _stopScan();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ControlsScreen(deviceToConnect: bleDevice),
      ),
    );
  }

  _stopScan() {
    UniversalBle.stopScan();
    _isScanning = false;
    _scanTimeoutTimer.cancel();
  }

  Timer _startScanTimer() {
    _scanTimedOut = false;
    return _scanTimeoutTimer = Timer(
      scanTimeout,
      () => setState(() => _scanTimedOut = true),
    );
  }

  void _setupAnimations() {
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 750), vsync: this)
      ..repeat();

    Tween<double>(begin: 0.0, end: 2 * pi).animate(_animationController);
  }

  @override
  void dispose() {
    //_scanTimeoutFuture.ignore();
    _animationController.dispose();
    _deviceNameController.dispose();
    _scanTimeoutTimer.cancel();
    _stopScan();
    super.dispose();
  }
}

enum ViewToggles { list, map }
