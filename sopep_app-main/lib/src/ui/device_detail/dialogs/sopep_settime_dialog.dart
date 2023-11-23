// Copyright (c) 2023, StarIC, author: Justin Y. Kim

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';

import 'package:sopep_app/src/ble/ble_interactor.dart';
import 'package:sopep_app/src/ble/ble_sopep_interactor.dart';
import 'package:sopep_app/src/widgets/ui_helper.dart';

class SopepSetTimeInteractionDialog extends StatelessWidget {
  const SopepSetTimeInteractionDialog({
    required this.sopepInteractor,
    Key? key,
  }) : super(key: key);

  final BleSopepInteractor sopepInteractor;

  @override
  Widget build(BuildContext context) => Consumer<BleInteractor>(
      builder: (context, bleInteractor, _) => _SopepSetTimeInteractionDialog(
            sopepInteractor: sopepInteractor,
          ));
}

class _SopepSetTimeInteractionDialog extends StatefulWidget {
  const _SopepSetTimeInteractionDialog({
    required this.sopepInteractor,
    Key? key,
  }) : super(key: key);

  final BleSopepInteractor sopepInteractor;

  @override
  _SopepSetTimeInteractionDialogState createState() =>
      _SopepSetTimeInteractionDialogState();
}

class _SopepSetTimeInteractionDialogState
    extends State<_SopepSetTimeInteractionDialog> {
  var _currentTime = 0;
  late TextEditingController _currentTimeEditingController;

  @override
  void initState() {
    _currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _currentTimeEditingController =
        TextEditingController(text: '$_currentTime');
    super.initState();
  }

  @override
  void dispose() {
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
                'Set time',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              UiHelper.divider,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Text(
                      'Timestamp (s)',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      textAlign: TextAlign.right,
                      controller: _currentTimeEditingController,
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
                  widget.sopepInteractor
                      .setTime(int.parse(_currentTimeEditingController.text));
                },
                child: const Text('Send'),
              ),
            ],
          ),
        ),
      );
}
