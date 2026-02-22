// 語音教練浮動面板元件
//
// 顯示即時語音教練的控制列、對話辨識內容、情緒分析以及結構化建議。
// 錄音時展開為完整面板，未錄音時折疊為精簡控制列。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme_colors.dart';
import '../../core/l10n/tr_extension.dart';
import '../providers/core_providers.dart';
import '../providers/voice_coach_provider.dart';

class VoiceCoachIsland extends ConsumerStatefulWidget {
  const VoiceCoachIsland({super.key});

  @override
  ConsumerState<VoiceCoachIsland> createState() => _VoiceCoachIslandState();
}

class _VoiceCoachIslandState extends ConsumerState<VoiceCoachIsland>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final ScrollController _transcriptScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _transcriptScrollController.dispose();
    super.dispose();
  }

  /// 切換語音教練會話狀態（開始/錄音/停止錄音）
  void _toggleSession() {
    final vcState = ref.read(voiceCoachSessionProvider);
    final notifier = ref.read(voiceCoachSessionProvider.notifier);

    if (vcState.status == VoiceCoachStatus.disconnected ||
        vcState.status == VoiceCoachStatus.error) {
      notifier.startSession();
    } else if (vcState.status == VoiceCoachStatus.connected) {
      if (vcState.isRecording) {
        notifier.stopRecording();
      } else {
        notifier.startRecording();
      }
    }
  }

  /// 結束語音教練會話並關閉面板
  void _endSession() {
    ref.read(voiceCoachSessionProvider.notifier).endSession();
    ref.read(voiceCoachEnabledProvider.notifier).state = false;
  }

  /// 根據目前狀態取得顯示文字
  String _statusText(VoiceCoachState vcState) {
    switch (vcState.status) {
      case VoiceCoachStatus.disconnected:
        return ref.tr('voice_coach_status');
      case VoiceCoachStatus.connecting:
        return ref.tr('vc_connecting');
      case VoiceCoachStatus.connected:
        if (vcState.isRecording) {
          return vcState.userSpeaking
              ? ref.tr('vc_listening')
              : ref.tr('vc_recording');
        }
        return ref.tr('vc_tap_to_record');
      case VoiceCoachStatus.error:
        return vcState.errorMessage ?? 'Error';
    }
  }

  /// 根據目前狀態取得圖示
  IconData _statusIcon(VoiceCoachState vcState) {
    switch (vcState.status) {
      case VoiceCoachStatus.disconnected:
        return LucideIcons.mic;
      case VoiceCoachStatus.connecting:
        return LucideIcons.loader2;
      case VoiceCoachStatus.connected:
        return vcState.isRecording ? LucideIcons.micOff : LucideIcons.mic;
      case VoiceCoachStatus.error:
        return LucideIcons.alertTriangle;
    }
  }

  /// 情緒標籤對應的 emoji
  String _emotionEmoji(String emotion) {
    const map = {
      '開心': '😊',
      '興奮': '🤩',
      '無聊': '😐',
      '緊張': '😰',
      '好奇': '🤔',
      '不耐煩': '😤',
      '放鬆': '😌',
      '害羞': '🙈',
      '中性': '😶',
    };
    return map[emotion] ?? '💬';
  }

  /// 情緒標籤對應的顏色
  Color _emotionColor(String emotion, AppThemeColors c) {
    switch (emotion) {
      case '開心':
      case '興奮':
      case '放鬆':
        return c.success;
      case '無聊':
      case '不耐煩':
        return c.warning;
      case '緊張':
      case '害羞':
        return c.info;
      default:
        return c.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final vcState = ref.watch(voiceCoachSessionProvider);
    final isActive =
        vcState.status == VoiceCoachStatus.connected && vcState.isRecording;
    final hasCoachingData = vcState.inputTranscripts.isNotEmpty ||
        vcState.emotion.isNotEmpty ||
        vcState.coachingSuggestions.isNotEmpty ||
        vcState.suggestions.isNotEmpty;

    // 連線錯誤時 3 秒後自動關閉面板
    ref.listen(voiceCoachSessionProvider, (prev, next) {
      if (next.status == VoiceCoachStatus.error &&
          prev?.status != VoiceCoachStatus.error) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) _endSession();
        });
      }
    });

    // 當有新的辨識內容時自動捲動到底部
    if (vcState.inputTranscripts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_transcriptScrollController.hasClients) {
          _transcriptScrollController.animateTo(
            _transcriptScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 控制列（始終顯示）──
          _buildControlBar(c, vcState, isActive),

          // ── 展開面板（錄音中且有資料時顯示）──
          if (isActive && hasCoachingData) ...[
            const SizedBox(height: 8),
            _buildExpandedPanel(c, vcState),
          ],

          // ── 純文字建議後備顯示（無結構化資料時）──
          if (!hasCoachingData && vcState.suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildFallbackSuggestion(c, vcState),
          ],
        ],
      ),
    );
  }

  /// 建構控制列：圖示 + 狀態文字 + 波形動畫 + 關閉按鈕
  Widget _buildControlBar(
      AppThemeColors c, VoiceCoachState vcState, bool isActive) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        onTap: _toggleSession,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? c.primary.withValues(alpha: 0.15)
                : c.surfaceLight.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            border: Border.all(
              color:
                  isActive ? c.primary.withValues(alpha: 0.4) : c.borderLight,
            ),
          ),
          child: Row(
            children: [
              // 狀態圖示
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      c.primary.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(
                    color: c.primary.withValues(alpha: 0.3),
                  ),
                ),
                child:
                    Icon(_statusIcon(vcState), size: 16, color: c.primary),
              ),
              const SizedBox(width: 12),
              // 標題 + 狀態文字
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.tr('voice_coach_title'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusText(vcState),
                      style: TextStyle(
                        fontSize: 10,
                        color: vcState.status == VoiceCoachStatus.error
                            ? c.warning
                            : c.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // 波形動畫（錄音中時顯示）
              if (isActive)
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(3, (index) {
                        final delay = index * 0.2;
                        final value =
                            (((_animController.value + delay) % 1.0) * 2 - 1)
                                .abs();
                        return Container(
                          width: 2,
                          height: 6 + value * 6,
                          margin: const EdgeInsets.only(left: 2),
                          decoration: BoxDecoration(
                            color: c.primary.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        );
                      }),
                    );
                  },
                ),
              const SizedBox(width: 12),
              // 結束按鈕
              GestureDetector(
                onTap: _endSession,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: c.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.square, size: 10, color: c.primary),
                      const SizedBox(width: 4),
                      Text(
                        ref.tr('vc_end_session'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: c.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 建構展開面板：對話辨識 + 情緒分析 + 建議卡片
  Widget _buildExpandedPanel(AppThemeColors c, VoiceCoachState vcState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: c.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 區塊 A：即時對話辨識 ──
          if (vcState.inputTranscripts.isNotEmpty)
            _buildTranscriptSection(c, vcState),

          // ── 區塊 B：情緒分析 ──
          if (vcState.emotion.isNotEmpty) ...[
            if (vcState.inputTranscripts.isNotEmpty)
              const SizedBox(height: 10),
            _buildEmotionSection(c, vcState),
          ],

          // ── 區塊 C：結構化建議 ──
          if (vcState.coachingSuggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildSuggestionsSection(c, vcState),
          ],
        ],
      ),
    );
  }

  /// 區塊 A：即時對話辨識內容（可捲動）
  Widget _buildTranscriptSection(AppThemeColors c, VoiceCoachState vcState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 區塊標題
        Row(
          children: [
            Icon(LucideIcons.messageSquare, size: 12, color: c.textTertiary),
            const SizedBox(width: 6),
            Text(
              ref.tr('vc_conversation'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: c.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // 可捲動的辨識內容區
        Container(
          constraints: const BoxConstraints(maxHeight: 80),
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
            border: Border.all(color: c.borderLight.withValues(alpha: 0.5)),
          ),
          child: Scrollbar(
            controller: _transcriptScrollController,
            thumbVisibility: true,
            child: ListView.separated(
              controller: _transcriptScrollController,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: vcState.inputTranscripts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                return Text(
                  vcState.inputTranscripts[index],
                  style: TextStyle(
                    fontSize: 11,
                    color: c.textSecondary,
                    height: 1.4,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 區塊 B：情緒分析指標
  Widget _buildEmotionSection(AppThemeColors c, VoiceCoachState vcState) {
    final emotionColor = _emotionColor(vcState.emotion, c);
    final emoji = _emotionEmoji(vcState.emotion);

    return Row(
      children: [
        // 情緒標籤
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: emotionColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                vcState.emotion,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: emotionColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // 情緒說明
        if (vcState.emotionDetail.isNotEmpty)
          Expanded(
            child: Text(
              vcState.emotionDetail,
              style: TextStyle(
                fontSize: 10,
                color: c.textTertiary,
                height: 1.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  /// 區塊 C：結構化建議卡片列表 + 聊天方向
  Widget _buildSuggestionsSection(AppThemeColors c, VoiceCoachState vcState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 區塊標題 + 技巧標籤
        Row(
          children: [
            Icon(LucideIcons.lightbulb, size: 12, color: c.primary),
            const SizedBox(width: 6),
            Text(
              ref.tr('vc_suggestions'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: c.primary,
                letterSpacing: 0.5,
              ),
            ),
            if (vcState.technique.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  vcState.technique,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: c.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        // 建議卡片列表
        ...vcState.coachingSuggestions.map(
          (suggestion) => _buildSuggestionCard(c, suggestion),
        ),
        // 聊天方向建議
        if (vcState.direction.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(LucideIcons.compass, size: 11, color: c.info),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${ref.tr('vc_direction')}：${vcState.direction}',
                  style: TextStyle(
                    fontSize: 10,
                    color: c.info,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// 單一建議卡片（含複製按鈕）
  Widget _buildSuggestionCard(AppThemeColors c, String suggestion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: c.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
          border: Border.all(color: c.primary.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                suggestion,
                style: TextStyle(
                  fontSize: 12,
                  color: c.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _VcCopyButton(text: suggestion, colors: c, tr: ref.tr),
          ],
        ),
      ),
    );
  }

  /// 純文字建議後備顯示（當結構化資料不可用時）
  Widget _buildFallbackSuggestion(AppThemeColors c, VoiceCoachState vcState) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: c.borderLight),
      ),
      child: Text(
        vcState.suggestions.last,
        style: TextStyle(
          fontSize: 12,
          color: c.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }
}

/// 語音教練建議複製按鈕（帶回饋動畫）
class _VcCopyButton extends StatefulWidget {
  final String text;
  final AppThemeColors colors;
  final String Function(String) tr;

  const _VcCopyButton({
    required this.text,
    required this.colors,
    required this.tr,
  });

  @override
  State<_VcCopyButton> createState() => _VcCopyButtonState();
}

class _VcCopyButtonState extends State<_VcCopyButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: widget.text));
        setState(() => _copied = true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _copied = false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: _copied
              ? c.success.withValues(alpha: 0.12)
              : c.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          _copied ? LucideIcons.checkCheck : LucideIcons.copy,
          size: 12,
          color: _copied ? c.success : c.primary,
        ),
      ),
    );
  }
}
