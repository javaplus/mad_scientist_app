import 'package:flutter/material.dart';
import 'package:mad_scientist_app/screens/scan_device_screen.dart';
import 'package:mad_scientist_app/services/bluetooth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _hasBluetoothPermissions = true;
  bool _isBluetoothReady = false;
  final deviceController = TextEditingController();

  @override
  initState() {
    _initiateBluetooth();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mad Scientist App'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 24.0, left: 30, right: 30),
          child: _hasBluetoothPermissions
              ? (_isBluetoothReady
                  ? _buildBluetoothReady()
                  : _buildBluetoothLoading())
              : Text(
                  'Bluetooth/nearby devices permission missing... Please enable them in settings and re-launch the app.'),
        ),
      ),
    );
  }

  Widget _buildBluetoothReady() {
    return Column(
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          height: 50,
          child: TextField(
            autofocus: false,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter device name or leave blank',
            ),
            controller: deviceController,
            onSubmitted: (value) => _findDevice(),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: 5),
          width: double.infinity,
          child: ElevatedButton(
            child: const Text(
              'Find Devices',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => _findDevice(),
          ),
        ),
      ],
    );
  }

  Widget _buildBluetoothLoading() {
    return const Text(
      'Bluetooth Module Loading...',
    );
  }

  _initiateBluetooth() async {
    await MyBluetoothService().initBLE((MyBleState state) {
      setState(() {
        if (state == MyBleState.poweredOn) {
          _isBluetoothReady = true;
        } else if (state == MyBleState.unauthorized) {
          _isBluetoothReady = false;
          _hasBluetoothPermissions = false;
        } else if (state == MyBleState.unsupported) {
          //TODO: Message to the user, that BLE is not supported...
          _isBluetoothReady = false;
        } else {
          //TODO: Message to the user that bluetooth is either turned off,
          // or not allowed for this app
          _isBluetoothReady = false;
        }
      });
    });

    // TODO: Timeout timer if it never becomes available... show an error asking user to verify bluetooth is enabled and relaunch the app
  }

  _findDevice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanDeviceScreen(
          deviceName: deviceController.text,
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
