import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme_colors.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/tr_extension.dart';
import '../../../data/models/reply_models.dart';
import '../../providers/camera_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/match_provider.dart';
import '../../providers/reply_provider.dart';

class CoachPage extends ConsumerStatefulWidget {
  const CoachPage({super.key});

  @override
  ConsumerState<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends ConsumerState<CoachPage> {
  final Set<String> _selectedContextKeys = {'coach_ctx_new_match'};
  final _chatTextController = TextEditingController();
  bool _hasResult = false;
  String? _selectedMatchId;

  static const _contextKeys = [
    'coach_ctx_new_match',
    'coach_ctx_dating',
    'coach_ctx_revive',
  ];

  static const _stageMap = {
    'coach_ctx_new_match': 'early',
    'coach_ctx_dating': 'flirting',
    'coach_ctx_revive': 'couple',
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(matchProvider.notifier).loadMatches();
    });
  }

  @override
  void dispose() {
    _chatTextController.dispose();
    super.dispose();
  }

  void _generateStrategy() {
    final image = ref.read(coachImageProvider);
    final chatText = _chatTextController.text.trim();
    if (image == null && chatText.isEmpty) return;

    final stage = _selectedContextKeys.isNotEmpty
        ? _stageMap[_selectedContextKeys.first] ?? 'early'
        : 'early';
    final locale = ref.read(localeProvider);

    ref.read(replyProvider.notifier).analyze(
          screenshot: image,
          chatText: chatText.isNotEmpty ? chatText : null,
          language: locale == AppLocale.zhTW ? 'zh-TW' : 'en',
          relationshipStage: stage,
          userGender: 'male',
          targetGender: 'female',
          matchId: _selectedMatchId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final replyState = ref.watch(replyProvider);
    final result = replyState.valueOrNull;

    // Track whether we got a result to switch to result view
    if (result != null && !_hasResult) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _hasResult = true);
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              ref.tr('coach_title'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Show result view or input view
          if (_hasResult && result != null)
            _buildResultView(c, result, replyState)
          else
            _buildInputView(c, replyState),
        ],
      ),
    );
  }

  // ── Match Selector (inline dropdown) ────────────────────────────────
  Widget _buildMatchSelector(AppThemeColors c) {
    final matchesState = ref.watch(matchProvider);
    final matches = matchesState.valueOrNull ?? [];
    if (matches.isEmpty) return const SizedBox.shrink();

    final selectedName = _selectedMatchId == null
        ? '不指定'
        : matches
            .where((m) => m.matchId == _selectedMatchId)
            .map((m) => m.name)
            .firstOrNull ?? '不指定';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '聊天對象',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: c.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedMatchId != null ? c.primary : c.borderLight,
                  ),
                ),
                child: PopupMenuButton<String?>(
                  onSelected: (value) => setState(() => _selectedMatchId = value),
                  offset: const Offset(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: c.surface,
                  itemBuilder: (_) => [
                    PopupMenuItem<String?>(
                      value: null,
                      child: Text(
                        '不指定',
                        style: TextStyle(
                          fontSize: 13,
                          color: _selectedMatchId == null
                              ? c.primary
                              : c.textPrimary,
                          fontWeight: _selectedMatchId == null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    ...matches.map((m) => PopupMenuItem<String?>(
                          value: m.matchId,
                          child: Text(
                            m.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: _selectedMatchId == m.matchId
                                  ? c.primary
                                  : c.textPrimary,
                              fontWeight: _selectedMatchId == m.matchId
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        )),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _selectedMatchId != null
                              ? c.primary
                              : c.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        LucideIcons.chevronDown,
                        size: 14,
                        color: _selectedMatchId != null
                            ? c.primary
                            : c.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Input View ──────────────────────────────────────────────────────
  Widget _buildInputView(
      AppThemeColors c, AsyncValue<ReplyResult?> replyState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMatchSelector(c),
        _buildUploadArea(c),
        const SizedBox(height: 16),
        // Chat text input
        Container(
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            border: Border.all(color: c.borderLight),
          ),
          child: TextField(
            controller: _chatTextController,
            maxLines: 4,
            minLines: 2,
            style: TextStyle(fontSize: 13, color: c.textPrimary),
            decoration: InputDecoration(
              hintText: ref.tr('coach_text_hint'),
              hintStyle: TextStyle(fontSize: 13, color: c.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildChipSection(ref.tr('coach_context_label'), _contextKeys,
            _selectedContextKeys, c),
        const SizedBox(height: 32),
        _buildGenerateButton(c, replyState),
        if (replyState is AsyncLoading) ...[
          const SizedBox(height: 20),
          _CoachLoadingTips(colors: c, tr: ref.tr),
        ],
      ],
    );
  }

  // ── Result View (redesigned) ────────────────────────────────────────
  Widget _buildResultView(AppThemeColors c, ReplyResult result,
      AsyncValue<ReplyResult?> replyState) {
    final ea = result.emotionAnalysis;
    final isLoading = replyState is AsyncLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Collapsed screenshot thumbnail + emotion tags ──
        _buildResultHeader(c, ea),
        const SizedBox(height: 20),

        // ── Horizontal swipe reply cards (core UX) ──
        if (result.replyOptions.isNotEmpty) ...[
          _buildReplyCarousel(c, result.replyOptions),
          const SizedBox(height: 20),
        ],

        // ── Stage coaching bar ──
        if (result.stageCoaching != null)
          _buildStageBar(c, result.stageCoaching!),

        // ── Collapsible Coach Notes (Deep Insights drawer) ──
        if (result.coachPanel != null) ...[
          const SizedBox(height: 16),
          _buildCollapsibleCoachNotes(c, result.coachPanel!),
        ],

        // ── Regenerate / Back buttons ──
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _hasResult = false;
                  ref.read(replyProvider.notifier).reset();
                }),
                icon: Icon(LucideIcons.arrowLeft,
                    size: 16, color: c.textSecondary),
                label: Text(ref.tr('coach_title'),
                    style: TextStyle(color: c.textSecondary, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.borderLight),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppColors.radiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: isLoading ? null : _generateStrategy,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.refreshCw,
                        size: 16, color: Colors.white),
                label: Text(ref.tr('coach_regenerate'),
                    style: const TextStyle(fontSize: 13)),
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppColors.radiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Result Header: thumbnail + emotion tags ─────────────────────────
  Widget _buildResultHeader(AppThemeColors c, EmotionAnalysis ea) {
    final image = ref.watch(coachImageProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          // Collapsed screenshot thumbnail
          if (image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
              child: Image.file(File(image.path),
                  width: 48, height: 48, fit: BoxFit.cover),
            ),
          if (image != null) const SizedBox(width: 12),
          // Emotion tags
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ea.detectedEmotion,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _emotionTag(
                        c, '${(ea.confidence * 100).toInt()}%', c.primary),
                    ..._extractKeywords(ea.subtext)
                        .take(3)
                        .map((kw) => _emotionTag(c, kw, c.textTertiary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emotionTag(AppThemeColors c, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }

  List<String> _extractKeywords(String subtext) {
    final words = subtext
        .replaceAll(RegExp(r'[,;.!?，；。！？]'), '|')
        .split('|')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length <= 20)
        .toList();
    return words;
  }

  // ── Horizontal Swipe Reply Carousel ─────────────────────────────────
  Widget _buildReplyCarousel(AppThemeColors c, List<ReplyOption> options) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.88),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _buildReplyCard(c, option, index),
          );
        },
      ),
    );
  }

  Widget _buildReplyCard(AppThemeColors c, ReplyOption option, int index) {
    final intentIcon = _getIntentIcon(option.intent);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusXl),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: c.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intent icon + technique tag row
          Row(
            children: [
              Text(intentIcon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  option.intent,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (option.frameworkTechnique.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    option.frameworkTechnique,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: c.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Reply text (the "golden line")
          Expanded(
            child: Text(
              option.text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Strategy + copy button
          Row(
            children: [
              Expanded(
                child: Text(
                  option.strategy,
                  style: TextStyle(
                      fontSize: 10, color: c.textTertiary, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _CopyButton(text: option.text, colors: c, tr: ref.tr),
            ],
          ),
        ],
      ),
    );
  }

  String _getIntentIcon(String intent) {
    final lower = intent.toLowerCase();
    if (lower.contains('flirt') || lower.contains('mystery') ||
        lower.contains('tease')) {
      return '\u{1F525}'; // 🔥
    }
    if (lower.contains('humor') || lower.contains('funny') ||
        lower.contains('joke')) {
      return '\u{1F602}'; // 😂
    }
    if (lower.contains('invite') || lower.contains('meet') ||
        lower.contains('date')) {
      return '\u{1F91D}'; // 🤝
    }
    if (lower.contains('rapport') || lower.contains('engage') ||
        lower.contains('connect')) {
      return '\u{1F4AC}'; // 💬
    }
    if (lower.contains('friend') || lower.contains('ground') ||
        lower.contains('stable')) {
      return '\u{2728}'; // ✨
    }
    return '\u{1F497}'; // 💗
  }

  // ── Stage coaching bar ──────────────────────────────────────────────
  Widget _buildStageBar(AppThemeColors c, StageCoaching stage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.textTertiary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: c.textTertiary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.compass, size: 14, color: c.textTertiary),
          const SizedBox(width: 8),
          Text(
            '${ref.tr('coach_stage')}: ${stage.currentStage.toUpperCase()}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              stage.techniqueUsed,
              style: TextStyle(
                  fontSize: 11, color: c.textTertiary.withValues(alpha: 0.8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Collapsible Coach Notes ─────────────────────────────────────────
  Widget _buildCollapsibleCoachNotes(AppThemeColors c, CoachPanel panel) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          side: BorderSide(color: c.borderLight),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          side: BorderSide(color: c.border),
        ),
        collapsedBackgroundColor: c.surface,
        backgroundColor: c.surface,
        leading:
            Icon(LucideIcons.graduationCap, size: 16, color: c.primary),
        title: Text(
          ref.tr('coach_deep_insights'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: c.textPrimary,
          ),
        ),
        children: [
          if (panel.perspectiveNote.isNotEmpty) ...[
            Text(
              panel.perspectiveNote,
              style: TextStyle(
                  fontSize: 12, color: c.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 12),
          ],
          if (panel.dos.isNotEmpty) ...[
            _buildDoDontSection(c, ref.tr('coach_dos'), panel.dos,
                LucideIcons.checkCircle2, c.primary),
            const SizedBox(height: 8),
          ],
          if (panel.donts.isNotEmpty)
            _buildDoDontSection(c, ref.tr('coach_donts'), panel.donts,
                LucideIcons.xCircle, c.primary),
        ],
      ),
    );
  }

  Widget _buildDoDontSection(AppThemeColors c, String title,
      List<String> items, IconData icon, Color iconColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.textTertiary,
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 13, color: iconColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(item,
                        style: TextStyle(
                            fontSize: 12,
                            color: c.textSecondary,
                            height: 1.3)),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ── Upload Area ─────────────────────────────────────────────────────
  Widget _buildUploadArea(AppThemeColors c) {
    final image = ref.watch(coachImageProvider);
    if (image != null) {
      return _buildImagePreview(c, image);
    }
    return GestureDetector(
      onTap: () => _pickImage(context),
      child: Container(
        width: double.infinity,
        height: 192,
        decoration: BoxDecoration(
          color: c.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppColors.radius2Xl),
          border: Border.all(color: c.borderLight),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.overlayLight,
              ),
              child: Icon(LucideIcons.imagePlus,
                  size: 24, color: c.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              ref.tr('coach_upload'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ref.tr('coach_upload_hint'),
              style: TextStyle(fontSize: 12, color: c.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(AppThemeColors c, XFile image) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppColors.radius2Xl),
      child: Stack(
        children: [
          Image.file(File(image.path),
              width: double.infinity, height: 192, fit: BoxFit.cover),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () =>
                  ref.read(coachImageProvider.notifier).state = null,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: const Icon(LucideIcons.x,
                    size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final c = context.colors;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppColors.radiusXl)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(LucideIcons.camera, color: c.textPrimary),
              title: Text(ref.tr('camera'),
                  style: TextStyle(color: c.textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(LucideIcons.image, color: c.textPrimary),
              title: Text(ref.tr('gallery'),
                  style: TextStyle(color: c.textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picker = ref.read(imagePickerProvider);
    final img = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (img != null) {
      ref.read(coachImageProvider.notifier).state = img;
    }
  }

  Widget _buildChipSection(String title, List<String> optionKeys,
      Set<String> selected, AppThemeColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: c.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: optionKeys.map((key) {
              final isSelected = selected.contains(key);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selected.clear();
                    selected.add(key);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? c.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? c.primary : c.borderLight,
                    ),
                  ),
                  child: Text(
                    ref.tr(key),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? c.primary : c.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(
      AppThemeColors c, AsyncValue<ReplyResult?> replyState) {
    final isLoading = replyState is AsyncLoading;

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c.primary, c.primaryDark]),
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: [
          BoxShadow(
            color: c.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          onTap: isLoading ? null : _generateStrategy,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.wand2,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        ref.tr('coach_generate'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Copy Button (stateful for feedback) ─────────────────────────────
class _CopyButton extends StatefulWidget {
  final String text;
  final AppThemeColors colors;
  final String Function(String) tr;

  const _CopyButton(
      {required this.text, required this.colors, required this.tr});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _copied
              ? c.textTertiary.withValues(alpha: 0.12)
              : c.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? LucideIcons.checkCheck : LucideIcons.copy,
              size: 12,
              color: _copied ? c.textTertiary : c.primary,
            ),
            const SizedBox(width: 4),
            Text(
              _copied
                  ? widget.tr('coach_copied')
                  : widget.tr('coach_copy'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _copied ? c.textTertiary : c.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading Tips for Coach (technique education) ─────────────────────
class _CoachLoadingTips extends StatefulWidget {
  final AppThemeColors colors;
  final String Function(String) tr;

  const _CoachLoadingTips({required this.colors, required this.tr});

  @override
  State<_CoachLoadingTips> createState() => _CoachLoadingTipsState();
}

class _CoachLoadingTipsState extends State<_CoachLoadingTips> {
  int _tipIndex = 0;
  static const _tipKeys = [
    'coach_tip_1',
    'coach_tip_2',
    'coach_tip_3',
    'coach_tip_4',
    'coach_tip_5',
  ];

  @override
  void initState() {
    super.initState();
    _tipIndex = Random().nextInt(_tipKeys.length);
    _rotateTip();
  }

  void _rotateTip() async {
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      setState(() => _tipIndex = (_tipIndex + 1) % _tipKeys.length);
      _rotateTip();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: c.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: c.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.tr('coach_analyzing'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.primary,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    widget.tr(_tipKeys[_tipIndex]),
                    key: ValueKey(_tipIndex),
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
