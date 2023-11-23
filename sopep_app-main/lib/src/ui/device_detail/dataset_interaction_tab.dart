// Copyright (c) 2023, StarIC, author: Justin Y. Kim

import 'dart:io';
import 'package:convert/convert.dart';
import 'package:provider/provider.dart';
import 'package:functional_data/functional_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'package:sopep_app/src/ble/ble_interactor.dart';
import 'package:sopep_app/src/utilities/file_storage.dart';

class DatasetInteractionTab extends StatelessWidget {
  final DiscoveredDevice device;

  const DatasetInteractionTab({
    required this.device,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Consumer2<BleInteractor, FileStorage>(
        builder: (_, bleInteractor, fileStorage, __) => _DatasetInteractionTab(
          deviceId: device.id,
          deviceMfrId:
              hex.encode(device.manufacturerData).toUpperCase().toString(),
          bleInteractor: bleInteractor,
          fileStorage: fileStorage,
        ),
      );
}

class _DatasetInteractionTab extends StatefulWidget {
  const _DatasetInteractionTab({
    required this.deviceId,
    required this.deviceMfrId,
    required this.bleInteractor,
    required this.fileStorage,
    Key? key,
  }) : super(key: key);

  final String deviceId;
  final String deviceMfrId;
  final BleInteractor bleInteractor;
  final FileStorage fileStorage;

  @CustomEquality(Ignore())
  @override
  _DatasetInteractionTabState createState() => _DatasetInteractionTabState();
}

class _DatasetInteractionTabState extends State<_DatasetInteractionTab> {
  List<ListItem> _datasetItems = [];

  @override
  void initState() {
    _getListOfDatasets();
    super.initState();
  }

  void _getListOfDatasets() async {
    List<FileSystemEntity>? textFilesTemp =
        widget.fileStorage.getFileList('datasets');
    if (textFilesTemp == null) {
      return;
    }

    // First, remove all non text files
    List<FileSystemEntity> textFiles = [];
    for (var i = 0; i < textFilesTemp.length; i++) {
      if (textFilesTemp[i].path.toString().substring(
              textFilesTemp[i].path.toString().length - 3,
              textFilesTemp[i].path.toString().length) ==
          'txt') {
        textFiles.add(textFilesTemp[i]);
      }
    }

    // Begin adding the datasets to a list, from newest to oldest
    String tempStr;
    for (var i = textFiles.length - 1; i >= 0; i--) {
      tempStr =
          await widget.fileStorage.readTextFile(textFiles[i].path.toString());

      // Remove error and ratio data from subtitle string
      var ind = tempStr.indexOf('Estimated peak');
      tempStr = tempStr.substring(0, ind);

      _datasetItems.add(DatasetItem(
          'Device: ${textFiles[i].path.toString().substring(textFiles[i].path.toString().length - 49, textFiles[i].path.toString().length - 34)}',
          '$tempStr'));
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 1.0, end: 1.0),
              child: ListView.builder(
                itemCount: _datasetItems.length,
                itemBuilder: (context, index) {
                  final item = _datasetItems[index];

                  return ListTile(
                    title: item.buildDeviceId(context),
                    subtitle: item.buildInfo(context),
                  );
                },
              ),
            ),
          ),
        ],
      );
}

abstract class ListItem {
  /// The title will be the device ID.
  Widget buildDeviceId(BuildContext context);

  /// The subtitles will have the following: session/set values, start/end
  /// times, and total samples.
  Widget buildInfo(BuildContext context);
}

/// A ListItem that contains datasets to be displayed.
class DatasetItem implements ListItem {
  final String deviceId;
  final String info;

  DatasetItem(this.deviceId, this.info);

  @override
  Widget buildDeviceId(BuildContext context) => Text(deviceId);

  @override
  Widget buildInfo(BuildContext context) => Text(info);
}
