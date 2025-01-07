import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:gamepads/gamepads.dart';
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

  // Mock focus node to listen to keyboard events
  // Needed incase other text fields are added to the screen
  final FocusNode _focusNode = FocusNode();
  final _gamePadDebouncer = Debouncer(milliseconds: 30);
  late StreamSubscription gamePadEventsSubscription;
  double _gamePadX = 0, _gamePadY = 0;
  bool _buttonPressed = false;

  Color currentColor = Colors.green;
  late Color pickerColor;
  bool swapX = false;
  bool swapY = false;

  @override
  void initState() {
    pickerColor = currentColor;
    _bleDevice = widget.deviceToConnect;
    _connectToDevice();
    gamePadEventsSubscription = Gamepads.events.listen(_onGamePadEvent);
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
        title: Text(_bleDevice.name ?? 'Rover Controls'),
        actions: [
          if (!_connecting) _buildSettings(),
        ],
      ),
      body: _connecting
          ? Center(child: Text("Connecting to device..."))
          : _buildControls(),
    );
  }

  Widget _buildControls() {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20, top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_buildGameSettings()],
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50, left: 30, right: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTapDown: (_) {
                      setState(() {
                        _buttonPressed = true;
                        _writeFireToDevice();
                      });
                    },
                    onTapUp: (_) {
                      setState(() {
                        _buttonPressed = false;
                      });
                    },
                    child: Image.asset(
                      _buttonPressed
                          ? 'assets/shark_button/down.png'
                          : 'assets/shark_button/up.png',
                      height: 100,
                      width: 100,
                    ),
                  ),
                  Joystick(
                    mode: JoystickMode.horizontalAndVertical,
                    listener: (StickDragDetails stick) {
                      _writeXYtoDevice(x: stick.x, y: stick.y);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameSettings() {
    return ElevatedButton.icon(
      icon: Icon(
        Icons.gamepad_outlined,
        color: Colors.white,
      ),
      label: Text('Game Mode'),
      onPressed: () {
        showDialog(
          useSafeArea: true,
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                scrollable: true,
                title: Text('Game Modes'),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel'),
                  )
                ],
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select a game mode to play with other rovers'),
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: 240,
                        height: 240,
                        child: GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                debugPrint('Virus mode selected');
                                MyBluetoothService().writeData('game:virus');
                                Navigator.of(context).pop();
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  //Image.asset('assets/virus.png', height: 50),
                                  Text('Virus'),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                debugPrint('Disco mode selected');
                                MyBluetoothService().writeData('game:disco');
                                Navigator.of(context).pop();
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  //Image.asset('assets/disco.png', height: 50),
                                  Text('Disco'),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                debugPrint('Hungry mode selected');
                                MyBluetoothService().writeData('game:hungry');
                                Navigator.of(context).pop();
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  //Image.asset('assets/hungry.png', height: 50),
                                  Text('Hungry'),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                debugPrint('WTF! mode selected');
                                MyBluetoothService().writeData('game:wtf');
                                Navigator.of(context).pop();
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  //Image.asset('assets/wtf.png', height: 50),
                                  Text('WTF!'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            });
          },
        );
      },
    );
  }

  Widget _buildSettings() {
    return IconButton(
      icon: Icon(
        Icons.settings,
      ),
      onPressed: () {
        showDialog(
          useSafeArea: true,
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return AlertDialog(
                  scrollable: true,
                  title: Text('Rover Settings'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rover RGB Color',
                            textAlign: TextAlign.left,
                          ),
                          _buildColorPicker(),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                            'Swap the controls for the joystick incase the motor controls are reversed.'),
                      ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Calibrate Photo Resistor'),
                          IconButton(
                            icon: Icon(Icons.support_rounded),
                            onPressed: () {
                              debugPrint('Calibrating photo resistor');
                              MyBluetoothService().writeData('calibrate');
                            },
                          ),
                        ],
                      ),
                    ],
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

  // Handler for gamepad events
  _onGamePadEvent(GamepadEvent event) {
    //debugPrint('Gamepad event: $event');
    if (event.key == 'l.joystick - yAxis') {
      _gamePadY = -event.value;
    } else if (event.key == 'l.joystick - xAxis') {
      _gamePadX = event.value;
    } else if (event.key == 'button - 0') {
      _writeFireToDevice();
    }
    // simple debouncer does not work great, its debouncing initial values when it shouldnt...
    // e.g when the joystick is at rest, and you move it, it will debounce the initial value keeping the shark from moving for a period of time
    // would need a way to record if the value has changed more than a delta
    // and then send the value to the device
    // Too low of a debounce timing, will cause commands to queue up which is bad too
    _gamePadDebouncer.run(() {
      if (_gamePadX.abs() > _gamePadY.abs()) {
        _writeXYtoDevice(x: _gamePadX, y: 0);
      } else {
        _writeXYtoDevice(x: 0, y: _gamePadY);
      }
    });
  }

  // Handler for keyboard events
  _onKeyEvent(KeyEvent event) {
    debugPrint('${event}');
    double? x;
    double? y;

    if ([
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.keyW,
    ].contains(
      event.logicalKey,
    )) {
      y = event is KeyUpEvent ? 0 : -1.0;
    } else if ([
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.keyS,
    ].contains(event.logicalKey)) {
      y = event is KeyUpEvent ? 0 : 1.0;
    } else if ([
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.keyA,
    ].contains(event.logicalKey)) {
      x = event is KeyUpEvent ? 0 : -1.0;
    } else if ([
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.keyD,
    ].contains(event.logicalKey)) {
      x = event is KeyUpEvent ? 0 : 1.0;
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      _writeFireToDevice();
      setState(() {
        _buttonPressed = event is KeyDownEvent;
      });
    }

    if (x != null || y != null) _writeXYtoDevice(x: x ?? 0, y: y ?? 0);
  }

  void _writeFireToDevice() {
    String data = 'fire';
    debugPrint('Sending to device: $data');
    MyBluetoothService().writeData(data);
  }

  // Writes directional movement to the device
  void _writeXYtoDevice({double x = 0, double y = 0}) {
    double finalX = swapX ? -x : x;
    double finalY = swapY ? -y : y;
    String data =
        'move:${finalX.toStringAsFixed(3)},${finalY.toStringAsFixed(3)}';
    debugPrint('Sending to device: $data');
    MyBluetoothService().writeData(data);
  }

  @override
  void dispose() {
    MyBluetoothService().disconnect();
    UniversalBle.onConnectionChange = null;
    gamePadEventsSubscription.cancel();
    super.dispose();
  }
}

int _floatToInt8(double x) {
  return (x * 255.0).round() & 0xff;
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;
  Debouncer({required this.milliseconds});
  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
