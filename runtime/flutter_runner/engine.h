// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOPAZ_RUNTIME_FLUTTER_RUNNER_ENGINE_H_
#define TOPAZ_RUNTIME_FLUTTER_RUNNER_ENGINE_H_

#include <fuchsia/ui/views_v1/cpp/fidl.h>
#include <fuchsia/ui/views_v1_token/cpp/fidl.h>
#include <zx/event.h>

#include "flutter/shell/common/shell.h"
#include "isolate_configurator.h"
#include "lib/component/cpp/startup_context.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/memory/weak_ptr.h"
#include "lib/ui/flutter/sdk_ext/src/natives.h"
#include "topaz/lib/deprecated_loop/thread.h"

namespace flutter {

// Represents an instance of running Flutter engine along with the threads that
// host the same.
class Engine final : public mozart::NativesDelegate {
 public:
  class Delegate {
   public:
    virtual void OnEngineTerminate(const Engine* holder) = 0;
  };

  Engine(
      Delegate& delegate, std::string thread_label,
      component::StartupContext& startup_context, blink::Settings settings,
      fxl::RefPtr<blink::DartSnapshot> isolate_snapshot,
      fxl::RefPtr<blink::DartSnapshot> shared_snapshot,
      fidl::InterfaceRequest<fuchsia::ui::views_v1_token::ViewOwner> view_owner,
      UniqueFDIONS fdio_ns,
      fidl::InterfaceRequest<fuchsia::sys::ServiceProvider>
          outgoing_services_request);

  ~Engine();

  // Returns the Dart return code for the root isolate if one is present. This
  // call is thread safe and synchronous. This call must be made infrequently.
  std::pair<bool, uint32_t> GetEngineReturnCode() const;

 private:
  Delegate& delegate_;
  const std::string thread_label_;
  blink::Settings settings_;
  std::array<deprecated_loop::Thread, 3> host_threads_;
  std::unique_ptr<IsolateConfigurator> isolate_configurator_;
  std::unique_ptr<shell::Shell> shell_;
  zx::event vsync_event_;
  fxl::WeakPtrFactory<Engine> weak_factory_;

  void OnMainIsolateStart();

  void OnMainIsolateShutdown();

  void Terminate();

  void OnSessionMetricsDidChange(double device_pixel_ratio);

  // |mozart::NativesDelegate|
  void OfferServiceProvider(
      fidl::InterfaceHandle<fuchsia::sys::ServiceProvider> service_provider,
      fidl::VectorPtr<fidl::StringPtr> services);

  FXL_DISALLOW_COPY_AND_ASSIGN(Engine);
};

}  // namespace flutter

#endif  // TOPAZ_RUNTIME_FLUTTER_RUNNER_ENGINE_H_
