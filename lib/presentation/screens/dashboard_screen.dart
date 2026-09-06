import 'package:flutter/material.dart';
import '../../core/theme/command_colors.dart';
import '../../core/theme/command_theme.dart';
import '../../domain/models/project.dart';
import '../../domain/models/project_status.dart';
import '../state/project_manager_controller.dart';
import '../widgets/command_header.dart';
import '../widgets/intelligence_banner.dart';
import '../widgets/project_pulse_card.dart';
import '../widgets/project_matrix_row.dart';
import '../widgets/empty_state_view.dart';
import 'project_detail_screen.dart';
import 'project_editor_dialog.dart';
import 'settings_screen.dart';
import 'github_import_dialog.dart';

class DashboardScreen extends StatelessWidget {
  final ProjectManagerController controller;

  const DashboardScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: CommandColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Top Command Header
                CommandHeader(
                  controller: controller,
                  onNewProject: () => _openNewProjectDialog(context),
                  onOpenSettings: () => _openSettingsDialog(context),
                  onImportGitHub: () => _openGitHubImportDialog(context),
                ),

                // Intelligence Radar Panel
                if (controller.showIntelligenceRadar && controller.observations.isNotEmpty)
                  IntelligenceRadarPanel(
                    observations: controller.observations,
                    onDismiss: () => controller.toggleIntelligenceRadar(),
                    onSelectProject: (id) => _navigateToDetail(context, id),
                  ),

                // Portfolio Display Area
                Expanded(
                  child: controller.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: CommandColors.signalIce,
                            strokeWidth: 2,
                          ),
                        )
                      : _buildPortfolioContent(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortfolioContent(BuildContext context) {
    final filtered = controller.filteredProjects;

    if (filtered.isEmpty) {
      return Center(
        child: EmptyStateView(
          icon: Icons.search_off_rounded,
          title: 'No matching projects found',
          subtitle: controller.searchQuery.isNotEmpty
              ? 'No projects match query "${controller.searchQuery}". Clear query to view portfolio.'
              : 'No projects match the selected filter.',
          action: controller.searchQuery.isNotEmpty || controller.filter != PortfolioFilter.all
              ? OutlinedButton(
                  onPressed: () {
                    controller.setSearchQuery('');
                    controller.setFilter(PortfolioFilter.all);
                  },
                  child: const Text('Reset Filters'),
                )
              : null,
        ),
      );
    }

    if (controller.viewMode == PortfolioViewMode.flightDeckTable) {
      return _buildFlightDeckTableView(context, filtered);
    } else {
      return _buildPulseGridView(context, filtered);
    }
  }

  Widget _buildFlightDeckTableView(BuildContext context, List<Project> projects) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: CommandColors.surfaceBase,
                border: Border(
                  bottom: BorderSide(color: CommandColors.borderSubtle, width: 1),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 180,
                    child: Text(
                      'PROJECT',
                      style: TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: CommandColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  SizedBox(
                    width: 120,
                    child: Text(
                      'HUMAN STATE',
                      style: TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: CommandColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    child: Text(
                      'OBSERVED SIGNAL',
                      style: TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: CommandColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  SizedBox(
                    width: 180,
                    child: Text(
                      'CURRENT MILESTONE',
                      style: TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: CommandColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'NEXT ACTION',
                      style: TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: CommandColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  SizedBox(
                    width: 130,
                    child: Text(
                      'TELEMETRY',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: CommandColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  SizedBox(width: 36),
                ],
              ),
            ),

            // Table Rows
            Expanded(
              child: ListView.builder(
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final p = projects[index];
                  return ProjectMatrixRow(
                    project: p,
                    onTap: () => _navigateToDetail(context, p.id),
                    onQuickStatusChange: (status) =>
                        controller.updateHumanStatus(p.id, status),
                  );
                },
              ),
            ),
          ],
        );

        if (constraints.maxWidth < 950) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 950,
              child: content,
            ),
          );
        }
        return content;
      },
    );
  }

  Widget _buildPulseGridView(BuildContext context, List<Project> projects) {
    // If user filtered or searched, show a single clean grid
    final isFiltered =
        controller.filter != PortfolioFilter.all || controller.searchQuery.isNotEmpty;

    if (isFiltered) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = _calcCrossAxisCount(constraints.maxWidth);
          final aspectRatio = _calcChildAspectRatio(constraints.maxWidth);
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final p = projects[index];
              return ProjectPulseCard(
                project: p,
                onTap: () => _navigateToDetail(context, p.id),
                onQuickStatusChange: (status) =>
                    controller.updateHumanStatus(p.id, status),
              );
            },
          );
        },
      );
    }

    // Default portfolio dashboard: Meaningful grouping by State & Momentum
    final active = projects.where((p) => p.humanStatus == ProjectHumanStatus.active).toList();
    final inDev = projects.where((p) => p.humanStatus == ProjectHumanStatus.inDevelopment).toList();
    final planningAndIdeas = projects
        .where((p) =>
            p.humanStatus == ProjectHumanStatus.planning ||
            p.humanStatus == ProjectHumanStatus.idea)
        .toList();
    final pausedAndMaint = projects
        .where((p) =>
            p.humanStatus == ProjectHumanStatus.paused ||
            p.humanStatus == ProjectHumanStatus.maintenance)
        .toList();
    final unset = projects.where((p) => p.humanStatus == null).toList();
    final completed = projects
        .where((p) =>
            p.humanStatus == ProjectHumanStatus.complete ||
            p.humanStatus == ProjectHumanStatus.archived)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (active.isNotEmpty) ...[
            _buildSectionHeader('ACTIVE MOMENTUM', active.length, CommandColors.signalEmerald),
            const SizedBox(height: 12),
            _buildGridSection(context, active),
            const SizedBox(height: 28),
          ],
          if (inDev.isNotEmpty) ...[
            _buildSectionHeader('IN DEVELOPMENT', inDev.length, CommandColors.signalIce),
            const SizedBox(height: 12),
            _buildGridSection(context, inDev),
            const SizedBox(height: 28),
          ],
          if (planningAndIdeas.isNotEmpty) ...[
            _buildSectionHeader('PLANNING & IDEAS', planningAndIdeas.length, const Color(0xFF60A5FA)),
            const SizedBox(height: 12),
            _buildGridSection(context, planningAndIdeas),
            const SizedBox(height: 28),
          ],
          if (pausedAndMaint.isNotEmpty) ...[
            _buildSectionHeader('PAUSED & MAINTENANCE', pausedAndMaint.length, CommandColors.signalAmber),
            const SizedBox(height: 12),
            _buildGridSection(context, pausedAndMaint),
            const SizedBox(height: 28),
          ],
          if (unset.isNotEmpty) ...[
            _buildSectionHeader('STATUS NOT SET', unset.length, CommandColors.textMuted),
            const SizedBox(height: 12),
            _buildGridSection(context, unset),
            const SizedBox(height: 28),
          ],
          if (completed.isNotEmpty) ...[
            _buildSectionHeader('COMPLETED & ARCHIVED', completed.length, const Color(0xFF34D399)),
            const SizedBox(height: 12),
            _buildGridSection(context, completed),
            const SizedBox(height: 28),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color accentColor) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: CommandTheme.fontMono,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: accentColor,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: CommandColors.surfaceRaised,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: CommandColors.borderSubtle),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontFamily: CommandTheme.fontMono,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: CommandColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Divider(
            height: 1,
            color: CommandColors.borderSubtle,
          ),
        ),
      ],
    );
  }

  Widget _buildGridSection(BuildContext context, List<Project> list) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calcCrossAxisCount(constraints.maxWidth);
        final aspectRatio = _calcChildAspectRatio(constraints.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final p = list[index];
            return ProjectPulseCard(
              project: p,
              onTap: () => _navigateToDetail(context, p.id),
              onQuickStatusChange: (status) =>
                  controller.updateHumanStatus(p.id, status),
            );
          },
        );
      },
    );
  }

  int _calcCrossAxisCount(double width) {
    if (width > 1500) return 4;
    if (width > 1100) return 3;
    if (width > 750) return 2;
    return 1;
  }

  double _calcChildAspectRatio(double width) {
    if (width < 500) return 1.34;
    if (width < 750) return 1.42;
    return 1.5;
  }

  void _navigateToDetail(BuildContext context, String projectId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(
          projectId: projectId,
          controller: controller,
        ),
      ),
    );
  }

  void _openNewProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => ProjectEditorDialog(
        onSave: (newProj) => controller.addProject(newProj),
      ),
    );
  }

  void _openSettingsDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(controller: controller),
      ),
    );
  }

  void _openGitHubImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => GitHubImportDialog(controller: controller),
    );
  }
}
