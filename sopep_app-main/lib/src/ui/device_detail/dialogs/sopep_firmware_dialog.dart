// Copyright (c) 2023, StarIC, author: Justin Y. Kim

import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:sopep_app/src/ble/ble_interactor.dart';
import 'package:sopep_app/src/ble/ble_logger.dart';
import 'package:sopep_app/src/ble/ble_sopep_interactor.dart';
import 'package:sopep_app/src/utilities/file_storage.dart';
import 'package:sopep_app/src/utilities/utils.dart';
import 'package:sopep_app/src/widgets/ui_helper.dart';

class SopepFirmwareUploadDialog extends StatelessWidget {
  const SopepFirmwareUploadDialog({
    required this.bleInteractor,
    required this.sopepInteractor,
    Key? key,
  }) : super(key: key);

  final BleInteractor bleInteractor;
  final BleSopepInteractor sopepInteractor;

  @override
  Widget build(BuildContext context) =>
      Consumer3<BleInteractor, FileStorage, BleLogger>(
          builder: (context, bleInteractor, fileStorage, bleLogger, _) =>
              _SopepFirmwareUploadDialog(
                bleInteractor: bleInteractor,
                sopepInteractor: sopepInteractor,
                fileStorage: fileStorage,
                logMessage: bleLogger.addToLog,
              ));
}

class _SopepFirmwareUploadDialog extends StatefulWidget {
  const _SopepFirmwareUploadDialog({
    required this.bleInteractor,
    required this.sopepInteractor,
    required this.fileStorage,
    required this.logMessage,
    Key? key,
  }) : super(key: key);

  final BleInteractor bleInteractor;
  final BleSopepInteractor sopepInteractor;
  final FileStorage fileStorage;

  final void Function(String message) logMessage;

  @override
  _SopepFirmwareUploadDialogState createState() =>
      _SopepFirmwareUploadDialogState();
}

class _SopepFirmwareUploadDialogState
    extends State<_SopepFirmwareUploadDialog> {
  StreamSubscription<BleSopepResponseData>? _sopepStreamSubscription;
  List<FileSystemEntity>? _firmwareFiles;
  File? _fwFile;
  bool _uploadInProgress = false;
  bool _uploadComplete = false;
  Uint8List? _fwBytes;
  int? _fwBlockSize;
  int? _fwTotalBlocks;
  int _fwBlocksWritten = 0;

  @override
  void initState() {
    _firmwareFiles = widget.fileStorage.getFileList('firmware');
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
        if (bleSopepResponseData.dataMap!['rsp'] == 'fw-start') {
          _fwBlockSize = bleSopepResponseData.dataMap?['block-size'] as int;
          double totalBlocks = _fwBytes!.length / _fwBlockSize!;
          _fwTotalBlocks = totalBlocks.ceil();
          widget.sopepInteractor
              .sendFwData(_fwBytes!.sublist(0, _fwBlockSize!));
        } else if (bleSopepResponseData.dataMap!['rsp'] == 'fw-block') {
          _fwBlocksWritten++;
          if (_fwBlocksWritten < (_fwTotalBlocks! - 1)) {
            widget.sopepInteractor.sendFwData(_fwBytes!.sublist(
                (_fwBlockSize! * _fwBlocksWritten),
                (_fwBlockSize! * (_fwBlocksWritten + 1))));
          } else if (_fwBlocksWritten == (_fwTotalBlocks! - 1)) {
            widget.sopepInteractor.sendFwData(_fwBytes!
                .sublist((_fwBlockSize! * _fwBlocksWritten), _fwBytes!.length));
          } else if (_fwBlocksWritten == _fwTotalBlocks!) {
            _uploadComplete = true;
          }
        } else if (bleSopepResponseData.dataMap!['rsp'] == 'fw-schedule') {
          if (bleSopepResponseData.dataMap!['error'] != null) {
            snackBar(this.context,
                'ERROR: ${bleSopepResponseData.dataMap!['error']}');
          }
        }
      });
    });
  }

  void getFwImageFile() async {
    _fwBytes = await _fwFile?.readAsBytes();
    widget
        .logMessage('[FIRM] Image file loaded, total size ${_fwBytes?.length}');
  }

  @override
  Widget build(BuildContext context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            shrinkWrap: true,
            children: !_uploadInProgress
                ? [
                    const Text(
                      'Available firmware files:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    UiHelper.divider,
                    ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: _firmwareFiles?.length,
                      itemBuilder: (context, index) {
                        return _firmwareFiles![index]
                                .path
                                .toString()
                                .contains('.bin')
                            ? ListTile(
                                title:
                                    Text(basename(_firmwareFiles![index].path)),
                                onTap: () {
                                  _fwFile = widget.fileStorage.getFile(
                                      '${_firmwareFiles![index].path}');
                                  setState(() {
                                    if (_fwFile != null) {
                                      getFwImageFile();
                                      widget.sopepInteractor.startFwUpload();
                                      widget
                                          .logMessage('[FIRM] Upload starting');
                                      _uploadInProgress = true;
                                    } else {
                                      snackBar(context,
                                          'ERROR: Could not load file');
                                    }
                                  });
                                },
                              )
                            : null;
                      },
                    ),
                    UiHelper.divider,
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Close'),
                    ),
                  ]
                : [
                    const Text(
                      'Firmware upload in progress...',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    UiHelper.divider,
                    _uploadComplete
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Update Ready',
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
                        : SpinKitRing(
                            color: Color.fromARGB(255, 157, 0, 200),
                            size: 50.0,
                          ),
                    UiHelper.dividerNoLine,
                    (_fwBytes == null)
                        ? Text('Loading image file, please wait')
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('FW size: ${_fwBytes?.length} B'),
                              (_fwBlockSize != null)
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('FW block size: $_fwBlockSize B'),
                                        Text(
                                            'FW blocks written: $_fwBlocksWritten out of $_fwTotalBlocks'),
                                      ],
                                    )
                                  : Text(
                                      'Waiting for sOPEP block size response...'),
                            ],
                          ),
                    UiHelper.divider,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: _uploadComplete
                              ? () {
                                  // Start the FW update schedule 3 seconds after
                                  widget.sopepInteractor.scheduleFwUpdate(
                                      (DateTime.now().millisecondsSinceEpoch ~/
                                              1000) +
                                          3);
                                  Navigator.pop(context);
                                }
                              : null,
                          child: const Text('Schedule Update'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
          ),
        ),
      );
}
