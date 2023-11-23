// Copyright (c) 2023, StarIC, author: Justin Y. Kim
// Copyright (c) 2023, authors of flutter_reactive_ble

import 'package:flutter/material.dart';
import 'package:convert/convert.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sopep_app/src/ble/ble_scanner.dart';
import 'package:provider/provider.dart';
import '../ble/ble_logger.dart';
import '../widgets/widgets.dart';
import 'device_detail/device_detail_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Consumer3<BleScanner, BleScannerState?, BleLogger>(
        builder: (_, bleScanner, bleScannerState, bleLogger, __) => _DeviceList(
          scannerState: bleScannerState ??
              const BleScannerState(
                discoveredDevices: [],
                scanIsInProgress: false,
              ),
          startScan: bleScanner.startScan,
          stopScan: bleScanner.stopScan,
        ),
      );
}

class _DeviceList extends StatefulWidget {
  const _DeviceList({
    required this.scannerState,
    required this.startScan,
    required this.stopScan,
  });

  final BleScannerState scannerState;
  final void Function() startScan;
  final VoidCallback stopScan;

  @override
  _DeviceListState createState() => _DeviceListState();
}

class _DeviceListState extends State<_DeviceList> {
  String? _version;
  String? _buildNumber;

  @override
  void initState() {
    _getAppVersion();
    _requestStoragePermission();
    super.initState();
  }

  @override
  void dispose() {
    widget.stopScan();
    super.dispose();
  }

  void _startScanning() {
    widget.startScan();
  }

  void _getAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;
    final buildNumber = packageInfo.buildNumber;
    setState(() {
      _version = version;
      _buildNumber = buildNumber;
    });
  }

  Future<void> _requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (status.isGranted) {
      // Storage permission is already granted; do nothing
    } else {
      // Request storage permission
      status = await Permission.storage.request();
      if (status.isDenied) {
        // TODO: Handle the case where the user denies the permission
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('sOPEP (v$_version, Build: $_buildNumber)'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                !widget.scannerState.scanIsInProgress
                                    ? const Color.fromARGB(255, 59, 158, 239)
                                    : Color.fromARGB(255, 255, 73, 73)),
                        child: !widget.scannerState.scanIsInProgress
                            ? Text('Scan')
                            : Text('Stop'),
                        onPressed: !widget.scannerState.scanIsInProgress
                            ? _startScanning
                            : widget.stopScan,
                      ),
                      if (widget.scannerState.scanIsInProgress)
                        SpinKitRipple(
                          color: Color.fromARGB(255, 0, 0, 255),
                          size: 50.0,
                        ),
                      if (widget.scannerState.scanIsInProgress)
                        Text(
                          'count: ${widget.scannerState.discoveredDevices.length}',
                          textAlign: TextAlign.justify,
                        )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                children: [
                  ...widget.scannerState.discoveredDevices
                      .map(
                        (device) => ListTile(
                          title: Text(
                            device.name.isNotEmpty ? device.name : "Unnamed",
                          ),
                          subtitle: Text(
                            "Device ID: 0x${hex.encode(device.manufacturerData).substring(5).toUpperCase()}\n"
                            "MAC/DEV: ${device.id}\n"
                            "RSSI: ${device.rssi} dBm",
                            style: TextStyle(fontSize: 13),
                          ),
                          leading: const BluetoothIcon(),
                          onTap: () async {
                            widget.stopScan();
                            await Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DeviceDetailScreen(device: device),
                              ),
                            );
                          },
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ],
        ),
      );
}
