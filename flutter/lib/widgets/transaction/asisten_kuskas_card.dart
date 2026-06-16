import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../config/theme.dart';

class AsistenKuskasCard extends StatefulWidget {
  final bool isLoading;
  final String status;
  final String statusColor;
  final String commentary;
  final List<String> tips;

  const AsistenKuskasCard({
    super.key,
    required this.isLoading,
    required this.status,
    required this.statusColor,
    required this.commentary,
    required this.tips,
  });

  @override
  State<AsistenKuskasCard> createState() => _AsistenKuskasCardState();
}

class _AsistenKuskasCardState extends State<AsistenKuskasCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.statusColor.toLowerCase()) {
      case 'green':
        return AppColors.income;
      case 'blue':
        return AppColors.secondaryLight;
      case 'orange':
      case 'red':
        return AppColors.expense;
      default:
        return AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0x1F0F1532), // Translucent Navy
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.03),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: widget.isLoading ? _buildLoadingSkeleton() : _buildContent(statusColor),
        ),
      ),
    );
  }

  Widget _buildContent(Color statusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // AI Glowing Pulse Icon
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withOpacity(0.15 + (_pulseController.value * 0.1)),
                            AppColors.primary.withOpacity(0.15 + (_pulseController.value * 0.1)),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.2 * _pulseController.value),
                            blurRadius: 8 + (8 * _pulseController.value),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.accentLight,
                        size: 20,
                      ),
                    );
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Asisten KUSKAS',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Analisis Keuangan AI',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.round),
                border: Border.all(
                  color: statusColor.withOpacity(0.25),
                  width: 1.0,
                ),
              ),
              child: Text(
                widget.status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const Divider(color: Color(0x14FFFFFF), height: 1),
        const SizedBox(height: AppSpacing.md),

        // Commentary text
        Text(
          widget.commentary,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Tips List
        if (widget.tips.isNotEmpty) ...[
          const SizedBox(height: 4),
          ...widget.tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 3.5),
                      child: const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AppColors.warning,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12.5,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final opacity = 0.3 + (_pulseController.value * 0.4);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1 * opacity),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1 * opacity),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 60,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06 * opacity),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 70,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08 * opacity),
                    borderRadius: BorderRadius.circular(AppRadius.round),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(color: Color(0x14FFFFFF), height: 1),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08 * opacity),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08 * opacity),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 180,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08 * opacity),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Tips skeleton
            ...List.generate(
              2,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08 * opacity),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 200,
                      height: 11,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06 * opacity),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
