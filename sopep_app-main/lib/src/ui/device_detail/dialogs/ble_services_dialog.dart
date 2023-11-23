// Copyright (c) 2023, StarIC, author: Justin Y. Kim

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';

import 'package:sopep_app/src/ble/ble_interactor.dart';
import 'package:sopep_app/src/ui/device_detail/dialogs/characteristic_interaction_dialog.dart';

class BleServicesDialog extends StatelessWidget {
  final DiscoveredDevice device;
  final QualifiedCharacteristic characteristic;

  const BleServicesDialog({
    required this.device,
    required this.characteristic,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Consumer2<BleInteractor, ConnectionStateUpdate>(
        builder: (context, bleInteractor, connectionStateUpdate, _) =>
            _BleServicesDialog(
                device: device,
                characteristic: characteristic,
                readCharacteristic: bleInteractor.readCharacteristic,
                writeWithResponse:
                    bleInteractor.writeCharacterisiticWithResponse,
                writeWithoutResponse:
                    bleInteractor.writeCharacterisiticWithoutResponse,
                subscribeToCharacteristic:
                    bleInteractor.subScribeToCharacteristic,
                connectionStatus: connectionStateUpdate.connectionState,
                discoverServices: () =>
                    bleInteractor.discoverServices(device.id)),
      );
}

class _BleServicesDialog extends StatefulWidget {
  const _BleServicesDialog({
    required this.device,
    required this.characteristic,
    required this.readCharacteristic,
    required this.writeWithResponse,
    required this.writeWithoutResponse,
    required this.subscribeToCharacteristic,
    required this.connectionStatus,
    required this.discoverServices,
    Key? key,
  }) : super(key: key);

  final DiscoveredDevice device;
  final QualifiedCharacteristic characteristic;
  final DeviceConnectionState connectionStatus;
  final Future<List<DiscoveredService>> Function() discoverServices;

  final Future<List<int>> Function(QualifiedCharacteristic characteristic)
      readCharacteristic;
  final Future<void> Function(
          QualifiedCharacteristic characteristic, List<int> value)
      writeWithResponse;

  final Stream<List<int>> Function(QualifiedCharacteristic characteristic)
      subscribeToCharacteristic;

  final Future<void> Function(
          QualifiedCharacteristic characteristic, List<int> value)
      writeWithoutResponse;

  bool get deviceConnected =>
      connectionStatus == DeviceConnectionState.connected;

  @override
  _BleServicesDialogState createState() => _BleServicesDialogState();
}

class _BleServicesDialogState extends State<_BleServicesDialog> {
  late List<DiscoveredService> discoveredServices;

  @override
  void initState() {
    discoveredServices = [];
    if (widget.deviceConnected) {
      discoverServices();
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> discoverServices() async {
    final result = await widget.discoverServices();
    setState(() {
      discoveredServices = result;
    });
  }

  @override
  Widget build(BuildContext context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'BLE Services',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (widget.deviceConnected)
                _ServiceDiscoveryList(
                  deviceId: widget.device.id,
                  discoveredServices: discoveredServices,
                ),
            ],
          ),
        ),
      );
}

class _ServiceDiscoveryList extends StatefulWidget {
  const _ServiceDiscoveryList({
    required this.deviceId,
    required this.discoveredServices,
    Key? key,
  }) : super(key: key);

  final String deviceId;
  final List<DiscoveredService> discoveredServices;

  @override
  _ServiceDiscoveryListState createState() => _ServiceDiscoveryListState();
}

class _ServiceDiscoveryListState extends State<_ServiceDiscoveryList> {
  late final List<int> _expandedItems;

  @override
  void initState() {
    _expandedItems = [];
    super.initState();
  }

  String _charactisticsSummary(DiscoveredCharacteristic c) {
    final props = <String>[];
    if (c.isReadable) {
      props.add("read");
    }
    if (c.isWritableWithoutResponse) {
      props.add("write without response");
    }
    if (c.isWritableWithResponse) {
      props.add("write with response");
    }
    if (c.isNotifiable) {
      props.add("notify");
    }
    if (c.isIndicatable) {
      props.add("indicate");
    }

    return props.join("\n");
  }

  Widget _characteristicTile(
          DiscoveredCharacteristic characteristic, String deviceId) =>
      ListTile(
        onTap: () => showDialog<void>(
            context: context,
            builder: (context) => CharacteristicInteractionDialog(
                  characteristic: QualifiedCharacteristic(
                      characteristicId: characteristic.characteristicId,
                      serviceId: characteristic.serviceId,
                      deviceId: deviceId),
                )),
        title: Text(
          '${characteristic.characteristicId}\n(${_charactisticsSummary(characteristic)})',
          style: const TextStyle(
            fontSize: 13,
          ),
        ),
      );

  List<ExpansionPanel> buildPanels() {
    final panels = <ExpansionPanel>[];

    widget.discoveredServices.asMap().forEach(
          (index, service) => panels.add(
            ExpansionPanel(
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsetsDirectional.only(start: 16.0),
                    child: Text(
                      'Characteristics',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    itemBuilder: (context, index) => _characteristicTile(
                      service.characteristics[index],
                      widget.deviceId,
                    ),
                    itemCount: service.characteristicIds.length,
                  ),
                ],
              ),
              headerBuilder: (context, isExpanded) => ListTile(
                title: Text(
                  '${service.serviceId}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              isExpanded: _expandedItems.contains(index),
            ),
          ),
        );

    return panels;
  }

  @override
  Widget build(BuildContext context) => widget.discoveredServices.isEmpty
      ? const SizedBox()
      : Padding(
          padding: const EdgeInsetsDirectional.only(
            top: 20.0,
            start: 20.0,
            end: 20.0,
          ),
          child: ExpansionPanelList(
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                setState(() {
                  if (isExpanded) {
                    _expandedItems.remove(index);
                  } else {
                    _expandedItems.add(index);
                  }
                });
              });
            },
            children: [
              ...buildPanels(),
            ],
          ),
        );
}
