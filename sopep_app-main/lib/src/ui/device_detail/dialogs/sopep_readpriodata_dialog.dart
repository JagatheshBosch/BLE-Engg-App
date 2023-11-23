// Copyright (c) 2023, StarIC, author: Justin Y. Kim

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';

import 'package:sopep_app/src/ble/ble_interactor.dart';
import 'package:sopep_app/src/ble/ble_sopep_interactor.dart';
import 'package:sopep_app/src/widgets/ui_helper.dart';

class SopepReadPrioDataInteractionDialog extends StatelessWidget {
  const SopepReadPrioDataInteractionDialog({
    required this.characteristic,
    required this.sopepInteractor,
    Key? key,
  }) : super(key: key);

  final QualifiedCharacteristic characteristic;
  final BleSopepInteractor sopepInteractor;

  @override
  Widget build(BuildContext context) => Consumer<BleInteractor>(
      builder: (context, bleInteractor, _) =>
          _SopepReadPrioDataInteractionDialog(
            characteristic: characteristic,
            subscribeToCharacteristic: bleInteractor.subScribeToCharacteristic,
            sopepInteractor: sopepInteractor,
          ));
}

class _SopepReadPrioDataInteractionDialog extends StatefulWidget {
  const _SopepReadPrioDataInteractionDialog({
    required this.characteristic,
    required this.subscribeToCharacteristic,
    required this.sopepInteractor,
    Key? key,
  }) : super(key: key);

  final QualifiedCharacteristic characteristic;
  final Stream<List<int>> Function(QualifiedCharacteristic characteristic)
      subscribeToCharacteristic;
  final BleSopepInteractor sopepInteractor;

  @override
  _SopepReadPrioDataInteractionDialogState createState() =>
      _SopepReadPrioDataInteractionDialogState();
}

class _SopepReadPrioDataInteractionDialogState
    extends State<_SopepReadPrioDataInteractionDialog> {
  StreamSubscription<List<int>>? subscribeStream;
  List<int> dataRaw = [];
  Map<Object?, Object?>? dataMap;

  var _dataSeq = 0;
  late TextEditingController _dataSeqEditingController;

  @override
  void initState() {
    _dataSeqEditingController = TextEditingController(text: '$_dataSeq');
    super.initState();
  }

  @override
  void dispose() {
    subscribeStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Get ACT Priority Data',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              UiHelper.divider,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Text(
                      'Seq number\n(send empty\nto get earliest\nseq num)',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      textAlign: TextAlign.right,
                      controller: _dataSeqEditingController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                        signed: false,
                      ),
                    ),
                  ),
                ],
              ),
              UiHelper.dividerNoLine,
              ElevatedButton(
                onPressed: () {
                  if (_dataSeqEditingController.text.isNotEmpty) {
                    widget.sopepInteractor.getPriorityData(
                        int.parse(_dataSeqEditingController.text));
                  } else {
                    widget.sopepInteractor.getOldestPriorityData();
                  }
                },
                child: const Text('Send'),
              ),
            ],
          ),
        ),
      );
}
