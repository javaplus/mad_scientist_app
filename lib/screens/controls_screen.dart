import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
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

  Color currentColor = Colors.green;
  late Color pickerColor;
  bool swapX = false;
  bool swapY = false;

  @override
  void initState() {
    pickerColor = currentColor;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Control Shark Rover'),
      ),
      body: _connecting
          ? Center(child: Text("Connecting to device..."))
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildReverseSwitch(),
                      _buildColorPicker(),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 50, right: 30),
                    child: Joystick(
                      mode: JoystickMode.horizontalAndVertical,
                      listener: (StickDragDetails stick) {
                        //debugPrint('Joystick: ${stick.x.toStringAsFixed(5)},${stick.y.toStringAsFixed(5)}');

                        double x = swapX ? -stick.x : stick.x;
                        double y = swapY ? -stick.y : stick.y;
                        MyBluetoothService().writeData(
                            'move:${x.toStringAsFixed(5)},${y.toStringAsFixed(5)}');
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildReverseSwitch() {
    return IconButton(
      icon: Icon(Icons.multiple_stop),
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return SingleChildScrollView(
                      child: Column(
                    children: [
                      Text(
                          'Swap the controls for the joystick incase the motor controls are reversed.'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Swap Left/Right'),
                          Switch(
                            value: swapX,
                            onChanged: (value) {
                              setState(() {
                                swapX = value;
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Swap Front/Back'),
                          Switch(
                            value: swapY,
                            onChanged: (value) {
                              setState(() {
                                swapY = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ));
                },
              ),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildColorPicker() {
    return IconButton(
      icon: Stack(
        children: [
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: <Color>[
                  Colors.red,
                  Colors.orange,
                  Colors.yellow,
                  Colors.green,
                  Colors.blue,
                  Colors.indigo,
                  Colors.purple
                ],
              ).createShader(bounds);
            },
            child: Icon(Icons.palette),
          ),
          Icon(Icons.palette_outlined, color: Colors.black38)
        ],
      ),
      iconSize: 45,
      color: Colors.white,
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: SingleChildScrollView(
                child: ColorPicker(
                    hexInputBar: false,
                    portraitOnly: false,
                    paletteType: PaletteType.hueWheel,
                    labelTypes: [],
                    enableAlpha: false,
                    pickerColor: pickerColor,
                    onColorChanged: (Color color) {
                      setState(() => pickerColor = color);
                    }),
              ),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () {
                    try {
                      String rgbData =
                          'rgb:${_floatToInt8(pickerColor.r)},${_floatToInt8(pickerColor.g)},${_floatToInt8(pickerColor.b)}';
                      debugPrint(rgbData);
                      MyBluetoothService().writeData(rgbData);
                      setState(() => currentColor = pickerColor);
                    } catch (e) {
                      Logger().e("Failed to send color", error: e);
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    MyBluetoothService().disconnect();
    UniversalBle.onConnectionChange = null;
    super.dispose();
  }
}

int _floatToInt8(double x) {
  return (x * 255.0).round() & 0xff;
}
