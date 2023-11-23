// Copyright (c) 2023, StarIC, author: Justin Y. Kim
// Copyright (c) 2023, authors of flutter_reactive_ble

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:sopep_app/src/ble/ble_interactor.dart';
import 'package:sopep_app/src/ble/ble_logger.dart';
import 'package:sopep_app/src/ble/ble_sopep_interactor.dart';
import 'package:sopep_app/src/utilities/file_storage.dart';
import 'package:sopep_app/src/widgets/ui_helper.dart';

class DeviceLogTab extends StatelessWidget {
  const DeviceLogTab({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Consumer3<BleLogger, BleInteractor, FileStorage>(
        builder: (context, logger, bleInteractor, fileStorage, _) =>
            _DeviceLogTab(
          logger: logger,
          messages: logger.messages,
          bleInteractor: bleInteractor,
          fileStorage: fileStorage,
        ),
      );
}

class _DeviceLogTab extends StatefulWidget {
  const _DeviceLogTab({
    required this.logger,
    required this.messages,
    required this.bleInteractor,
    required this.fileStorage,
    Key? key,
  }) : super(key: key);

  final BleLogger logger;
  final List<String> messages;
  final BleInteractor bleInteractor;
  final FileStorage fileStorage;

  @override
  _DeviceLogTabState createState() => _DeviceLogTabState();
}

class _DeviceLogTabState extends State<_DeviceLogTab> {
  bool _showRawToggle = false;
  late BleSopepInteractor _sopepInteractor;

  @override
  void initState() {
    _sopepInteractor = widget.bleInteractor.getSopepInteractor();
    super.initState();
  }

  RichText _generateMessage(int index) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14.0,
          color: Colors.black,
        ),
        children: <TextSpan>[
          TextSpan(
            text: widget.messages[index]
                .substring(0, widget.messages[index].indexOf(']') + 1),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: widget.messages[index]
                .substring(widget.messages[index].indexOf(']') + 1),
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                  start: 16.0, top: 16.0, end: 16.0),
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemBuilder: (context, index) => _showRawToggle
                    ? _generateMessage(index)
                    : widget.messages[index]
                            .substring(0, widget.messages[index].indexOf(']'))
                            .contains('RAW')
                        ? const SizedBox(width: 0)
                        : _generateMessage(index),
                itemCount: widget.messages.length,
              ),
            ),
          ),
          UiHelper.divider,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Raw',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Switch(
                // This bool value toggles the switch.
                value: _showRawToggle,
                activeColor: Color.fromARGB(255, 40, 211, 40),
                onChanged: (bool value) {
                  setState(() {
                    _showRawToggle = value;
                  });
                },
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 255, 0, 0)),
                onPressed: () {
                  setState(() {
                    widget.messages.clear();
                    widget.logger.clearLogs();
                  });
                },
                child: Text('Clear All'),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 0, 200, 0)),
                onPressed: () {
                  setState(() {
                    String log = '';
                    for (int i = 0; i < widget.messages.length; i++) {
                      log += widget.messages[i] + '\n';
                    }
                    widget.fileStorage.writeTextFile(
                        'logs/${_sopepInteractor.getSopepDeviceId()}_LOG_${DateFormat("yyyy_MM_dd_HH_mm_ss").format(DateTime.now())}',
                        log);
                  });
                },
                child: Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 15),
        ],
      );
}
