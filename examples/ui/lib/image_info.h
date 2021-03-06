// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LIB_UI_SCENIC_SKIA_IMAGE_INFO_H_
#define LIB_UI_SCENIC_SKIA_IMAGE_INFO_H_

#include <fuchsia/images/cpp/fidl.h>

#include "third_party/skia/include/core/SkImageInfo.h"

namespace scenic {
namespace skia {

// Creates Skia image information from a |fuchsia::images::ImageInfo| object.
SkImageInfo MakeSkImageInfo(const fuchsia::images::ImageInfo& image_info);

}  // namespace skia
}  // namespace scenic

#endif  // LIB_UI_SCENIC_SKIA_IMAGE_INFO_H_
