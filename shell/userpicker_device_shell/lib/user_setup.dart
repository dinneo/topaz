// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.ui.flutter/child_view.dart';
import 'package:lib.widgets/model.dart';
import 'package:timezone/timezone_picker.dart';

import 'user_setup_model.dart';

/// Callback to cancel the authentication flow
typedef void CancelAuthentication();

/// Move to a common place?
const double _kUserAvatarSizeLarge = 112.0;
const double _kButtonWidthLarge = 256.0;
final BorderRadius _kButtonBorderRadiusLarge =
    new BorderRadius.circular(_kUserAvatarSizeLarge / 2.0);

Widget _buildUserActionButton({
  Widget child,
  VoidCallback onTap,
  bool isSmall,
  double width,
  bool isDisabled: false,
}) {
  return new GestureDetector(
    onTap: () => onTap?.call(),
    child: new Container(
      height: _kUserAvatarSizeLarge,
      width: width ?? _kButtonWidthLarge,
      alignment: FractionalOffset.center,
      margin: const EdgeInsets.only(left: 16.0),
      decoration: new BoxDecoration(
        borderRadius: _kButtonBorderRadiusLarge,
        border: new Border.all(
          color: Colors.white,
          width: 1.0,
        ),
      ),
      child: child,
    ),
  );
}

/// Widget that handles the steps required to set up a new user.
class UserSetup extends StatelessWidget {
  static const TextStyle _textStyle =
      const TextStyle(fontSize: 30.0, color: Colors.white);

  static const TextStyle _blackText =
      const TextStyle(fontSize: 20.0, color: Colors.black);

  static final Map<SetupStage, ScopedModelDescendantBuilder<UserSetupModel>>
      _widgetBuilders =
      const <SetupStage, ScopedModelDescendantBuilder<UserSetupModel>>{
    SetupStage.timeZone: _buildTimeZone,
    SetupStage.userAuth: _buildUserAuth
  };

  static final Map<SetupStage, String> _stageTitles = <SetupStage, String>{
    SetupStage.timeZone: 'Select your time zone',
    SetupStage.userAuth: 'Log in to your account'
  };

  /// Builds a new UserSetup widget that orchestrates the steps required
  const UserSetup();

  @override
  Widget build(BuildContext context) =>
      new ScopedModelDescendant<UserSetupModel>(builder: (
        BuildContext context,
        Widget child,
        UserSetupModel model,
      ) {
        if (model.currentStage == SetupStage.notStarted ||
            model.currentStage == SetupStage.complete)
          return new Offstage(offstage: true);

        return new Stack(fit: StackFit.passthrough, children: <Widget>[
          new GestureDetector(onTap: () {
            if (model.currentStage == SetupStage.userAuth) {
              model.cancelAuthenticationFlow();
              model.reset();
            }
          }),
          new FractionallySizedBox(
              heightFactor: 0.9,
              widthFactor: 0.75,
              child: new Material(
                  color: Colors.white,
                  child: new Column(children: <Widget>[
                    new AppBar(
                        title: new Text(
                            _stageTitles[model.currentStage] ?? 'Placeholder')),
                    new Expanded(
                        child: (_widgetBuilders[model.currentStage] ??
                                _placeholderStage)
                            .call(context, child, model))
                  ])))
        ]);
      });

  static Widget _placeholderStage(
          BuildContext context, Widget child, UserSetupModel model) =>
      _buildUserActionButton(
          isDisabled: false,
          child: new Text(
            'Stage: ${model.currentStage}',
            style: _textStyle,
          ),
          onTap: () {
            model.nextStep();
          });

  static Widget _buildUserAuth(
          BuildContext context, Widget child, UserSetupModel model) =>
      new AnimatedBuilder(
        animation: model.authModel.animation,
        builder: (BuildContext context, Widget child) => new Offstage(
              offstage: model.authModel.animation.isDismissed,
              child: new Opacity(
                opacity: model.authModel.animation.value,
                child: child,
              ),
            ),
        child: new ChildView(connection: model.authModel.childViewConnection),
      );

  static Widget _buildTimeZone(
      BuildContext context, Widget child, UserSetupModel model) {
    return new Column(children: <Widget>[
      new Expanded(
          child: new TimezonePicker(
              onTap: (String newTimeZone) {
                model.currentTimezone = newTimeZone;
              },
              currentTimezoneId: model.currentTimezone)),
      new FlatButton(
          onPressed: () {
            model.nextStep();
          },
          child: new Text('Next', style: _blackText))
    ]);
  }
}