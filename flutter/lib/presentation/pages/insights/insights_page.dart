import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme_colors.dart';
import '../../../core/l10n/tr_extension.dart';
import '../../../data/models/insights_models.dart';
import '../../providers/insights_provider.dart';

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(skillsProvider.notifier).loadSkills();
      ref.read(reportsProvider.notifier).loadReports();
      ref.read(voiceCoachLogsProvider.notifier).loadLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              ref.tr('insights_title'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildRadarSection(c),
          const SizedBox(height: 32),
          _buildReportSection(c),
          const SizedBox(height: 32),
          _buildVoiceCoachSection(c),
        ],
      ),
    );
  }

  Widget _buildRadarSection(AppThemeColors c) {
    final skills = ref.watch(skillsProvider);
    final labels = [
      ref.tr('insights_emotional_value'),
      ref.tr('insights_listening'),
      ref.tr('insights_frame_control'),
      ref.tr('insights_escalation'),
      ref.tr('insights_empathy'),
      ref.tr('insights_humor_label'),
    ];

    return skills.when(
      data: (s) {
        final values = s?.toList() ?? [0.83, 0.72, 0.67, 0.55, 0.60, 0.78];
        return _buildRadarChart(labels, values, c);
      },
      loading: () => _buildRadarChart(
          labels, [0.83, 0.72, 0.67, 0.55, 0.60, 0.78], c),
      error: (_, __) => _buildRadarChart(
          labels, [0.83, 0.72, 0.67, 0.55, 0.60, 0.78], c),
    );
  }

  Widget _buildRadarChart(
      List<String> labels, List<double> values, AppThemeColors c) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppColors.radius2Xl),
        border: Border.all(color: c.border),
      ),
      child: Center(
        child: SizedBox(
          width: 280,
          height: 280,
          child: CustomPaint(
            painter: _RadarChartPainter(
              labels: labels,
              values: values,
              primaryColor: c.primary,
              gridColor: c.muted,
              labelColor: c.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportSection(AppThemeColors c) {
    final reports = ref.watch(reportsProvider);

    return reports.when(
      data: (list) {
        if (list.isNotEmpty) {
          return _buildPostDateReport(c, list.first);
        }
        return _buildPostDateReportFallback(c);
      },
      loading: () => _buildPostDateReportFallback(c),
      error: (_, __) => _buildPostDateReportFallback(c),
    );
  }

  Widget _buildPostDateReport(AppThemeColors c, DateReport report) {
    final score = report.score.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            ref.tr('insights_report_title'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: c.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.surface, c.background],
            ),
            borderRadius: BorderRadius.circular(AppColors.radius2Xl),
            border: Border.all(color: c.border),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -6,
                top: -20,
                child: Text(
                  score,
                  style: TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary.withValues(alpha: 0.03),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        score,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w500,
                          color: c.primary,
                          letterSpacing: -2,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 4),
                        child: Text(
                          '/ 100',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: c.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (report.goodPoints.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      ref.tr('insights_went_well'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: c.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...report.goodPoints.map((point) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildFeedbackItem(
                            c: c,
                            icon: LucideIcons.checkCircle2,
                            iconColor: c.primary,
                            text: point,
                          ),
                        )),
                  ],
                  if (report.toImprove.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Divider(color: c.border, thickness: 1),
                    const SizedBox(height: 20),
                    Text(
                      ref.tr('insights_to_improve'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: c.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...report.toImprove.map((point) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildFeedbackItem(
                            c: c,
                            icon: LucideIcons.info,
                            iconColor: c.warning,
                            text: point,
                          ),
                        )),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Fallback with hardcoded data when API is unavailable
  Widget _buildPostDateReportFallback(AppThemeColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            ref.tr('insights_report_title'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: c.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.surface, c.background],
            ),
            borderRadius: BorderRadius.circular(AppColors.radius2Xl),
            border: Border.all(color: c.border),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -6,
                top: -20,
                child: Text(
                  '85',
                  style: TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary.withValues(alpha: 0.03),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '85',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w500,
                          color: c.primary,
                          letterSpacing: -2,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 4),
                        child: Text(
                          '/ 100',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: c.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    ref.tr('insights_went_well'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: c.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeedbackItem(
                    c: c,
                    icon: LucideIcons.checkCircle2,
                    iconColor: c.primary,
                    text: ref.tr('insights_eye_contact'),
                  ),
                  const SizedBox(height: 8),
                  _buildFeedbackItem(
                    c: c,
                    icon: LucideIcons.checkCircle2,
                    iconColor: c.primary,
                    text: ref.tr('insights_humor_feedback'),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: c.border, thickness: 1),
                  const SizedBox(height: 20),
                  Text(
                    ref.tr('insights_to_improve'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: c.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeedbackItem(
                    c: c,
                    icon: LucideIcons.info,
                    iconColor: c.warning,
                    text: ref.tr('insights_interrupted'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceCoachSection(AppThemeColors c) {
    final logs = ref.watch(voiceCoachLogsProvider);

    return logs.when(
      data: (list) {
        if (list.isEmpty) {
          return _buildVoiceCoachEmpty(c);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                ref.tr('insights_vc_title'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: c.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...list.map((log) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildVoiceCoachLogCard(c, log),
                )),
          ],
        );
      },
      loading: () => _buildVoiceCoachEmpty(c),
      error: (_, __) => _buildVoiceCoachEmpty(c),
    );
  }

  Widget _buildVoiceCoachEmpty(AppThemeColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            ref.tr('insights_vc_title'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: c.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppColors.radius2Xl),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              Icon(LucideIcons.mic, size: 32, color: c.textTertiary),
              const SizedBox(height: 12),
              Text(
                ref.tr('insights_vc_empty'),
                style: TextStyle(fontSize: 14, color: c.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceCoachLogCard(AppThemeColors c, VoiceCoachLog log) {
    final dateStr =
        log.createdAt.isNotEmpty ? _formatDate(log.createdAt) : '';

    // 建構交錯的對話時間軸：對話 → 教練回覆 → 教練分析
    final timelineItems = <_TimelineEntry>[];
    final maxLen = [
      log.inputTranscripts.length,
      log.coachTranscripts.length,
      log.coachingUpdates.length,
    ].reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < maxLen; i++) {
      if (i < log.inputTranscripts.length) {
        timelineItems.add(_TimelineEntry(
          type: _TimelineType.userSpeech,
          text: log.inputTranscripts[i],
        ));
      }
      if (i < log.coachTranscripts.length) {
        timelineItems.add(_TimelineEntry(
          type: _TimelineType.coachSpeech,
          text: log.coachTranscripts[i],
        ));
      }
      if (i < log.coachingUpdates.length) {
        timelineItems.add(_TimelineEntry(
          type: _TimelineType.analysis,
          update: log.coachingUpdates[i],
        ));
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppColors.radius2Xl),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 標題列：日期 + 持續時間 ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.mic, size: 16, color: c.primary),
                  const SizedBox(width: 8),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  log.durationFormatted,
                  style: TextStyle(
                    fontSize: 11,
                    color: c.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          if (timelineItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            // ── 對話時間軸 ──
            ...timelineItems
                .map((entry) => _buildTimelineItem(c, entry)),
          ],
        ],
      ),
    );
  }

  /// 根據類型渲染時間軸項目
  Widget _buildTimelineItem(AppThemeColors c, _TimelineEntry entry) {
    switch (entry.type) {
      case _TimelineType.userSpeech:
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.textTertiary.withValues(alpha: 0.15),
                ),
                child: Icon(LucideIcons.user, size: 12, color: c.textSecondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: c.background,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: c.borderLight.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    entry.text,
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case _TimelineType.coachSpeech:
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.primary.withValues(alpha: 0.15),
                ),
                child: Icon(LucideIcons.bot, size: 12, color: c.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entry.text,
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case _TimelineType.analysis:
        final update = entry.update!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 32),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.primary.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 情緒 + 技巧標籤
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (update.emotion.isNotEmpty)
                      _buildTag(c, update.emotion, c.info),
                    if (update.technique.isNotEmpty)
                      _buildTag(c, update.technique, c.primary),
                  ],
                ),

                // 情緒說明
                if (update.emotionDetail.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    update.emotionDetail,
                    style: TextStyle(
                      fontSize: 11,
                      color: c.textTertiary,
                      height: 1.3,
                    ),
                  ),
                ],

                // 建議
                if (update.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...update.suggestions.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(LucideIcons.lightbulb,
                                size: 13, color: c.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                s,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: c.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],

                // 方向
                if (update.direction.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.compass,
                          size: 12, color: c.textTertiary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          update.direction,
                          style: TextStyle(
                            fontSize: 11,
                            color: c.textTertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
    }
  }

  Widget _buildTag(AppThemeColors c, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  Widget _buildFeedbackItem({
    required AppThemeColors c,
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: c.textSecondary),
          ),
        ),
      ],
    );
  }
}

enum _TimelineType { userSpeech, coachSpeech, analysis }

class _TimelineEntry {
  final _TimelineType type;
  final String text;
  final CoachingUpdate? update;

  const _TimelineEntry({
    required this.type,
    this.text = '',
    this.update,
  });
}

class _RadarChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;
  final Color primaryColor;
  final Color gridColor;
  final Color labelColor;

  _RadarChartPainter({
    required this.labels,
    required this.values,
    required this.primaryColor,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 40;
    final sides = labels.length;
    final angle = 2 * math.pi / sides;

    for (int level = 1; level <= 3; level++) {
      final r = radius * level / 3;
      final gridPaint = Paint()
        ..color = gridColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      final path = Path();
      for (int i = 0; i < sides; i++) {
        final x = center.dx + r * math.cos(angle * i - math.pi / 2);
        final y = center.dy + r * math.sin(angle * i - math.pi / 2);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    final axisPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (int i = 0; i < sides; i++) {
      final x = center.dx + radius * math.cos(angle * i - math.pi / 2);
      final y = center.dy + radius * math.sin(angle * i - math.pi / 2);
      canvas.drawLine(center, Offset(x, y), axisPaint);
    }

    final fillPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;

    final dataPath = Path();
    final dataPoints = <Offset>[];
    for (int i = 0; i < sides; i++) {
      final r = radius * values[i];
      final x = center.dx + r * math.cos(angle * i - math.pi / 2);
      final y = center.dy + r * math.sin(angle * i - math.pi / 2);
      dataPoints.add(Offset(x, y));
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    final pointPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    for (final point in dataPoints) {
      canvas.drawCircle(point, 3.5, pointPaint);
    }

    for (int i = 0; i < sides; i++) {
      final labelRadius = radius + 24;
      final x = center.dx + labelRadius * math.cos(angle * i - math.pi / 2);
      final y = center.dy + labelRadius * math.sin(angle * i - math.pi / 2);

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: labelColor,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      double offsetX = x - textPainter.width / 2;
      double offsetY = y - textPainter.height / 2;

      if (i == 0) {
        offsetY -= 8;
      } else if (i == 3) {
        offsetY += 8;
      } else if (i == 1 || i == 2) {
        offsetX += 8;
      } else {
        offsetX -= 8;
      }

      textPainter.paint(canvas, Offset(offsetX, offsetY));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.labels != labels ||
        oldDelegate.values != values ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.primaryColor != primaryColor;
  }
}
