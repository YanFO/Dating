import 'dart:math';
import 'dart:typed_data';

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
import '../../../data/models/icebreaker_models.dart';
import '../../../data/models/match_models.dart';
import '../../providers/camera_provider.dart';
import '../../providers/icebreaker_provider.dart';
import '../../providers/match_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _textController = TextEditingController();
  bool _hasResult = false;
  String? _expandedMatchId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(matchProvider.notifier).loadMatches();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitAnalysis() {
    final text = _textController.text.trim();
    final image = ref.read(icebreakerImageProvider);
    if (text.isEmpty && image == null) return;

    final locale = ref.read(localeProvider);
    ref.read(icebreakerProvider.notifier).analyze(
          description: text.isNotEmpty ? text : null,
          image: image,
          language: locale == AppLocale.zhTW ? 'zh-TW' : 'en',
        );
  }

  void _submitImageOnly() {
    // When scanning with camera, only send the image, not any lingering text
    final image = ref.read(icebreakerImageProvider);
    if (image == null) return;

    final locale = ref.read(localeProvider);
    ref.read(icebreakerProvider.notifier).analyze(
          description: null,
          image: image,
          language: locale == AppLocale.zhTW ? 'zh-TW' : 'en',
        );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final icebreakerState = ref.watch(icebreakerProvider);
    final result = icebreakerState.valueOrNull;
    final isLoading = icebreakerState is AsyncLoading;

    if (result != null && !_hasResult) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _hasResult = true);
      });
    }

    // Full immersive scanning view when loading
    if (isLoading) {
      final image = ref.watch(icebreakerImageProvider);
      return _ImmersiveScanView(colors: c, image: image, tr: ref.tr);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          if (_hasResult && result != null)
            _buildResultView(c, result)
          else
            _buildIcebreakerSection(c),
          const SizedBox(height: 32),
          _buildPipelineSection(c),
        ],
      ),
    );
  }

  // ── Input Section ───────────────────────────────────────────────────
  Widget _buildIcebreakerSection(AppThemeColors c) {
    final image = ref.watch(icebreakerImageProvider);
    final hasText = _textController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppColors.radius2Xl),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              ref.tr('icebreaker_title'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Scan button + image preview side by side if image exists
          if (image != null)
            _buildCompactScanRow(c, image)
          else
            _ScanButton(onCapture: _submitImageOnly),
          const SizedBox(height: 24),
          Text(
            ref.tr('icebreaker_hint'),
            style: TextStyle(fontSize: 12, color: c.textTertiary),
          ),
          const SizedBox(height: 16),
          // Integrated input bar with send button that lights up
          Container(
            decoration: BoxDecoration(
              color: c.background,
              borderRadius: BorderRadius.circular(AppColors.radiusLg),
              border: Border.all(color: c.borderLight),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(LucideIcons.pencil, size: 18, color: c.textTertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(fontSize: 12, color: c.textPrimary),
                    decoration: InputDecoration(
                      hintText: ref.tr('icebreaker_input_hint'),
                      hintStyle:
                          TextStyle(fontSize: 12, color: c.textMuted),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submitAnalysis(),
                  ),
                ),
                GestureDetector(
                  onTap: _submitAnalysis,
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (hasText || image != null)
                          ? c.primary
                          : c.overlayLight,
                    ),
                    child: Icon(
                      LucideIcons.arrowRight,
                      size: 16,
                      color: (hasText || image != null)
                          ? Colors.white
                          : c.textSecondary,
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

  // ── Compact scan row: small scan button + image thumbnail ───────────
  Widget _buildCompactScanRow(AppThemeColors c, XFile image) {
    return Row(
      children: [
        // Small scan button to retake (camera or gallery)
        GestureDetector(
          onTap: () async {
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
              ref.read(icebreakerImageProvider.notifier).state = img;
              _submitImageOnly();
            }
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.primary, c.primaryDark],
              ),
            ),
            child: const Icon(LucideIcons.scan, size: 24, color: Colors.white),
          ),
        ),
        const SizedBox(width: 16),
        // Image thumbnail — shows full image with contain
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            child: Stack(
              children: [
                Container(
                  height: 120,
                  color: c.background,
                  child: Image.network(
                    image.path,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => ref
                        .read(icebreakerImageProvider.notifier)
                        .state = null,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                      child: const Icon(LucideIcons.x,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Result View: horizontal card carousel ───────────────────────────
  Widget _buildResultView(AppThemeColors c, IcebreakerResult result) {
    final cards = <_CardData>[];

    final accent = c.primary;

    // Card 1: Scene Analysis
    if (result.sceneAnalysis.isNotEmpty) {
      cards.add(_CardData(
        icon: LucideIcons.eye,
        title: ref.tr('icebreaker_scene'),
        color: accent,
        child: _buildSceneCard(c, result),
      ));
    }

    // Card 2+: Opening Lines (one per card)
    for (final line in result.openingLines) {
      cards.add(_CardData(
        icon: LucideIcons.messageCircle,
        title: ref.tr('icebreaker_lines'),
        color: accent,
        child: _buildOpeningLineCard(c, line),
      ));
    }

    // Card: Observation Hooks + Topic Suggestions
    if (result.observationHooks.isNotEmpty ||
        result.topicSuggestions.isNotEmpty) {
      cards.add(_CardData(
        icon: LucideIcons.lightbulb,
        title: ref.tr('icebreaker_hooks'),
        color: accent,
        child: _buildHooksAndTopicsCard(c, result),
      ));
    }

    // Card: Behavior Tips
    if (result.behaviorTips.isNotEmpty) {
      cards.add(_CardData(
        icon: LucideIcons.shield,
        title: ref.tr('icebreaker_tips'),
        color: accent,
        child: _buildBehaviorTipsCard(c, result.behaviorTips),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with back button
        Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() => _hasResult = false);
                ref.read(icebreakerProvider.notifier).reset();
                ref.read(icebreakerImageProvider.notifier).state = null;
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.surface,
                  border: Border.all(color: c.borderLight),
                ),
                child: Icon(LucideIcons.arrowLeft,
                    size: 16, color: c.textSecondary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              ref.tr('icebreaker_title'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        // Readiness badge
        if (result.approachReadiness.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.zap, size: 14, color: c.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    result.approachReadiness,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: c.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        // Card carousel
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.9),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius:
                        BorderRadius.circular(AppColors.radiusXl),
                    border: Border.all(color: c.border),
                    boxShadow: [
                      BoxShadow(
                        color: card.color.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          children: [
                            Icon(card.icon, size: 16, color: card.color),
                            const SizedBox(width: 8),
                            Text(
                              card.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: card.color,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${index + 1}/${cards.length}',
                              style: TextStyle(
                                  fontSize: 11, color: c.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: card.child,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        // Restart button — go back to input
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() => _hasResult = false);
              ref.read(icebreakerProvider.notifier).reset();
              ref.read(icebreakerImageProvider.notifier).state = null;
              _textController.clear();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: c.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.rotateCcw, size: 16, color: c.primary),
                  const SizedBox(width: 8),
                  Text(
                    ref.tr('icebreaker_new_scan'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: c.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Card builders ───────────────────────────────────────────────────
  Widget _buildSceneCard(AppThemeColors c, IcebreakerResult result) {
    return SingleChildScrollView(
      child: Text(
        result.sceneAnalysis,
        style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.6),
      ),
    );
  }

  Widget _buildOpeningLineCard(AppThemeColors c, OpeningLine line) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              line.text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                line.tone.replaceAll('_', ' '),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: c.primary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(line.confidence * 100).toInt()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: c.textTertiary,
              ),
            ),
            const Spacer(),
            _IceCopyButton(text: line.text, colors: c),
          ],
        ),
        if (line.basedOn.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            line.basedOn,
            style: TextStyle(fontSize: 11, color: c.textTertiary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildHooksAndTopicsCard(
      AppThemeColors c, IcebreakerResult result) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.observationHooks.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.observationHooks.map((hook) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: c.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(hook.detail,
                          style: TextStyle(
                              fontSize: 12, color: c.textPrimary)),
                      Text(hook.hookType,
                          style: TextStyle(
                              fontSize: 10, color: c.textTertiary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          if (result.topicSuggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              ref.tr('icebreaker_topics'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.textTertiary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            ...result.topicSuggestions.map((ts) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.messageSquare,
                          size: 13, color: c.textTertiary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ts.topic,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: c.textPrimary)),
                            Text(ts.context,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: c.textTertiary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildBehaviorTipsCard(AppThemeColors c, List<String> tips) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tips
            .map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
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
                                color: c.textSecondary,
                                height: 1.4)),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ── Pipeline Section ────────────────────────────────────────────────
  Widget _buildPipelineSection(AppThemeColors c) {
    final matchesState = ref.watch(matchProvider);
    final memoryState = ref.watch(memoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            ref.tr('pipeline_title'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: c.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: matchesState.when(
            data: (matches) => ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildAddLeadCard(c),
                ),
                ...matches.map((m) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildMatchCard(
                          c, m.name, m.contextTag ?? '', m.matchId),
                    )),
              ],
            ),
            loading: () => ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [_buildAddLeadCard(c)],
            ),
            error: (_, __) => ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [_buildAddLeadCard(c)],
            ),
          ),
        ),
        // 展開式 Memory 面板
        if (_expandedMatchId != null)
          _buildExpandedMemoryPanel(c, matchesState, memoryState),
      ],
    );
  }

  Widget _buildMatchCard(
      AppThemeColors c, String name, String tag, String matchId) {
    final isExpanded = _expandedMatchId == matchId;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_expandedMatchId == matchId) {
            _expandedMatchId = null;
            ref.read(memoryProvider.notifier).clear();
          } else {
            _expandedMatchId = matchId;
            ref.read(memoryProvider.notifier).loadMemory(matchId);
          }
        });
      },
      onLongPress: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: c.surface,
            title: Text('Delete $name?',
                style: TextStyle(color: c.textPrimary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: TextStyle(color: c.textSecondary)),
              ),
              TextButton(
                onPressed: () {
                  ref.read(matchProvider.notifier).deleteMatch(matchId);
                  Navigator.pop(ctx);
                },
                child: Text('Delete', style: TextStyle(color: c.primary)),
              ),
            ],
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 140,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 24),
            decoration: BoxDecoration(
              color: isExpanded ? c.primary.withValues(alpha: 0.05) : c.surface,
              borderRadius: BorderRadius.circular(AppColors.radius2Xl),
              border: Border.all(
                color: isExpanded ? c.primary : c.border,
                width: isExpanded ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.muted,
                    border: Border.all(color: c.borderLight),
                  ),
                  child: Icon(LucideIcons.user,
                      size: 20, color: c.textTertiary),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                if (tag.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: c.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(fontSize: 10, color: c.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Delete button – positioned top-right
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: c.surface,
                    title: Text('刪除 $name？',
                        style: TextStyle(color: c.textPrimary)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('取消',
                            style: TextStyle(color: c.textSecondary)),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(matchProvider.notifier).deleteMatch(matchId);
                          Navigator.pop(ctx);
                          if (_expandedMatchId == matchId) {
                            setState(() => _expandedMatchId = null);
                          }
                        },
                        child: Text('刪除',
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.muted,
                  border: Border.all(color: c.border),
                ),
                child: Icon(LucideIcons.x, size: 12, color: c.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddLeadCard(AppThemeColors c) {
    return GestureDetector(
      onTap: () => _showAddMatchDialog(c),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppColors.radius2Xl),
          border: Border.all(color: c.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primary.withValues(alpha: 0.15),
              ),
              child: Icon(LucideIcons.plusCircle,
                  size: 20, color: c.primary),
            ),
            const SizedBox(height: 8),
            Text(
              ref.tr('pipeline_add'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: c.primary),
            ),
          ],
        ),
      ),
    );
  }

  // ── Expanded Memory Panel ───────────────────────────────────────────
  Widget _buildExpandedMemoryPanel(
    AppThemeColors c,
    AsyncValue<List<MatchRecord>> matchesState,
    AsyncValue<MemoryProfile?> memoryState,
  ) {
    final matchName = matchesState.valueOrNull
            ?.where((m) => m.matchId == _expandedMatchId)
            .firstOrNull
            ?.name ??
        '';

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppColors.radius2Xl),
          border: Border.all(color: c.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.brain, size: 18, color: c.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$matchName Memory',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _expandedMatchId = null;
                    ref.read(memoryProvider.notifier).clear();
                  }),
                  child: Icon(LucideIcons.x, size: 18, color: c.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            memoryState.when(
              data: (memory) {
                if (memory == null || memory.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        '尚無記憶資料，上傳聊天紀錄後將自動擷取',
                        style: TextStyle(
                            fontSize: 12, color: c.textMuted),
                      ),
                    ),
                  );
                }
                return _buildMemoryContent(c, memory);
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('Error: $e',
                      style: TextStyle(fontSize: 12, color: c.textMuted)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryContent(AppThemeColors c, MemoryProfile memory) {
    final sections = <_MemorySectionData>[];

    // 1. 基本資訊
    final basics = <_MemoryItem>[];
    if (memory.birthday != null) {
      basics.add(_MemoryItem(memory.birthday!, '生日'));
    }
    if (memory.mbtiOrZodiac != null) {
      basics.add(_MemoryItem(memory.mbtiOrZodiac!, '人格'));
    }
    for (final a in memory.anniversaries) {
      if (a is Map) {
        basics.add(_MemoryItem('${a['date'] ?? ''}', a['label'] ?? '紀念日'));
      }
    }
    for (final r in memory.routine) {
      basics.add(_MemoryItem(r, '作息'));
    }
    if (basics.isNotEmpty) {
      sections.add(_MemorySectionData('基本資訊', LucideIcons.cake, basics));
    }

    // 2. 飲食偏好
    final diet = <_MemoryItem>[
      ...memory.favoriteFood.map((e) => _MemoryItem(e, '喜歡')),
      ...memory.favoriteRestaurant.map((e) => _MemoryItem(e, '愛店')),
      ...memory.dislikedFood.map((e) => _MemoryItem(e, '不吃', isNegative: true)),
      ...memory.dietaryRestrictions.map((e) => _MemoryItem(e, '禁忌', isNegative: true)),
      ...memory.beverageCustomization.map((e) => _MemoryItem(e, '飲料')),
    ];
    if (diet.isNotEmpty) {
      sections.add(_MemorySectionData('飲食偏好', LucideIcons.utensils, diet));
    }

    // 3. 地點與休閒
    final leisure = <_MemoryItem>[
      ...memory.favoritePlaces.map((e) => _MemoryItem(e, '地點')),
      ...memory.travelWishlist.map((e) => _MemoryItem(e, '想去')),
      ...memory.hobbies.map((e) => _MemoryItem(e, '嗜好')),
      ...memory.entertainmentTastes.map((e) => _MemoryItem(e, '品味')),
    ];
    if (leisure.isNotEmpty) {
      sections.add(_MemorySectionData('休閒娛樂', LucideIcons.mapPin, leisure));
    }

    // 4. 情感地雷
    final emotional = <_MemoryItem>[
      ...memory.landmines.map((e) => _MemoryItem(e, '地雷', isNegative: true)),
      ...memory.petPeeves.map((e) => _MemoryItem(e, '煩躁', isNegative: true)),
      ...memory.soothingMethods.map((e) => _MemoryItem(e, '安撫')),
      ...memory.loveLanguages.map((e) => _MemoryItem(e, '愛之語')),
    ];
    if (emotional.isNotEmpty) {
      sections.add(_MemorySectionData('情感地雷', LucideIcons.shield, emotional));
    }

    // 5. 送禮
    final gifting = <_MemoryItem>[
      ...memory.wishlist.map((e) => _MemoryItem(e, '想要')),
      ...memory.favoriteBrands.map((e) => _MemoryItem(e, '品牌')),
      ...memory.aestheticPreference.map((e) => _MemoryItem(e, '風格')),
    ];
    if (gifting.isNotEmpty) {
      sections.add(_MemorySectionData('送禮偏好', LucideIcons.gift, gifting));
    }

    // 6. 其他
    if (memory.otherNotes.isNotEmpty) {
      sections.add(_MemorySectionData(
          '其他備註', LucideIcons.stickyNote,
          memory.otherNotes.map((e) => _MemoryItem(e, '備註')).toList()));
    }

    return Column(
      children: sections.map((s) => _MemoryCollapsibleSection(
        colors: c,
        title: s.title,
        icon: s.icon,
        items: s.items,
        itemCount: s.items.length,
      )).toList(),
    );
  }

  void _showAddMatchDialog(AppThemeColors c) {
    final nameController = TextEditingController();
    final tagController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(ref.tr('pipeline_add').replaceAll('\n', ' '),
            style: TextStyle(color: c.textPrimary, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Name',
                hintStyle: TextStyle(color: c.textMuted),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tagController,
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Context (optional)',
                hintStyle: TextStyle(color: c.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              ref.read(matchProvider.notifier).createMatch(
                    name,
                    contextTag: tagController.text.trim().isNotEmpty
                        ? tagController.text.trim()
                        : null,
                  );
              Navigator.pop(ctx);
            },
            child: Text('Add', style: TextStyle(color: c.primary)),
          ),
        ],
      ),
    );
  }
}

// ── Memory Section Data ──────────────────────────────────────────────
class _MemoryItem {
  final String value;
  final String label;
  final bool isNegative;
  const _MemoryItem(this.value, this.label, {this.isNegative = false});
}

class _MemorySectionData {
  final String title;
  final IconData icon;
  final List<_MemoryItem> items;
  const _MemorySectionData(this.title, this.icon, this.items);
}

// ── Collapsible Memory Section ──────────────────────────────────────
class _MemoryCollapsibleSection extends StatefulWidget {
  final AppThemeColors colors;
  final String title;
  final IconData icon;
  final List<_MemoryItem> items;
  final int itemCount;

  const _MemoryCollapsibleSection({
    required this.colors,
    required this.title,
    required this.icon,
    required this.items,
    required this.itemCount,
  });

  @override
  State<_MemoryCollapsibleSection> createState() =>
      _MemoryCollapsibleSectionState();
}

class _MemoryCollapsibleSectionState
    extends State<_MemoryCollapsibleSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Column(
      children: [
        // Section header (tappable)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(widget.icon, size: 14, color: c.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.itemCount}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _expanded ? 0.0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(LucideIcons.chevronDown,
                      size: 16, color: c.textTertiary),
                ),
              ],
            ),
          ),
        ),
        // Collapsible content
        AnimatedCrossFade(
          firstChild: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.isNegative
                        ? c.textTertiary.withValues(alpha: 0.08)
                        : c.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: item.isNegative
                          ? c.textTertiary.withValues(alpha: 0.15)
                          : c.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: item.isNegative
                              ? c.textTertiary
                              : c.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item.value,
                          style: TextStyle(
                            fontSize: 11,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
        Divider(color: c.border, height: 1),
      ],
    );
  }
}

// ── Scan Button ─────────────────────────────────────────────────────
class _ScanButton extends ConsumerStatefulWidget {
  final VoidCallback onCapture;

  const _ScanButton({required this.onCapture});

  @override
  ConsumerState<_ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends ConsumerState<_ScanButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image != null) {
      ref.read(icebreakerImageProvider.notifier).state = image;
      widget.onCapture();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: _pickImage,
      child: SizedBox(
        width: 100,
        height: 100,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + _pulseController.value * 0.05;
                final opacity =
                    0.1 + (1 - _pulseController.value) * 0.2;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.primary.withValues(alpha: opacity),
                    ),
                  ),
                );
              },
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.primary, c.primaryDark],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.3),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: const Icon(LucideIcons.scan,
                  size: 40, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Immersive Scan View (full-screen scanning experience) ────────────
class _ImmersiveScanView extends StatefulWidget {
  final AppThemeColors colors;
  final XFile? image;
  final String Function(String) tr;

  const _ImmersiveScanView({
    required this.colors,
    required this.image,
    required this.tr,
  });

  @override
  State<_ImmersiveScanView> createState() => _ImmersiveScanViewState();
}

class _ImmersiveScanViewState extends State<_ImmersiveScanView>
    with TickerProviderStateMixin {
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  int _tipIndex = 0;
  int _phaseIndex = 0;
  Uint8List? _imageBytes;

  static const _tipKeys = [
    'icebreaker_tip_1',
    'icebreaker_tip_2',
    'icebreaker_tip_3',
    'icebreaker_tip_4',
    'icebreaker_tip_5',
  ];

  static const _phaseKeys = [
    'scan_phase_detect',
    'scan_phase_context',
    'scan_phase_strategy',
    'scan_phase_generate',
  ];

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _tipIndex = Random().nextInt(_tipKeys.length);
    _rotateTip();
    _rotatePhase();
    _loadImageBytes();
  }

  Future<void> _loadImageBytes() async {
    if (widget.image == null) return;
    final bytes = await widget.image!.readAsBytes();
    if (mounted) setState(() => _imageBytes = bytes);
  }

  void _rotateTip() async {
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      setState(() => _tipIndex = (_tipIndex + 1) % _tipKeys.length);
      _rotateTip();
    }
  }

  void _rotatePhase() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted && _phaseIndex < _phaseKeys.length - 1) {
      setState(() => _phaseIndex++);
      _rotatePhase();
    }
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Header
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.tr('icebreaker_title'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Image with scan line overlay
          if (widget.image != null) _buildScanImageArea(c),
          if (widget.image == null) _buildTextScanArea(c),
          const SizedBox(height: 24),
          // Progress phases
          _buildProgressPhases(c),
          const SizedBox(height: 24),
          // Glassmorphism tip card
          _buildTipCard(c),
        ],
      ),
    );
  }

  Widget _buildImageForScan({
    required double width,
    BoxFit fit = BoxFit.contain,
    Color? color,
    BlendMode? colorBlendMode,
  }) {
    if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        width: width,
        fit: fit,
        color: color,
        colorBlendMode: colorBlendMode,
      );
    }
    // Fallback while bytes load
    return Image.network(
      widget.image!.path,
      width: width,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
    );
  }

  Widget _buildScanImageArea(AppThemeColors c) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppColors.radiusXl),
      child: Container(
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            // Image – non-positioned, drives Stack size
            _buildImageForScan(
              width: double.infinity,
              fit: BoxFit.contain,
              color: Colors.black.withValues(alpha: 0.2),
              colorBlendMode: BlendMode.darken,
            ),
            // Scan line animation
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _scanLineController,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment(0, -1 + 2 * _scanLineController.value),
                    child: child,
                  );
                },
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        c.primary.withValues(alpha: 0.0),
                        c.primary.withValues(alpha: 0.9),
                        c.primary,
                        c.primary.withValues(alpha: 0.9),
                        c.primary.withValues(alpha: 0.0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c.primary.withValues(alpha: 0.6),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Corner brackets
            ..._buildCornerBrackets(c),
            // "Scanning" badge
            Positioned(
              bottom: 12,
              left: 12,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final opacity = 0.7 + _pulseController.value * 0.3;
                  return Opacity(opacity: opacity, child: child);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: c.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: c.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.tr('icebreaker_analyzing'),
                        style: TextStyle(
                            fontSize: 11,
                            color: c.primary,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextScanArea(AppThemeColors c) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusXl),
        border: Border.all(color: c.primary.withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          // Scan line
          AnimatedBuilder(
            animation: _scanLineController,
            builder: (context, child) {
              return Positioned(
                top: _scanLineController.value * 116,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        c.primary.withValues(alpha: 0.0),
                        c.primary.withValues(alpha: 0.7),
                        c.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.tr('icebreaker_analyzing'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerBrackets(AppThemeColors c) {
    final color = c.primary.withValues(alpha: 0.7);
    const size = 24.0;
    const thickness = 2.5;
    return [
      // Top-left
      Positioned(
        top: 8,
        left: 8,
        child: SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: color, width: thickness),
                left: BorderSide(color: color, width: thickness),
              ),
            ),
          ),
        ),
      ),
      // Top-right
      Positioned(
        top: 8,
        right: 8,
        child: SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: color, width: thickness),
                right: BorderSide(color: color, width: thickness),
              ),
            ),
          ),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: 8,
        left: 8,
        child: SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color, width: thickness),
                left: BorderSide(color: color, width: thickness),
              ),
            ),
          ),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: 8,
        right: 8,
        child: SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color, width: thickness),
                right: BorderSide(color: color, width: thickness),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildProgressPhases(AppThemeColors c) {
    return Row(
      children: List.generate(_phaseKeys.length, (i) {
        final isActive = i <= _phaseIndex;
        final isCurrent = i == _phaseIndex;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isActive
                            ? c.primary
                            : c.borderLight,
                      ),
                    ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isCurrent ? 10 : 8,
                    height: isCurrent ? 10 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? c.primary : c.borderLight,
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: c.primary.withValues(alpha: 0.5),
                                blurRadius: 8,
                              )
                            ]
                          : null,
                    ),
                  ),
                  if (i < _phaseKeys.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i < _phaseIndex
                            ? c.primary
                            : c.borderLight,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  widget.tr(_phaseKeys[i]),
                  key: ValueKey('${_phaseKeys[i]}_$isActive'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? c.primary : c.textMuted,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTipCard(AppThemeColors c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: c.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.lightbulb, size: 16, color: c.primary),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                widget.tr(_tipKeys[_tipIndex]),
                key: ValueKey(_tipIndex),
                style: TextStyle(
                  fontSize: 12,
                  color: c.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Copy Button ─────────────────────────────────────────────────────
class _IceCopyButton extends StatefulWidget {
  final String text;
  final AppThemeColors colors;

  const _IceCopyButton({required this.text, required this.colors});

  @override
  State<_IceCopyButton> createState() => _IceCopyButtonState();
}

class _IceCopyButtonState extends State<_IceCopyButton> {
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: _copied
              ? c.textTertiary.withValues(alpha: 0.12)
              : c.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppColors.radiusSm),
        ),
        child: Icon(
          _copied ? LucideIcons.checkCheck : LucideIcons.copy,
          size: 14,
          color: _copied ? c.textTertiary : c.primary,
        ),
      ),
    );
  }
}

// ── Card Data ───────────────────────────────────────────────────────
class _CardData {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  const _CardData({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });
}
