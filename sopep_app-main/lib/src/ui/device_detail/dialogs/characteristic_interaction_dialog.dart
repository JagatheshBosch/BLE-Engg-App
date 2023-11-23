// Copyright (c) 2023, StarIC, author: Justin Y. Kim
// Copyright (c) 2023, authors of flutter_reactive_ble

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';

import 'package:sopep_app/src/ble/ble_interactor.dart';
import 'package:sopep_app/src/widgets/ui_helper.dart';

class CharacteristicInteractionDialog extends StatelessWidget {
  const CharacteristicInteractionDialog({
    required this.characteristic,
    Key? key,
  }) : super(key: key);
  final QualifiedCharacteristic characteristic;

  @override
  Widget build(BuildContext context) => Consumer<BleInteractor>(
      builder: (context, bleInteractor, _) => _CharacteristicInteractionDialog(
            characteristic: characteristic,
            readCharacteristic: bleInteractor.readCharacteristic,
            writeWithResponse: bleInteractor.writeCharacterisiticWithResponse,
            writeWithoutResponse:
                bleInteractor.writeCharacterisiticWithoutResponse,
            subscribeToCharacteristic: bleInteractor.subScribeToCharacteristic,
          ));
}

class _CharacteristicInteractionDialog extends StatefulWidget {
  const _CharacteristicInteractionDialog({
    required this.characteristic,
    required this.readCharacteristic,
    required this.writeWithResponse,
    required this.writeWithoutResponse,
    required this.subscribeToCharacteristic,
    Key? key,
  }) : super(key: key);

  final QualifiedCharacteristic characteristic;
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

  @override
  _CharacteristicInteractionDialogState createState() =>
      _CharacteristicInteractionDialogState();
}

class _CharacteristicInteractionDialogState
    extends State<_CharacteristicInteractionDialog> {
  late String readOutput;
  late String writeOutput;
  late String subscribeOutput;
  late TextEditingController textEditingController;
  StreamSubscription<List<int>>? subscribeStream;

  @override
  void initState() {
    readOutput = '';
    writeOutput = '';
    subscribeOutput = '';
    textEditingController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    subscribeStream?.cancel();
    super.dispose();
  }

  Future<void> subscribeCharacteristic() async {
    subscribeStream =
        widget.subscribeToCharacteristic(widget.characteristic).listen((event) {
      setState(() {
        subscribeOutput = event.toString();
      });
    });
    setState(() {
      subscribeOutput = 'Notification set';
    });
  }

  Future<void> readCharacteristic() async {
    final result = await widget.readCharacteristic(widget.characteristic);
    setState(() {
      readOutput = result.toString();
    });
  }

  List<int> _parseInput() => textEditingController.text
      .split(',')
      .map(
        int.parse,
      )
      .toList();

  Future<void> writeCharacteristicWithResponse() async {
    await widget.writeWithResponse(widget.characteristic, _parseInput());
    setState(() {
      writeOutput = 'Ok';
    });
  }

  Future<void> writeCharacteristicWithoutResponse() async {
    await widget.writeWithoutResponse(widget.characteristic, _parseInput());
    setState(() {
      writeOutput = 'Done';
    });
  }

  List<Widget> get writeSection => [
        UiHelper.sectionHeader('Write characteristic'),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: textEditingController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Value',
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: false,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: writeCharacteristicWithResponse,
              child: const Text('W/'),
            ),
            ElevatedButton(
              onPressed: writeCharacteristicWithoutResponse,
              child: const Text('W/O'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 8.0),
          child: Text('Output: $writeOutput'),
        ),
      ];

  List<Widget> get readSection => [
        UiHelper.sectionHeader('Read characteristic'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: readCharacteristic,
              child: const Text('Read'),
            ),
            Text('Output: $readOutput'),
          ],
        ),
      ];

  List<Widget> get subscribeSection => [
        UiHelper.sectionHeader('Subscribe / notify'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: subscribeCharacteristic,
              child: const Text('Subscribe'),
            ),
            Text('Output: $subscribeOutput'),
          ],
        ),
      ];

  @override
  Widget build(BuildContext context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Select an operation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  widget.characteristic.characteristicId.toString(),
                ),
              ),
              UiHelper.divider,
              ...readSection,
              UiHelper.divider,
              ...writeSection,
              UiHelper.divider,
              ...subscribeSection,
              UiHelper.divider,
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('close')),
                ),
              )
            ],
          ),
        ),
      );
}
