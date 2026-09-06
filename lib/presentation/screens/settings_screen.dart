import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/command_colors.dart';
import '../../core/theme/command_theme.dart';
import '../state/project_manager_controller.dart';
import 'github_import_dialog.dart';
import 'onboarding_screen.dart';
import '../widgets/github_device_login_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final ProjectManagerController controller;

  const SettingsScreen({super.key, required this.controller});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _tokenInputController = TextEditingController();
  final TextEditingController _jsonImportController = TextEditingController();
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller.gitHubToken != null) {
      _tokenInputController.text = widget.controller.gitHubToken!;
    }
    widget.controller.refreshRateLimit();
  }

  @override
  void dispose() {
    _tokenInputController.dispose();
    _jsonImportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;

        return Scaffold(
          backgroundColor: CommandColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Top Header Bar
                _buildHeader(context),

                // Settings Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. GitHub Connection & Account Section
                            _buildGitHubSection(context, controller),
                            const SizedBox(height: 24),

                            // 2. Portfolio Data & Backups
                            _buildDataManagementSection(context, controller),
                            const SizedBox(height: 24),

                            // 3. Interface & Workspace Preferences
                            _buildPreferencesSection(context, controller),
                            const SizedBox(height: 24),

                            // 4. System & Philosophy
                            _buildSystemInfoSection(context, controller),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: CommandColors.surfaceBase,
        border: Border(bottom: BorderSide(color: CommandColors.borderSubtle)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to Dashboard',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: CommandColors.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: CommandColors.borderSubtle),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'SETTINGS & INTEGRATIONS',
            style: TextStyle(
              fontFamily: CommandTheme.fontMono,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: CommandColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: CommandColors.surfaceRaised,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: CommandColors.borderSubtle),
            ),
            child: const Text(
              'CONTROL ROOM',
              style: TextStyle(
                fontFamily: CommandTheme.fontMono,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: CommandColors.signalIce,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGitHubSection(BuildContext context, ProjectManagerController controller) {
    final user = controller.currentUser;
    final isConnected = controller.gitHubToken != null && controller.gitHubToken!.isNotEmpty;
    final rate = controller.rateLimitInfo;

    return Container(
      decoration: BoxDecoration(
        color: CommandColors.surfaceCard,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: CommandColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                const Icon(Icons.hub_rounded, size: 18, color: CommandColors.signalIce),
                const SizedBox(width: 10),
                const Text(
                  'GITHUB INTEGRATION',
                  style: TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: CommandColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (isConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: CommandColors.signalEmeraldSoft,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: CommandColors.signalEmeraldBorder),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 11, color: CommandColors.signalEmerald),
                        SizedBox(width: 4),
                        Text(
                          'CONNECTED',
                          style: TextStyle(
                            fontFamily: CommandTheme.fontMono,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: CommandColors.signalEmerald,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: CommandColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: CommandColors.borderSubtle),
                    ),
                    child: const Text(
                      'NOT CONNECTED',
                      style: TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 9.5,
                        color: CommandColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, color: CommandColors.borderSubtle),

          if (isConnected) ...[
            // User Card
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  if (user?.avatarUrl.isNotEmpty ?? false)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        user!.avatarUrl,
                        width: 46,
                        height: 46,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_circle, size: 46),
                      ),
                    )
                  else
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: CommandColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.person, color: CommandColors.textMuted),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Authenticated User',
                          style: const TextStyle(
                            fontFamily: CommandTheme.fontSans,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: CommandColors.textPrimary,
                          ),
                        ),
                        if (user?.login != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '@${user!.login}',
                            style: const TextStyle(
                              fontFamily: CommandTheme.fontMono,
                              fontSize: 12,
                              color: CommandColors.signalIce,
                            ),
                          ),
                        ],
                        if (rate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'API Rate Limit: ${rate['remaining']} / ${rate['limit']} requests available',
                            style: const TextStyle(
                              fontFamily: CommandTheme.fontMono,
                              fontSize: 10.5,
                              color: CommandColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: CommandColors.borderSubtle),

            // Actions Toolbar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => GitHubImportDialog(controller: controller),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: CommandColors.textPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 15),
                    label: const Text(
                      'PULL & IMPORT REPOSITORIES',
                      style: TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.isSyncingTelemetry
                        ? null
                        : () => controller.refreshAllTelemetry(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: CommandColors.borderSubtle),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.sync_rounded, size: 14, color: CommandColors.signalIce),
                    label: const Text(
                      'SYNC SIGNALS NOW',
                      style: TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => controller.disconnectGitHub(),
                    child: const Text(
                      'Disconnect',
                      style: TextStyle(color: CommandColors.signalCoral, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Connect Form
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Connect your GitHub account to import repositories and observe live telemetry without needing any server.',
                    style: TextStyle(
                      fontFamily: CommandTheme.fontSans,
                      fontSize: 13,
                      color: CommandColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await GitHubDeviceLoginDialog.show(context, controller);
                        if (!mounted) return;
                        if (success == true) {
                          setState(() {});
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Connected to GitHub as @${controller.currentUser?.login ?? 'user'}'),
                              backgroundColor: CommandColors.signalEmerald,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.hub_rounded, size: 16),
                      label: const Text(
                        'SIGN IN WITH GITHUB (DEVICE FLOW)',
                        style: TextStyle(
                          fontFamily: CommandTheme.fontMono,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: CommandColors.textPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: CommandColors.borderSubtle)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR ENTER TOKEN MANUALLY',
                          style: TextStyle(
                            fontFamily: CommandTheme.fontMono,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: CommandColors.textMuted,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: CommandColors.borderSubtle)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tokenInputController,
                          obscureText: true,
                          style: const TextStyle(fontFamily: CommandTheme.fontMono, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx or github_pat_xxxx',
                            filled: true,
                            fillColor: CommandColors.background,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(color: CommandColors.borderSubtle),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _isConnecting ? null : _connectToken,
                        style: FilledButton.styleFrom(
                          backgroundColor: CommandColors.surfaceRaised,
                          foregroundColor: CommandColors.textPrimary,
                          side: const BorderSide(color: CommandColors.borderSubtle),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: _isConnecting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: CommandColors.signalIce),
                              )
                            : const Text('SAVE TOKEN'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      launchUrl(
                        Uri.parse('https://github.com/settings/tokens/new?scopes=repo,read:org,read:user&description=Helm_Personal_Token'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    child: const Text(
                      'Generate new GitHub token with "repo" scope →',
                      style: TextStyle(
                        fontFamily: CommandTheme.fontSans,
                        fontSize: 12,
                        color: CommandColors.signalIce,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _connectToken() async {
    final token = _tokenInputController.text.trim();
    if (token.isEmpty) return;

    setState(() => _isConnecting = true);
    final success = await widget.controller.loginWithGitHubToken(token);
    setState(() => _isConnecting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected to GitHub account successfully.'),
            backgroundColor: CommandColors.signalEmerald,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not authenticate. Please check your token.'),
            backgroundColor: CommandColors.signalCoral,
          ),
        );
      }
    }
  }

  Widget _buildDataManagementSection(
      BuildContext context, ProjectManagerController controller) {
    return Container(
      decoration: BoxDecoration(
        color: CommandColors.surfaceCard,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: CommandColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 18, color: CommandColors.signalEmerald),
                SizedBox(width: 10),
                Text(
                  'PORTFOLIO DATA & BACKUPS',
                  style: TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: CommandColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: CommandColors.borderSubtle),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Currently tracking ${controller.totalProjectsCount} projects '
                  '(${controller.activeProjectsCount} active, ${controller.connectedReposCount} connected to GitHub).',
                  style: const TextStyle(
                    fontFamily: CommandTheme.fontSans,
                    fontSize: 13,
                    color: CommandColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final jsonStr = await controller.exportPortfolioJson();
                        await Clipboard.setData(ClipboardData(text: jsonStr));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Portfolio JSON copied to clipboard.'),
                              backgroundColor: CommandColors.signalEmerald,
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: CommandColors.borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text(
                        'COPY PORTFOLIO JSON',
                        style: TextStyle(
                          fontFamily: CommandTheme.fontMono,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openImportModal(context, controller),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: CommandColors.borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.file_upload_outlined, size: 14),
                      label: const Text(
                        'RESTORE FROM JSON',
                        style: TextStyle(
                          fontFamily: CommandTheme.fontMono,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _confirmReset(context, controller),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: CommandColors.borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.restart_alt_rounded, size: 14),
                      label: const Text(
                        'RESET TO DEFAULT SEED DATA',
                        style: TextStyle(
                          fontFamily: CommandTheme.fontMono,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openImportModal(BuildContext context, ProjectManagerController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CommandColors.surfaceCard,
        title: const Text(
          'RESTORE PORTFOLIO FROM JSON',
          style: TextStyle(
            fontFamily: CommandTheme.fontMono,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paste your exported portfolio JSON below to restore or migrate your projects.',
                style: TextStyle(fontSize: 12, color: CommandColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _jsonImportController,
                maxLines: 8,
                style: const TextStyle(fontFamily: CommandTheme.fontMono, fontSize: 11),
                decoration: InputDecoration(
                  hintText: '[\n  {\n    "id": "...",\n    "name": "..."\n  }\n]',
                  filled: true,
                  fillColor: CommandColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final jsonText = _jsonImportController.text.trim();
              if (jsonText.isNotEmpty) {
                final ok = await controller.importPortfolioJson(jsonText);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? 'Portfolio successfully imported.'
                          : 'Failed to parse JSON backup.'),
                      backgroundColor:
                          ok ? CommandColors.signalEmerald : CommandColors.signalCoral,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: CommandColors.textPrimary),
            child: const Text('RESTORE'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, ProjectManagerController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CommandColors.surfaceCard,
        title: const Text('Load Sample Projects?'),
        content: const Text(
          'This will replace your current portfolio list with illustrative sample demo projects.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await controller.resetToSeedData();
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Portfolio reset to initial seed data.'),
                    backgroundColor: CommandColors.signalEmerald,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: CommandColors.signalCoral),
            child: const Text('RESET'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(
      BuildContext context, ProjectManagerController controller) {
    return Container(
      decoration: BoxDecoration(
        color: CommandColors.surfaceCard,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: CommandColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 18, color: CommandColors.signalIce),
                SizedBox(width: 10),
                Text(
                  'WORKSPACE & DISPLAY PREFERENCES',
                  style: TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: CommandColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: CommandColors.borderSubtle),
          // View Mode
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Default View Mode',
                        style: TextStyle(
                          fontFamily: CommandTheme.fontSans,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: CommandColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Choose between visual momentum pulse cards or dense flight deck table.',
                        style: TextStyle(fontSize: 12, color: CommandColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                SegmentedButton<PortfolioViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: PortfolioViewMode.simpleGrid,
                      label: Text('Simple'),
                      icon: Icon(Icons.view_agenda_outlined, size: 14),
                    ),
                    ButtonSegment(
                      value: PortfolioViewMode.pulseGrid,
                      label: Text('Pulse'),
                      icon: Icon(Icons.grid_view_rounded, size: 14),
                    ),
                    ButtonSegment(
                      value: PortfolioViewMode.flightDeckTable,
                      label: Text('Flight Deck'),
                      icon: Icon(Icons.table_rows_rounded, size: 14),
                    ),
                  ],
                  selected: {controller.viewMode},
                  onSelectionChanged: (set) => controller.setViewMode(set.first),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: CommandColors.borderSubtle),
          // Radar Banner Toggle
          SwitchListTile(
            value: controller.showIntelligenceRadar,
            onChanged: (_) => controller.toggleIntelligenceRadar(),
            title: const Text(
              'Portfolio Intelligence Radar',
              style: TextStyle(
                fontFamily: CommandTheme.fontSans,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: CommandColors.textPrimary,
              ),
            ),
            subtitle: const Text(
              'Show momentum observations, dormant branch warnings, and attention banners.',
              style: TextStyle(fontSize: 12, color: CommandColors.textSecondary),
            ),
            activeThumbColor: CommandColors.signalIce,
          ),
          const Divider(height: 1, color: CommandColors.borderSubtle),
          // Re-launch Tour
          ListTile(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OnboardingScreen(controller: controller),
                ),
              );
            },
            leading: const Icon(Icons.tour_outlined, size: 20, color: CommandColors.signalIce),
            title: const Text(
              'Revisit Onboarding Tour',
              style: TextStyle(
                fontFamily: CommandTheme.fontSans,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Re-run the welcome walkthrough and system architecture overview.',
              style: TextStyle(fontSize: 12, color: CommandColors.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoSection(
      BuildContext context, ProjectManagerController controller) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CommandColors.surfaceBase,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: CommandColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'SYSTEM ARCHITECTURE // P² PROTOCOL',
                style: TextStyle(
                  fontFamily: CommandTheme.fontMono,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: CommandColors.textMuted,
                ),
              ),
              Spacer(),
              Text(
                'v1.0.0',
                style: TextStyle(
                  fontFamily: CommandTheme.fontMono,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: CommandColors.signalIce,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Local Storage Path: ${controller.storagePath}',
            style: const TextStyle(
              fontFamily: CommandTheme.fontMono,
              fontSize: 10.5,
              color: CommandColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Rule: Human status is authoritative. External GitHub telemetry provides ground truth without overwriting decisions.',
            style: TextStyle(
              fontFamily: CommandTheme.fontSans,
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: CommandColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
