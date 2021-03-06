// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'change.dart';
import 'value.dart';
import 'value_observer.dart';

/// Interface implemented by all observable Sledge Values.
abstract class LeafValue implements Value {
  /// Observes events occuring on this value.
  set observer(ValueObserver observer);

  /// Ends the transaction and retrieves its data.
  Change getChange();

  /// Applies external transactions.
  void applyChange(Change input);

  /// The Stream of changes.
  Stream<Object> get onChange;
}
