import 'dart:math';
import 'package:flutter/material.dart';

class PrettySpinner extends StatefulWidget {
  final double size;
  final double ringThickness;

  const PrettySpinner({super.key, this.size = 110, this.ringThickness = 10});

  @override
  State<PrettySpinner> createState() => _PrettySpinnerState();
}

class _PrettySpinnerState extends State<PrettySpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final thickness = widget.ringThickness;

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final angle = _c.value * 2 * pi;
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: angle,
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 18,
                        spreadRadius: 0,
                        color: Color(0x22E91E63),
                      ),
                    ],
                  ),
                  child: ShaderMask(
                    shaderCallback: (rect) => const SweepGradient(
                      startAngle: 0.0,
                      endAngle: 2 * pi,
                      stops: [0.0, 0.3, 0.6, 1.0],
                      colors: [
                        Color(0xFFE91E63),
                        Color(0xFF2196F3),
                        Color(0xFFFF9800),
                        Color(0xFFE91E63),
                      ],
                    ).createShader(rect),
                    blendMode: BlendMode.srcATop,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: thickness),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: size - thickness * 2,
                height: size - thickness * 2,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      offset: Offset(0, 6),
                      color: Color(0x14000000),
                    ),
                  ],
                ),
              ),
              _dot(size, size / 2 - 6, angle),
              _dot(size, size / 2 - 6, angle + 2.0944),
              _dot(size, size / 2 - 6, angle + 4.1888),
            ],
          );
        },
      ),
    );
  }

  Widget _dot(double size, double r, double a) {
    final cx = size / 2 + r * cos(a);
    final cy = size / 2 + r * sin(a);
    return Positioned(
      left: cx - 6,
      top: cy - 6,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE91E63),
        ),
      ),
    );
  }
}
