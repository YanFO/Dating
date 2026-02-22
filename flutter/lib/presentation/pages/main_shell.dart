/// 主要 Shell 頁面
///
/// 包含底部導航列（5 個項目）、頁面切換（IndexedStack）、
/// 全域語音教練島與衝動控制覆蓋層。
/// 中央的 Love Coach 按鈕觸發聊天面板（BottomSheet），不切換頁面。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_theme_colors.dart';
import '../../core/l10n/tr_extension.dart';
import '../providers/core_providers.dart';
import '../widgets/impulse_control_overlay.dart';
import '../widgets/love_coach_chat_sheet.dart';
import '../widgets/voice_coach_island.dart';
import 'home/home_page.dart';
import 'coach/coach_page.dart';
import 'insights/insights_page.dart';
import 'profile/profile_page.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;
  bool _showImpulseControl = false;

  // 頁面列表（4 個，中央 Love Coach 不佔頁面位）
  final _pages = const [
    HomePage(),
    CoachPage(),
    InsightsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // 4 個頁面標籤（不含中央 Love Coach）
    final tabLabels = [
      ref.tr('tab_home'),
      ref.tr('tab_coach'),
      ref.tr('tab_insights'),
      ref.tr('tab_profile'),
    ];

    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(c),
              // 全域語音教練島：所有分頁可見
              if (ref.watch(voiceCoachEnabledProvider))
                const VoiceCoachIsland(),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNav(c, tabLabels),
          ),
          if (_showImpulseControl)
            Positioned.fill(
              child: ImpulseControlOverlay(
                onClose: () => setState(() => _showImpulseControl = false),
              ),
            ),
        ],
      ),
    );
  }

  // ─── 頂部標題列 ─────────────────────────────────

  Widget _buildHeader(AppThemeColors c) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              ref.tr('app_title'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
                letterSpacing: -1.5,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showImpulseControl = true),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.impulseBlueSoft,
                      border: Border.all(
                          color: c.impulseBlue.withValues(alpha: 0.3)),
                    ),
                    child: Icon(
                      LucideIcons.shieldAlert,
                      size: 14,
                      color: c.impulseBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.surfaceLight,
                    border: Border.all(color: c.border),
                  ),
                  child: Icon(
                    LucideIcons.bell,
                    size: 14,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── 底部導航列（5 個項目）──────────────────────

  Widget _buildBottomNav(AppThemeColors c, List<String> tabLabels) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: c.background.withValues(alpha: 0.9),
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 首頁（index 0 → page 0）
            _buildNavItem(c, LucideIcons.home, tabLabels[0], 0, 0),
            // 教練（index 1 → page 1）
            _buildNavItem(c, LucideIcons.wand2, tabLabels[1], 1, 1),
            // 中央 Love Coach 按鈕（不切換頁面）
            _buildCenterButton(c),
            // 洞察（index 3 → page 2）
            _buildNavItem(c, LucideIcons.radar, tabLabels[2], 2, 3),
            // 個人（index 4 → page 3）
            _buildNavItem(c, LucideIcons.userCircle, tabLabels[3], 3, 4),
          ],
        ),
      ),
    );
  }

  // ─── 一般導航項目 ──────────────────────────────

  Widget _buildNavItem(
    AppThemeColors c,
    IconData icon,
    String label,
    int pageIndex,
    int navIndex,
  ) {
    final isActive = _currentIndex == pageIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = pageIndex),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: isActive ? c.primary : c.textTertiary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isActive ? c.primary : c.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 中央 Love Coach 按鈕（發光效果）───────────

  Widget _buildCenterButton(AppThemeColors c) {
    return GestureDetector(
      onTap: _openLoveCoachSheet,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.primary, c.primaryDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.heart,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ref.tr('tab_love_coach'),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: c.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 開啟 Love Coach 聊天面板 ──────────────────

  void _openLoveCoachSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, __) => const LoveCoachChatSheet(),
      ),
    );
  }
}
