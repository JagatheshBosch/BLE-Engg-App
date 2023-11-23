// Copyright (c) 2023, StarIC, author: Justin Y. Kim

import 'dart:async';
import 'package:convert/convert.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'package:sopep_app/constants.dart';
import 'package:sopep_app/src/ble/ble_interactor.dart';
import 'package:sopep_app/src/ui/device_detail/dialogs/sopep_erase_dialog.dart';
import 'package:sopep_app/src/ui/device_detail/dialogs/sopep_readdata_dialog.dart';
import 'package:sopep_app/src/widgets/ui_helper.dart';
import 'package:sopep_app/src/utilities/file_storage.dart';
import 'package:sopep_app/src/ble/ble_sopep_interactor.dart';
import 'package:sopep_app/src/ui/device_detail/dialogs/sopep_firmware_dialog.dart';
import 'package:sopep_app/src/ui/device_detail/dialogs/sopep_echo_dialog.dart';
import 'package:sopep_app/src/ui/device_detail/dialogs/sopep_configure_dialog.dart';
import 'package:sopep_app/src/ui/device_detail/dialogs/sopep_readpriodata_dialog.dart';
import 'package:sopep_app/src/ui/device_detail/dialogs/sopep_settime_dialog.dart';
import 'package:sopep_app/src/ui/device_detail/dialogs/characteristic_interaction_dialog.dart';
import 'package:sopep_app/src/ui/device_detail/dialogs/cbor_interaction_dialog.dart';

class DeviceInteractionTab extends StatelessWidget {
  final DiscoveredDevice device;

  const DeviceInteractionTab({
    required this.device,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Consumer3<BleInteractor, ConnectionStateUpdate, FileStorage>(
        builder: (_, bleInteractor, connectionStateUpdate, fileStorage, __) =>
            _DeviceInteractionTab(
          deviceId: device.id,
          deviceMfrId:
              hex.encode(device.manufacturerData).toUpperCase().toString(),
          connectableStatus: device.connectable,
          connectionStatus: connectionStateUpdate.connectionState,
          bleInteractor: bleInteractor,
          fileStorage: fileStorage,
        ),
      );
}

class _DeviceInteractionTab extends StatefulWidget {
  const _DeviceInteractionTab({
    required this.deviceId,
    required this.deviceMfrId,
    required this.connectableStatus,
    required this.connectionStatus,
    required this.bleInteractor,
    required this.fileStorage,
    Key? key,
  }) : super(key: key);

  final String deviceId;
  final String deviceMfrId;
  final Connectable connectableStatus;
  final DeviceConnectionState connectionStatus;
  final BleInteractor bleInteractor;
  final FileStorage fileStorage;

  DeviceConnectionState get deviceConnectionStatus => connectionStatus;

  @override
  _DeviceInteractionTabState createState() => _DeviceInteractionTabState();
}

class _DeviceInteractionTabState extends State<_DeviceInteractionTab>
    with AutomaticKeepAliveClientMixin<_DeviceInteractionTab> {
  late final _sopepId;
  late BleSopepInteractor _sopepInteractor;
  late final QualifiedCharacteristic _characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse(SOPEP_SERVICE_UUID),
      characteristicId: Uuid.parse(SOPEP_CHARACTERISTIC_UUID),
      deviceId: widget.deviceId);
  StreamSubscription<BleSopepResponseData>? _sopepStreamSubscription;
  BleSopepResponseData _bleSopepResponseData = BleSopepResponseData();

  @override
  void initState() {
    _sopepId = widget.deviceMfrId.substring(5);
    _sopepInteractor = widget.bleInteractor.getSopepInteractor();
    _connect();

    super.initState();
  }

  @override
  void dispose() {
    _sopepStreamSubscription?.cancel();

    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _connect() {
    // Connect to sOPEP device and listen for success/error
    widget.bleInteractor.connect(widget.deviceId, _sopepId);

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sopepInteractor.getBleNotificationStream() != null) {
        // Notification enabled successfully; add listener to new response data
        _sopepStreamSubscription = widget.bleInteractor
            .getSopepInteractor()
            .getSopepStreamController()
            .stream
            .listen((bleSopepResponseData) {
          setState(() {
            // Got new data; update our response text display
            _bleSopepResponseData = bleSopepResponseData;
          });
        });
        timer.cancel();
      } else if ((widget.deviceConnectionStatus ==
              DeviceConnectionState.disconnecting) ||
          (widget.deviceConnectionStatus ==
              DeviceConnectionState.disconnected)) {
        timer.cancel();
      }
    });
  }

  void _cborDialog() {
    showDialog<void>(
        context: context,
        builder: (context) => CborInteractionDialog(
              characteristic: QualifiedCharacteristic(
                  characteristicId: _characteristic.characteristicId,
                  serviceId: _characteristic.serviceId,
                  deviceId: widget.deviceId),
            ));
  }

  void _bleServiceDialog() {
    showDialog<void>(
        context: context,
        builder: (context) => CharacteristicInteractionDialog(
              characteristic: QualifiedCharacteristic(
                  characteristicId: _characteristic.characteristicId,
                  serviceId: _characteristic.serviceId,
                  deviceId: widget.deviceId),
            ));
  }

  void _configureDialog() {
    showDialog<void>(
        context: context,
        builder: (context) => SopepConfigureInteractionDialog(
              bleInteractor: widget.bleInteractor,
              sopepInteractor: _sopepInteractor,
            ));
  }

  void _setTimeDialog() {
    showDialog<void>(
        context: context,
        builder: (context) => SopepSetTimeInteractionDialog(
              sopepInteractor: _sopepInteractor,
            ));
  }

  void _getPriorityDataDialog() {
    showDialog<void>(
        context: context,
        builder: (context) => SopepReadPrioDataInteractionDialog(
              characteristic: QualifiedCharacteristic(
                  characteristicId: _characteristic.characteristicId,
                  serviceId: _characteristic.serviceId,
                  deviceId: widget.deviceId),
              sopepInteractor: _sopepInteractor,
            ));
  }

  void _getDataDialog() {
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => SopepReadDataDialog(
              bleInteractor: widget.bleInteractor,
              sopepInteractor: _sopepInteractor,
              sopepId: _sopepId,
            ));
  }

  void _firmwareDialog() {
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => SopepFirmwareUploadDialog(
              bleInteractor: widget.bleInteractor,
              sopepInteractor: _sopepInteractor,
            ));
  }

  void _echoDialog() {
    showDialog<void>(
        context: context,
        builder: (context) => SopepEchoDialog(
              sopepInteractor: _sopepInteractor,
            ));
  }

  void _eraseDialog() {
    showDialog<void>(
        context: context,
        builder: (context) => SopepEraseDialog(
              sopepInteractor: _sopepInteractor,
            ));
  }

  Widget _widgetInteractButton(String text, VoidCallback? cbFunction) {
    return ElevatedButton(
      onPressed:
          widget.deviceConnectionStatus == DeviceConnectionState.connected
              ? cbFunction
              : null,
      child: Text(text),
    );
  }

  Widget _widgetResponseInterface(
      String title, String timestamp, String response) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 1.0, start: 16.0),
          child: UiHelper.sectionHeader(title),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 1.0, start: 16.0),
          child: Text(
            timestamp,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 1.0, start: 16.0),
          child: Text(
            response,
            style: const TextStyle(fontSize: 12),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate.fixed(
            [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SizedBox(
                    width: (2 * MediaQuery.of(context).size.width) / 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                              top: 8.0, start: 16.0),
                          child: Text(
                            "sOPEP ID: 0x$_sopepId",
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.only(start: 16.0),
                          child: Text(
                            "MAC/DEV: ${widget.deviceId}",
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.only(start: 16.0),
                          child: Text(
                            "MTU size: ${widget.bleInteractor.geMtuBytes()} Bytes",
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 3,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                          start: 2.0, top: 8.0, end: 16.0),
                      child: widget.deviceConnectionStatus ==
                              DeviceConnectionState.connecting
                          ? ElevatedButton(
                              onPressed: null,
                              child: Text('Connecting'),
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      widget.deviceConnectionStatus ==
                                              DeviceConnectionState.disconnected
                                          ? Color.fromARGB(255, 52, 203, 72)
                                          : Color.fromARGB(255, 255, 73, 73)),
                              onPressed: () {
                                if (widget.deviceConnectionStatus ==
                                    DeviceConnectionState.disconnected) {
                                  _connect();
                                } else if (widget.deviceConnectionStatus ==
                                    DeviceConnectionState.connected) {
                                  _bleSopepResponseData.rspTextTimestamp = "";
                                  _bleSopepResponseData.rspText = "";
                                  _bleSopepResponseData
                                      .eventNewDataTextTimestamp = "";
                                  _bleSopepResponseData.eventNewDataText = "";
                                  _bleSopepResponseData
                                      .eventDevStatusTextTimestamp = "";
                                  _bleSopepResponseData.eventDevStatusText = "";
                                  widget.bleInteractor
                                      .disconnect(widget.deviceId, _sopepId);
                                  _sopepStreamSubscription?.cancel();
                                }
                              },
                              child: widget.deviceConnectionStatus ==
                                      DeviceConnectionState.connected
                                  ? Text('Disconnect')
                                  : Text('Connect'),
                            ),
                    ),
                  ),
                ],
              ),
              UiHelper.divider,
              Padding(
                padding:
                    const EdgeInsetsDirectional.only(bottom: 1.0, start: 16.0),
                child: UiHelper.sectionHeader('Low-Level Messages:'),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _widgetInteractButton('CBOR', _cborDialog),
                    _widgetInteractButton('sOPEP Service', _bleServiceDialog),
                  ],
                ),
              ),
              UiHelper.divider,
              Padding(
                padding:
                    const EdgeInsetsDirectional.only(bottom: 1.0, start: 16.0),
                child: UiHelper.sectionHeader('Commands and Configurations:'),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _widgetInteractButton(
                        'Device Info', _sopepInteractor.getDeviceInfo),
                    _widgetInteractButton('Configure', _configureDialog),
                    _widgetInteractButton('Set Time', _setTimeDialog),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _widgetInteractButton(
                        'Get Prio Data', _getPriorityDataDialog),
                    _widgetInteractButton('Get Data', _getDataDialog),
                    _widgetInteractButton(
                        'Travel', _sopepInteractor.setTravelMode),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _widgetInteractButton('FW Update', _firmwareDialog),
                    _widgetInteractButton(
                        'Get Config Ranges', _sopepInteractor.getConfigRanges),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _widgetInteractButton('Echo', _echoDialog),
                    _widgetInteractButton('Erase Flash', _eraseDialog),
                  ],
                ),
              ),
              UiHelper.divider,
              _widgetResponseInterface(
                  'RSP from sOPEP:',
                  _bleSopepResponseData.rspTextTimestamp,
                  _bleSopepResponseData.rspText),
              UiHelper.divider,
              _widgetResponseInterface(
                  'EVENT (new-data) from sOPEP:',
                  _bleSopepResponseData.eventNewDataTextTimestamp,
                  _bleSopepResponseData.eventNewDataText),
              UiHelper.divider,
              _widgetResponseInterface(
                  'EVENT (device-status) from sOPEP:',
                  _bleSopepResponseData.eventDevStatusTextTimestamp,
                  _bleSopepResponseData.eventDevStatusText),
            ],
          ),
        ),
      ],
    );
  }
}
