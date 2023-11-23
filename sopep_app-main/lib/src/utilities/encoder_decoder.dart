// Copyright (c) 2023, StarIC, author: Justin Y. Kim

import 'dart:convert';
import 'package:cbor/simple.dart'; // CBOR
import 'dart:typed_data'; // CRC32C
import 'package:convert/convert.dart'; // CRC32C
import 'package:crclib/catalog.dart'; // CRC32C
import 'package:cobs2/cobs2.dart'; // COBS

class EncoderDecoder {
  List<int> _dataRaw = [];

  /// Converts CBOR message structure to be sent to the sOPEP device into raw
  /// long bytes of data.
  List<int> encoder(final Object decoded) {
    // Encode CBOR
    var encodedCbor = cbor.encode(decoded);
    encodedCbor = [...encodedCbor, ...[]]; // Get rid of ending zeros

    // Calculate 4 bytes of CRC32C and append at the end
    var crcStr = Crc32C().convert(encodedCbor).toRadixString(16);
    if (crcStr.length < 8) {
      // Ensure CRC string has appropriate starting 0s
      while (crcStr.length < 8) {
        crcStr = '0' + crcStr;
      }
    }
    var crc = // Reverse CRC32C bytes to be little-endian
        hex.decode(crcStr).reversed.toList();
    var encodedCrc = [...encodedCbor, ...crc];

    // Encode COBS
    // NOTE: We're using x2 length for buffer, since the buffer can get larger
    //       than original bytes of data
    var encodedCobsTemp = ByteData(encodedCrc.length * 2);
    var retCobs = encodeCOBS(encodedCobsTemp,
        ByteData.view(new Uint8List.fromList(encodedCrc).buffer));
    if (retCobs.status != EncodeStatus.OK) {
      return [];
    }
    var encodedCobs = ByteData(retCobs.outLen);
    for (var i = 0; i < retCobs.outLen; i++) {
      encodedCobs.setInt8(i, encodedCobsTemp.getInt8(i));
    }
    final encoded = [
      ...[0],
      ...encodedCobs.buffer.asUint8List().toList(),
      ...[0]
    ];

    return encoded;
  }

  /// Converts raw bytes into the original CBOR message structure sent from
  /// sOPEP device.
  Map<Object?, Object?>? decoder(final List<int> data) {
    Map<Object?, Object?>? dataMap;

    // Continue to stack up arrays until we see a full message
    for (var i = 0; i < data.length; i++) {
      if (data[i] != 0x00) {
        _dataRaw.add(data[i]);
      } else if (_dataRaw.isNotEmpty) {
        dataMap = decode(_dataRaw);
        _dataRaw = [];
      }
    }

    return dataMap;
  }

  /// Helper method for decoder which first applies COBS decoding, then checks
  /// CRC32C bytes, and finally applies CBOR decoding to get the original
  /// Map<Key, Value> message structure.
  Map<Object?, Object?>? decode(final List<int> encoded) {
    // Decode COBS
    // NOTE: Decode function expects the 0x00 to be removed beforehand!
    var decodedCobsTemp = ByteData(
        encoded.length * 2); // x2 larger buffer length to prevent overflow
    var retCobs = decodeCOBS(
        decodedCobsTemp, ByteData.view(new Uint8List.fromList(encoded).buffer));
    if (retCobs.status != DecodeStatus.OK) {
      return null;
    }
    var decodedCobs = ByteData(retCobs.outLen);
    for (var i = 0; i < retCobs.outLen; i++) {
      decodedCobs.setInt8(i, decodedCobsTemp.getInt8(i));
    }

    // Check CRC32C bytes
    var decodedCrc = new List<int>.from(decodedCobs.buffer.asUint8List());
    var crcOri = [
      decodedCrc[decodedCrc.length - 4],
      decodedCrc[decodedCrc.length - 3],
      decodedCrc[decodedCrc.length - 2],
      decodedCrc[decodedCrc.length - 1]
    ];
    for (var i = 0; i < 4; i++) {
      decodedCrc.removeLast();
    }
    // Calculate 4 bytes of CRC32C and check with the original
    var crcStr = Crc32C().convert(decodedCrc).toRadixString(16);
    if (crcStr.length < 8) {
      // Ensure CRC string has appropriate starting 0s
      while (crcStr.length < 8) {
        crcStr = '0' + crcStr;
      }
    }
    var crc = // Reverse CRC32C bytes to be little-endian
        hex.decode(crcStr).reversed.toList();
    if ((crc[0] != crcOri[0]) ||
        (crc[1] != crcOri[1]) ||
        (crc[2] != crcOri[2]) ||
        (crc[3] != crcOri[3])) {
      print('CRC32C bytes do not match');
      return null;
    }

    // Decode CBOR
    var decodedCbor = cbor.decode(decodedCrc) as Map<Object?, Object?>;

    return decodedCbor;
  }

  /// Takes the long CBOR string and turns it into pretty indented string
  /// structure (same looking as JSON format).
  static String cborToPrettyStr(final Object cbor) {
    JsonEncoder encoder = new JsonEncoder.withIndent('  ');
    return encoder.convert(cbor);
  }
}
