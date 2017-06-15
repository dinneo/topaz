// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:ui' show lerpDouble;

import 'package:apps.mozart.lib.flutter/child_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

import '../modular/module_model.dart';

/// The video screen for the video player
class Screen extends StatelessWidget {
  final double _circleDiameter = 100.0;

  /// Constructor for the video screen for the video player
  Screen({
    Key key,
  })
      : super(key: key);

  Rect _animateIntoThumbnail(VideoModuleModel model) {
    model.pause();
    model.hideDeviceChooser = false;
    model.thumbnailAnimationController.forward();
    return new Rect.fromLTWH(0.0, 0.0, 0.0, 0.0);
  }

  void _animateIntoScreen(VideoModuleModel model) {
    model.hideDeviceChooser = true;
    model.thumbnailAnimationController.reverse();
    model.play();
  }

  Widget _buildScreen(VideoModuleModel model, BuildContext context) {
    LayoutBuilder layoutBuilder = new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      double currentWidth = constraints.maxWidth;
      double currentHeight = constraints.maxHeight;

      // TODO(maryxia) SO-480 wrap this in a GestureDetector
      return new Center(
        child: new LongPressDraggable<String>(
          // TODO(maryxia) SO-449 use real device names, not hardcoded ones
          data: 'Living Room TV',
          dragAnchor: DragAnchor.pointer,
          childWhenDragging: new Container(),
          feedback: new AnimatedBuilder(
            animation: model.thumbnailAnimationController,
            child: new ChildView(connection: model.videoViewConnection),
            builder: (BuildContext context, Widget child) {
              double lerpWidth = lerpDouble(currentWidth, _circleDiameter,
                  model.thumbnailAnimation.value);
              double lerpHeight = lerpDouble(currentHeight, _circleDiameter,
                  model.thumbnailAnimation.value);
              double leftOffset = (currentWidth - lerpWidth) / 2.0;
              double topOffset = (currentHeight - lerpHeight) / 2.0;
              double x = -lerpWidth / 2.0;
              double y = -lerpHeight / 2.0;

              return new Transform(
                transform: new Matrix4.translationValues(x, y, 0.0),
                child: new Container(
                  width: lerpWidth,
                  height: lerpHeight,
                  child: new Container(
                    child: new ClipRRect(
                      borderRadius: new BorderRadius.circular(
                        _circleDiameter * model.thumbnailAnimation.value,
                      ),
                      child: child,
                    ),
                  ),
                ),
              );
            },
          ),
          onDragStarted: () => _animateIntoThumbnail(model),
          onDraggableCanceled: (Velocity v, Offset o) =>
              _animateIntoScreen(model),
          child: model.videoViewConnection != null
              ? new ChildView(connection: model.videoViewConnection)
              : new Container(),
        ),
      );
    });
    return layoutBuilder;
  }

  @override
  Widget build(BuildContext context) {
    return new ScopedModelDescendant<VideoModuleModel>(
      builder: (
        BuildContext context,
        Widget child,
        VideoModuleModel model,
      ) {
        // TODO(maryxia) SO-480 make this conditional via onTap
        model.brieflyShowControlOverlay();
        return _buildScreen(model, context);
      },
    );
  }
}
