import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';

class MobileAnimatedBackground extends StatefulWidget {
  final Widget child;
  final int pointCount;
  final double connectionDistance;
  final double mouseConnectionDistance;
  final Color lineColor;
  final Color backgroundColor;
  final double lineOpacity;

  const MobileAnimatedBackground({
    Key? key,
    required this.child,
    this.connectionDistance = 180,
    this.mouseConnectionDistance = 130,
    this.backgroundColor = Colors.black,
    this.lineColor = Colors.white,
    this.lineOpacity = 0.2,
    this.pointCount = 30,
  }) : super(key: key);

  @override
  State<MobileAnimatedBackground> createState() => _MobileAnimatedBackgroundState();
}

class _MobileAnimatedBackgroundState extends State<MobileAnimatedBackground>
    with SingleTickerProviderStateMixin {
  Offset _mousePosition = Offset.zero;
  List<PointData> _points = [];
  final Random _random = Random();
  bool _isInitialized = false;
  late AnimationController _animationController;
  double _time = 0.0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20),
    )..repeat();

    _animationController.addListener(() {
      _time += 0.01;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _isMobile => MediaQuery.of(context).size.width < 600;

  void _addPoints(Size size) {
    if (_isInitialized) return;
    _points.clear();

    final screenArea = size.width * size.height;
    final adaptivePointCount = (screenArea / 4000).floor();

    final pointCount = min(adaptivePointCount, _isMobile ? 60 : 150);

    for (int i = 0; i < pointCount; i++) {
      _points.add(PointData(
        position: Offset(
          _random.nextDouble() * size.width,
          _random.nextDouble() * size.height,
        ),
        velocity: Offset(
          (_random.nextDouble() - 0.5) * 0.4,
          (_random.nextDouble() - 0.5) * 0.4,
        ),
        size: _random.nextDouble() * 1.0 + 0.3, 
      ));
    }

    _isInitialized = true;
  }

  void _mouseUpdatePosition(PointerEvent details) {
    if (!_isMobile) {
      setState(() {
        _mousePosition = details.localPosition;
      });
    }
  }

  void _updatePoints(Size size) {
    for (int i = 0; i < _points.length; i++) {
      var point = _points[i];

      final waveX = sin(_time + i * 0.08) * 0.6;
      final waveY = cos(_time + i * 0.06) * 0.6;

      var newPosition = Offset(
        point.position.dx + point.velocity.dx + waveX,
        point.position.dy + point.velocity.dy + waveY,
      );

      var newVelocity = point.velocity;
      if (newPosition.dx <= 0 || newPosition.dx >= size.width) {
        newVelocity = Offset(-point.velocity.dx * 0.9, point.velocity.dy);
      }
      if (newPosition.dy <= 0 || newPosition.dy >= size.height) {
        newVelocity = Offset(point.velocity.dx, -point.velocity.dy * 0.9);
      }

      newPosition = Offset(
        newPosition.dx.clamp(10.0, size.width - 10),
        newPosition.dy.clamp(10.0, size.height - 10),
      );

      _points[i] = PointData(
        position: newPosition,
        velocity: newVelocity,
        size: point.size,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
        
        if (!_isInitialized) {
          _addPoints(screenSize);
        }
        
        _updatePoints(screenSize);

        return MouseRegion(
          onHover: !_isMobile ? _mouseUpdatePosition : null,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: widget.backgroundColor,
            child: Stack(
              children: [
                CustomPaint(
                  painter: _LinePainter(
                    connectionDistance: widget.connectionDistance,
                    mouseConnectionDistance: widget.mouseConnectionDistance,
                    lineColor: widget.lineColor,
                    lineOpacity: widget.lineOpacity,
                    mousePosition: !_isMobile ? _mousePosition : Offset.zero,
                    points: _points.map((p) => p.position).toList(),
                    enableMouseInteraction: !_isMobile,
                    time: _time,
                    isMobile: _isMobile,
                  ),
                  size: screenSize,
                ),
                widget.child,
              ],
            ),
          ),
        );
      },
    );
  }
}

class PointData {
  final Offset position;
  final Offset velocity;
  final double size;

  PointData({
    required this.position,
    required this.velocity,
    required this.size,
  });
}

class _LinePainter extends CustomPainter {
  final List<Offset> points;
  final Offset mousePosition;
  final double connectionDistance;
  final double mouseConnectionDistance;
  final Color lineColor;
  final double lineOpacity;
  final bool enableMouseInteraction;
  final double time;
  final bool isMobile;

  _LinePainter({
    required this.connectionDistance,
    required this.mouseConnectionDistance,
    required this.lineColor,
    required this.lineOpacity,
    required this.mousePosition,
    required this.points,
    required this.enableMouseInteraction,
    required this.time,
    required this.isMobile,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final enhancedLineOpacity = lineOpacity * 2;
    
    final linePaint = Paint()
      ..color = lineColor.withOpacity(enhancedLineOpacity)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = lineColor.withOpacity(enhancedLineOpacity * 1.5)
      ..style = PaintingStyle.fill;

    for (final point in points) {
      final radius = pointPaint.color.opacity * 1.5; 
      canvas.drawCircle(point, radius, pointPaint);
    }

    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final distance = (points[i] - points[j]).distance;
        if (distance < connectionDistance) {
          final opacity = 1.0 - (distance / connectionDistance);
          linePaint.color = lineColor.withOpacity(enhancedLineOpacity * opacity * 0.9);
          canvas.drawLine(points[i], points[j], linePaint);
        }
      }
    }

    if (enableMouseInteraction && mousePosition != Offset.zero) {
      final mouseLinePaint = Paint()
        ..color = Colors.white 
        ..strokeWidth = 2.0 
        ..style = PaintingStyle.stroke;

      for (final point in points) {
        final distance = (point - mousePosition).distance;
        if (distance < mouseConnectionDistance) {
          final opacity = 1.0 - (distance / mouseConnectionDistance);
          mouseLinePaint.color = Colors.white.withOpacity(opacity * 0.9); 
          mouseLinePaint.strokeWidth = 2.0 * opacity;
          canvas.drawLine(point, mousePosition, mouseLinePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}