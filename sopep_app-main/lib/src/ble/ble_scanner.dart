// Copyright (c) 2023, StarIC, author: Justin Y. Kim
// Copyright (c) 2023, authors of flutter_reactive_ble

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:sopep_app/constants.dart';
import 'package:sopep_app/src/ble/reactive_state.dart';
import 'package:meta/meta.dart';

class BleScanner implements ReactiveState<BleScannerState> {
  BleScanner({
    required FlutterReactiveBle ble,
    required Function(String message) logMessage,
  })  : _ble = ble,
        _logMessage = logMessage;

  final FlutterReactiveBle _ble;
  final void Function(String message) _logMessage;
  final StreamController<BleScannerState> _stateStreamController =
      StreamController();

  final _devices = <DiscoveredDevice>[];

  @override
  Stream<BleScannerState> get state => _stateStreamController.stream;

  bool memEquals(Uint8List bytes0, Uint8List bytes1) {
    // Complete basic initial checks
    if (identical(bytes0, bytes1)) {
      return true;
    }
    if (bytes0.lengthInBytes != bytes1.lengthInBytes) {
      return false;
    }

    // Treat the original byte lists as lists of 8-byte words
    var numWords = bytes0.lengthInBytes ~/ 8;
    var words1 = bytes0.buffer.asUint64List(0, numWords);
    var words2 = bytes1.buffer.asUint64List(0, numWords);

    for (var i = 0; i < words1.length; i += 1) {
      if (words1[i] != words2[i]) {
        return false;
      }
    }

    // Compare any remaining bytes
    for (var i = words1.lengthInBytes; i < bytes0.lengthInBytes; i += 1) {
      if (bytes0[i] != bytes1[i]) {
        return false;
      }
    }

    return true;
  }

  void startScan() {
    _logMessage('[BLE] Start ble discovery');
    _devices.clear();
    _subscription?.cancel();
    // NOTE: Known bug (found on S21) where if service UUID is provided into scanForDevices
    //       function for argument withServices: [], then the sOPEP device never shows on
    //       if the S21 phone had the device paired previously. Thus, the filtering is
    //       placed inside the scan callback function with the if statement below.
    _subscription = _ble.scanForDevices(withServices: []).listen((device) {
      if (device.serviceUuids.contains(Uuid.parse(SOPEP_SERVICE_UUID))) {
        final knownDeviceIndex = _devices.indexWhere(
            (d) => memEquals(d.manufacturerData, device.manufacturerData));
        if (knownDeviceIndex >= 0) {
          _devices[knownDeviceIndex] = device;
        } else {
          _devices.add(device);
        }
        _pushState();
      }
    },
        onError: (Object e) =>
            _logMessage('[BLE,ERR] Device scan fails with error: $e'));
    _pushState();
  }

  void _pushState() {
    _stateStreamController.add(
      BleScannerState(
        discoveredDevices: _devices,
        scanIsInProgress: _subscription != null,
      ),
    );
  }

  Future<void> stopScan() async {
    _logMessage('[BLE] Stop ble discovery');

    await _subscription?.cancel();
    _subscription = null;
    _pushState();
  }

  Future<void> dispose() async {
    await _stateStreamController.close();
  }

  StreamSubscription? _subscription;
}

@immutable
class BleScannerState {
  const BleScannerState({
    required this.discoveredDevices,
    required this.scanIsInProgress,
  });

  final List<DiscoveredDevice> discoveredDevices;
  final bool scanIsInProgress;
}
