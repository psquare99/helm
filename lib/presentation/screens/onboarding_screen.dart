import 'package:flutter/material.dart';
import '../../core/theme/command_colors.dart';
import '../../core/theme/command_theme.dart';
import '../state/project_manager_controller.dart';
import 'dashboard_screen.dart';
import 'github_import_dialog.dart';
import '../widgets/github_device_login_dialog.dart';

class OnboardingScreen extends StatefulWidget {
  final ProjectManagerController controller;

  const OnboardingScreen({super.key, required this.controller});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedSetupOption = 'blank'; // 'blank', 'github', 'sample'

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    if (_selectedSetupOption == 'sample') {
      await widget.controller.resetToSeedData();
    } else if (_selectedSetupOption == 'blank') {
      await widget.controller.clearPortfolio();
    }
    // If 'github', projects were imported directly via the import dialog

    await widget.controller.completeOnboarding();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(controller: widget.controller),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CommandColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  // Brand Indicator
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: CommandColors.signalEmerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'HELM',
                    style: TextStyle(
                      fontFamily: CommandTheme.fontMono,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
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
                      'P²',
                      style: TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: CommandColors.signalIce,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Step Indicator Dots
                  Row(
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 20 : 6,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isActive
                              ? CommandColors.textPrimary
                              : CommandColors.borderMedium,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text(
                      'SKIP',
                      style: TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 11,
                        color: CommandColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: CommandColors.borderSubtle),

            // Main Slide Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildSlide1CommandCenter(context),
                  _buildSlide2Philosophy(context),
                  _buildSlide3Setup(context),
                ],
              ),
            ),

            const Divider(height: 1, color: CommandColors.borderSubtle),

            // Bottom Navigation Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    OutlinedButton(
                      onPressed: _previousPage,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: CommandColors.borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('BACK'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _nextPage,
                    style: FilledButton.styleFrom(
                      backgroundColor: CommandColors.textPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(
                      _currentPage == 2 ? 'ENTER COMMAND CENTER' : 'CONTINUE',
                      style: const TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
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

  // Slide 1: Welcome & Command Center Concept
  Widget _buildSlide1CommandCenter(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CommandColors.signalEmeraldSoft,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: CommandColors.signalEmeraldBorder),
                ),
                child: const Text(
                  'FOUNDATIONAL P² SYSTEM',
                  style: TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: CommandColors.signalEmerald,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Personal Command Center\nFor Everything You Build.',
                style: TextStyle(
                  fontFamily: CommandTheme.fontSans,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: CommandColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Helm is an intelligent flight deck designed to give you a clear, effortless overview of all active, in-development, and planned systems across your ecosystem.',
                style: TextStyle(
                  fontFamily: CommandTheme.fontSans,
                  fontSize: 14.5,
                  height: 1.6,
                  color: CommandColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              // Feature Pillars
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildPillarCard(
                      icon: Icons.radar_rounded,
                      title: 'Dual-Channel State',
                      description:
                          'Separates human intent (Active, Paused, Complete) from observed git commit telemetry.',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildPillarCard(
                      icon: Icons.track_changes_rounded,
                      title: 'Momentum Radar',
                      description:
                          'Monitors dormant branches, stale milestones, and tells you the single next action.',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Slide 2: Philosophy (Standalone first, connected second)
  Widget _buildSlide2Philosophy(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CommandColors.signalIceSoft,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: CommandColors.signalIceBorder),
                ),
                child: const Text(
                  'SYSTEM PHILOSOPHY',
                  style: TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: CommandColors.signalIce,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Standalone First,\nConnected Second.',
                style: TextStyle(
                  fontFamily: CommandTheme.fontSans,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: CommandColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildPhilosophyItem(
                number: '01',
                title: 'Human State is Authoritative',
                description:
                    'External systems like GitHub provide observed telemetry, but they never overwrite what you decided. If a repo has no commits for a month, it is stale—not paused, unless you declare it paused.',
              ),
              const SizedBox(height: 14),
              _buildPhilosophyItem(
                number: '02',
                title: 'Honest Empty States Over Fake Data',
                description:
                    'No synthetic dates, fake milestones, or simulated activity. When a project has no next action defined or GitHub is unconnected, it displays exactly that.',
              ),
              const SizedBox(height: 14),
              _buildPhilosophyItem(
                number: '03',
                title: 'Offline Resilient Local Storage',
                description:
                    'All project configurations and notes are persisted directly on your local device. The application functions completely offline even without network access.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Slide 3: Initial Setup & Project Pull
  Widget _buildSlide3Setup(BuildContext context) {
    final controller = widget.controller;
    final isConnected = controller.gitHubToken != null && controller.gitHubToken!.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CommandColors.signalAmberSoft,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: CommandColors.signalAmberBorder),
                ),
                child: const Text(
                  'INITIALIZE WORKSPACE',
                  style: TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: CommandColors.signalAmber,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'How Would You Like To Begin?',
                style: TextStyle(
                  fontFamily: CommandTheme.fontSans,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: CommandColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a starter configuration. You can change and import more projects anytime.',
                style: TextStyle(
                  fontFamily: CommandTheme.fontSans,
                  fontSize: 13.5,
                  color: CommandColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),

              // Option A: Start Fresh (Blank Canvas) - Default
              _buildSetupOptionTile(
                id: 'blank',
                title: 'Start Fresh (Clean State)',
                subtitle:
                    'Begin with an empty workspace and add your own projects on your terms.',
                icon: Icons.space_dashboard_outlined,
                accentColor: CommandColors.signalEmerald,
              ),

              const SizedBox(height: 12),

              // Option B: Pull Real GitHub Repositories
              _buildSetupOptionTile(
                id: 'github',
                title: isConnected
                    ? 'Pull From GitHub (${controller.currentUser?.login ?? 'Connected'})'
                    : 'Sign In With GitHub',
                subtitle: isConnected
                    ? 'Browse and select your repositories to automatically track as projects'
                    : '1-click sign-in via browser to pull your repositories into Helm',
                icon: Icons.hub_rounded,
                accentColor: CommandColors.signalIce,
                trailing: FilledButton.tonal(
                  onPressed: () async {
                    if (isConnected) {
                      await showDialog(
                        context: context,
                        builder: (_) => GitHubImportDialog(controller: controller),
                      );
                    } else {
                      await GitHubDeviceLoginDialog.show(context, controller);
                    }
                    if (mounted) setState(() {});
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text(
                    isConnected ? 'BROWSE REPOS' : 'SIGN IN',
                    style: const TextStyle(
                      fontFamily: CommandTheme.fontMono,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Option C: Explore Sample Demo Projects
              _buildSetupOptionTile(
                id: 'sample',
                title: 'Explore Demo Projects',
                subtitle:
                    'Load 2 illustrative sample projects (Mobile App & Cloud API) to preview the system.',
                icon: Icons.lightbulb_outline_rounded,
                accentColor: CommandColors.signalAmber,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetupOptionTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    Widget? trailing,
  }) {
    final isSelected = _selectedSetupOption == id;

    return InkWell(
      onTap: () => setState(() => _selectedSetupOption = id),
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? CommandColors.surfaceRaised : CommandColors.surfaceCard,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isSelected ? CommandColors.textPrimary : CommandColors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(icon, size: 20, color: accentColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: CommandTheme.fontSans,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: CommandColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: CommandTheme.fontSans,
                      fontSize: 12,
                      color: CommandColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              trailing,
            ] else ...[
              const SizedBox(width: 10),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? CommandColors.textPrimary
                        : CommandColors.borderMedium,
                    width: isSelected ? 5.5 : 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPillarCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CommandColors.surfaceCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: CommandColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: CommandColors.signalIce),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontFamily: CommandTheme.fontSans,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: CommandColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontFamily: CommandTheme.fontSans,
              fontSize: 12,
              height: 1.4,
              color: CommandColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhilosophyItem({
    required String number,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CommandColors.surfaceCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: CommandColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              fontFamily: CommandTheme.fontMono,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: CommandColors.signalIce,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: CommandTheme.fontSans,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CommandColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: CommandTheme.fontSans,
                    fontSize: 12.5,
                    height: 1.5,
                    color: CommandColors.textSecondary,
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
