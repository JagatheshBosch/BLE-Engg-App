// Copyright (c) 2023, StarIC, author: Justin Y. Kim

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sopep_app/src/ble/ble_interactor.dart';
import 'package:sopep_app/src/ble/ble_sopep_interactor.dart';
import 'package:sopep_app/src/widgets/ui_helper.dart';

class SopepEchoDialog extends StatelessWidget {
  const SopepEchoDialog({
    required this.sopepInteractor,
    Key? key,
  }) : super(key: key);

  final BleSopepInteractor sopepInteractor;

  @override
  Widget build(BuildContext context) => Consumer<BleInteractor>(
      builder: (context, bleInteractor, _) => _SopepEchoDialog(
            sopepInteractor: sopepInteractor,
          ));
}

class _SopepEchoDialog extends StatefulWidget {
  const _SopepEchoDialog({
    required this.sopepInteractor,
    Key? key,
  }) : super(key: key);

  final BleSopepInteractor sopepInteractor;

  @override
  _SopepEchoDialogState createState() => _SopepEchoDialogState();
}

class _SopepEchoDialogState extends State<_SopepEchoDialog> {
  late TextEditingController _totalBytesEditingController;

  @override
  void initState() {
    _totalBytesEditingController = TextEditingController(text: '215');
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
                'Echo Payload Test',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              UiHelper.divider,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Text(
                      'Total TX bytes',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      textAlign: TextAlign.right,
                      controller: _totalBytesEditingController,
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
                  widget.sopepInteractor.sendEchoTest(
                      int.parse(_totalBytesEditingController.text));
                },
                child: const Text('Send'),
              ),
            ],
          ),
        ),
      );
}
