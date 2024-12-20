import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:logger/logger.dart';
import 'package:mad_scientist_app/services/bluetooth_service.dart';
import 'package:universal_ble/universal_ble.dart';

class ControlsScreen extends StatefulWidget {
  const ControlsScreen({super.key, required this.deviceToConnect});

  final BleDevice deviceToConnect;

  @override
  State<ControlsScreen> createState() => _ControlsScreenScreenState();
}

class _ControlsScreenScreenState extends State<ControlsScreen> {
  bool _connecting = true;
  late BleDevice _bleDevice;
  List<BleService> services = [];

  @override
  void initState() {
    _bleDevice = widget.deviceToConnect;

    _connectToDevice();
    super.initState();
  }

  _connectToDevice() async {
    try {
      services = await MyBluetoothService().connect(_bleDevice);
    } catch (e) {
      // TODO: POP AN ALERT FOR FAILED CONNECTION....
      Logger().e("Failed to connect to device $_bleDevice", error: e);
    }
    setState(() {
      _connecting = false;
    });
  }

  void _onForwardPressed() {
    print("Moving robot forward");
    MyBluetoothService().writeData('forward');
  }

  void _onLeftPressed() {
    print("Moving robot left");
    MyBluetoothService().writeData('left');
  }

  void _onRightPressed() {
    print("Moving robot right");
    MyBluetoothService().writeData('right');
  }

  void _onBackwardPressed() {
    print("Moving robot backward");
    MyBluetoothService().writeData('backward');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Robot Control'),
      ),
      body: _connecting
          ? Center(child: Text("Connecting to device..."))
          : Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(50),
                child: Joystick(
                  mode: JoystickMode.horizontalAndVertical,
                  listener: (StickDragDetails stick) {
                    //debugPrint('Joystick: ${stick.x}, ${stick.y}');
                    if (stick.x > 0) {
                      _onRightPressed();
                    } else if (stick.x < 0) {
                      _onLeftPressed();
                    } else if (stick.y > 0) {
                      _onBackwardPressed();
                    } else if (stick.y < 0) {
                      _onForwardPressed();
                    }
                  },
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    MyBluetoothService().disconnect();
    UniversalBle.onConnectionChange = null;
    super.dispose();
  }
}
