// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:lib.schemas.dart/entity_codec.dart';
import 'package:lib.logging/logging.dart';

import 'filter_entity_data.dart';

/// The [EntityCodec] that translates [FilterEntityData]
class FilterEntityCodec extends EntityCodec<FilterEntityData> {
  /// Creates an instance of the codec
  FilterEntityCodec()
      : super(
          type: 'com.fuchsia.contact.detail_type',
          encode: _encode,
          decode: _decode,
        );
}

String _encode(FilterEntityData entity) {
  assert(entity != null);
  return json.encode(<String, String>{
    'prefix': entity.prefix,
    'detailType': entity.detailType.toString()
  });
}

FilterEntityData _decode(String data) {
  assert(data != null);
  assert(data.isNotEmpty);

  FilterEntityData filter = new FilterEntityData();
  try {
    Object decoded = json.decode(data);
    if (decoded is Map<String, String>) {
      filter.prefix = decoded['prefix'];
      DetailType detailType;
      switch (data) {
        case 'email':
          detailType = DetailType.email;
          break;

        case 'phoneNumber':
          detailType = DetailType.phoneNumber;
          break;

        default:
          detailType = DetailType.custom;
          break;
      }
      filter.detailType = detailType;
    }
  } on Exception catch (err, stackTrace) {
    log.warning('Error parsing FilterEntityData: $err\n$stackTrace');
  }

  return filter;
}