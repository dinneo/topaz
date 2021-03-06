// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sledge/sledge.dart';

import 'fakes/fake_ledger_object_factories.dart';
import 'fakes/fake_ledger_page.dart';

Sledge newSledgeForTesting() {
  return new Sledge.testing(
      new FakeLedgerPage(), new FakeLedgerPageSnapshotFactory());
}
