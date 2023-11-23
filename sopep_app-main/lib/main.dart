// Copyright (c) 2023, StarIC, author: Justin Y. Kim

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:sopep_app/src/ble/ble_interactor.dart';
import 'package:sopep_app/src/ble/ble_scanner.dart';
import 'package:sopep_app/src/ble/ble_status_monitor.dart';
import 'package:sopep_app/src/ui/ble_status_screen.dart';
import 'package:sopep_app/src/ui/device_list.dart';
import 'package:provider/provider.dart';
import 'package:sopep_app/src/utilities/file_storage.dart';
import 'package:wakelock/wakelock.dart';
import 'package:firebase_core/firebase_core.dart';

import 'src/ble/ble_logger.dart';

const _themeColor = Colors.purple;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(); // NOTE: remove if not using Firebase

  Wakelock.enable(); // Prevent phone from sleeping

  final _ble = FlutterReactiveBle();
  final _bleLogger = BleLogger(ble: _ble);
  final _scanner = BleScanner(ble: _ble, logMessage: _bleLogger.addToLog);
  final _monitor = BleStatusMonitor(_ble);
  final _interactor = BleInteractor(
    ble: _ble,
    logMessage: _bleLogger.addToLog,
  );
  final _fileStorage = FileStorage(logMessage: _bleLogger.addToLog);
  _fileStorage.createDefaultDirectories();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: _scanner),
        Provider.value(value: _monitor),
        Provider.value(value: _interactor),
        Provider.value(value: _bleLogger),
        Provider.value(value: _fileStorage),
        StreamProvider<BleScannerState?>(
          create: (_) => _scanner.state,
          initialData: const BleScannerState(
            discoveredDevices: [],
            scanIsInProgress: false,
          ),
        ),
        StreamProvider<BleStatus?>(
          create: (_) => _monitor.state,
          initialData: BleStatus.unknown,
        ),
        StreamProvider<ConnectionStateUpdate>(
          create: (_) => _interactor.state,
          initialData: const ConnectionStateUpdate(
            deviceId: 'Unknown device',
            connectionState: DeviceConnectionState.disconnected,
            failure: null,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Reactive BLE example',
        color: _themeColor,
        theme: ThemeData(primarySwatch: _themeColor),
        home: const HomeScreen(),
      ),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Consumer<BleStatus?>(
        builder: (_, status, __) {
          if (status == BleStatus.ready) {
            return const DeviceListScreen();
          } else {
            return BleStatusScreen(status: status ?? BleStatus.unknown);
          }
        },
      );
}
