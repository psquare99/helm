import 'package:flutter/material.dart';
import '../../core/theme/command_colors.dart';
import '../../core/theme/command_theme.dart';
import '../../domain/models/project_intelligence.dart';

class IntelligenceRadarPanel extends StatelessWidget {
  final List<ProjectObservation> observations;
  final VoidCallback onDismiss;
  final Function(String projectId)? onSelectProject;

  const IntelligenceRadarPanel({
    super.key,
    required this.observations,
    required this.onDismiss,
    this.onSelectProject,
  });

  @override
  Widget build(BuildContext context) {
    if (observations.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: BoxDecoration(
        color: CommandColors.surfaceBase,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: CommandColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: CommandColors.surfaceRaised,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
              border: Border(
                bottom: BorderSide(color: CommandColors.borderSubtle),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: CommandColors.signalIce,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'SYSTEM RADAR // PORTFOLIO INTELLIGENCE',
                  style: TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: CommandColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${observations.length} SIGNALS OBSERVED',
                  style: const TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 10,
                    color: CommandColors.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: onDismiss,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: CommandColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Observation Items
          Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                final itemsToShow = observations.take(4).toList();

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: itemsToShow
                        .map((obs) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                child: _buildObservationCard(context, obs),
                              ),
                            ))
                        .toList(),
                  );
                } else {
                  return Column(
                    children: itemsToShow
                        .map((obs) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildObservationCard(context, obs),
                            ))
                        .toList(),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObservationCard(BuildContext context, ProjectObservation obs) {
    return InkWell(
      onTap: obs.projectId != null ? () => onSelectProject?.call(obs.projectId!) : null,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: CommandColors.background,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: obs.type == ObservationType.recommendation
                ? CommandColors.signalViolet.withValues(alpha: 0.3)
                : CommandColors.borderSubtle,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(obs.type.icon, size: 14, color: obs.type.color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    obs.title,
                    style: const TextStyle(
                      fontFamily: CommandTheme.fontMono,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: CommandColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              obs.description,
              style: const TextStyle(
                fontFamily: CommandTheme.fontSans,
                fontSize: 11.5,
                color: CommandColors.textSecondary,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (obs.actionableHint != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CommandColors.surfaceBase,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: CommandColors.borderSubtle),
                ),
                child: Text(
                  obs.actionableHint!,
                  style: TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: obs.type.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
