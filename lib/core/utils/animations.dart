import 'package:flutter/material.dart';

class AppAnimations {
  AppAnimations._();

  // Fade In Animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, value, _) {
        return AnimatedOpacity(
          opacity: value,
          duration: duration,
          child: child,
        );
      },
    );
  }

  // Fade In Up Animation
  static Widget fadeInUp({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    Duration delay = Duration.zero,
    double offset = 30,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, value, _) {
        return AnimatedOpacity(
          opacity: value,
          duration: duration,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }

  // Slide In Left Animation
  static Widget slideInLeft({
    required Widget child,
    Duration duration = const Duration(milliseconds: 800),
    Duration delay = Duration.zero,
    double offset = 30,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, value, _) {
        return AnimatedOpacity(
          opacity: value,
          duration: duration,
          child: Transform.translate(
            offset: Offset(-offset * (1 - value), 0),
            child: child,
          ),
        );
      },
    );
  }

  // Float Animation Widget
  static Widget floatAnimation({
    required Widget child,
    Duration duration = const Duration(seconds: 3),
    double offset = 20,
  }) {
    return _FloatingWidget(
      duration: duration,
      offset: offset,
      child: child,
    );
  }

  // Bounce Animation Widget
  static Widget bounceAnimation({
    required Widget child,
    Duration duration = const Duration(seconds: 2),
    double offset = 10,
  }) {
    return _BouncingWidget(
      duration: duration,
      offset: offset,
      child: child,
    );
  }

  // Animation Delays
  static Duration get delay100 => const Duration(milliseconds: 100);
  static Duration get delay200 => const Duration(milliseconds: 200);
  static Duration get delay300 => const Duration(milliseconds: 300);
  static Duration get delay400 => const Duration(milliseconds: 400);
  static Duration get delay500 => const Duration(milliseconds: 500);
  static Duration get delay700 => const Duration(milliseconds: 700);
  static Duration get delay1000 => const Duration(seconds: 1);
}

// Floating Animation Widget
class _FloatingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offset;

  const _FloatingWidget({
    required this.child,
    required this.duration,
    required this.offset,
  });

  @override
  State<_FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<_FloatingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(
      begin: 0,
      end: widget.offset,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_animation.value),
          child: widget.child,
        );
      },
    );
  }
}

// Bouncing Animation Widget
class _BouncingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offset;

  const _BouncingWidget({
    required this.child,
    required this.duration,
    required this.offset,
  });

  @override
  State<_BouncingWidget> createState() => _BouncingWidgetState();
}

class _BouncingWidgetState extends State<_BouncingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(
      begin: 0,
      end: widget.offset,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.bounceOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_animation.value),
          child: widget.child,
        );
      },
    );
  }
} 