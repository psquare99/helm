import 'package:flutter/material.dart';
import '../../core/theme/command_colors.dart';
import '../../core/theme/command_theme.dart';
import '../state/project_manager_controller.dart';

class SettingsDialog extends StatefulWidget {
  final ProjectManagerController controller;

  const SettingsDialog({super.key, required this.controller});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _tokenController;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.controller.gitHubToken ?? '');
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CommandColors.surfaceBase,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: CommandColors.borderSubtle),
      ),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.settings_suggest_rounded, size: 18, color: CommandColors.signalIce),
                const SizedBox(width: 10),
                const Text(
                  'SYSTEM SETTINGS & INTEGRATIONS',
                  style: TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: CommandColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: CommandColors.textMuted,
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: CommandColors.borderSubtle),
            const SizedBox(height: 16),

            // GitHub Integration
            const Text(
              'GITHUB INTEGRATION',
              style: TextStyle(
                fontFamily: CommandTheme.fontMono,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: CommandColors.signalIce,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Public repositories are queried automatically without authentication (60 req/hr). Add a Personal Access Token (classic or fine-grained with repo read access) to raise your rate limit to 5,000 req/hr and observe private repositories.',
              style: TextStyle(
                fontFamily: CommandTheme.fontSans,
                fontSize: 12,
                color: CommandColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tokenController,
                    obscureText: _obscureToken,
                    style: const TextStyle(
                      fontFamily: CommandTheme.fontMono,
                      fontSize: 12,
                      color: CommandColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureToken ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                          size: 16,
                          color: CommandColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscureToken = !_obscureToken),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final t = _tokenController.text.trim();
                    widget.controller.setGitHubToken(t.isEmpty ? null : t);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('GitHub token saved successfully.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: CommandColors.surfaceRaised,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    side: const BorderSide(color: CommandColors.borderSubtle),
                  ),
                  child: const Text(
                    'SAVE',
                    style: TextStyle(
                      fontFamily: CommandTheme.fontMono,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CommandColors.signalIce,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Portfolio Reset
            const Text(
              'DATA MANAGEMENT',
              style: TextStyle(
                fontFamily: CommandTheme.fontMono,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: CommandColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Reset all projects back to the canonical seed portfolio (P² Studio, Prime, Curio, Nook, Wayfarer, WAYFINDER, etc.) based on disk state.',
              style: TextStyle(
                fontFamily: CommandTheme.fontSans,
                fontSize: 12,
                color: CommandColors.textDisabled,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: CommandColors.surfaceBase,
                    title: const Text('Reset Portfolio Data?'),
                    content: const Text(
                      'This will restore all projects to their default discovered state. Any custom tasks or notes created will be replaced with seed data.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: CommandColors.signalCoral,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Confirm Reset'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await widget.controller.resetToSeedData();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Portfolio reset to seed data.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: CommandColors.borderSubtle),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              icon: const Icon(Icons.restart_alt_rounded, size: 16, color: CommandColors.signalAmber),
              label: const Text(
                'RESET PORTFOLIO TO SEED STATE',
                style: TextStyle(
                  fontFamily: CommandTheme.fontMono,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CommandColors.signalAmber,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // P² Ecosystem Philosophy Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CommandColors.surfaceRaised,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: CommandColors.borderSubtle),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: CommandColors.signalIce),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'P² Philosophy: Standalone first, connected second. Human status is authoritative. External telemetry provides momentum visibility without altering user intent.',
                      style: TextStyle(
                        fontFamily: CommandTheme.fontSans,
                        fontSize: 11,
                        color: CommandColors.textMuted,
                        height: 1.35,
                      ),
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
