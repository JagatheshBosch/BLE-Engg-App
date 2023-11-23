// Copyright (c) 2023, StarIC, author: Justin Y. Kim

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sopep_app/src/ble/ble_interactor.dart';
import 'package:sopep_app/src/ble/ble_sopep_interactor.dart';
import 'package:sopep_app/src/widgets/ui_helper.dart';

class SopepEraseDialog extends StatelessWidget {
  const SopepEraseDialog({
    required this.sopepInteractor,
    Key? key,
  }) : super(key: key);

  final BleSopepInteractor sopepInteractor;

  @override
  Widget build(BuildContext context) => Consumer<BleInteractor>(
      builder: (context, bleInteractor, _) => _SopepEraseDialog(
            sopepInteractor: sopepInteractor,
          ));
}

class _SopepEraseDialog extends StatefulWidget {
  const _SopepEraseDialog({
    required this.sopepInteractor,
    Key? key,
  }) : super(key: key);

  final BleSopepInteractor sopepInteractor;

  @override
  _SopepEraseDialogState createState() => _SopepEraseDialogState();
}

class _SopepEraseDialogState extends State<_SopepEraseDialog> {
  bool _isCheckedData = false;
  bool _isCheckedPrioData = false;
  bool _isCheckedDiagData = false;
  bool _isCheckedConfig = false;
  bool _isCheckedBleBonds = false;
  bool _toggleDeleteFormatData = false;
  bool _toggleDeleteFormatPrioData = false;
  bool _toggleDeleteFormatDiagData = false;

  @override
  void initState() {
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
                'Erase Memory',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              UiHelper.divider,
              Row(
                children: <Widget>[
                  Checkbox(
                    value: _isCheckedData,
                    onChanged: (bool? value) {
                      setState(() {
                        _isCheckedData = value!;
                      });
                    },
                  ),
                  Text('Pressure data'),
                ],
              ),
              Row(
                children: _isCheckedData
                    ? [
                        SizedBox(width: 40),
                        Text(
                          'Delete',
                          style: !_toggleDeleteFormatData
                              ? TextStyle(fontWeight: FontWeight.bold)
                              : null,
                        ),
                        Switch(
                          // This bool value toggles the switch.
                          value: _toggleDeleteFormatData,
                          activeColor: Color.fromARGB(255, 40, 211, 40),
                          activeTrackColor: Color.fromARGB(255, 40, 211, 40),
                          inactiveThumbColor: Color.fromARGB(255, 40, 211, 40),
                          inactiveTrackColor: Color.fromARGB(255, 40, 211, 40),
                          onChanged: (bool value) {
                            setState(() {
                              _toggleDeleteFormatData = value;
                            });
                          },
                        ),
                        Text(
                          'Format',
                          style: _toggleDeleteFormatData
                              ? TextStyle(fontWeight: FontWeight.bold)
                              : null,
                        ),
                      ]
                    : [],
              ),
              Row(
                children: <Widget>[
                  Checkbox(
                    value: _isCheckedPrioData,
                    onChanged: (bool? value) {
                      setState(() {
                        _isCheckedPrioData = value!;
                      });
                    },
                  ),
                  Text('Priority data'),
                ],
              ),
              Row(
                children: _isCheckedPrioData
                    ? [
                        SizedBox(width: 40),
                        Text(
                          'Delete',
                          style: !_toggleDeleteFormatPrioData
                              ? TextStyle(fontWeight: FontWeight.bold)
                              : null,
                        ),
                        Switch(
                          // This bool value toggles the switch.
                          value: _toggleDeleteFormatPrioData,
                          activeColor: Color.fromARGB(255, 40, 211, 40),
                          activeTrackColor: Color.fromARGB(255, 40, 211, 40),
                          inactiveThumbColor: Color.fromARGB(255, 40, 211, 40),
                          inactiveTrackColor: Color.fromARGB(255, 40, 211, 40),
                          onChanged: (bool value) {
                            setState(() {
                              _toggleDeleteFormatPrioData = value;
                            });
                          },
                        ),
                        Text(
                          'Format',
                          style: _toggleDeleteFormatPrioData
                              ? TextStyle(fontWeight: FontWeight.bold)
                              : null,
                        ),
                      ]
                    : [],
              ),
              Row(
                children: <Widget>[
                  Checkbox(
                    value: _isCheckedDiagData,
                    onChanged: (bool? value) {
                      setState(() {
                        _isCheckedDiagData = value!;
                      });
                    },
                  ),
                  Text('Diagnostic data'),
                ],
              ),
              Row(
                children: _isCheckedDiagData
                    ? [
                        SizedBox(width: 40),
                        Text(
                          'Delete',
                          style: !_toggleDeleteFormatDiagData
                              ? TextStyle(fontWeight: FontWeight.bold)
                              : null,
                        ),
                        Switch(
                          // This bool value toggles the switch.
                          value: _toggleDeleteFormatDiagData,
                          activeColor: Color.fromARGB(255, 40, 211, 40),
                          activeTrackColor: Color.fromARGB(255, 40, 211, 40),
                          inactiveThumbColor: Color.fromARGB(255, 40, 211, 40),
                          inactiveTrackColor: Color.fromARGB(255, 40, 211, 40),
                          onChanged: (bool value) {
                            setState(() {
                              _toggleDeleteFormatDiagData = value;
                            });
                          },
                        ),
                        Text(
                          'Format',
                          style: _toggleDeleteFormatDiagData
                              ? TextStyle(fontWeight: FontWeight.bold)
                              : null,
                        ),
                      ]
                    : [],
              ),
              Row(
                children: <Widget>[
                  Checkbox(
                    value: _isCheckedConfig,
                    onChanged: (bool? value) {
                      setState(() {
                        _isCheckedConfig = value!;
                      });
                    },
                  ),
                  Text('Reset configuration'),
                ],
              ),
              Row(
                children: <Widget>[
                  Checkbox(
                    value: _isCheckedBleBonds,
                    onChanged: (bool? value) {
                      setState(() {
                        _isCheckedBleBonds = value!;
                      });
                    },
                  ),
                  Text('Delete BLE bonds'),
                ],
              ),
              UiHelper.dividerNoLine,
              ElevatedButton(
                onPressed: () {
                  widget.sopepInteractor.eraseFlash(
                    _isCheckedData,
                    _toggleDeleteFormatData,
                    _isCheckedPrioData,
                    _toggleDeleteFormatPrioData,
                    _isCheckedDiagData,
                    _toggleDeleteFormatDiagData,
                    _isCheckedConfig,
                    _isCheckedBleBonds,
                  );
                },
                child: const Text('Erase'),
              ),
            ],
          ),
        ),
      );
}
