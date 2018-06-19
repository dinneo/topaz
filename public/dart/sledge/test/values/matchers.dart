// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:matcher/matcher.dart';
import 'package:sledge/src/document/change.dart';
import 'package:sledge/src/document/values/key_value.dart';

const ListEquality _listEquality = const ListEquality();

class KeyValueEquality implements Equality<KeyValue> {
  // Default constructor;
  const KeyValueEquality();

  @override
  bool equals(KeyValue kv1, KeyValue kv2) {
    return _listEquality.eqauls(kv1.key, kv2.key) &&
        _listEquality.equals(kv1.value, kv2.value);
  }

  @override
  int hash(KeyValue kv) {
    return 0;
  }
}

const _keyValueEquality = const KeyValueEquality();
const ListEquality _keyValueListEquality =
    const ListEquality<KeyValue>(_keyValueEquality);
const ListEquality _keysListEquality =
    const ListEquality<List<int>>(_listEquality);

class Uint8ListMatcher extends Matcher {
  final Uint8List _list;

  // Default constructor.
  Uint8ListMatcher(this._list);

  @override
  bool matches(Uint8List list, Map matchState) {
    return _listEquality.equals(list, _list);
  }

  @override
  Description describe(Description description) =>
      description.add('Uint8List equals to ').addDescriptionOf(_list.toList());
}

class KeyValueMatcher extends Matcher {
  final KeyValue _kv;

  // Default constructor.
  KeyValueMatcher(this._kv);

  @override
  bool matches(KeyValue kv, Map matchState) {
    return _listEquality.equals(kv.key, _kv.key) &&
        _listEquality.equals(kv.value, _kv.value);
  }

  @override
  Description describe(Description description) =>
      description.add('KeyValue equals to ').addDescriptionOf(_kv.toList());
}

class ChangeMatcher extends Matcher {
  final Change _change;

  // Default constructor.
  ChangeMatcher(this._change);

  @override
  bool matches(Change change, Map matchState) {
    return _keyValueListEquality.equals(
            change.changedEntries, _change.changedEntries) &&
        _keysListEquality.equals(change.deletedKeys, _change.deletedKeys);
  }

  @override
  Description describe(Description description) =>
      description.add('Change matcher.'); // TODO add description.
}
