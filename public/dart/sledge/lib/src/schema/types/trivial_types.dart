// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../document/base_value.dart';
import '../../document/values/trivial_values.dart';
import '../base_type.dart';

/// The Sledge type to store booleans.
class Boolean implements BaseType {
  @override
  String jsonValue() {
    return '"Boolean"';
  }

  @override
  BaseValue newValue() {
    return new BooleanValue();
  }
}

/// The Sledge type to store integers.
class Integer implements BaseType {
  @override
  String jsonValue() {
    return '"Integer"';
  }

  @override
  BaseValue newValue() {
    return new IntegerValue();
  }
}