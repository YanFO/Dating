import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme_colors.dart';
import '../../data/models/icebreaker_models.dart';

class IcebreakerResultSheet extends StatelessWidget {
  final IcebreakerResult result;

  const IcebreakerResultSheet({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: c.background,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.muted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Scene analysis
                    if (result.sceneAnalysis.isNotEmpty) ...[
                      Text(
                        'Scene Analysis',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.sceneAnalysis,
                        style: TextStyle(
                            fontSize: 14,
                            color: c.textSecondary,
                            height: 1.5),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Approach readiness
                    if (result.approachReadiness.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: c.primary.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusLg),
                          border: Border.all(
                              color: c.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.zap,
                                size: 18, color: c.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                result.approachReadiness,
                                style: TextStyle(
                                    fontSize: 13, color: c.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Opening lines
                    if (result.openingLines.isNotEmpty) ...[
                      Text(
                        'Opening Lines',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...result.openingLines.map((line) => _buildOpeningLine(c, line)),
                      const SizedBox(height: 16),
                    ],

                    // Observation hooks
                    if (result.observationHooks.isNotEmpty) ...[
                      Text(
                        'Observation Hooks',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: result.observationHooks
                            .map((hook) => _buildHookChip(c, hook))
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Behavior tips
                    if (result.behaviorTips.isNotEmpty) ...[
                      Text(
                        'Behavior Tips',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...result.behaviorTips.map((tip) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(LucideIcons.checkCircle2,
                                    size: 14, color: c.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(tip,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: c.textSecondary)),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOpeningLine(AppThemeColors c, OpeningLine line) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${line.text}"',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  line.tone,
                  style: TextStyle(fontSize: 10, color: c.primary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(line.confidence * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: c.textTertiary,
                ),
              ),
            ],
          ),
          if (line.basedOn.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              line.basedOn,
              style: TextStyle(fontSize: 11, color: c.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHookChip(AppThemeColors c, ObservationHook hook) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hook.detail,
            style: TextStyle(fontSize: 12, color: c.textPrimary),
          ),
          Text(
            hook.hookType,
            style: TextStyle(fontSize: 10, color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}
