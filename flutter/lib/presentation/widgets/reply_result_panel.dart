import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme_colors.dart';
import '../../data/models/reply_models.dart';

class ReplyResultPanel extends StatelessWidget {
  final ReplyResult result;

  const ReplyResultPanel({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Emotion analysis
        _buildEmotionCard(c),
        const SizedBox(height: 16),

        // Reply options
        if (result.replyOptions.isNotEmpty) ...[
          Text(
            'Reply Options',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...result.replyOptions
              .map((option) => _buildReplyOptionCard(c, option)),
          const SizedBox(height: 16),
        ],

        // Coach panel
        if (result.coachPanel != null) _buildCoachPanel(c, result.coachPanel!),
      ],
    );
  }

  Widget _buildEmotionCard(AppThemeColors c) {
    final ea = result.emotionAnalysis;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.surface, c.background],
        ),
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.heartPulse, size: 16, color: c.primary),
              const SizedBox(width: 8),
              Text(
                'Emotion: ${ea.detectedEmotion}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${(ea.confidence * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: c.primary,
                ),
              ),
            ],
          ),
          if (ea.subtext.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              ea.subtext,
              style: TextStyle(
                  fontSize: 12, color: c.textSecondary, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyOptionCard(AppThemeColors c, ReplyOption option) {
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
            '"${option.text}"',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildTag(c, option.intent),
              _buildTag(c, option.strategy),
              if (option.frameworkTechnique.isNotEmpty)
                _buildTag(c, option.frameworkTechnique),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(AppThemeColors c, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: c.primary),
      ),
    );
  }

  Widget _buildCoachPanel(AppThemeColors c, CoachPanel panel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.graduationCap, size: 16, color: c.primary),
              const SizedBox(width: 8),
              Text(
                'Coach Notes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          if (panel.perspectiveNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              panel.perspectiveNote,
              style: TextStyle(
                  fontSize: 12, color: c.textSecondary, height: 1.4),
            ),
          ],
          if (panel.dos.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...panel.dos.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.checkCircle2,
                          size: 14, color: c.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(d,
                            style: TextStyle(
                                fontSize: 12, color: c.textSecondary)),
                      ),
                    ],
                  ),
                )),
          ],
          if (panel.donts.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...panel.donts.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.xCircle, size: 14, color: c.textTertiary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(d,
                            style: TextStyle(
                                fontSize: 12, color: c.textSecondary)),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
