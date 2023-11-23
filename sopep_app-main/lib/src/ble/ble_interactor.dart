// Copyright (c) 2023, StarIC, author: Justin Y. Kim

import 'dart:async';
import 'package:convert/convert.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:sopep_app/constants.dart';

import 'package:sopep_app/src/ble/ble_sopep_interactor.dart';
import 'package:sopep_app/src/ble/reactive_state.dart';
import 'package:sopep_app/src/utilities/encoder_decoder.dart';

class BleInteractor extends ReactiveState<ConnectionStateUpdate> {
  BleInteractor({
    required FlutterReactiveBle ble,
    required Function(String message) logMessage,
  })  : _ble = ble,
        _logMessage = logMessage;

  final void Function(String message) _logMessage;

  EncoderDecoder _encoderDecoder = EncoderDecoder();
  final FlutterReactiveBle _ble;
  late final BleSopepInteractor _sopepInteractor = BleSopepInteractor(
    bleDiscoverServices: _ble.discoverServices,
    readCharacteristic: _ble.readCharacteristic,
    writeWithResponse: _ble.writeCharacteristicWithResponse,
    writeWithOutResponse: _ble.writeCharacteristicWithoutResponse,
    writeCborWithoutResponse: writeCborWithoutResponse,
    subscribeToCharacteristic: _ble.subscribeToCharacteristic,
    logMessage: _logMessage,
  );
  int _mtu = 0;

  @override
  Stream<ConnectionStateUpdate> get state => _deviceConnectionController.stream;

  final _deviceConnectionController = StreamController<ConnectionStateUpdate>();
  late StreamSubscription<ConnectionStateUpdate> _connection;
  BleConnectionErrors _bleConnError = BleConnectionErrors.none;

  Future<void> connect(String deviceId, String sopepId) async {
    _bleConnError = BleConnectionErrors.none;
    _logMessage('[BLE] Start connecting to $sopepId (MAC/DEV: $deviceId)');
    _connection = _ble
        .connectToDevice(id: deviceId, connectionTimeout: Duration(seconds: 20))
        .listen(
      (update) async {
        _logMessage(
            '[BLE] ConnectionState for device $sopepId (MAC/DEV: $deviceId): ${update.connectionState}');
        _deviceConnectionController.add(update);

        switch (update.connectionState) {
          case DeviceConnectionState.connected:
            // After connecting, discover services and negotiate MTU size
            discoverServices(deviceId);
            await getMtuSize(deviceId);
            if (_mtu <= 0) {
              _logMessage('[BLE,ERR] Failed getting MTU size');
              _bleConnError = BleConnectionErrors.getMtuSize;
              disconnect(deviceId, sopepId);
            }

            // If MTU size is good, begin notification enable
            Timer.periodic(const Duration(seconds: 1), (timer) {
              // Send set-time command on successful subscription
              if (_sopepInteractor.getBleNotificationStream() != null) {
                _sopepInteractor.setTime(null);
                timer.cancel();
              } else {
                _sopepInteractor.enableNotification(deviceId, sopepId);
              }

              // Check if we disconnected or timeout occurred
              if (update.connectionState ==
                  DeviceConnectionState.disconnected) {
                timer.cancel();
              }
            });

            break;

          case DeviceConnectionState.disconnected:
            _sopepInteractor.disableNotification();
            break;

          case DeviceConnectionState.connecting:
            // Do nothing for now...
            break;

          case DeviceConnectionState.disconnecting:
            // Do nothing for now...
            break;
        }
      },
      onError: (Object e) => _logMessage(
          '[BLE] Connecting to device $sopepId (MAC/DEV: $deviceId) resulted in error $e'),
    );
  }

  /// Disconnects current BLE connection and cancels notification.
  ///
  /// Throws an error if disconnecting process is not completed and logs all
  /// errors that occurred.
  Future<void> disconnect(String deviceId, String sopepId) async {
    try {
      _logMessage(
          '[BLE] Disconnecting to device: $sopepId (MAC/DEV: $deviceId)');
      _sopepInteractor.disableNotification();
      await _connection.cancel();
    } on Exception catch (e, _) {
      _logMessage("[BLE,ERR] Error disconnecting from a device: $e");
    } finally {
      // Since [_connection] subscription is terminated, the "disconnected"
      // state cannot be received and propagated
      _deviceConnectionController.add(
        ConnectionStateUpdate(
          deviceId: deviceId,
          connectionState: DeviceConnectionState.disconnected,
          failure: null,
        ),
      );
    }
  }

  Future<void> dispose() async {
    await _deviceConnectionController.close();
  }

  BleConnectionErrors getBleError() => _bleConnError;

  BleSopepInteractor getSopepInteractor() => _sopepInteractor;

  Future<List<DiscoveredService>> discoverServices(String deviceId) async {
    try {
      _logMessage('[BLE] Start discovering services for: $deviceId');
      final result = await _ble.discoverServices(deviceId);
      _logMessage('[BLE] Discovering services finished');
      return result;
    } on Exception catch (e) {
      _logMessage('[BLE,ERR] Error occured when discovering services: $e');
      rethrow;
    }
  }

  Future<int> getMtuSize(String deviceId) async {
    _mtu = 0; // Clear any previous MTU size

    try {
      _logMessage('[BLE] Start MTU size negotiation with $deviceId');
      // NOTE: For iOS, below function only returns the set MTU size
      _mtu = await _ble.requestMtu(deviceId: deviceId, mtu: MTU_SIZE_MAX);
      _logMessage('[BLE] MTU size is $_mtu bytes');
      return _mtu;
    } on Exception catch (e) {
      _logMessage('[BLE,ERR] Error occured negotiating MTU size: $e');
      rethrow;
    }
  }

  Future<List<int>> readCharacteristic(
      QualifiedCharacteristic characteristic) async {
    try {
      final result = await _ble.readCharacteristic(characteristic);

      _logMessage(
          '[RX] Read ${characteristic.characteristicId}: value = $result');
      return result;
    } on Exception catch (e, s) {
      _logMessage(
        '[RX,ERR] Error occured when reading ${characteristic.characteristicId} : $e',
      );
      // ignore: avoid_print
      print(s);
      rethrow;
    }
  }

  Future<void> writeCharacterisiticWithResponse(
      QualifiedCharacteristic characteristic, List<int> value) async {
    try {
      _logMessage(
          '[TX] Write with response value : $value to ${characteristic.characteristicId}');
      await _ble.writeCharacteristicWithResponse(characteristic, value: value);
    } on Exception catch (e, s) {
      _logMessage(
        '[TX,ERR] Error occured when writing ${characteristic.characteristicId} : $e',
      );
      // ignore: avoid_print
      print(s);
      rethrow;
    }
  }

  Future<void> writeCharacterisiticWithoutResponse(
      QualifiedCharacteristic characteristic, List<int> value) async {
    try {
      await _ble.writeCharacteristicWithoutResponse(characteristic,
          value: value);
      _logMessage(
          '[TX] Write without response value: $value to ${characteristic.characteristicId}');
    } on Exception catch (e, s) {
      _logMessage(
        '[TX,ERR] Error occured when writing ${characteristic.characteristicId} : $e',
      );
      // ignore: avoid_print
      print(s);
      rethrow;
    }
  }

  Future<void> writeCborWithoutResponse(QualifiedCharacteristic characteristic,
      {required Object data, required bool log}) async {
    try {
      final encoded = _encoderDecoder.encoder(data);

      // Find total number of packets we need to send and send them!
      final totalPackets =
          (encoded.length / (_mtu - BLE_ATT_HEADER_BYTES)).ceil();
      var i = 0;
      for (; i < (totalPackets - 1); i++) {
        await _ble.writeCharacteristicWithoutResponse(characteristic,
            value: encoded
                .getRange((_mtu - BLE_ATT_HEADER_BYTES) * i,
                    (_mtu - BLE_ATT_HEADER_BYTES) * (i + 1))
                .toList());
      }
      await _ble.writeCharacteristicWithoutResponse(characteristic,
          value: encoded
              .getRange((_mtu - BLE_ATT_HEADER_BYTES) * i, encoded.length)
              .toList());

      if (log) {
        _logMessage('[TX] $data');
        _logMessage(
            '[TX_RAW, ${encoded.length}B] ${hex.encode(encoded).toUpperCase()}');
      }
    } on Exception catch (e, s) {
      if (log) {
        _logMessage(
          '[TX,ERR] $data : $e',
        );
      }
      // ignore: avoid_print
      print(s);
    }
  }

  Stream<List<int>> subScribeToCharacteristic(
      QualifiedCharacteristic characteristic) {
    _logMessage('[BLE] Subscribing to: ${characteristic.characteristicId} ');
    return _ble.subscribeToCharacteristic(characteristic);
  }

  int geMtuBytes() => _mtu;

  int getMaxPayloadBytes() => _mtu - BLE_ATT_HEADER_BYTES;
}

/// Connection error return values.
enum BleConnectionErrors {
  /// No errors occurred.
  none,

  /// Unable to get MTU size.
  getMtuSize,

  /// Unable to enable notifications.
  enableNotification,

  /// Unable to send set current time command to device.
  setTime,
}
