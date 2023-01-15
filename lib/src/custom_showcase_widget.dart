/*
 * Copyright (c) 2021 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'package:flutter/material.dart';

import '../showcaseview.dart';

class CustomShowCaseWidget extends StatefulWidget {

  final Builder builder;

  /// Triggered when all the showcases are completed.
  final VoidCallback? onFinish;

  /// Triggered every time on start of each showcase.
  final Function(int?, GlobalKey)? onStart;

  /// Triggered every time on completion of each showcase
  final Function(int?, GlobalKey)? onComplete;

  /// Whether all showcases will auto sequentially start
  /// having time interval of [autoPlayDelay] .
  ///
  /// Default to `false`
  final bool autoPlay;

  /// Visibility time of current showcase when [autoplay] sets to true.
  ///
  /// Default to [Duration(seconds: 3)]
  final Duration autoPlayDelay;

  /// Whether blocking user interaction while [autoPlay] is enabled.
  ///
  /// Default to `false`
  final bool enableAutoPlayLock;

  /// Whether disabling bouncing/moving animation for all tooltips
  /// while showcasing
  ///
  /// Default to `false`
  final bool disableMovingAnimation;

  /// Whether disabling initial scale animation for all the default tooltips
  /// when showcase is started and completed
  ///
  /// Default to `false`
  final bool disableScaleAnimation;

  /// Whether disabling barrier interaction
  final bool disableBarrierInteraction;

  /// Provides time duration for auto scrolling when [enableAutoScroll] is true
  final Duration scrollDuration;

  /// Default overlay blur used by showcase. if [Showcase.blurValue]
  /// is not provided.
  ///
  /// Default value is 0.
  final double blurValue;

  /// While target widget is out viewport then
  /// whether enabling auto scroll so as to make the target widget visible.
  final bool enableAutoScroll;

  /// Enable/disable showcase globally. Enabled by default.
  final bool enableShowcase;

  final int totalWidgets;





  const CustomShowCaseWidget({
    required this.builder,
    this.totalWidgets = 0,
    this.onFinish,
    this.onStart,
    this.onComplete,
    this.autoPlay = false,
    this.autoPlayDelay = const Duration(milliseconds: 2000),
    this.enableAutoPlayLock = false,
    this.blurValue = 0,
    this.scrollDuration = const Duration(milliseconds: 300),
    this.disableMovingAnimation = false,
    this.disableScaleAnimation = false,
    this.enableAutoScroll = false,
    this.disableBarrierInteraction = false,
    this.enableShowcase = true,
  });

  static GlobalKey? activeTargetWidget(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedShowCaseView>()
        ?.activeWidgetIds;
  }

  static CustomShowCaseWidgetState of(BuildContext context) {
    final state = context.findAncestorStateOfType<CustomShowCaseWidgetState>();
    if (state != null) {
      return state;
    } else {
      throw Exception('Please provide ShowCaseView context');
    }
  }

  @override
  CustomShowCaseWidgetState createState() => CustomShowCaseWidgetState();
}

class CustomShowCaseWidgetState extends State<CustomShowCaseWidget> {
  List<GlobalKey>? ids;
  int? activeWidgetId;
  late bool autoPlay;
  late bool disableMovingAnimation;
  late bool disableScaleAnimation;
  late Duration autoPlayDelay;
  late bool enableAutoPlayLock;
  late bool enableAutoScroll;
  late bool disableBarrierInteraction;
  late bool enableShowcase;

  /// Returns value of  [CustomShowCaseWidget.blurValue]
  double get blurValue => widget.blurValue;

  int get totalWidgets => widget.totalWidgets;

  set totalWidgets(int newVal) {
    totalWidgets = newVal;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant CustomShowCaseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _init();
  }

  void _init() {
    autoPlayDelay = widget.autoPlayDelay;
    autoPlay = widget.autoPlay;
    disableMovingAnimation = widget.disableMovingAnimation;
    disableScaleAnimation = widget.disableScaleAnimation;
    enableAutoPlayLock = widget.enableAutoPlayLock;
    enableAutoScroll = widget.enableAutoScroll;
    disableBarrierInteraction = widget.disableBarrierInteraction;
    enableShowcase = widget.enableShowcase;
  }

  /// Starts Showcase view from the beginning of specified list of widget ids.
  /// If this function is used when showcase has been disabled then it will
  /// throw an exception.
  void startShowCase(List<GlobalKey> widgetIds) {
    if (!enableShowcase) {
      throw Exception(
        "You are trying to start Showcase while it has been disabled with "
            "`enableShowcase` parameter to false from ShowCaseWidget",
      );
    }
    if (mounted) {
      setState(() {
        ids = widgetIds;
        activeWidgetId = 0;
        _onStart();
      });
    }
  }

  /// Completes showcase of given key and starts next one
  /// otherwise will finish the entire showcase view
  void completed(GlobalKey? key) {
    if (ids != null && ids![activeWidgetId!] == key && mounted) {
      setState(() {
        _onComplete();
        activeWidgetId = activeWidgetId! + 1;
        _onStart();

        if (activeWidgetId! >= ids!.length) {
          _cleanupAfterSteps();
          if (widget.onFinish != null) {
            widget.onFinish!();
          }
        }
      });
    }
  }

  /// Completes current active showcase and starts next one
  /// otherwise will finish the entire showcase view
  void next() {
    if (ids != null && mounted) {
      setState(() {
        _onComplete();
        activeWidgetId = activeWidgetId! + 1;
        _onStart();

        if (activeWidgetId! >= ids!.length) {
          _cleanupAfterSteps();
          if (widget.onFinish != null) {
            widget.onFinish!();
          }
        }
      });
    }
  }

  /// Completes current active showcase and starts previous one
  /// otherwise will finish the entire showcase view
  void previous() {
    if (ids != null && ((activeWidgetId ?? 0) - 1) >= 0 && mounted) {
      setState(() {
        _onComplete();
        activeWidgetId = activeWidgetId! - 1;
        _onStart();
        if (activeWidgetId! >= ids!.length) {
          _cleanupAfterSteps();
          if (widget.onFinish != null) {
            widget.onFinish!();
          }
        }
      });
    }
  }

  /// Dismiss entire showcase view
  void dismiss() {
    if (mounted) {
      setState(_cleanupAfterSteps);
    }
  }

  void _onStart() {
    if (activeWidgetId! < ids!.length) {
      widget.onStart?.call(activeWidgetId, ids![activeWidgetId!]);
    }
  }

  void _onComplete() {
    widget.onComplete?.call(activeWidgetId, ids![activeWidgetId!]);
  }

  void _cleanupAfterSteps() {
    ids = null;
    activeWidgetId = null;
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedShowCaseView(
      activeWidgetIds: ids?.elementAt(activeWidgetId!),
      child: widget.builder,
    );
  }
}

class _InheritedShowCaseView extends InheritedWidget {
  final GlobalKey? activeWidgetIds;

  const _InheritedShowCaseView({
    required this.activeWidgetIds,
    required Widget child,
  }) : super(child: child);

  @override
  bool updateShouldNotify(_InheritedShowCaseView oldWidget) =>
      oldWidget.activeWidgetIds != activeWidgetIds;
}
