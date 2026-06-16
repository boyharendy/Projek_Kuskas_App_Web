import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AnimatedGlowingBackground extends StatefulWidget {
  final Widget child;

  const AnimatedGlowingBackground({super.key, required this.child});

  @override
  State<AnimatedGlowingBackground> createState() => _AnimatedGlowingBackgroundState();
}

class _AnimatedGlowingBackgroundState extends State<AnimatedGlowingBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base navy black background
        Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFF03050C),
        ),

        // Moving glowing blobs
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final val = _controller.value * 2 * pi;
              
              // Smooth circular paths for shifting blobs
              final x1 = sin(val) * 0.45;
              final y1 = cos(val) * 0.35 - 0.4;

              final x2 = cos(val + pi / 2) * 0.5;
              final y2 = sin(val + pi / 2) * 0.3 + 0.1;

              final x3 = sin(val * 1.5) * 0.3;
              final y3 = cos(val * 1.5) * 0.4 - 0.1;

              return Stack(
                children: [
                  // Blob 1: Indigo glow (top area)
                  Align(
                    alignment: Alignment(x1, y1),
                    child: Container(
                      width: 350,
                      height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6366F1).withOpacity(0.18),
                      ),
                    ),
                  ),

                  // Blob 2: Fuchsia glow (bottom/mid area)
                  Align(
                    alignment: Alignment(x2, y2),
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFD946EF).withOpacity(0.12),
                      ),
                    ),
                  ),

                  // Blob 3: Cyan glow (center area)
                  Align(
                    alignment: Alignment(x3, y3),
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0EA5E9).withOpacity(0.1),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // High blur filter to blend circles into a smooth organic shifting glow
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ),

        // Foreground content
        Positioned.fill(child: widget.child),
      ],
    );
  }
}
