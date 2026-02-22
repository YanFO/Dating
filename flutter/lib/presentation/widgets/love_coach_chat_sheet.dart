/// Love Coach 聊天面板元件
///
/// 以 DraggableScrollableSheet 呈現的全域聊天介面，
/// 包含聊天歷史、即時串流回覆、文字輸入區域。
/// 從底部導航列的中央按鈕觸發顯示。

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme_colors.dart';
import '../../core/l10n/tr_extension.dart';
import '../../data/models/love_coach_models.dart';
import '../providers/love_coach_provider.dart';

class LoveCoachChatSheet extends ConsumerStatefulWidget {
  const LoveCoachChatSheet({super.key});

  @override
  ConsumerState<LoveCoachChatSheet> createState() => _LoveCoachChatSheetState();
}

class _LoveCoachChatSheetState extends ConsumerState<LoveCoachChatSheet> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── 發送訊息 ───────────────────────────────────

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    ref.read(loveCoachProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  // ─── 自動捲動至底部 ─────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final chatState = ref.watch(loveCoachProvider);

    // 串流文字更新時自動捲動
    ref.listen(loveCoachProvider, (prev, next) {
      if (next.streamingText != (prev?.streamingText ?? '')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 拖曳把手
          _buildDragHandle(c),
          // 標題列
          _buildHeader(c),
          Divider(height: 1, color: c.border),
          // 聊天訊息區域
          Expanded(
            child: chatState.messages.isEmpty && !chatState.isStreaming
                ? _buildEmptyState(c)
                : _buildMessageList(c, chatState),
          ),
          // 文字輸入區域
          _buildInputArea(c, chatState.isStreaming),
        ],
      ),
    );
  }

  // ─── 拖曳把手 ───────────────────────────────────

  Widget _buildDragHandle(AppThemeColors c) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: c.muted,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ─── 標題列 ─────────────────────────────────────

  Widget _buildHeader(AppThemeColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          // 教練頭像圖示
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  c.primary.withValues(alpha: 0.3),
                  c.primary.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Icon(LucideIcons.heart, size: 18, color: c.primary),
          ),
          const SizedBox(width: 12),
          // 標題與副標題
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.tr('love_coach_title'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  ref.tr('love_coach_subtitle'),
                  style: TextStyle(fontSize: 11, color: c.textTertiary),
                ),
              ],
            ),
          ),
          // 清除歷史按鈕
          if (ref.watch(loveCoachProvider).messages.isNotEmpty)
            GestureDetector(
              onTap: () =>
                  ref.read(loveCoachProvider.notifier).startNewConversation(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.surfaceLight,
                ),
                child:
                    Icon(LucideIcons.trash2, size: 14, color: c.textTertiary),
              ),
            ),
        ],
      ),
    );
  }

  // ─── 空狀態提示 ─────────────────────────────────

  Widget _buildEmptyState(AppThemeColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.messageCircle,
              size: 48,
              color: c.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              ref.tr('love_coach_empty'),
              style: TextStyle(
                fontSize: 14,
                color: c.textTertiary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── 訊息列表 ──────────────────────────────────

  Widget _buildMessageList(AppThemeColors c, LoveCoachState chatState) {
    final itemCount =
        chatState.messages.length + (chatState.isStreaming ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < chatState.messages.length) {
          return _buildMessageBubble(c, chatState.messages[index]);
        }
        // 串流中的部分回覆
        return _buildStreamingBubble(c, chatState.streamingText);
      },
    );
  }

  // ─── 訊息氣泡 ──────────────────────────────────

  Widget _buildMessageBubble(AppThemeColors c, LoveCoachMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? c.primary.withValues(alpha: 0.15)
              : c.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser
                ? c.primary.withValues(alpha: 0.2)
                : c.borderLight,
          ),
        ),
        child: isUser
            ? Text(
                msg.text,
                style: TextStyle(
                  fontSize: 14,
                  color: c.textPrimary,
                  height: 1.5,
                ),
              )
            : _buildMarkdown(c, msg.text),
      ),
    );
  }

  // ─── 串流中回覆氣泡 ────────────────────────────

  Widget _buildStreamingBubble(AppThemeColors c, String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: c.borderLight),
        ),
        child: text.isEmpty
            ? _buildTypingIndicator(c)
            : _buildMarkdown(c, text),
      ),
    );
  }

  // ─── Markdown 渲染 ───────────────────────────

  Widget _buildMarkdown(AppThemeColors c, String text) {
    return MarkdownBody(
      data: text,
      selectable: true,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(fontSize: 14, color: c.textPrimary, height: 1.5),
        strong: TextStyle(fontSize: 14, color: c.textPrimary, fontWeight: FontWeight.w700),
        em: TextStyle(fontSize: 14, color: c.textPrimary, fontStyle: FontStyle.italic),
        listBullet: TextStyle(fontSize: 14, color: c.textPrimary),
        blockSpacing: 8,
        listIndent: 16,
        listBulletPadding: const EdgeInsets.only(right: 4),
      ),
    );
  }

  // ─── 打字指示器（三個圓點）────────────────────

  Widget _buildTypingIndicator(AppThemeColors c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Container(
          width: 6,
          height: 6,
          margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.textTertiary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  // ─── 文字輸入區域 ──────────────────────────────

  Widget _buildInputArea(AppThemeColors c, bool isStreaming) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: c.background,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            // 文字輸入框
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius:
                      BorderRadius.circular(AppColors.radius2Xl),
                  border: Border.all(color: c.borderLight),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  enabled: !isStreaming,
                  style: TextStyle(fontSize: 14, color: c.textPrimary),
                  decoration: InputDecoration(
                    hintText: ref.tr('love_coach_input_hint'),
                    hintStyle:
                        TextStyle(fontSize: 14, color: c.textMuted),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 發送 / 取消按鈕
            GestureDetector(
              onTap: isStreaming
                  ? () =>
                      ref.read(loveCoachProvider.notifier).cancelStream()
                  : _sendMessage,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isStreaming
                      ? c.error.withValues(alpha: 0.2)
                      : c.primary,
                ),
                child: Icon(
                  isStreaming ? LucideIcons.square : LucideIcons.send,
                  size: 18,
                  color: isStreaming ? c.error : c.primaryForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
