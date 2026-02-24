import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme_colors.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/tr_extension.dart';
import '../../providers/auth_provider.dart';
import '../../providers/camera_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/match_provider.dart';
import '../../providers/persona_provider.dart';
import '../../providers/theme_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  double _emojiUsage = 50;
  double _sentenceLength = 30;
  double _colloquialism = 70;
  bool _toneExpanded = true;
  bool _sandboxExpanded = true;
  final _sandboxController = TextEditingController();
  bool _personaLoaded = false;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(personaProvider.notifier).loadPersona();
    });
  }

  @override
  void dispose() {
    _sandboxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sync slider values from API on first load
    final persona = ref.watch(personaProvider);
    if (!_personaLoaded) {
      persona.whenData((settings) {
        if (settings != null) {
          _emojiUsage = settings.emojiUsage;
          _sentenceLength = settings.sentenceLength;
          _colloquialism = settings.colloquialism;
          _personaLoaded = true;
        }
      });
    }
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
              ref.tr('profile_title'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildAccountCard(c),
          const SizedBox(height: 16),
          _buildPersonaCard(c),
          const SizedBox(height: 16),
          _buildToneAdjustments(c),
          const SizedBox(height: 16),
          _buildSandboxTesting(c),
          const SizedBox(height: 32),
          Divider(color: c.border, thickness: 1),
          const SizedBox(height: 16),
          _buildSettingsLinks(c),
        ],
      ),
    );
  }

  Widget _buildAccountCard(AppThemeColors c) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      // Not signed in — show sign-in prompt
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppColors.radius2Xl),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.overlayLight,
              ),
              child: Icon(LucideIcons.userCircle, size: 24, color: c.textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Guest Mode',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sign in to sync your data',
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/login'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Signed in — show user info
    final user = authState.user!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppColors.radius2Xl),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: c.primary.withValues(alpha: 0.2),
                backgroundImage:
                    user.image != null ? NetworkImage(user.image!) : null,
                child: user.image == null
                    ? Text(
                        (user.name ?? user.email).substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: c.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? 'User',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Log Out',
                  icon: LucideIcons.logOut,
                  color: c.textSecondary,
                  onTap: () => _handleLogout(c),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Delete Account',
                  icon: LucideIcons.trash2,
                  color: c.error,
                  onTap: () => _handleDeleteAccount(c),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(AppThemeColors c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('Log Out', style: TextStyle(color: c.textPrimary, fontSize: 16)),
        content: Text('Are you sure you want to log out?',
            style: TextStyle(color: c.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Log Out', style: TextStyle(color: c.primary)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  Future<void> _handleDeleteAccount(AppThemeColors c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('Delete Account',
            style: TextStyle(color: c.error, fontSize: 16)),
        content: Text(
          'This will permanently delete all your data. This action cannot be undone.',
          style: TextStyle(color: c.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: c.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final success = await ref.read(authProvider.notifier).deleteAccount();
      if (mounted && success) {
        _showTopSnack('Account deleted successfully');
      } else if (mounted) {
        _showTopSnack('Failed to delete account', isError: true);
      }
    }
  }

  Widget _buildPersonaCard(AppThemeColors c) {
    final persona = ref.watch(personaProvider);
    final syncPct = persona.valueOrNull?.syncPct ?? 85.0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppColors.radius2Xl),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.primary, const Color(0xFF7C3AED)],
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.background,
                  ),
                  child: Icon(LucideIcons.user, size: 24, color: c.textPrimary),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ref.tr('profile_clone_status'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 6,
                        decoration: BoxDecoration(
                          color: c.muted,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: syncPct / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: c.primary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${syncPct.toInt()}% ${ref.tr('profile_sync_suffix')}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: c.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            ref.tr('profile_clone_desc'),
            style: TextStyle(
              fontSize: 12,
              color: c.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _importing ? null : _showImportOptions,
            child: Container(
              width: double.infinity,
              height: 112,
              decoration: BoxDecoration(
                color: c.background,
                borderRadius: BorderRadius.circular(AppColors.radiusLg),
                border: Border.all(color: c.borderLight),
              ),
              child: _importing
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '分析中...',
                            style: TextStyle(
                              fontSize: 12,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.overlayLight,
                          ),
                          child: Icon(LucideIcons.upload,
                              size: 18, color: c.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ref.tr('profile_upload_chats'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Collapsible: Tone Adjustments ---
  Widget _buildToneAdjustments(AppThemeColors c) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppColors.radius2Xl),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCollapsibleHeader(
            title: ref.tr('profile_tone_title'),
            isExpanded: _toneExpanded,
            onTap: () => setState(() => _toneExpanded = !_toneExpanded),
            c: c,
          ),
          AnimatedCrossFade(
            firstChild: Column(
              children: [
                const SizedBox(height: 24),
                _buildSlider(
                  c: c,
                  label: ref.tr('profile_emoji_usage'),
                  value: _emojiUsage,
                  valueLabel: _emojiUsage < 33
                      ? ref.tr('profile_none')
                      : _emojiUsage < 66
                          ? ref.tr('profile_moderate')
                          : ref.tr('profile_lots'),
                  leftLabel: ref.tr('profile_none'),
                  rightLabel: ref.tr('profile_lots'),
                  onChanged: (v) {
                    setState(() => _emojiUsage = v);
                    _saveTone();
                  },
                ),
                const SizedBox(height: 20),
                _buildSlider(
                  c: c,
                  label: ref.tr('profile_sentence_length'),
                  value: _sentenceLength,
                  valueLabel: _sentenceLength < 33
                      ? ref.tr('profile_brief')
                      : _sentenceLength < 66
                          ? ref.tr('profile_short')
                          : ref.tr('profile_detailed'),
                  leftLabel: ref.tr('profile_brief'),
                  rightLabel: ref.tr('profile_detailed'),
                  onChanged: (v) {
                    setState(() => _sentenceLength = v);
                    _saveTone();
                  },
                ),
                const SizedBox(height: 20),
                _buildSlider(
                  c: c,
                  label: ref.tr('profile_colloquialism'),
                  value: _colloquialism,
                  valueLabel: _colloquialism < 33
                      ? ref.tr('profile_formal')
                      : _colloquialism < 66
                          ? ref.tr('profile_casual')
                          : ref.tr('profile_slang'),
                  leftLabel: ref.tr('profile_formal'),
                  rightLabel: ref.tr('profile_slang'),
                  onChanged: (v) {
                    setState(() => _colloquialism = v);
                    _saveTone();
                  },
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _toneExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  // --- Collapsible: Sandbox Testing ---
  Widget _buildSandboxTesting(AppThemeColors c) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.surface, c.background],
        ),
        borderRadius: BorderRadius.circular(AppColors.radius2Xl),
        border: Border.all(color: c.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCollapsibleHeader(
            title: ref.tr('profile_sandbox_title'),
            isExpanded: _sandboxExpanded,
            onTap: () =>
                setState(() => _sandboxExpanded = !_sandboxExpanded),
            c: c,
            leadingIcon: LucideIcons.testTube,
          ),
          AnimatedCrossFade(
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  ref.tr('profile_sandbox_desc'),
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Input field
                Container(
                  decoration: BoxDecoration(
                    color: c.background,
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                    border: Border.all(color: c.borderLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _sandboxController,
                          style: TextStyle(fontSize: 14, color: c.textPrimary),
                          decoration: InputDecoration(
                            hintText: ref.tr('profile_sample_input'),
                            hintStyle: TextStyle(fontSize: 12, color: c.textMuted),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          final text = _sandboxController.text.trim();
                          if (text.isNotEmpty) {
                            ref.read(sandboxProvider.notifier).rewrite(text);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.primary.withValues(alpha: 0.1),
                          ),
                          child: Icon(LucideIcons.arrowRight,
                              size: 14, color: c.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Output
                _buildSandboxOutput(c),
              ],
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _sandboxExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildSandboxOutput(AppThemeColors c) {
    final sandbox = ref.watch(sandboxProvider);
    return sandbox.when(
      data: (result) {
        if (result == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppColors.radiusMd),
              border: Border.all(color: c.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.tr('profile_clone_rewritten'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: c.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ref.tr('profile_sample_output'),
                  style: TextStyle(fontSize: 14, color: c.textPrimary),
                ),
              ],
            ),
          );
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            border: Border.all(color: c.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ref.tr('profile_clone_rewritten'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: c.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                result.rewritten,
                style: TextStyle(fontSize: 14, color: c.textPrimary),
              ),
            ],
          ),
        );
      },
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
          ),
        ),
      ),
      error: (e, _) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
        ),
        child: Text('Error: $e',
            style: TextStyle(fontSize: 12, color: c.textSecondary)),
      ),
    );
  }

  Widget _buildCollapsibleHeader({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required AppThemeColors c,
    IconData? leadingIcon,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primary.withValues(alpha: 0.1),
              ),
              child: Icon(leadingIcon, size: 18, color: c.primary),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
            ),
          ),
          AnimatedRotation(
            turns: isExpanded ? 0.0 : -0.25,
            duration: const Duration(milliseconds: 200),
            child: Icon(LucideIcons.chevronDown, size: 18, color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required AppThemeColors c,
    required String label,
    required double value,
    required String valueLabel,
    required String leftLabel,
    required String rightLabel,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: c.textSecondary)),
            Text(
              valueLabel,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w500, color: c.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: c.primary,
            inactiveTrackColor: c.muted,
            thumbColor: c.primary,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 4,
            overlayColor: c.primary.withValues(alpha: 0.1),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(leftLabel,
                  style: TextStyle(fontSize: 10, color: c.textMuted)),
              Text(rightLabel,
                  style: TextStyle(fontSize: 10, color: c.textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  void _showImportOptions() {
    final c = context.colors;
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(LucideIcons.camera, color: c.textPrimary),
                title: Text(ref.tr('camera'),
                    style: TextStyle(color: c.textPrimary)),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              ListTile(
                leading: Icon(LucideIcons.image, color: c.textPrimary),
                title: Text(ref.tr('gallery'),
                    style: TextStyle(color: c.textPrimary)),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: Icon(LucideIcons.type, color: c.textPrimary),
                title: Text('貼上聊天文字',
                    style: TextStyle(color: c.textPrimary)),
                onTap: () => Navigator.pop(ctx, 'text'),
              ),
            ],
          ),
        ),
      ),
    ).then((choice) {
      if (choice == null) return;
      if (choice == 'text') {
        _showTextImportDialog();
      } else if (choice == 'camera') {
        _importFromCamera();
      } else {
        _importFromGallery();
      }
    });
  }

  Future<void> _importFromCamera() async {
    final picker = ref.read(imagePickerProvider);
    final picked =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null) return;

    setState(() => _importing = true);
    final bytes = await picked.readAsBytes();
    final match = await ref.read(matchProvider.notifier).importChat(
          imageBytes: bytes,
          imageFilename: picked.name,
        );
    setState(() => _importing = false);

    if (!mounted) return;
    if (match != null) {
      _showTopSnack('已建立聊天對象：${match.name}');
    } else {
      _showTopSnack('分析失敗，請再試一次', isError: true);
    }
  }

  Future<void> _importFromGallery() async {
    final picker = ref.read(imagePickerProvider);
    final pickedList = await picker.pickMultiImage(imageQuality: 85);
    if (pickedList.isEmpty) return;

    setState(() => _importing = true);

    List<dynamic>? results;
    if (pickedList.length == 1) {
      final bytes = await pickedList.first.readAsBytes();
      final match = await ref.read(matchProvider.notifier).importChat(
            imageBytes: bytes,
            imageFilename: pickedList.first.name,
          );
      results = match != null ? [match] : null;
    } else {
      final bytesList = <dynamic>[];
      final filenames = <String>[];
      for (final picked in pickedList) {
        bytesList.add(await picked.readAsBytes());
        filenames.add(picked.name);
      }
      results = await ref.read(matchProvider.notifier).importChatMulti(
            imageBytesList: bytesList.cast(),
            filenames: filenames,
          );
    }

    setState(() => _importing = false);

    if (!mounted) return;
    if (results != null && results.isNotEmpty) {
      final names = results.map((m) => m.name).join('、');
      _showTopSnack('已建立聊天對象：$names');
    } else {
      _showTopSnack('分析失敗，請再試一次', isError: true);
    }
  }

  void _showTextImportDialog() {
    final c = context.colors;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('貼上聊天記錄',
            style: TextStyle(fontSize: 16, color: c.textPrimary)),
        content: TextField(
          controller: controller,
          maxLines: 8,
          style: TextStyle(fontSize: 14, color: c.textPrimary),
          decoration: InputDecoration(
            hintText: '將聊天內容貼在這裡...',
            hintStyle: TextStyle(fontSize: 12, color: c.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: c.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消', style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx, text);
              }
            },
            child: Text('分析', style: TextStyle(color: c.primary)),
          ),
        ],
      ),
    ).then((text) async {
      if (text == null || text.toString().isEmpty) return;
      setState(() => _importing = true);
      final match = await ref.read(matchProvider.notifier).importChat(
            chatText: text.toString(),
          );
      setState(() => _importing = false);

      if (!mounted) return;
      if (match != null) {
        _showTopSnack('已建立聊天對象：${match.name}');
      } else {
        _showTopSnack('分析失敗，請再試一次', isError: true);
      }
    });
  }

  void _showTopSnack(String message, {bool isError = false}) {
    final c = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : c.primary,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  void _saveTone() {
    ref.read(personaProvider.notifier).updateTone(
          emojiUsage: _emojiUsage,
          sentenceLength: _sentenceLength,
          colloquialism: _colloquialism,
        );
  }

  Widget _buildSettingsLinks(AppThemeColors c) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final locale = ref.watch(localeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // Language toggle
          _buildSettingsRowWithTrailing(
            c: c,
            icon: LucideIcons.languages,
            label: ref.tr('settings_language'),
            trailing: Text(
              locale.displayName,
              style: TextStyle(fontSize: 12, color: c.primary),
            ),
            onTap: () => ref.read(localeProvider.notifier).toggle(),
          ),
          // Theme toggle
          _buildSettingsRowWithTrailing(
            c: c,
            icon: isDark ? LucideIcons.moon : LucideIcons.sun,
            label: ref.tr('settings_theme'),
            trailing: SizedBox(
              height: 24,
              child: Switch(
                value: isDark,
                onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
                activeTrackColor: c.primary,
              ),
            ),
            onTap: () => ref.read(themeProvider.notifier).toggle(),
          ),
          _buildSettingsRow(c, LucideIcons.settings,
              ref.tr('profile_account_settings')),
          _buildSettingsRow(c, LucideIcons.creditCard,
              ref.tr('profile_subscription')),
        ],
      ),
    );
  }

  Widget _buildSettingsRow(AppThemeColors c, IconData icon, String label) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: c.textSecondary),
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: c.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsRowWithTrailing({
    required AppThemeColors c,
    required IconData icon,
    required String label,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: c.textSecondary),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
