// Copyright (c) 2023, StarIC, author: Justin Y. Kim

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';

import 'package:sopep_app/src/ble/ble_interactor.dart';
import 'package:sopep_app/src/utilities/encoder_decoder.dart';
import 'package:sopep_app/src/widgets/ui_helper.dart';

class _GroupControllers {
  TextEditingController str = TextEditingController();
  TextEditingController val = TextEditingController();
  void dispose() {
    str.dispose();
    val.dispose();
  }
}

class CborInteractionDialog extends StatelessWidget {
  const CborInteractionDialog({
    required this.characteristic,
    Key? key,
  }) : super(key: key);
  final QualifiedCharacteristic characteristic;

  @override
  Widget build(BuildContext context) => Consumer<BleInteractor>(
      builder: (context, bleInteractor, _) => _CborInteractionDialog(
            characteristic: characteristic,
            readCharacteristic: bleInteractor.readCharacteristic,
            writeWithResponse: bleInteractor.writeCharacterisiticWithResponse,
            writeWithoutResponse:
                bleInteractor.writeCharacterisiticWithoutResponse,
            writeCborWithoutResponse: bleInteractor.writeCborWithoutResponse,
            subscribeToCharacteristic: bleInteractor.subScribeToCharacteristic,
          ));
}

class _CborInteractionDialog extends StatefulWidget {
  const _CborInteractionDialog({
    required this.characteristic,
    required this.readCharacteristic,
    required this.writeWithResponse,
    required this.writeWithoutResponse,
    required this.writeCborWithoutResponse,
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
  final Future<void> Function(QualifiedCharacteristic characteristic,
      {required Object data, required bool log}) writeCborWithoutResponse;

  @override
  _CborInteractionDialogState createState() => _CborInteractionDialogState();
}

class _CborInteractionDialogState extends State<_CborInteractionDialog> {
  EncoderDecoder _encoderDecoder = EncoderDecoder();
  late String rxDataStr;
  final bottomKey = GlobalKey();
  StreamSubscription<List<int>>? subscribeStream;
  List<int> dataRaw = [];
  List<_GroupControllers> _groupControllers = [];
  List<TextField> _strFields = [];
  List<TextField> _valFields = [];

  @override
  void initState() {
    rxDataStr = '';
    subscribeCharacteristic();
    super.initState();
  }

  @override
  void dispose() {
    for (final controller in _groupControllers) {
      controller.dispose();
    }
    subscribeStream?.cancel();
    super.dispose();
  }

  bool _isNumeric(String str) {
    return double.tryParse(str) != null;
  }

  Object _parseInput() {
    Object _val;

    if (_isNumeric(_groupControllers[0].val.text)) {
      _val = num.parse(_groupControllers[0].val.text);
    } else {
      _val = _groupControllers[0].val.text;
    }
    Map<Object, Object> raw = {
      _groupControllers[0].str.text: _val,
    };
    String text = "[0]: '${_groupControllers[0].str.text}': " +
        "${_groupControllers[0].val.text}\n";
    print(text);

    for (var i = 1; i < _groupControllers.length; i++) {
      if (_isNumeric(_groupControllers[i].val.text)) {
        _val = num.parse(_groupControllers[i].val.text);
      } else {
        _val = _groupControllers[i].val.text;
      }
      raw[_groupControllers[i].str.text] = _val;

      String text = "[$i]: '${_groupControllers[i].str.text}': " +
          "${_groupControllers[i].val.text}\n";
      print(text);
    }

    return raw;
  }

  TextField _generateTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: hint,
      ),
    );
  }

  Widget _addTile() {
    return ListTile(
      title: Icon(Icons.add),
      onTap: () {
        final group = _GroupControllers();
        final nameField = _generateTextField(group.str, "String");
        final telField = _generateTextField(group.val, "Value");
        setState(() {
          _groupControllers.add(group);
          _strFields.add(nameField);
          _valFields.add(telField);
        });
      },
    );
  }

  Widget _listView() {
    final children = [
      for (var i = 0; i < _groupControllers.length; i++)
        Container(
          margin: EdgeInsets.all(5),
          child: InputDecorator(
            child: Column(
              children: [
                _strFields[i],
                SizedBox(height: 10),
                _valFields[i],
              ],
            ),
            decoration: InputDecoration(
              labelText: i.toString(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        )
    ];
    return SingleChildScrollView(
      child: Column(
        children: children,
      ),
    );
  }

  Future<void> subscribeCharacteristic() async {
    subscribeStream =
        widget.subscribeToCharacteristic(widget.characteristic).listen((data) {
      dataRaw = [...dataRaw, ...data];
      var dataMap = _encoderDecoder.decode(dataRaw);
      setState(() {
        if (dataMap != null) {
          // Display decoded CBOR, scroll to bottom, and close input keyboard
          rxDataStr = 'rxData = ${EncoderDecoder.cborToPrettyStr(dataMap)}';
          Scrollable.ensureVisible(bottomKey.currentContext!);
          FocusManager.instance.primaryFocus?.unfocus();
        } else {
          rxDataStr = 'Invalid CBOR data received...';
        }
      });
    });
    setState(() {
      rxDataStr = '';
    });
  }

  List<Widget> get subscribeSection => [
        UiHelper.sectionHeader('RX Data'),
        UiHelper.dividerNoLine,
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$rxDataStr',
              style: const TextStyle(fontSize: 11),
            )
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
                'Enter CBOR Data',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              UiHelper.divider,
              _addTile(),
              _listView(),
              UiHelper.divider,
              ElevatedButton(
                onPressed: _strFields.isNotEmpty
                    ? () {
                        widget.writeCborWithoutResponse(widget.characteristic,
                            data: _parseInput(), log: true);
                        rxDataStr = '';
                        dataRaw = [];
                      }
                    : null,
                child: const Text('Send'),
              ),
              UiHelper.divider,
              ...subscribeSection,
              Text(
                '',
                key: bottomKey,
              )
            ],
          ),
        ),
      );
}
