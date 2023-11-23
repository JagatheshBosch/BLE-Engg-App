// Copyright (c) 2023, StarIC, author: Justin Y. Kim

import 'dart:async';
import 'dart:typed_data';
import 'package:cbor/cbor.dart';
import 'package:convert/convert.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:intl/intl.dart';

import 'package:sopep_app/constants.dart';
import 'package:sopep_app/src/utilities/encoder_decoder.dart';

class BleSopepInteractor {
  BleSopepInteractor({
    required Future<List<DiscoveredService>> Function(String deviceId)
        bleDiscoverServices,
    required Future<List<int>> Function(QualifiedCharacteristic characteristic)
        readCharacteristic,
    required Future<void> Function(QualifiedCharacteristic characteristic,
            {required List<int> value})
        writeWithResponse,
    required Future<void> Function(QualifiedCharacteristic characteristic,
            {required List<int> value})
        writeWithOutResponse,
    required Future<void> Function(QualifiedCharacteristic characteristic,
            {required Object data, required bool log})
        writeCborWithoutResponse,
    required Stream<List<int>> Function(QualifiedCharacteristic characteristic)
        subscribeToCharacteristic,
    required void Function(String message) logMessage,
  })  : _bleDiscoverServices = bleDiscoverServices,
        _readCharacteristic = readCharacteristic,
        _writeWithResponse = writeWithResponse,
        _writeWithoutResponse = writeWithOutResponse,
        _writeCborWithoutResponse = writeCborWithoutResponse,
        _subScribeToCharacteristic = subscribeToCharacteristic,
        _logMessage = logMessage;

  final Future<List<DiscoveredService>> Function(String deviceId)
      _bleDiscoverServices;
  final Future<List<int>> Function(QualifiedCharacteristic characteristic)
      _readCharacteristic;
  final Future<void> Function(QualifiedCharacteristic characteristic,
      {required List<int> value}) _writeWithResponse;
  final Future<void> Function(QualifiedCharacteristic characteristic,
      {required List<int> value}) _writeWithoutResponse;
  final Future<void> Function(QualifiedCharacteristic characteristic,
      {required Object data, required bool log}) _writeCborWithoutResponse;
  final Stream<List<int>> Function(QualifiedCharacteristic characteristic)
      _subScribeToCharacteristic;
  final void Function(String message) _logMessage;

  EncoderDecoder _encoderDecoder = EncoderDecoder();
  QualifiedCharacteristic? _characteristic;
  StreamSubscription<List<int>>? _bleNotificationStream;
  Map<Object?, Object?>? _dataMap;
  int _dataMapBytes = 0;
  BleSopepResponseData _sopepResponse = BleSopepResponseData();
  StreamController<BleSopepResponseData> _sopepStreamController =
      StreamController<BleSopepResponseData>.broadcast();
  bool _enableLogging = true;
  String _sopepId = '';

  Future<void> enableNotification(String deviceId, String sopepId) async {
    _sopepId = sopepId;
    _characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse(SOPEP_SERVICE_UUID),
      characteristicId: Uuid.parse(SOPEP_CHARACTERISTIC_UUID),
      deviceId: deviceId,
    );
    _bleNotificationStream =
        _subScribeToCharacteristic(_characteristic!).listen((data) {
      // Continue to stack up arrays until we see a valid CBOR message
      _logMessage(
          '[RX_RAW, ${data.length}B] ${hex.encode(data).toUpperCase()}');
      _dataMap = _encoderDecoder.decoder(data);
      _dataMapBytes += data.length;
      if (_dataMap != null) {
        if (_dataMap?.keys.first == 'rsp') {
          // Display decoded CBOR on RSP text area
          _sopepResponse.rspTextTimestamp =
              DateFormat('kk:mm:ss').format(DateTime.now()).toString();
          _sopepResponse.rspText = "";
          _dataMap!.forEach((final key, final value) {
            _sopepResponse.rspText += '$key: $value\n';
          });
        } else if (_dataMap?.keys.first == 'event') {
          // Display decoded CBOR on EVENT text area
          if (_dataMap?['event'] == 'new-data') {
            _sopepResponse.eventNewDataTextTimestamp =
                DateFormat('kk:mm:ss').format(DateTime.now()).toString();
            _sopepResponse.eventNewDataText = "";
            _dataMap!.forEach((final key, final value) {
              _sopepResponse.eventNewDataText += '$key: $value\n';
            });
          } else if (_dataMap?['event'] == 'device-status') {
            _sopepResponse.eventDevStatusTextTimestamp =
                DateFormat('kk:mm:ss').format(DateTime.now()).toString();
            _sopepResponse.eventDevStatusText = "";
            _dataMap!.forEach((final key, final value) {
              _sopepResponse.eventDevStatusText += '$key: $value\n';
            });
          }
        }
        _sopepResponse.dataMap = _dataMap;
        _sopepResponse.dataMapBytes = _dataMapBytes;

        // Add new data to stream to update all subscribed listeners
        _sopepStreamController.add(_sopepResponse);

        // Log the RX data and clear it
        if (_enableLogging) {
          _logMessage('[RX] $_dataMap');
        }
        _dataMap = null;
        _dataMapBytes = 0;
      }
    });
  }

  void disableNotification() {
    _bleNotificationStream?.cancel();
    _bleNotificationStream = null;
    _characteristic = null;
    _sopepId = '';
  }

  StreamController<BleSopepResponseData> getSopepStreamController() =>
      _sopepStreamController;

  StreamSubscription<List<int>>? getBleNotificationStream() =>
      _bleNotificationStream;

  String getSopepDeviceId() => _sopepId;

  void getDeviceInfo() {
    Map<Object, Object> cborCmd = {'cmd': 'device-info'};
    _writeCborWithoutResponse(_characteristic!,
        data: cborCmd, log: _enableLogging);
  }

  void getConfigRanges() {
    Map<Object, Object> cborCmd = {'cmd': 'config-get-ranges'};
    _writeCborWithoutResponse(_characteristic!,
        data: cborCmd, log: _enableLogging);
  }

  void getOldestPriorityData() {
    Map<Object, Object> cborCmd = {'cmd': 'read-prio-data'};
    _writeCborWithoutResponse(_characteristic!,
        data: cborCmd, log: _enableLogging);
  }

  void getPriorityData(int seq) {
    Map<Object, Object> cborCmd = {'cmd': 'read-prio-data'};
    cborCmd['seq'] = seq;
    _writeCborWithoutResponse(_characteristic!,
        data: cborCmd, log: _enableLogging);
  }

  void getData(int? seq) {
    Map<Object, Object> cborCmd = {'cmd': 'read-data'};
    if (seq != null) {
      cborCmd['seq'] = seq;
    }
    _writeCborWithoutResponse(_characteristic!,
        data: cborCmd, log: _enableLogging);
  }

  void getConfigure() {
    Map<Object, Object> cborCmd = {'cmd': 'configure'};
    _writeCborWithoutResponse(_characteristic!,
        data: cborCmd, log: _enableLogging);
  }

  void setConfigure(
    bool _ledToggle,
    int _ledIntensity,
    double _thresholdGood,
    double _thresholdHigh,
    double _targetTreatmentTime,
    int _targetExhalationCount,
    double _minBreathLength,
    bool _useExhaleCountToggle,
  ) {
    Map<Object, Object> cborCmd = {'cmd': 'configure'};
    cborCmd['led-toggle'] = _ledToggle;
    cborCmd['led-intensity'] = _ledIntensity;
    cborCmd['good-zone-threshold'] = _thresholdGood;
    cborCmd['high-zone-threshold'] = _thresholdHigh;
    cborCmd['target-treatment-time'] = _targetTreatmentTime;
    cborCmd['target-exhalation-count'] = _targetExhalationCount;
    cborCmd['minimum-breath-length'] = _minBreathLength;
    cborCmd['use-exhalation-count'] = _useExhaleCountToggle;

    _writeCborWithoutResponse(_characteristic!,
        data: cborCmd, log: _enableLogging);
  }

  void setTime(int? epochTimeSeconds) {
    Map<Object, Object> cborCmd = {'cmd': 'set-time'};
    if (epochTimeSeconds != null) {
      cborCmd['timestamp'] = epochTimeSeconds;
    } else {
      cborCmd['timestamp'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }
    _writeCborWithoutResponse(_characteristic!,
        data: cborCmd, log: _enableLogging);
  }

  void setTravelMode() {
    Map<Object, Object> cborCmd = {'cmd': 'travel-mode'};
    _writeCborWithoutResponse(_characteristic!,
        data: cborCmd, log: _enableLogging);
  }

  void eraseFlash(
    bool data,
    bool? formatData,
    bool prioData,
    bool? formatPrioData,
    bool diagData,
    bool? formatDiagData,
    bool config,
    bool pairing,
  ) {
    bool sendErase = false;

    Map<Object, Object> cborCmd = {'cmd': 'erase'};
    if (data) {
      if (formatData!) {
        cborCmd['data'] = 'format';
      } else {
        cborCmd['data'] = 'delete';
      }
      sendErase = true;
    }
    if (prioData) {
      if (formatPrioData!) {
        cborCmd['prio-data'] = 'format';
      } else {
        cborCmd['prio-data'] = 'delete';
      }
      sendErase = true;
    }
    if (diagData) {
      if (formatDiagData!) {
        cborCmd['diag-data'] = 'format';
      } else {
        cborCmd['diag-data'] = 'delete';
      }
      sendErase = true;
    }
    if (config) {
      cborCmd['configuration'] = true;
      sendErase = true;
    }
    if (pairing) {
      cborCmd['pairing'] = true;
      sendErase = true;
    }

    if (sendErase) {
      _writeCborWithoutResponse(_characteristic!,
          data: cborCmd, log: _enableLogging);
    }
  }

  void setEnableLogging(bool val) {
    _enableLogging = val;
  }

  void sendEchoTest(int bytes) {
    // Generate desired bytes of filler data
    List<int> data = [];
    int counter = 0;
    for (var i = 0; i < bytes; i++) {
      data.add(counter);
      counter++;
      if (counter >= 255) {
        counter = 0;
      }
    }

    // NOTE: {'cmd': 'echo-test', 'data':} is 29 bytes, which means for MTU size
    //       of 247, you should send 247 - 29 - 3 = 215 bytes of filler data for
    //       a full single TX BLE packet
    Map<Object, Object> cborCmd = {'cmd': 'echo-test'};
    cborCmd['data'] = CborBytes(data);
    _writeCborWithoutResponse(_characteristic!,
        data: cborCmd, log: _enableLogging);
  }

  void startFwUpload() {
    Map<Object, Object> cborCmd = {'cmd': 'fw-start'};
    _writeCborWithoutResponse(_characteristic!,
        data: cborCmd, log: _enableLogging);
  }

  void sendFwData(Uint8List data) {
    Map<Object, Object> cborCmd = {'cmd': 'fw-block'};
    cborCmd['data'] = CborBytes(data);
    _writeCborWithoutResponse(_characteristic!,
        data: cborCmd, log: _enableLogging);
  }

  void scheduleFwUpdate(int time) {
    Map<Object, Object> cborCmd = {'cmd': 'fw-schedule'};
    cborCmd['timestamp'] = time;
    _writeCborWithoutResponse(_characteristic!,
        data: cborCmd, log: _enableLogging);
  }
}

class BleSopepResponseData {
  String rspTextTimestamp = "";
  String rspText = "";
  String eventNewDataTextTimestamp = "";
  String eventNewDataText = "";
  String eventDevStatusTextTimestamp = "";
  String eventDevStatusText = "";
  Map<Object?, Object?>? dataMap;
  int dataMapBytes = 0;
}
