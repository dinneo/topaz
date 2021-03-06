// Copyright 2015 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_TONIC_DART_PERSISTENT_VALUE_H_
#define LIB_TONIC_DART_PERSISTENT_VALUE_H_

#include "lib/fxl/macros.h"
#include "lib/fxl/memory/weak_ptr.h"
#include "third_party/dart/runtime/include/dart_api.h"

namespace tonic {
class DartState;

// DartPersistentValue is a bookkeeping class to help pair calls to
// Dart_NewPersistentHandle with Dart_DeletePersistentHandle. Consider using
// this class instead of holding a Dart_PersistentHandle directly so that you
// don't leak the Dart_PersistentHandle.
class DartPersistentValue {
 public:
  DartPersistentValue();
  DartPersistentValue(DartPersistentValue&& other);
  DartPersistentValue(DartState* dart_state, Dart_Handle value);
  ~DartPersistentValue();

  Dart_PersistentHandle value() const { return value_; }
  bool is_empty() const { return !value_; }

  void Set(DartState* dart_state, Dart_Handle value);
  void Clear();
  Dart_Handle Get();
  Dart_Handle Release();

  const fxl::WeakPtr<DartState>& dart_state() const { return dart_state_; }

 private:
  fxl::WeakPtr<DartState> dart_state_;
  Dart_PersistentHandle value_;

  FXL_DISALLOW_COPY_AND_ASSIGN(DartPersistentValue);
};

}  // namespace tonic

#endif  // LIB_TONIC_DART_PERSISTENT_VALUE_H_
