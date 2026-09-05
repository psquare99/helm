import 'package:flutter/material.dart';
import '../../core/theme/command_colors.dart';
import '../../core/theme/command_theme.dart';

/// Minimalist, honest empty state indicator
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool compact;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: compact ? 20 : 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 8 : 12),
              decoration: BoxDecoration(
                color: CommandColors.surfaceRaised,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: CommandColors.borderSubtle),
              ),
              child: Icon(
                icon,
                size: compact ? 18 : 24,
                color: CommandColors.textMuted,
              ),
            ),
            SizedBox(height: compact ? 8 : 14),
            Text(
              title,
              style: TextStyle(
                fontFamily: CommandTheme.fontMono,
                fontSize: compact ? 11.5 : 13,
                fontWeight: FontWeight.w600,
                color: CommandColors.textSecondary,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Text(
                  subtitle!,
                  style: const TextStyle(
                    fontFamily: CommandTheme.fontSans,
                    fontSize: 12,
                    color: CommandColors.textDisabled,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 14),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
