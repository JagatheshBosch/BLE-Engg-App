// Copyright (c) 2023, StarIC, author: Justin Y. Kim
// Copyright (c) 2023, authors of flutter_reactive_ble

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:sopep_app/src/ble/reactive_state.dart';

class BleStatusMonitor implements ReactiveState<BleStatus?> {
  const BleStatusMonitor(this._ble);

  final FlutterReactiveBle _ble;

  @override
  Stream<BleStatus?> get state => _ble.statusStream;
}
