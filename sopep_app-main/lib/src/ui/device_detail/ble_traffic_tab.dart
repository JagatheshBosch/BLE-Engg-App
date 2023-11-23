// Copyright (c) 2023, StarIC, author: Justin Y. Kim

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:convert/convert.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';

import 'package:sopep_app/constants.dart';
import 'package:sopep_app/src/ble/ble_interactor.dart';
import 'package:sopep_app/src/ble/ble_sopep_interactor.dart';

class BleTrafficTab extends StatelessWidget {
  final DiscoveredDevice device;

  const BleTrafficTab({
    required this.device,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Consumer2<BleInteractor, ConnectionStateUpdate>(
        builder: (_, bleInteractor, connectionStateUpdate, __) =>
            _BleTrafficTab(
          deviceId: device.id,
          deviceMfrId:
              hex.encode(device.manufacturerData).toUpperCase().toString(),
          connectableStatus: device.connectable,
          connectionStatus: connectionStateUpdate.connectionState,
          bleInteractor: bleInteractor,
        ),
      );
}

class _BleTrafficTab extends StatefulWidget {
  const _BleTrafficTab({
    required this.deviceId,
    required this.deviceMfrId,
    required this.connectableStatus,
    required this.connectionStatus,
    required this.bleInteractor,
    Key? key,
  }) : super(key: key);

  final String deviceId;
  final String deviceMfrId;
  final Connectable connectableStatus;
  final DeviceConnectionState connectionStatus;
  final BleInteractor bleInteractor;
  DeviceConnectionState get deviceConnectionStatus => connectionStatus;

  @override
  _BleTrafficTabState createState() => _BleTrafficTabState();
}

class _BleTrafficTabState extends State<_BleTrafficTab> {
  BleSopepInteractor? _sopepInteractor;
  StreamSubscription<BleSopepResponseData>? _sopepStreamSubscription;
  Timer? testMonitorTimer;
  Map<Object, Object> _cborCmd = {'cmd': 'echo-test'};
  late final int totalTxPacketSize;
  late final int maxTxEchoSizeBytes;
  bool _startTestFlag = false;
  int _packetCounter = 0;
  int _timeCounterSeconds = 0;
  double _packetsPerSecond = 0.0;
  int _totalTxBytes = 0;
  int _totalRxBytes = 0;
  double _totalTxBytesPerSecond = 0;
  double _totalRxBytesPerSecond = 0;

  @override
  void initState() {
    totalTxPacketSize = widget.bleInteractor.geMtuBytes();
    maxTxEchoSizeBytes =
        totalTxPacketSize - BLE_CMD_ECHO_BYTES - BLE_ATT_HEADER_BYTES;
    if (widget.deviceConnectionStatus == DeviceConnectionState.connected) {
      _subscribeCharacteristic();
      _sopepInteractor = widget.bleInteractor.getSopepInteractor();
    }

    super.initState();
  }

  @override
  void dispose() {
    _sopepStreamSubscription!.cancel();
    testMonitorTimer?.cancel();
    _sopepInteractor!.setEnableLogging(true);

    super.dispose();
  }

  Future<void> _subscribeCharacteristic() async {
    _sopepStreamSubscription = widget.bleInteractor
        .getSopepInteractor()
        .getSopepStreamController()
        .stream
        .listen((bleSopepResponseData) {
      // Got new data; update our response text display
      setState(() {
        if (_startTestFlag) {
          // Add to our RX packet counter and calculate RX params
          _packetCounter++;
          _packetsPerSecond = _packetCounter / _timeCounterSeconds;
          _totalRxBytes += bleSopepResponseData.dataMapBytes;
          _totalRxBytesPerSecond = _totalRxBytes / _timeCounterSeconds;

          // Re-send TX packet to loop again
          _sopepInteractor!.sendEchoTest(215);
          _totalTxBytes += totalTxPacketSize;
          _totalTxBytesPerSecond = _totalTxBytes / _timeCounterSeconds;
        }
      });
    });
  }

  void _startTest() {
    // Reset all test variables
    _startTestFlag = true;
    _packetCounter = 0;
    _timeCounterSeconds = 0;
    _packetsPerSecond = 0;
    _totalTxBytes = 0;
    _totalRxBytes = 0;
    _totalTxBytesPerSecond = 0;
    _totalRxBytesPerSecond = 0;

    // Disable BLE TX/RX logging and start the initial TX packet
    _sopepInteractor!.setEnableLogging(false);
    _sopepInteractor!.sendEchoTest(215);
    _totalTxBytes += totalTxPacketSize;
    _totalTxBytesPerSecond = _totalTxBytes / _timeCounterSeconds;

    testMonitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startTestFlag) {
        _sopepInteractor!.sendEchoTest(215);
        _totalTxBytes += totalTxPacketSize;
        _totalTxBytesPerSecond = _totalTxBytes / _timeCounterSeconds;
        _timeCounterSeconds++;
      } else {
        timer.cancel();
      }

      if (widget.deviceConnectionStatus == DeviceConnectionState.disconnected) {
        _startTestFlag = false;
      }
    });
  }

  Widget _widgetDisplayData(String text, Object val) {
    String valStr = val.toString();

    // Adjust the decimal place to 2 if it's double
    if (val is double) {
      double valDobule = val;
      valStr = valDobule.toStringAsFixed(2);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 25.0),
          child: Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 6.0),
          child: Text(
            valStr,
            style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _widgetDisplayDataTwo(String text, Object val0, Object val1) {
    String valStr0 = val0.toString();
    String valStr1 = val1.toString();

    // Adjust the decimal place to 2 if it's double
    if ((val0 is double) && (val1 is double)) {
      double valDobule0 = val0;
      double valDobule1 = val1;
      valStr0 = valDobule0.toStringAsFixed(2);
      valStr1 = valDobule1.toStringAsFixed(2);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 25.0),
          child: Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 6.0),
          child: Text(
            valStr0 + ' /\n' + valStr1,
            style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate.fixed(
              [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ((widget.deviceConnectionStatus ==
                              DeviceConnectionState.disconnected) ||
                          (_sopepStreamSubscription == null))
                      ? [
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                                start: 20.0, top: 20.0, end: 20.0),
                            child: Text(
                              "Please connect/subscribe to the device...",
                              style: const TextStyle(
                                  fontSize: 30, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ]
                      : [
                          Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(top: 20.0),
                              child: !_startTestFlag
                                  ? Text(
                                      "Press start to begin the BLE traffic test",
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    )
                                  : Text(
                                      "Sending TX cmd: $_cborCmd",
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    )),
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 3,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                  start: 2.0, top: 8.0, end: 16.0),
                              child: widget.deviceConnectionStatus ==
                                      DeviceConnectionState.connecting
                                  ? ElevatedButton(
                                      onPressed: null,
                                      child: Text('Starting'),
                                    )
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: !_startTestFlag
                                              ? Color.fromARGB(255, 52, 203, 72)
                                              : Color.fromARGB(
                                                  255, 255, 73, 73)),
                                      onPressed: () {
                                        setState(() {
                                          if (!_startTestFlag) {
                                            _startTest();
                                          } else {
                                            _startTestFlag = false;
                                            _sopepInteractor!
                                                .setEnableLogging(true);
                                          }
                                        });
                                      },
                                      child: !_startTestFlag
                                          ? Text('Start')
                                          : Text('Stop'),
                                    ),
                            ),
                          ),
                          //---
                          _widgetDisplayData(
                              "Total TX->RX Packets:", _packetCounter),
                          _widgetDisplayData(
                              "Packets per Second:", _packetsPerSecond),
                          _widgetDisplayDataTwo("Total Bytes Sent/Received:",
                              _totalTxBytes, _totalRxBytes),
                          _widgetDisplayDataTwo(
                              "Bytes per Second Sent/Received:",
                              _totalTxBytesPerSecond,
                              _totalRxBytesPerSecond),
                          _widgetDisplayData("Total Test Time in Seconds:",
                              _timeCounterSeconds),
                        ],
                ),
              ],
            ),
          ),
        ],
      );
}
