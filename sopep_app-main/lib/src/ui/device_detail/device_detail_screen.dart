// Copyright (c) 2023, StarIC, author: Justin Y. Kim
// Copyright (c) 2023, authors of flutter_reactive_ble

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:sopep_app/constants.dart';
import 'package:sopep_app/src/ble/ble_interactor.dart';
import 'package:sopep_app/src/ui/device_detail/device_log_tab.dart';
import 'package:provider/provider.dart';
import 'package:sopep_app/src/utilities/utils.dart';

import 'ble_traffic_tab.dart';
import 'device_interaction_tab.dart';
import 'dataset_interaction_tab.dart';
import 'dialogs/ble_services_dialog.dart';
import '../report_bug_screen.dart';

class DeviceDetailScreen extends StatelessWidget {
  final DiscoveredDevice device;

  const DeviceDetailScreen({required this.device, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Consumer2<BleInteractor, ConnectionStateUpdate>(
        builder: (_, bleInteractor, connectionStateUpdate, __) => _DeviceDetail(
          device: device,
          bleInteractor: bleInteractor,
          connectionStatus: connectionStateUpdate.connectionState,
        ),
      );
}

class _DeviceDetail extends StatefulWidget {
  const _DeviceDetail({
    required this.device,
    required this.bleInteractor,
    required this.connectionStatus,
    Key? key,
  }) : super(key: key);

  final DiscoveredDevice device;
  final BleInteractor bleInteractor;
  final DeviceConnectionState connectionStatus;

  @override
  _DeviceDetailState createState() => _DeviceDetailState();
}

class _DeviceDetailState extends State<_DeviceDetail> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void bleServicesDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => BleServicesDialog(
        device: widget.device,
        characteristic: QualifiedCharacteristic(
            characteristicId: Uuid.parse(SOPEP_CHARACTERISTIC_UUID),
            serviceId: Uuid.parse(SOPEP_SERVICE_UUID),
            deviceId: widget.device.id),
      ),
    );
  }

  void reportBugScreen() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => BugReportScreen(
          device: widget.device,
          characteristic: QualifiedCharacteristic(
              characteristicId: Uuid.parse(SOPEP_CHARACTERISTIC_UUID),
              serviceId: Uuid.parse(SOPEP_SERVICE_UUID),
              deviceId: widget.device.id),
        ),
      ),
    );
  }

  void _handleBleErrors() {
    switch (widget.connectionStatus) {
      case DeviceConnectionState.connected:
        // Do nothing for now...
        break;

      case DeviceConnectionState.connecting:
        // Do nothing for now...
        break;

      case DeviceConnectionState.disconnecting:
        // Do nothing for now...
        break;

      case DeviceConnectionState.disconnected:
        // Check for errors and handle if any
        switch (widget.bleInteractor.getBleError()) {
          case BleConnectionErrors.none:
            // Do nothing, we're good!
            break;

          case BleConnectionErrors.getMtuSize:
            snackBar(context, 'Failed getting MTU size');
            widget.bleInteractor.disconnect(
                widget.device.id,
                hex
                    .encode(widget.device.manufacturerData)
                    .toUpperCase()
                    .toString());
            Navigator.pop(context, true);
            break;

          case BleConnectionErrors.enableNotification:
            // Do nothing for now...
            break;

          case BleConnectionErrors.setTime:
            // Do nothing for now...
            break;
        }
        break;
    }
  }

  Widget _handleBleConnChanges() {
    String bleConnStr = 'Unknown';

    switch (widget.connectionStatus) {
      case DeviceConnectionState.connected:
        bleConnStr = "Connected";
        break;

      case DeviceConnectionState.connecting:
        bleConnStr = "Connecting";
        break;

      case DeviceConnectionState.disconnecting:
        bleConnStr = "Disconnecting";
        break;

      case DeviceConnectionState.disconnected:
        bleConnStr = "Disconnected";
        break;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleBleErrors();
    });

    return Text(
        (widget.device.name.isNotEmpty ? widget.device.name : "Unnamed") +
            (' ($bleConnStr)'));
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () async {
          widget.bleInteractor.disconnect(
              widget.device.id,
              hex
                  .encode(widget.device.manufacturerData)
                  .toUpperCase()
                  .toString());
          return true;
        },
        child: DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: _handleBleConnChanges(),
              actions: [
                PopupMenuButton(
                    icon: Icon(Icons.menu),
                    itemBuilder: (context) {
                      return [
                        if (widget.connectionStatus ==
                            DeviceConnectionState.connected)
                          PopupMenuItem<int>(
                            value: 0,
                            child: Text("BLE Services"),
                          ),
                        PopupMenuItem<int>(
                          value: 1,
                          child: Text("Report Bug"),
                        ),
                      ];
                    },
                    onSelected: (value) {
                      if (value == 0) {
                        bleServicesDialog();
                      } else if (value == 1) {
                        reportBugScreen();
                      }
                    }),
              ],
              bottom: const TabBar(
                tabs: [
                  // NOTE: Populate tab and its icon here
                  Tab(
                    icon: Icon(
                      Icons.bluetooth_connected,
                    ),
                  ),
                  Tab(
                    icon: Icon(
                      Icons.line_axis_outlined,
                    ),
                  ),
                  Tab(
                    icon: Icon(
                      Icons.traffic_outlined,
                    ),
                  ),
                  Tab(
                    icon: Icon(
                      Icons.article_outlined,
                    ),
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // NOTE: Populate tab objects here
                DeviceInteractionTab(
                  device: widget.device,
                ),
                DatasetInteractionTab(
                  device: widget.device,
                ),
                BleTrafficTab(
                  device: widget.device,
                ),
                DeviceLogTab(),
              ],
            ),
          ),
        ),
      );
}
