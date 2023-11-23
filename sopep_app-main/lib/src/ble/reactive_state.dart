// Copyright (c) 2023, StarIC, author: Justin Y. Kim
// Copyright (c) 2023, authors of flutter_reactive_ble

abstract class ReactiveState<T> {
  Stream<T> get state;
}
