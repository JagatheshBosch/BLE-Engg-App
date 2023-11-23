// Copyright (c) 2023, StarIC, author: Justin Y. Kim

import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'package:sopep_app/src/ble/ble_interactor.dart';
import 'package:sopep_app/src/ble/ble_sopep_interactor.dart';
import 'package:sopep_app/src/widgets/ui_helper.dart';

class SopepConfigureInteractionDialog extends StatelessWidget {
  const SopepConfigureInteractionDialog({
    required this.bleInteractor,
    required this.sopepInteractor,
    Key? key,
  }) : super(key: key);

  final BleInteractor bleInteractor;
  final BleSopepInteractor sopepInteractor;

  @override
  Widget build(BuildContext context) => Consumer<BleInteractor>(
      builder: (context, bleInteractor, _) => _SopepConfigureInteractionDialog(
            bleInteractor: bleInteractor,
            sopepInteractor: sopepInteractor,
          ));
}

class _SopepConfigureInteractionDialog extends StatefulWidget {
  const _SopepConfigureInteractionDialog({
    required this.bleInteractor,
    required this.sopepInteractor,
    Key? key,
  }) : super(key: key);

  final BleInteractor bleInteractor;
  final BleSopepInteractor sopepInteractor;

  @override
  _SopepConfigureInteractionDialogState createState() =>
      _SopepConfigureInteractionDialogState();
}

class _SopepConfigureInteractionDialogState
    extends State<_SopepConfigureInteractionDialog> {
  StreamSubscription<BleSopepResponseData>? _sopepStreamSubscription;

  var _ledToggle = true;
  var _ledIntensity = 50;
  late TextEditingController _ledIntensityEditingController;
  var _thresholdGood = 8.5;
  late TextEditingController _thresholdGoodEditingController;
  var _thresholdHigh = 15.2;
  late TextEditingController _thresholdHighEditingController;
  var _targetTreatmentTime = 200.0;
  late TextEditingController _targetTreatmentTimeEditingController;
  var _targetExhalationCount = 5;
  late TextEditingController _targetExhalationCountEditingController;
  var _minBreathLength = 1.2;
  late TextEditingController _minBreathLengthEditingController;
  var _useExhaleCountToggle = false;

  @override
  void initState() {
    _ledIntensityEditingController =
        TextEditingController(text: '$_ledIntensity');
    _thresholdGoodEditingController =
        TextEditingController(text: '$_thresholdGood');
    _thresholdHighEditingController =
        TextEditingController(text: '$_thresholdHigh');
    _targetTreatmentTimeEditingController =
        TextEditingController(text: '$_targetTreatmentTime');
    _targetExhalationCountEditingController =
        TextEditingController(text: '$_targetExhalationCount');
    _minBreathLengthEditingController =
        TextEditingController(text: '$_minBreathLength');

    subscribeCharacteristic();
    widget.sopepInteractor.getConfigure();
    super.initState();
  }

  @override
  void dispose() {
    _sopepStreamSubscription!.cancel();
    super.dispose();
  }

  Future<void> subscribeCharacteristic() async {
    _sopepStreamSubscription = widget.bleInteractor
        .getSopepInteractor()
        .getSopepStreamController()
        .stream
        .listen((bleSopepResponseData) {
      // Got new data; update our response text display
      setState(() {
        if (bleSopepResponseData.dataMap!['rsp'] == 'configure') {
          // Display decoded CBOR
          _ledToggle = bleSopepResponseData.dataMap?['led-toggle'] as bool;
          _ledIntensityEditingController = TextEditingController(
              text: '${bleSopepResponseData.dataMap?['led-intensity']}');
          _thresholdGoodEditingController = TextEditingController(
              text: '${bleSopepResponseData.dataMap?['good-zone-threshold']}');
          _thresholdHighEditingController = TextEditingController(
              text: '${bleSopepResponseData.dataMap?['high-zone-threshold']}');
          _targetTreatmentTimeEditingController = TextEditingController(
              text:
                  '${bleSopepResponseData.dataMap?['target-treatment-time']}');
          _targetExhalationCountEditingController = TextEditingController(
              text:
                  '${bleSopepResponseData.dataMap?['target-exhalation-count']}');
          _minBreathLengthEditingController = TextEditingController(
              text:
                  '${bleSopepResponseData.dataMap?['minimum-breath-length']}');
          _useExhaleCountToggle =
              bleSopepResponseData.dataMap?['use-exhalation-count'] as bool;
        }
      });
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
                'Configure settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              UiHelper.divider,
              // LED toggle ----------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'LED Toggle',
                    style: TextStyle(fontSize: 14),
                  ),
                  Switch(
                    // This bool value toggles the switch.
                    value: _ledToggle,
                    activeColor: Color.fromARGB(255, 40, 211, 40),
                    onChanged: (bool value) {
                      setState(() {
                        _ledToggle = value;
                      });
                    },
                  ),
                ],
              ),
              UiHelper.dividerNoLine,
              // LED intensity -------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Text(
                      'LED Intensity',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      textAlign: TextAlign.right,
                      controller: _ledIntensityEditingController,
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
              // Thesholds for low, good, and high -----------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: const Text(
                      'Thresholds',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      textAlign: TextAlign.right,
                      controller: _thresholdGoodEditingController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Good',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      textAlign: TextAlign.right,
                      controller: _thresholdHighEditingController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'High',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                    ),
                  ),
                ],
              ),
              UiHelper.dividerNoLine,
              // Target treatment ----------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Text(
                      'Target Time',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      textAlign: TextAlign.right,
                      controller: _targetTreatmentTimeEditingController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                        signed: false,
                      ),
                      /*inputFormatters: [
                    LimitRange(0, 100),
                  ],*/
                    ),
                  ),
                ],
              ),
              UiHelper.dividerNoLine,
              // Target exhalation count ---------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Text(
                      'Traget Exhale Count',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      textAlign: TextAlign.right,
                      controller: _targetExhalationCountEditingController,
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
              // Minimum breath length -----------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Text(
                      'Min Breath Length',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      textAlign: TextAlign.right,
                      controller: _minBreathLengthEditingController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                    ),
                  ),
                ],
              ),
              UiHelper.dividerNoLine,
              // Use exhalation count ------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Use Exhalation Count',
                    style: TextStyle(fontSize: 14),
                  ),
                  Switch(
                    // This bool value toggles the switch.
                    value: _useExhaleCountToggle,
                    activeColor: Color.fromARGB(255, 40, 211, 40),
                    onChanged: (bool value) {
                      setState(() {
                        _useExhaleCountToggle = value;
                      });
                    },
                  ),
                ],
              ),
              UiHelper.divider,
              // Send button ---------------------------------------------------
              ElevatedButton(
                onPressed: () {
                  widget.sopepInteractor.setConfigure(
                    _ledToggle,
                    int.parse(_ledIntensityEditingController.text),
                    double.parse(_thresholdGoodEditingController.text),
                    double.parse(_thresholdHighEditingController.text),
                    double.parse(_targetTreatmentTimeEditingController.text),
                    int.parse(_targetExhalationCountEditingController.text),
                    double.parse(_minBreathLengthEditingController.text),
                    _useExhaleCountToggle,
                  );
                },
                child: const Text('Send'),
              ),
            ],
          ),
        ),
      );
}
