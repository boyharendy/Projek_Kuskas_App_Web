import 'package:flutter/material.dart';
import '../../config/theme.dart';

class MiniChart extends StatelessWidget {
  const MiniChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pengeluaran 7 Hari Terakhir',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              Text(
                'Rp 1.2jt',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.expense,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 60,
            child: CustomPaint(
              size: const Size(double.infinity, 60),
              painter: _MiniChartPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.16, size.height * 0.6),
      Offset(size.width * 0.33, size.height * 0.9),
      Offset(size.width * 0.5, size.height * 0.4),
      Offset(size.width * 0.66, size.height * 0.5),
      Offset(size.width * 0.83, size.height * 0.2),
      Offset(size.width, size.height * 0.1),
    ];

    final paint = Paint()
      ..color = AppColors.expense
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);

    // Draw dots
    final dotPaint = Paint()..color = AppColors.expense;
    for (final p in points) {
      canvas.drawCircle(p, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
