// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:fidl_fuchsia_modular/fidl.dart';
import 'package:lib.app.dart/logging.dart';
import 'package:lib.proposal.dart/proposal.dart';
import 'package:lib.story.dart/story.dart';

const String _kWallpapersLinkKey = 'wallpapers';
const String _kImageSelectorModulePath = 'gallery';
const List<String> _kImageSelectorLinkPath = const <String>['root'];
const String _kImageSelectorLinkName = 'selection';
const String _kImageSelectorRootKey = 'image selection';
const String _kImageSelectorImageListKey = 'selected images';
const List<StoryInfoExtraEntry> _kImageSelectorStoryExtraInfo =
    const <StoryInfoExtraEntry>[const StoryInfoExtraEntry(
        key: 'color', value: '0xFFA5A700')];
const int _kChooseWallpaperSuggestionColor = 0xFFA5A700;
const String _kChooseWallpaperSuggestionHeadline = 'Change Wallpaper';
const String _kChooseWallpaperSuggestionImageUrl =
    '/system/data/sysui/aparna-home.png';

/// Chooses wallpaper for the user.
class WallpaperChooser {
  final _Proposer _proposer = new _Proposer();

  final LinkProxy _changeWallpaperLink = new LinkProxy();

  /// Called when different wallpaper is chosen.
  final ValueChanged<List<String>> onWallpaperChosen;

  _CustomAction _customAction;

  /// Constructor.
  WallpaperChooser({this.onWallpaperChosen});

  /// Begins proposing the wallpaper chooser module be run.
  void start(
    FocusProvider focusProvider,
    StoryProvider storyProvider,
    IntelligenceServices intelligenceServices,
    Link link,
  ) {
    _customAction = new _CustomAction(
      storyProvider: storyProvider,
      linkProxy: _changeWallpaperLink,
      focusProvider: focusProvider,
      onWallpaperChosen: (List<String> images) {
        log.info('wallpaper chosen: $images');
        link.set(<String>[_kWallpapersLinkKey], json.encode(images));
        onWallpaperChosen(images);
      },
    );

    _proposer.start(
      intelligenceServices: intelligenceServices,
      customAction: _customAction,
    );
  }

  /// Called when the Link json changes.
  void onLinkChanged(String encoded) {
    dynamic decodedJson = json.decode(encoded);
    if (decodedJson == null ||
        !(decodedJson is Map) ||
        !decodedJson.containsKey(_kWallpapersLinkKey)) {
      return;
    }
    onWallpaperChosen(decodedJson[_kWallpapersLinkKey]);
  }

  /// Closes any open handles.
  void stop() {
    _customAction.stop();
    _proposer.stop();
    _changeWallpaperLink.ctrl.close();
  }
}

class _Proposer {
  final QueryHandlerBinding _queryHandlerBinding = new QueryHandlerBinding();
  _QueryHandlerImpl _queryHandlerImpl;

  void start({
    IntelligenceServices intelligenceServices,
    CustomAction customAction,
  }) {
    _queryHandlerImpl = new _QueryHandlerImpl(customAction: customAction);
    intelligenceServices.registerQueryHandler(
      _queryHandlerBinding.wrap(_queryHandlerImpl),
    );
  }

  void stop() {
    _queryHandlerImpl.stop();
    _queryHandlerBinding.close();
  }
}

class _QueryHandlerImpl extends QueryHandler {
  final Set<CustomActionBinding> _bindings = new Set<CustomActionBinding>();

  final CustomAction customAction;

  _QueryHandlerImpl({this.customAction});

  @override
  Future<Null> onQuery(
    UserInput query,
    void callback(QueryResponse response),
  ) async {
    List<Proposal> proposals = <Proposal>[];

    if ((query.text?.toLowerCase()?.startsWith('wal') ?? false) ||
        (query.text?.toLowerCase()?.contains('wallpaper') ?? false) ||
        (query.text?.toLowerCase()?.contains('change') ?? false)) {
      CustomActionBinding binding = new CustomActionBinding();
      _bindings.add(binding);
      proposals.add(
        await createProposal(
          id: _kChooseWallpaperSuggestionHeadline,
          headline: _kChooseWallpaperSuggestionHeadline,
          color: _kChooseWallpaperSuggestionColor,
          imageUrl: _kChooseWallpaperSuggestionImageUrl,
          actions: <Action>[
            new Action.withCustomAction(binding.wrap(customAction))
          ],
        ),
      );
    }

    callback(new QueryResponse(proposals: proposals));
  }

  void stop() {
    for (CustomActionBinding binding in _bindings) {
      binding.close();
    }
  }
}

class _CustomAction extends CustomAction {
  final StoryProvider storyProvider;
  final FocusProvider focusProvider;
  final LinkProxy linkProxy;
  final ValueChanged<List<String>> onWallpaperChosen;
  StoryControllerProxy storyControllerProxy;
  LinkWatcherBinding _linkWatcherBinding;
  dynamic _lastDecodedJson;

  _CustomAction({
    this.storyProvider,
    this.focusProvider,
    this.linkProxy,
    this.onWallpaperChosen,
  });

  @override
  void execute() {
    stop();

    storyProvider.createStoryWithInfo(
      _kImageSelectorModulePath,
      _kImageSelectorStoryExtraInfo,
      json.encode(
        <String, List<String>>{},
      ),
      (String storyId) {
        storyControllerProxy = new StoryControllerProxy();
        storyProvider.getController(
          storyId,
          storyControllerProxy.ctrl.request(),
        );
        storyControllerProxy.getInfo((StoryInfo info, StoryState state) {
          focusProvider.request(info.id);
          var linkPath = new LinkPath(
              modulePath: _kImageSelectorLinkPath,
              linkName: _kImageSelectorLinkName);
          storyControllerProxy.getLink(linkPath, linkProxy.ctrl.request());
          storyControllerProxy?.ctrl?.close();
          storyControllerProxy = null;

          _linkWatcherBinding = new LinkWatcherBinding();
          linkProxy.watch(
            _linkWatcherBinding.wrap(
              new LinkWatcherImpl(
                onNotify: (String encoded) {
                  dynamic decodedJson = json.decode(encoded);
                  if (_lastDecodedJson != null && decodedJson == null) {
                    if (_lastDecodedJson is Map &&
                        _lastDecodedJson.containsKey(_kImageSelectorRootKey) &&
                        _lastDecodedJson[_kImageSelectorRootKey]
                            .containsKey(_kImageSelectorImageListKey)) {
                      onWallpaperChosen(
                        _lastDecodedJson[_kImageSelectorRootKey]
                            [_kImageSelectorImageListKey],
                      );
                      storyProvider.deleteStory(info.id, () {});
                    }
                  }
                  _lastDecodedJson = decodedJson;
                },
              ),
            ),
          );
        });
      },
    );
  }

  void stop() {
    storyControllerProxy?.ctrl?.close();
    storyControllerProxy = null;
    _linkWatcherBinding?.close();
    _linkWatcherBinding = null;
  }
}
