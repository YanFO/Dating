import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_theme_colors.dart';
import '../../core/l10n/tr_extension.dart';

class ImpulseControlOverlay extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const ImpulseControlOverlay({super.key, required this.onClose});

  @override
  ConsumerState<ImpulseControlOverlay> createState() =>
      _ImpulseControlOverlayState();
}

class _ImpulseControlOverlayState
    extends ConsumerState<ImpulseControlOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _breatheController;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            c.impulseBlue.withValues(alpha: 0.15),
            c.background,
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 12,
              right: 24,
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.overlayLight,
                  ),
                  child: Icon(
                    LucideIcons.x,
                    size: 20,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _breatheController,
                    builder: (context, child) {
                      final scale = 0.85 + _breatheController.value * 0.3;
                      final opacity = 0.1 + _breatheController.value * 0.5;
                      return SizedBox(
                        width: 224,
                        height: 224,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 224,
                                height: 224,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: c.impulseBlue
                                        .withValues(alpha: opacity),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: c.impulseBlue
                                          .withValues(alpha: opacity * 0.5),
                                      blurRadius:
                                          20 + _breatheController.value * 40,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: 176,
                              height: 176,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.impulseBlue.withValues(alpha: 0.05),
                              ),
                            ),
                            Icon(
                              LucideIcons.moonStar,
                              size: 48,
                              color: c.impulseBlue.withValues(alpha: 0.8),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 48),
                  Text(
                    ref.tr('impulse_title'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ref.tr('impulse_desc'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: c.impulseBlue.withValues(alpha: 0.6),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
