// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:lib.app.dart/logging.dart';
import 'package:xi_client/client.dart';

import 'editor.dart';

// ignore_for_file: avoid_annotating_with_dynamic

/// Top-level Widget.
class XiApp extends StatefulWidget {
  /// The client API interface to the xi-core Fuchsia service.
  final XiClient xi;
  final bool drawDebugBackground;

  /// [XiApp] constructor.
  const XiApp({
    @required this.xi,
    this.drawDebugBackground = false,
    Key key,
  })  : assert(xi != null),
        super(key: key);

  @override
  XiAppState createState() =>
      new XiAppState(debugBackground: drawDebugBackground);
}

/// A handler for RPC's and notifications from core, dispatching to
/// an [EditorState] object.
// TODO: dispatch to multiple editor tabs
class XiAppHandler extends XiRpcHandler {
  EditorState _editorState;

  /// Constructor
  XiAppHandler(this._editorState);

  @override
  void handleNotification(String method, dynamic params) {
    switch (method) {
      case 'update':
        Map<String, dynamic> update = params['update'];
        //print('update, update=$update');
        List<dynamic> opsList = update['ops'];
        List<Map<String, dynamic>> ops = opsList.cast();
        _editorState.update(ops);
        break;
      case 'scroll_to':
        Map<String, dynamic> scrollInfo = params;
        int line = scrollInfo['line'];
        int col = scrollInfo['col'];
        // TODO: dispatch based on tab
        _editorState.scrollTo(line, col);
        //print('scroll_to: $params');
        break;
      default:
        log.warning('notification, unknown method $method, params=$params');
    }
  }

  @override
  dynamic handleRpc(String method, dynamic params) {
    switch (method) {
      case 'measure_width':
        return _editorState.measureWidths(params);
        break;
      default:
        log.warning('rpc request, unknown method $method, params=$params');
    }
    return null;
  }
}

class _PendingNotification {
  _PendingNotification(this.method, this.params);
  String method;
  dynamic params;
}

/// State for XiApp.
class XiAppState extends State<XiApp> {
  /// Allows parent [Widget]s in either vanilla Flutter or Fuchsia to modify
  /// the message.
  String message;

  /// If `true`, draws a watermark in the background of the editor view.
  bool debugBackground = false;
  String _viewId;
  List<_PendingNotification> _pendingReqs;
  EditorState _editorState;

  XiAppState({@required this.debugBackground});

  /// Route a notification to the xi core. Called by [Editor] widget. If the tab
  /// has not yet initialized, notifications are queued up until it has.
  void sendNotification(String method, dynamic params) {
    if (_viewId == null) {
      _pendingReqs ??= <_PendingNotification>[];
      _pendingReqs.add(new _PendingNotification(method, params));
    } else {
      Map<String, dynamic> innerParams = <String, dynamic>{
        'method': method,
        'params': params,
        'view_id': _viewId
      };
      widget.xi.sendNotification('edit', innerParams);
    }
  }

  /// Connect editor state, so that notifications from the core are routed to
  /// the editor. Called by [Editor] widget.
  void connectEditor(EditorState editorState) {
    widget.xi.handler = new XiAppHandler(editorState);
  }

  @override
  void initState() {
    super.initState();
    widget.xi.onMessage(handleMessage);

    /// ignore: void_checks
    widget.xi.init().then((Null _) {
      widget.xi.sendNotification('client_started', <String, dynamic>{});
      // Arguably new_view should be sent by the editor (and the editor should plumb
      // the view id through to the connectEditor call). However, that would require holding
      // a pending queue of new_view requests, waiting for init to complete. This is easier.
      return widget.xi.sendRpc('new_view', <String, dynamic>{}, (dynamic id) {
        _viewId = id;
        log.info('view_id = $id');
        if (_pendingReqs != null) {
          for (_PendingNotification pending in _pendingReqs) {
            sendNotification(pending.method, pending.params);
          }
          _pendingReqs = null;
        }
      });
    });
  }

  /// Handle messages from xi-core.
  void handleMessage(dynamic data) {
    setState(() => message = '$data');
  }

  /// Uses a [MaterialApp] as the root of the Xi UI hierarchy.
  @override
  Widget build(BuildContext context) {
    const editor = Editor();
    return new MaterialApp(
        title: 'Xi',
        home: new Material(
            // required for the debug background to render correctly
            type: MaterialType.transparency,
            child: Container(
              constraints: new BoxConstraints.expand(),
              color: Colors.white,
              child: debugBackground ? _makeDebugBackground(editor) : editor,
            )));
  }
}

/// Creates a new widget with the editor overlayed on a watermarked background
Widget _makeDebugBackground(Widget editor) {
  return new Stack(children: <Widget>[
    Container(
        constraints: new BoxConstraints.expand(),
        child: new Center(
            child: Transform.rotate(
          angle: -math.pi / 6.0,
          child: new Text('xi editor',
              style: TextStyle(
                  fontSize: 144.0,
                  color: Colors.pink[50],
                  fontWeight: FontWeight.w800)),
        ))),
    editor,
  ]);
}
