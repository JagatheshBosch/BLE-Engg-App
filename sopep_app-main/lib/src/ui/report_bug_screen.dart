// Copyright (c) 2023, StarIC, author: Justin Y. Kim

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:convert/convert.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sopep_app/src/ble/ble_interactor.dart';
import 'package:sopep_app/src/widgets/ui_helper.dart';

class BugReportScreen extends StatelessWidget {
  final DiscoveredDevice device;
  final QualifiedCharacteristic characteristic;

  const BugReportScreen({
    required this.device,
    required this.characteristic,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Consumer2<BleInteractor, ConnectionStateUpdate>(
        builder: (context, bleInteractor, connectionStateUpdate, _) =>
            _BugReportScreen(
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

class _BugReportScreen extends StatefulWidget {
  const _BugReportScreen({
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
  _BugReportScreenState createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<_BugReportScreen> {
  String? _version;
  String? _buildNumber;
  String appPlatform = 'Unknown';
  String firmwareVersion = '*Need to connect to device...';
  late TextEditingController testerNameTextEditingController;
  late TextEditingController stepsTextEditingController;
  late TextEditingController bugResultTextEditingController;
  late TextEditingController expectedResultTextEditingController;
  final String emailAddress = "sopep_debuglogs@staric.ca";

  @override
  void initState() {
    testerNameTextEditingController = TextEditingController();
    stepsTextEditingController = TextEditingController();
    bugResultTextEditingController = TextEditingController();
    expectedResultTextEditingController = TextEditingController();

    _getAppVersion();
    if (Platform.isAndroid) {
      appPlatform = 'Android';
    } else if (Platform.isIOS) {
      appPlatform = 'iOS';
    }

    if (widget.deviceConnected) {
      _getFirmwareVersion();
    }

    super.initState();
  }

  Future<void> _getFirmwareVersion() async {
    late QualifiedCharacteristic devCharacteristic = QualifiedCharacteristic(
        serviceId: Uuid.parse('180a'),
        characteristicId: Uuid.parse('2a26'),
        deviceId: widget.device.id);

    final firmwareVerRaw = await widget.readCharacteristic(devCharacteristic);
    setState(() {
      firmwareVersion = String.fromCharCodes(firmwareVerRaw);
    });
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

  bool userInputIsGood() {
    if (testerNameTextEditingController.text.isEmpty ||
        stepsTextEditingController.text.isEmpty ||
        bugResultTextEditingController.text.isEmpty ||
        expectedResultTextEditingController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Invalid Bug Report"),
          content: Text("Please fill out all text form sections!"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                //Navigator.pop(context); TODO: RE-ENABLE AFTER DONE!
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                child: const Text("Okay"),
              ),
            ),
          ],
        ),
      );

      return false;
    }

    return true;
  }

  void sendBugReportEmail() async {
    final time = DateFormat("hh:mm:ss a").format(DateTime.now());
    final date = DateFormat("yyyy-MM-dd").format(DateTime.now());
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    await firestore.collection('mail').add(
      {
        'to': "$emailAddress",
        'message': {
          'subject': "sOPEP Bug Report ($time, $date)",
          'text': "Device ID:\n"
              "${widget.device.id}"
              "\n\n"
              "Manufacturer ID:\n"
              "0x${hex.encode(widget.device.manufacturerData).toUpperCase().toString()}"
              "\n\n"
              "Device firmware version:\n"
              "$firmwareVersion"
              "\n\n"
              "App version:\n"
              "v$_version (Build: $_buildNumber)"
              "\n\n"
              "App platform:\n"
              "$appPlatform"
              "\n\n"
              "Tester's name:\n"
              "${testerNameTextEditingController.text}"
              "\n\n"
              "Steps to reproduce bug:\n"
              "${stepsTextEditingController.text}"
              "\n\n"
              "Bug result:\n"
              "${bugResultTextEditingController.text}"
              "\n\n"
              "Expected result:\n"
              "${expectedResultTextEditingController.text}",
        },
      },
    ).then(
      (value) {
        print('Email is queued for delivery!');
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Report sOPEP Bug'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            shrinkWrap: true,
            children: [
              // Device info ---------------------------------------------------
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 2.0),
                    child: Text(
                      "Dev ID: ${widget.device.id}",
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    "Mfr ID: 0x${hex.encode(widget.device.manufacturerData).toUpperCase().toString()}",
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Firmware: $firmwareVersion",
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              // App info ------------------------------------------------------
              UiHelper.dividerNoLine,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 2.0),
                    child: Text(
                      "App ver: v$_version (Build: $_buildNumber)",
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    "App platform: $appPlatform",
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              // Tester info ---------------------------------------------------
              UiHelper.divider,
              UiHelper.sectionHeader("Tester's name:"),
              UiHelper.dividerNoLine,
              TextField(
                textCapitalization: TextCapitalization.sentences,
                controller: testerNameTextEditingController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Your name goes here',
                ),
              ),
              UiHelper.dividerNoLine,
              // TextFields ----------------------------------------------------
              UiHelper.divider,
              UiHelper.sectionHeader('Steps to reproduce bug:'),
              UiHelper.dividerNoLine,
              TextField(
                textCapitalization: TextCapitalization.sentences,
                controller: stepsTextEditingController,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter steps here',
                ),
              ),
              UiHelper.dividerNoLine,
              UiHelper.sectionHeader('Bug result:'),
              UiHelper.dividerNoLine,
              TextField(
                textCapitalization: TextCapitalization.sentences,
                controller: bugResultTextEditingController,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter the bug result that you saw',
                ),
              ),
              UiHelper.dividerNoLine,
              UiHelper.sectionHeader('Expected result:'),
              UiHelper.dividerNoLine,
              TextField(
                textCapitalization: TextCapitalization.sentences,
                controller: expectedResultTextEditingController,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter the expected result (without the bug)',
                ),
              ),
              UiHelper.dividerNoLine,
              // Button: send bug report ---------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (userInputIsGood()) {
                        sendBugReportEmail();
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Bug Report Sent"),
                            content: Text(
                                "An email with the bug report and log files have been sent to: $emailAddress"),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  child: const Text("Okay"),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: const Text('Send Bug Report'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
