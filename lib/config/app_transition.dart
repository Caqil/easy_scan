import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Animation durations used throughout the app
class AnimDurations {
  /// Standard transition duration (300ms)
  static const standard = Duration(milliseconds: 300);

  /// Fast transition duration (200ms)
  static const fast = Duration(milliseconds: 200);

  /// Slow transition duration (400ms)
  static const slow = Duration(milliseconds: 400);

  /// Modal transition duration (280ms)
  static const modal = Duration(milliseconds: 280);

  /// Hero transition duration (350ms)
  static const hero = Duration(milliseconds: 350);
}

/// Animation curves used throughout the app
class AnimCurves {
  /// Standard curve for most animations
  static const standard = Curves.easeOutCubic;

  /// Emphasized curve for more dramatic animations
  static const emphasized = Curves.easeOutQuint;

  /// Modal curve for sheet-like animations
  static const modal = Curves.easeOutExpo;

  /// Deceleration curve for hero transitions
  static const decelerate = Curves.easeOutQuart;

  /// Acceleration curve for exit animations
  static const accelerate = Curves.easeIn;
}

/// Custom page transitions for the app
class AppTransitions {
  /// Standard transition for most routes - smooth fade + slide
  static CustomTransitionPage<void> buildPageTransition<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    Duration? duration,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Fade + slide transition from bottom
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        final curve = AnimCurves.emphasized;

        // Create a curved animation
        final Animation<double> curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        // Combine fade and slide
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position:
                Tween<Offset>(begin: begin, end: end).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: duration ?? AnimDurations.standard,
      reverseTransitionDuration: (duration ?? AnimDurations.standard) * 0.7,
    );
  }

  /// Modal transition for sheets and dialogs
  static CustomTransitionPage<void> buildModalTransition<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    Duration? duration,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Use a combined scale + fade for modals
        const begin = 0.95;
        const end = 1.0;
        final curve = AnimCurves.modal;

        // Create a curved animation
        final Animation<double> curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        // Create the scale animation
        final Animation<double> scaleAnimation = Tween<double>(
          begin: begin,
          end: end,
        ).animate(curvedAnimation);

        // Combine fade and scale
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
      transitionDuration: duration ?? AnimDurations.modal,
      reverseTransitionDuration: (duration ?? AnimDurations.modal) * 0.7,
    );
  }

  /// Hero transition for detailed views like document viewing
  static CustomTransitionPage<void> buildHeroTransition<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    Duration? duration,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // For hero transitions, we let the hero widget handle animation
        // and just add a fade for non-hero elements
        final curve = AnimCurves.decelerate;

        // Create a curved animation
        final Animation<double> curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );
      },
      transitionDuration: duration ?? AnimDurations.hero,
      reverseTransitionDuration: (duration ?? AnimDurations.hero) * 0.7,
    );
  }

  /// Slide transition from right (standard navigation)
  static CustomTransitionPage<void> buildSlideTransition<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    Duration? duration,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final curve = AnimCurves.standard;
        final reverseCurve = AnimCurves.accelerate;

        // Create a curved animation
        final Animation<double> curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
          reverseCurve: reverseCurve,
        );

        // Create the slide animation
        final Animation<Offset> slideAnimation = Tween<Offset>(
          begin: begin,
          end: end,
        ).animate(curvedAnimation);

        // Add subtle fade for smoothness
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
          ),
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: duration ?? AnimDurations.standard,
      reverseTransitionDuration: (duration ?? AnimDurations.standard) * 0.7,
    );
  }

  /// Vertical slide transition (for sheets or detail views)
  static CustomTransitionPage<void> buildVerticalSlideTransition<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    Duration? duration,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final curve = AnimCurves.decelerate;

        // Create a curved animation
        final Animation<double> curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        // Create the slide animation
        final Animation<Offset> slideAnimation = Tween<Offset>(
          begin: begin,
          end: end,
        ).animate(curvedAnimation);

        // Add subtle fade for smoothness
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
          ),
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: duration ?? const Duration(milliseconds: 320),
      reverseTransitionDuration: duration ?? const Duration(milliseconds: 250),
    );
  }

  /// Shared axis transition (z-axis) for related content
  static CustomTransitionPage<void> buildSharedAxisTransition<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    Duration? duration,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Shared Z-Axis pattern: scale + fade
        final Animation<double> fadeIn = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
        );

        final Animation<double> fadeOut = CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
        );

        final Animation<double> scaleIn = Tween<double>(
          begin: 0.92,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        return FadeTransition(
          opacity: fadeIn,
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.3).animate(fadeOut),
            child: ScaleTransition(
              scale: scaleIn,
              child: child,
            ),
          ),
        );
      },
      transitionDuration: duration ?? const Duration(milliseconds: 400),
      reverseTransitionDuration: duration ?? const Duration(milliseconds: 350),
    );
  }

  /// Container transform transition for material design patterns
  static CustomTransitionPage<void> buildContainerTransform<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    required Rect? fromRect,
    Color? fromColor,
    Duration? duration,
  }) {
    // If we don't have a source rectangle, fall back to standard transition
    if (fromRect == null) {
      return buildPageTransition(
        context: context,
        state: state,
        child: child,
      );
    }

    // Get screen size for calculating animations
    final Size screenSize = MediaQuery.of(context).size;

    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final Color color = fromColor ?? Theme.of(context).colorScheme.surface;

        return _ContainerTransformOverlay(
          animation: animation,
          fromRect: fromRect,
          screenSize: screenSize,
          color: color,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
      transitionDuration: duration ?? const Duration(milliseconds: 500),
      reverseTransitionDuration: duration ?? const Duration(milliseconds: 400),
    );
  }
}

/// Widget that handles the container transform animation
class _ContainerTransformOverlay extends StatelessWidget {
  final Animation<double> animation;
  final Rect fromRect;
  final Size screenSize;
  final Color color;
  final Widget child;

  const _ContainerTransformOverlay({
    required this.animation,
    required this.fromRect,
    required this.screenSize,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate the starting and ending values
    final double startRadius = math.sqrt(
          fromRect.width * fromRect.width + fromRect.height * fromRect.height,
        ) /
        2;

    final double endRadius = math.sqrt(
      screenSize.width * screenSize.width +
          screenSize.height * screenSize.height,
    );

    final Offset center = Offset(
      fromRect.left + fromRect.width / 2,
      fromRect.top + fromRect.height / 2,
    );

    // Create the animations
    final Animation<double> radiusAnimation = Tween<double>(
      begin: startRadius,
      end: endRadius,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.5, curve: Curves.fastOutSlowIn),
    ));

    final Animation<double> fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.3, 0.5, curve: Curves.easeOut),
    ));

    return Stack(
      children: [
        // Expanding circle overlay
        AnimatedBuilder(
          animation: radiusAnimation,
          builder: (context, _) {
            return ClipPath(
              clipper: _CircleClipper(
                center: center,
                radius: radiusAnimation.value,
              ),
              child: Container(
                color: color,
                width: screenSize.width,
                height: screenSize.height,
              ),
            );
          },
        ),

        // Content that fades in after the circle expands
        FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      ],
    );
  }
}

/// Custom clipper for the expanding circle animation
class _CircleClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  _CircleClipper({
    required this.center,
    required this.radius,
  });

  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    return path;
  }

  @override
  bool shouldReclip(_CircleClipper oldClipper) {
    return center != oldClipper.center || radius != oldClipper.radius;
  }
}
