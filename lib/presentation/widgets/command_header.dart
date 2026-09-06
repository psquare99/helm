import 'package:flutter/material.dart';
import '../../core/theme/command_colors.dart';
import '../../core/theme/command_theme.dart';
import '../state/project_manager_controller.dart';

class CommandHeader extends StatelessWidget {
  final ProjectManagerController controller;
  final VoidCallback onNewProject;
  final VoidCallback onOpenSettings;
  final VoidCallback onImportGitHub;

  const CommandHeader({
    super.key,
    required this.controller,
    required this.onNewProject,
    required this.onOpenSettings,
    required this.onImportGitHub,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 820;

        return Container(
          decoration: const BoxDecoration(
            color: CommandColors.surfaceBase,
            border: Border(
              bottom: BorderSide(color: CommandColors.borderSubtle, width: 1),
            ),
          ),
          child: isMobile ? _buildMobileHeader(context) : _buildDesktopHeader(context),
        );
      },
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return Column(
      children: [
        // Primary App Bar & Telemetry Counters
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Row(
            children: [
              _buildBrand(),
              const SizedBox(width: 24),
              Expanded(
                child: _buildTelemetryBar(),
              ),
              const SizedBox(width: 14),
              _buildGitHubImportButton(),
              const SizedBox(width: 8),
              _buildSyncButton(),
              const SizedBox(width: 8),
              _buildRadarButton(),
              const SizedBox(width: 8),
              _buildSettingsButton(),
              const SizedBox(width: 8),
              _buildNewProjectButton(),
            ],
          ),
        ),
        const Divider(height: 1, color: CommandColors.borderSubtle),
        // Filters & Search & View Switcher Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 240,
                height: 32,
                child: _buildSearchField(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterChips(),
              ),
              const SizedBox(width: 12),
              _buildViewModeSwitcher(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Column(
      children: [
        // Mobile Row 1: Brand & Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Row(
            children: [
              _buildBrand(),
              const Spacer(),
              _buildGitHubImportIconButton(),
              const SizedBox(width: 4),
              _buildSyncIconButton(),
              const SizedBox(width: 4),
              _buildRadarButton(),
              const SizedBox(width: 4),
              _buildSettingsButton(),
              const SizedBox(width: 6),
              _buildNewProjectIconButton(),
            ],
          ),
        ),
        const Divider(height: 1, color: CommandColors.borderSubtle),
        // Mobile Row 2: Telemetry Counters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: _buildTelemetryBar(),
        ),
        const Divider(height: 1, color: CommandColors.borderSubtle),
        // Mobile Row 3: Search Bar & View Mode Switcher
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: _buildSearchField(),
                ),
              ),
              const SizedBox(width: 8),
              _buildViewModeSwitcher(),
            ],
          ),
        ),
        // Mobile Row 4: Filter Chips
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: _buildFilterChips(),
        ),
      ],
    );
  }

  Widget _buildBrand() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: CommandColors.signalEmerald,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'PROJECT MANAGER',
          style: TextStyle(
            fontFamily: CommandTheme.fontMono,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: CommandColors.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
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
      ],
    );
  }

  Widget _buildTelemetryBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildMetricPill(
            label: 'TOTAL',
            value: '${controller.totalProjectsCount}',
            color: CommandColors.textPrimary,
          ),
          const SizedBox(width: 8),
          _buildMetricPill(
            label: 'ACTIVE',
            value: '${controller.activeProjectsCount}',
            color: CommandColors.signalEmerald,
          ),
          const SizedBox(width: 8),
          _buildMetricPill(
            label: 'CONNECTED REPOS',
            value: '${controller.connectedReposCount}',
            color: CommandColors.signalIce,
          ),
          const SizedBox(width: 8),
          if (controller.missingNextActionsCount > 0)
            _buildMetricPill(
              label: 'ACTION REQUIRED',
              value: '${controller.missingNextActionsCount}',
              color: CommandColors.signalAmber,
            ),
        ],
      ),
    );
  }

  Widget _buildGitHubImportButton() {
    return OutlinedButton.icon(
      onPressed: onImportGitHub,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        side: const BorderSide(color: CommandColors.borderSubtle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        backgroundColor: CommandColors.surfaceBase,
      ),
      icon: const Icon(
        Icons.hub_rounded,
        size: 14,
        color: CommandColors.signalIce,
      ),
      label: const Text(
        'PULL REPOS',
        style: TextStyle(
          fontFamily: CommandTheme.fontMono,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: CommandColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildGitHubImportIconButton() {
    return IconButton(
      tooltip: 'Pull repositories from GitHub',
      onPressed: onImportGitHub,
      icon: const Icon(
        Icons.hub_rounded,
        size: 18,
        color: CommandColors.signalIce,
      ),
      style: IconButton.styleFrom(
        backgroundColor: CommandColors.surfaceBase,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: CommandColors.borderSubtle),
        ),
      ),
    );
  }

  Widget _buildSyncButton() {
    return OutlinedButton.icon(
      onPressed: controller.isSyncingTelemetry
          ? null
          : () => controller.refreshAllTelemetry(),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: const BorderSide(color: CommandColors.borderSubtle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        backgroundColor: CommandColors.surfaceBase,
      ),
      icon: controller.isSyncingTelemetry
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CommandColors.signalIce,
              ),
            )
          : const Icon(
              Icons.sync_rounded,
              size: 14,
              color: CommandColors.signalIce,
            ),
      label: Text(
        controller.isSyncingTelemetry ? 'SYNCING...' : 'SYNC SIGNALS',
        style: const TextStyle(
          fontFamily: CommandTheme.fontMono,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: CommandColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSyncIconButton() {
    return IconButton(
      tooltip: 'Sync observed GitHub signals',
      onPressed: controller.isSyncingTelemetry
          ? null
          : () => controller.refreshAllTelemetry(),
      icon: controller.isSyncingTelemetry
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CommandColors.signalIce,
              ),
            )
          : const Icon(
              Icons.sync_rounded,
              size: 18,
              color: CommandColors.signalIce,
            ),
      style: IconButton.styleFrom(
        backgroundColor: CommandColors.surfaceBase,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: CommandColors.borderSubtle),
        ),
      ),
    );
  }

  Widget _buildRadarButton() {
    return IconButton(
      tooltip: 'Portfolio Intelligence Radar',
      onPressed: () => controller.toggleIntelligenceRadar(),
      icon: Icon(
        Icons.radar_rounded,
        size: 18,
        color: controller.showIntelligenceRadar
            ? CommandColors.signalIce
            : CommandColors.textMuted,
      ),
      style: IconButton.styleFrom(
        backgroundColor: controller.showIntelligenceRadar
            ? CommandColors.signalIceSoft
            : CommandColors.surfaceBase,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: CommandColors.borderSubtle),
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return IconButton(
      tooltip: 'Settings & Integrations',
      onPressed: onOpenSettings,
      icon: const Icon(
        Icons.tune_rounded,
        size: 18,
        color: CommandColors.textSecondary,
      ),
      style: IconButton.styleFrom(
        backgroundColor: CommandColors.surfaceBase,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: CommandColors.borderSubtle),
        ),
      ),
    );
  }

  Widget _buildNewProjectButton() {
    return FilledButton.icon(
      onPressed: onNewProject,
      style: FilledButton.styleFrom(
        backgroundColor: CommandColors.textPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      icon: const Icon(Icons.add_rounded, size: 16),
      label: const Text(
        'NEW PROJECT',
        style: TextStyle(
          fontFamily: CommandTheme.fontMono,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildNewProjectIconButton() {
    return FilledButton(
      onPressed: onNewProject,
      style: FilledButton.styleFrom(
        backgroundColor: CommandColors.textPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(34, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: const Icon(Icons.add_rounded, size: 16),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (val) => controller.setSearchQuery(val),
      style: const TextStyle(
        fontFamily: CommandTheme.fontSans,
        fontSize: 12.5,
        color: CommandColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Filter portfolio...',
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 14,
          color: CommandColors.textMuted,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 32),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
        filled: true,
        fillColor: CommandColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: CommandColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: CommandColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: CommandColors.signalIce),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: PortfolioFilter.values.map((f) {
          final isSelected = controller.filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => controller.setFilter(f),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? CommandColors.surfaceRaised
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? CommandColors.borderMedium
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  f.label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? CommandColors.textPrimary
                        : CommandColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildViewModeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: CommandColors.surfaceBase,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: CommandColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: PortfolioViewMode.values.map((mode) {
          final isSelected = controller.viewMode == mode;
          return InkWell(
            onTap: () => controller.setViewMode(mode),
            borderRadius: BorderRadius.circular(3),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? CommandColors.surfaceRaised
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                mode.icon,
                size: 14,
                color: isSelected
                    ? CommandColors.signalIce
                    : CommandColors.textMuted,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CommandColors.background,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: CommandColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: CommandTheme.fontMono,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: CommandColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: CommandTheme.fontMono,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
