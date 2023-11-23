// Copyright (c) 2023, StarIC, author: Justin Y. Kim

import 'dart:async';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:sopep_app/src/ble/ble_interactor.dart';
import 'package:sopep_app/src/ble/ble_logger.dart';
import 'package:sopep_app/src/ble/ble_sopep_interactor.dart';
import 'package:sopep_app/src/utilities/file_storage.dart';
import 'package:sopep_app/src/utilities/utils.dart';
import 'package:sopep_app/src/widgets/ui_helper.dart';

class SopepReadDataDialog extends StatelessWidget {
  const SopepReadDataDialog({
    required this.bleInteractor,
    required this.sopepInteractor,
    required this.sopepId,
    Key? key,
  }) : super(key: key);

  final BleInteractor bleInteractor;
  final BleSopepInteractor sopepInteractor;
  final String sopepId;

  @override
  Widget build(BuildContext context) =>
      Consumer3<BleInteractor, FileStorage, BleLogger>(
          builder: (context, bleInteractor, fileStorage, bleLogger, _) =>
              _SopepReadDataDialog(
                bleInteractor: bleInteractor,
                sopepInteractor: sopepInteractor,
                fileStorage: fileStorage,
                sopepId: sopepId,
                logMessage: bleLogger.addToLog,
              ));
}

class _SopepReadDataDialog extends StatefulWidget {
  const _SopepReadDataDialog({
    required this.bleInteractor,
    required this.sopepInteractor,
    required this.fileStorage,
    required this.sopepId,
    required this.logMessage,
    Key? key,
  }) : super(key: key);

  final BleInteractor bleInteractor;
  final BleSopepInteractor sopepInteractor;
  final FileStorage fileStorage;
  final String sopepId;

  final void Function(String message) logMessage;

  @override
  _SopepReadDataDialogState createState() => _SopepReadDataDialogState();
}

class _SopepReadDataDialogState extends State<_SopepReadDataDialog> {
  StreamSubscription<BleSopepResponseData>? _sopepStreamSubscription;
  BleSopepResponseData _bleSopepResponseData = BleSopepResponseData();
  bool _readingInProgress = false;
  bool _readingComplete = false;
  String completeMessage = '';
  String currentSesSet = '';
  int _seqDataOldest = -1;

  @override
  void initState() {
    subscribeCharacteristic();
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
        // Got new data; update our response text display
        _bleSopepResponseData = bleSopepResponseData;

        // Check if pressure data is available on sOPEP device
        if (!_readingInProgress) {
          if (_bleSopepResponseData.dataMap?['rsp'] == 'read-data') {
            _readingInProgress = true;

            if (_bleSopepResponseData.dataMap!['seq'] != null) {
              _seqDataOldest =
                  int.parse(_bleSopepResponseData.dataMap!['seq'].toString());
              _getDataLoop(_seqDataOldest);
            } else {
              completeMessage = 'No new data available';
              _readingComplete = true;
            }
          }
        }
      });
    });
  }

  void _formatData(List<Map<Object?, Object?>> pressureDataRaw) {
    int indexStart = -1, indexEnd = -1;
    Map<Object, Object> pressureDataInfo = {};
    List<int> binaryData = [];
    List<int> binaryDataRaw = [];
    List<double> rawData = [];

    for (int i = 0; i < pressureDataRaw.length; i++) {
      if (pressureDataRaw[i]['type'] == 'Start set') {
        indexStart = i;
      } else if ((indexStart >= 0) &&
          (pressureDataRaw[i]['type'] == 'End set')) {
        indexEnd = i;
      }

      if ((indexStart >= 0) && (indexEnd > 0)) {
        // We have a valid range of datasets; format it and add it to our list
        pressureDataInfo['Session'] = pressureDataRaw[indexStart]['session']!;
        pressureDataInfo['Set'] = pressureDataRaw[indexStart]['set']!;
        pressureDataInfo['Start Time'] = DateFormat("EEE MMM dd HH:mm:ss yyyy")
            .format(DateTime.fromMillisecondsSinceEpoch(
                (pressureDataRaw[indexStart]['timestamp']! as int) * 1000));
        pressureDataInfo['End Time'] = DateFormat("EEE MMM dd HH:mm:ss yyyy")
            .format(DateTime.fromMillisecondsSinceEpoch(
                (pressureDataRaw[indexEnd]['timestamp']! as int) * 1000));
        pressureDataInfo['Num Samples'] =
            pressureDataRaw[indexEnd]['n_samples']!;
        pressureDataInfo['Estimated peak reconstructed error'] =
            pressureDataRaw[indexEnd]['peak_error']!;
        pressureDataInfo['Estimated RMS reconstructed error'] =
            pressureDataRaw[indexEnd]['rms_error']!;
        pressureDataInfo['Estimated compression ratio'] =
            pressureDataRaw[indexEnd]['compression_ratio']!;

        // Grab our binary dataset
        for (int i = indexStart + 1; i < indexEnd; i++) {
          if (pressureDataRaw[i]['type']! == 'Pressure') {
            binaryData = [
              ...binaryData,
              ...pressureDataRaw[i]['data']! as List<int>
            ];
          } else if (pressureDataRaw[i]['type']! == 'Raw Pressure') {
            binaryDataRaw = [
              ...binaryDataRaw,
              ...pressureDataRaw[i]['data']! as List<int>
            ];
          }
        }
        // Format bytes into 32-bit floats if raw pressure data is available
        if (binaryDataRaw.isNotEmpty) {
          for (int i = 0; i < binaryDataRaw.length; i += 4) {
            final bytes = Uint8List.fromList(binaryDataRaw.sublist(i, i + 4));
            final byteData = ByteData.sublistView(bytes);
            rawData.add(byteData.getFloat32(0, Endian.little));
          }
        }

        // Save all files to storage
        String fileName =
            'datasets/${widget.sopepId}_SES${pressureDataInfo['Session']}_SET${pressureDataInfo['Set']}_${DateFormat("yyyy_MM_dd_HH_mm_ss").format(DateTime.fromMillisecondsSinceEpoch((pressureDataRaw[indexStart]['timestamp']! as int) * 1000))}';
        widget.fileStorage
            .writeTextFile(fileName, cborToRegularTextString(pressureDataInfo));
        widget.fileStorage.writeBinaryFile(fileName, binaryData);
        // Save raw dataset as CSV if available
        if (rawData.isNotEmpty) {
          widget.fileStorage.writeDoublesCsvFile(fileName, rawData);
        }
      }
    }
  }

  List<Map<Object?, Object?>> _pressureDataRaw = []; // Needs to be global
  StreamSubscription<BleSopepResponseData>? _streamSubscriptionReadData;
  void _getDataLoop(int seqOldest) {
    // NOTE: 'seq' number sent to sOPEP device should be -1 of oldest seq number
    //       since it tells the device the seq number we send is the last
    //       successfully saved dataset we have
    int seqCounter = seqOldest - 1;
    bool startSetFound = false;
    _pressureDataRaw = [];

    _streamSubscriptionReadData = widget.bleInteractor
        .getSopepInteractor()
        .getSopepStreamController()
        .stream
        .listen((bleSopepResponseData) {
      // Got new data; update our response text display
      _bleSopepResponseData = bleSopepResponseData;

      if ((_bleSopepResponseData.dataMap?['rsp'] == 'read-data') &&
          (_bleSopepResponseData.dataMap?['seq'] != null)) {
        if (_bleSopepResponseData.dataMap!['seq'] == (seqCounter + 1)) {
          if (_bleSopepResponseData.dataMap!['type'] == 'Start set') {
            // We found the very first dataset
            setState(() {
              currentSesSet =
                  'Reading session: ${_bleSopepResponseData.dataMap!['session']}, set: ${_bleSopepResponseData.dataMap!['set']}';
              startSetFound = true;
            });
          }

          if (startSetFound) {
            _pressureDataRaw.add(_bleSopepResponseData.dataMap!);

            if (_bleSopepResponseData.dataMap!['type'] == 'End set') {
              // We got a full set of pressure data; format and save it
              _formatData(_pressureDataRaw);
              _pressureDataRaw = [];
              startSetFound = false;
            }
          }
          seqCounter++;
          widget.sopepInteractor.getData(seqCounter);
        }
      } else if (startSetFound) {
        // NOTE: sOPEP is likely still generating and saving pressure data;
        //       keep trying to get data until we see 'End set' type
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.sopepInteractor.getData(seqCounter);
        });
      } else {
        // We got the very last pressure data!
        _streamSubscriptionReadData!.cancel();
        _streamSubscriptionReadData = null;

        setState(() {
          completeMessage = 'Reading Complete';
          _readingComplete = true;
        });
      }
    });

    // Start off the loop with the first read-data command
    widget.sopepInteractor.getData(seqCounter);
  }

  @override
  Widget build(BuildContext context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            shrinkWrap: true,
            children: !_readingInProgress
                ? [
                    const Text(
                      'Read pressure data',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    UiHelper.divider,
                    const Text(
                      'Press \'Start\' to begin reading all available pressure datasets',
                    ),
                    UiHelper.divider,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              // Get the oldest pressure data seq using 'read-data' command
                              widget.sopepInteractor.getData(null);
                            });
                          },
                          child: const Text('Start'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ]
                : [
                    const Text(
                      'Reading in progress...',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    UiHelper.divider,
                    _readingComplete
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                completeMessage,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Icon(
                                Icons.check,
                                color: Color.fromARGB(255, 52, 203, 72),
                                size: 40,
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SpinKitRing(
                                color: Color.fromARGB(255, 157, 0, 200),
                                size: 50.0,
                              ),
                              Text(
                                currentSesSet,
                              ),
                            ],
                          ),
                    UiHelper.dividerNoLine,
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
          ),
        ),
      );
}
