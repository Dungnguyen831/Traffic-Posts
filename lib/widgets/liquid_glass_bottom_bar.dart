import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:motor/motor.dart';
import 'package:traffic_app/theme/app_theme.dart';

/// Creates a horizontal jelly squash-and-stretch matrix from 1D drag velocity.
Matrix4 _buildJellyTransform(double velocity) {
  final distortion = (velocity.abs() / 10.0).clamp(0.0, 1.0) * 0.8;
  if (distortion == 0) return Matrix4.identity();

  final scaleX = 1.0 - (distortion * 0.5);
  final scaleY = 1.0 + (distortion * 0.3);
  return Matrix4.diagonal3Values(scaleX, scaleY, 1.0);
}

class LiquidGlassBottomBarTab {
  const LiquidGlassBottomBarTab({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
}

class LiquidGlassBottomBar extends StatefulWidget {
  const LiquidGlassBottomBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.horizontalPadding = 20,
    this.bottomPadding = 20,
    this.barHeight = 64,
    this.collapsedBarHeight = 50,
    this.collapsed = false,
    this.onExpandRequested,
  });

  final List<LiquidGlassBottomBarTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final double horizontalPadding;
  final double bottomPadding;
  final double barHeight;

  /// Height of the bar when [collapsed] is true (labels hidden).
  final double collapsedBarHeight;

  /// When true the bar shrinks (narrower, shorter, labels hidden),
  /// e.g. while the user scrolls down a feed.
  final bool collapsed;

  /// Called when the user interacts with the collapsed bar to expand it back.
  final VoidCallback? onExpandRequested;

  @override
  State<LiquidGlassBottomBar> createState() => _LiquidGlassBottomBarState();
}

class _LiquidGlassBottomBarState extends State<LiquidGlassBottomBar> {
  bool _isHolding = false;

  void _handleHoldChanged(bool isHolding) {
    if (_isHolding != isHolding) {
      setState(() => _isHolding = isHolding);
    }
    if (isHolding && widget.collapsed) {
      widget.onExpandRequested?.call();
    }
  }

  void _selectTab(int index) {
    if (widget.collapsed) {
      widget.onExpandRequested?.call();
    }
    widget.onTabSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final glassSettings = LiquidGlassSettings(
      refractiveIndex: 1.12,
      thickness: 18,
      blur: 8,
      saturation: 1.1,
      lightIntensity: 1.1,
      ambientStrength: 0.5,
      lightAngle: math.pi / 4,
      glassColor: Colors.white.withValues(alpha: 0.55),
    );

    final screenWidth = MediaQuery.sizeOf(context).width;
    final collapsedHorizontalPadding =
        widget.horizontalPadding + screenWidth * 0.12;
    final isCollapsed = widget.collapsed && !_isHolding;

    return LiquidGlassLayer(
      settings: glassSettings,
      child: LiquidGlassBlendGroup(
        blend: 10,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: isCollapsed ? 1 : 0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) {
            final horizontalPadding = lerpDouble(
              widget.horizontalPadding,
              collapsedHorizontalPadding,
              t,
            )!;
            final height = lerpDouble(
              widget.barHeight,
              widget.collapsedBarHeight,
              t,
            )!;
            final radius = height / 2;

            return AnimatedScale(
              scale: _isHolding ? 1.03 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Padding(
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  bottom: widget.bottomPadding,
                  top: 8,
                ),
                child: _TabIndicator(
                  tabIndex: widget.selectedIndex.clamp(
                    0,
                    widget.tabs.length - 1,
                  ),
                  tabCount: widget.tabs.length,
                  onHoldChanged: _handleHoldChanged,
                  onTabChanged: _selectTab,
                  background: LiquidGlass.grouped(
                    clipBehavior: Clip.antiAlias,
                    shape: LiquidRoundedSuperellipse(borderRadius: radius),
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        shape: LiquidRoundedSuperellipse(
                          borderRadius: radius,
                          side: BorderSide(
                            color: AppTheme.textColor.withValues(alpha: 0.045),
                            width: 0.8,
                          ),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.68),
                            Colors.white.withValues(alpha: 0.58),
                          ],
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    height: height,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        for (var i = 0; i < widget.tabs.length; i++)
                          Expanded(
                            child: _BottomBarTab(
                              tab: widget.tabs[i],
                              selected: widget.selectedIndex == i,
                              labelProgress: 1 - t,
                              onTap: () => _selectTab(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BottomBarTab extends StatelessWidget {
  const _BottomBarTab({
    required this.tab,
    required this.selected,
    required this.onTap,
    this.labelProgress = 1,
  });

  final LiquidGlassBottomBarTab tab;
  final bool selected;
  final VoidCallback onTap;

  /// 1 = label fully visible, 0 = label hidden (collapsed bar).
  final double labelProgress;

  @override
  Widget build(BuildContext context) {
    const glow = AppTheme.primaryColor;
    final unselectedColor = Color.lerp(
      AppTheme.subTextColor,
      AppTheme.textColor,
      0.32,
    )!;
    final itemColor = selected ? Colors.white : unselectedColor;
    final iconSize = lerpDouble(22, 24, labelProgress)!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        selected: selected,
        label: tab.label,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: AnimatedScale(
                scale: selected ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Icon(
                  selected ? (tab.selectedIcon ?? tab.icon) : tab.icon,
                  color: itemColor,
                  size: iconSize,
                  shadows: selected
                      ? [
                          Shadow(
                            color: glow.withValues(alpha: 0.90),
                            blurRadius: 10,
                          ),
                          Shadow(
                            color: AppTheme.primaryLightColor.withValues(
                              alpha: 0.65,
                            ),
                            blurRadius: 18,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
            if (labelProgress > 0.01)
              ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: labelProgress.clamp(0.0, 1.0),
                  child: Opacity(
                    opacity: labelProgress.clamp(0.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: ExcludeSemantics(
                        child: Text(
                          tab.label,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: itemColor,
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            shadows: selected
                                ? [
                                    Shadow(
                                      color: glow.withValues(alpha: 0.90),
                                      blurRadius: 8,
                                    ),
                                    Shadow(
                                      color: glow.withValues(alpha: 0.55),
                                      blurRadius: 14,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabIndicator extends StatefulWidget {
  const _TabIndicator({
    required this.child,
    required this.background,
    required this.tabIndex,
    required this.tabCount,
    required this.onTabChanged,
    this.onHoldChanged,
  });

  final int tabIndex;
  final int tabCount;
  final Widget child;
  final Widget background;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<bool>? onHoldChanged;

  @override
  State<_TabIndicator> createState() => _TabIndicatorState();
}

class _TabIndicatorState extends State<_TabIndicator> {
  bool _isDown = false;
  bool _isDragging = false;

  late double xAlign = _computeXAlignmentForTab(widget.tabIndex);

  double _computeXAlignmentForTab(int tabIndex) {
    final relativeTabIndex = (tabIndex / (widget.tabCount - 1)).clamp(0.0, 1.0);
    return (relativeTabIndex * 2) - 1;
  }

  @override
  void didUpdateWidget(covariant _TabIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabIndex != widget.tabIndex ||
        oldWidget.tabCount != widget.tabCount) {
      setState(() {
        xAlign = _computeXAlignmentForTab(widget.tabIndex);
      });
    }
  }

  double _getAlignmentFromGlobalPosition(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(globalPosition);

    final indicatorWidth = 1.0 / widget.tabCount;
    final draggableRange = 1.0 - indicatorWidth;
    final padding = indicatorWidth / 2;

    final rawRelativeX = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
    final normalizedX = (rawRelativeX - padding) / draggableRange;
    final adjustedRelativeX = _applyRubberBandResistance(normalizedX);
    return (adjustedRelativeX * 2) - 1;
  }

  double _applyRubberBandResistance(double value) {
    const double resistance = 0.4;
    const double maxOverdrag = 0.3;

    if (value < 0) {
      return -((-value) * resistance).clamp(0.0, maxOverdrag);
    } else if (value > 1) {
      return 1 + ((value - 1) * resistance).clamp(0.0, maxOverdrag);
    }
    return value;
  }

  void _startHoldAt(Offset globalPosition) {
    widget.onHoldChanged?.call(true);
    setState(() {
      _isDown = true;
      xAlign = _getAlignmentFromGlobalPosition(globalPosition);
    });
  }

  void _updateHoldAt(Offset globalPosition) {
    setState(() {
      _isDragging = true;
      xAlign = _getAlignmentFromGlobalPosition(globalPosition);
    });
  }

  void _finishHold({Velocity velocity = Velocity.zero}) {
    widget.onHoldChanged?.call(false);
    setState(() {
      _isDragging = false;
      _isDown = false;
    });

    final box = context.findRenderObject() as RenderBox;
    final currentRelativeX = (xAlign + 1) / 2;
    final tabWidth = 1.0 / widget.tabCount;
    final draggableRange = 1.0 - tabWidth;
    final velocityX =
        (velocity.pixelsPerSecond.dx / box.size.width) / draggableRange;

    int targetTabIndex;

    if (currentRelativeX < 0) {
      targetTabIndex = 0;
    } else if (currentRelativeX > 1) {
      targetTabIndex = widget.tabCount - 1;
    } else {
      const velocityThreshold = 0.5;
      if (velocityX.abs() > velocityThreshold) {
        final projectedX = (currentRelativeX + velocityX * 0.3).clamp(0.0, 1.0);
        targetTabIndex = (projectedX / tabWidth).round().clamp(
          0,
          widget.tabCount - 1,
        );

        final currentTabIndex = (currentRelativeX / tabWidth).round().clamp(
          0,
          widget.tabCount - 1,
        );
        if (velocityX > velocityThreshold &&
            targetTabIndex <= currentTabIndex &&
            currentTabIndex < widget.tabCount - 1) {
          targetTabIndex = currentTabIndex + 1;
        } else if (velocityX < -velocityThreshold &&
            targetTabIndex >= currentTabIndex &&
            currentTabIndex > 0) {
          targetTabIndex = currentTabIndex - 1;
        }
      } else {
        targetTabIndex = (currentRelativeX / tabWidth).round().clamp(
          0,
          widget.tabCount - 1,
        );
      }
    }

    xAlign = _computeXAlignmentForTab(targetTabIndex);

    if (targetTabIndex != widget.tabIndex) {
      widget.onTabChanged(targetTabIndex);
    }
  }

  void _cancelHold() {
    widget.onHoldChanged?.call(false);
    setState(() {
      _isDragging = false;
      _isDown = false;
      xAlign = _computeXAlignmentForTab(widget.tabIndex);
    });
  }

  /// Soft, diffused glowing lens behind the selected icon + label.
  Widget _buildGlowIndicator() {
    const glow = AppTheme.primaryColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(64),
        gradient: RadialGradient(
          radius: 0.72,
          colors: [
            glow.withValues(alpha: 0.52),
            AppTheme.primaryLightColor.withValues(alpha: 0.24),
            glow.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.58, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.20),
            blurRadius: 16,
            spreadRadius: -4,
          ),
        ],
      ),
      child: const SizedBox.expand(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetAlignment = _computeXAlignmentForTab(widget.tabIndex);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (d) => _startHoldAt(d.globalPosition),
      onLongPressMoveUpdate: (d) => _updateHoldAt(d.globalPosition),
      onLongPressEnd: (_) => _finishHold(),
      onLongPressCancel: _cancelHold,
      onHorizontalDragStart: (d) => _startHoldAt(d.globalPosition),
      onHorizontalDragUpdate: (d) => _updateHoldAt(d.globalPosition),
      onHorizontalDragEnd: (d) => _finishHold(velocity: d.velocity),
      onHorizontalDragCancel: _cancelHold,
      child: VelocityMotionBuilder(
        converter: SingleMotionConverter(),
        value: xAlign,
        motion: _isDragging
            ? const Motion.interactiveSpring(snapToEnd: true)
            : const Motion.bouncySpring(snapToEnd: true),
        builder: (context, value, velocity, _) {
          final alignment = Alignment(value, 0);
          return SingleMotionBuilder(
            motion: const Motion.snappySpring(
              snapToEnd: true,
              duration: Duration(milliseconds: 300),
            ),
            value: _isDown || (alignment.x - targetAlignment).abs() > 0.30
                ? 1.0
                : 0.0,
            builder: (context, thickness, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: widget.background),
                  _IndicatorTransform(
                    velocity: velocity,
                    tabCount: widget.tabCount,
                    alignment: alignment,
                    thickness: thickness,
                    child: IgnorePointer(
                      child: _buildGlowIndicator(),
                    ),
                  ),
                  child!,
                  if (thickness > 0.01)
                    _IndicatorTransform(
                      velocity: velocity,
                      tabCount: widget.tabCount,
                      alignment: alignment,
                      thickness: thickness,
                      child: IgnorePointer(
                        child: LiquidGlass.withOwnLayer(
                          settings: LiquidGlassSettings(
                            visibility: thickness.clamp(0.0, 1.0),
                            glassColor: AppTheme.primaryColor.withValues(
                              alpha: .14,
                            ),
                            saturation: 1.5,
                            refractiveIndex: 1.15,
                            thickness: 20,
                            lightIntensity: 2,
                            chromaticAberration: .5,
                            blur: 0,
                          ),
                          shape: const LiquidRoundedSuperellipse(
                            borderRadius: 64,
                          ),
                          child: const GlassGlow(child: SizedBox.expand()),
                        ),
                      ),
                    ),
                ],
              );
            },
            child: widget.child,
          );
        },
      ),
    );
  }
}

class _IndicatorTransform extends StatelessWidget {
  const _IndicatorTransform({
    required this.velocity,
    required this.tabCount,
    required this.alignment,
    required this.thickness,
    required this.child,
  });

  final double velocity;
  final int tabCount;
  final Alignment alignment;
  final double thickness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rect = RelativeRect.lerp(
      RelativeRect.fill,
      const RelativeRect.fromLTRB(-14, -14, -14, -14),
      thickness,
    )!;
    return Positioned.fill(
      left: 4,
      right: 4,
      top: 4,
      bottom: 4,
      child: FractionallySizedBox(
        widthFactor: 1 / tabCount,
        alignment: alignment,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fromRelativeRect(
              rect: rect,
              child: SingleMotionBuilder(
                motion: const Motion.bouncySpring(
                  duration: Duration(milliseconds: 600),
                ),
                value: velocity,
                builder: (context, velocity, child) {
                  return Transform(
                    alignment: Alignment.center,
                    transform: _buildJellyTransform(velocity),
                    child: child,
                  );
                },
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
