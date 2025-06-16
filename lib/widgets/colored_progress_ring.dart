// lib/widgets/colored_progress_ring.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ColoredProgressRing extends StatefulWidget {
  final double progress; // 0.0 - 1.0
  final Color color;
  final double size;
  final double strokeWidth;
  final String centerText;
  final String centerSubText;
  final bool animate;
  
  const ColoredProgressRing({
    Key? key,
    required this.progress,
    required this.color,
    this.size = 100,
    this.strokeWidth = 10,
    this.centerText = '',
    this.centerSubText = '',
    this.animate = true,
  }) : super(key: key);

  @override
  State<ColoredProgressRing> createState() => _ColoredProgressRingState();
}

class _ColoredProgressRingState extends State<ColoredProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.animate) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress Ring
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ProgressRingPainter(
                  progress: widget.animate ? _animation.value : widget.progress,
                  color: widget.color,
                  strokeWidth: widget.strokeWidth,
                ),
              );
            },
          ),
          
          // Center Text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.centerText.isNotEmpty)
                Text(
                  widget.centerText,
                  style: TextStyle(
                    fontSize: widget.size * 0.2,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              if (widget.centerSubText.isNotEmpty)
                Text(
                  widget.centerSubText,
                  style: TextStyle(
                    fontSize: widget.size * 0.08,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
