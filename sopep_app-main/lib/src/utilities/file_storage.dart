// Copyright (c) 2023, StarIC, author: Justin Y. Kim

import 'dart:async';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

////////////////////////////////////////////////////////////////////////////////
// NOTES FOR IOS
//
// NOTE: To access iOS files, you need macOS and complete the following steps:
//       1) Connect iPhone to macOS,
//       2) Open Finder,
//       3) Your iPhone should be listed under 'Locations' on the left,
//       4) Once iPhone directory is open, go to 'Files' tab,
//       5) The folder 'sopep_app' should be visible where everything is saved,
//       6) Press 'Sync' button at the bottom-right if you don't see the files,
//       7) Drag and drop the files you'd like to save and view.
//
// NOTE: You can also access the files via Files app on the iPhone

////////////////////////////////////////////////////////////////////////////////
// NOTES FOR ANDROID
//
// NOTE: To access Android files from macOS, you can use Android's application
//       from https://www.android.com/filetransfer/. On Windows, you should be
//       able to access it directory from File Explorer. Remember to unlock your
//       Android phone to access the internal storage via USB.
//
// NOTE: You may need to unplug/replug the device after saving to a file to
//       refresh the directory and for the file to appear
//
// NOTE: Android internal save directory is something like the following:
//       Android/data/com.staric.sopep.flutterapp/files

class FileStorage {
  FileStorage({
    required Function(String message) logMessage,
  }) : _logMessage = logMessage;

  late final Directory? _appDirectory;
  late final void Function(String message) _logMessage;

  Future<void> createDefaultDirectories() async {
    _appDirectory = await getAppDirectory();
    await Directory('${_appDirectory?.path}/datasets').create(recursive: true);
    await Directory('${_appDirectory?.path}/logs').create(recursive: true);
    await Directory('${_appDirectory?.path}/firmware').create(recursive: true);
  }

  Future<Directory?> getAppDirectory() async {
    if (Platform.isAndroid) {
      return await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else {
      _logMessage('[FILE] Unsopported OS; cannot get save directory');
      return null;
    }
  }

  Future<void> writeTextFile(String fileName, String text) async {
    if (_appDirectory == null) {
      return;
    }
    final File file = File('${_appDirectory?.path}/$fileName.txt');
    await file.writeAsString(text, flush: true);
    _logMessage('[FILE] Saved $file');
  }

  Future<String> readTextFile(String filePath) async {
    if (_appDirectory == null) {
      return '';
    }
    final File file = File(filePath);
    final str = await file.readAsString();
    _logMessage('[FILE] Read $file');
    return str;
  }

  Future<void> writeBinaryFile(String fileName, List<int> bytes) async {
    if (_appDirectory == null) {
      return;
    }
    final File file = File('${_appDirectory?.path}/$fileName.bin');
    await file.writeAsBytes(bytes, flush: true);
    _logMessage('[FILE] Saved $file');
  }

  Future<void> writeDoublesCsvFile(
      String fileName, List<double> doubles) async {
    if (_appDirectory == null) {
      return;
    }
    List<List<dynamic>> doublesList = doubles.map((item) => [item]).toList();
    String csv = const ListToCsvConverter().convert(doublesList);
    final File file = File('${_appDirectory?.path}/$fileName.csv');
    await file.writeAsString(csv, flush: true);
    _logMessage('[FILE] Saved $file');
  }

  List<FileSystemEntity>? getFileList(String directoryName) {
    if (_appDirectory == null) {
      return null;
    }
    final directory = new Directory('${_appDirectory?.path}/$directoryName/');
    return directory.listSync(recursive: true, followLinks: false);
  }

  File? getFile(String filePath) {
    if (_appDirectory == null) {
      return null;
    }
    final File file = File('$filePath');
    _logMessage('[FILE] Loading $filePath');
    return file;
  }
}
