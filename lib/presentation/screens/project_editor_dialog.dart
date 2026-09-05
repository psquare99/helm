import 'package:flutter/material.dart';
import '../../core/theme/command_colors.dart';
import '../../core/theme/command_theme.dart';
import '../../domain/models/project.dart';
import '../../domain/models/project_status.dart';
import '../../domain/models/github_telemetry.dart';

class ProjectEditorDialog extends StatefulWidget {
  final Project? initialProject;
  final Function(Project project) onSave;

  const ProjectEditorDialog({
    super.key,
    this.initialProject,
    required this.onSave,
  });

  @override
  State<ProjectEditorDialog> createState() => _ProjectEditorDialogState();
}

class _ProjectEditorDialogState extends State<ProjectEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _localPathController;
  late TextEditingController _milestoneController;
  late TextEditingController _nextActionController;
  late TextEditingController _githubOwnerController;
  late TextEditingController _githubRepoController;

  late ProjectType _type;
  ProjectHumanStatus? _humanStatus;
  late ProjectPriority _priority;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProject;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _localPathController = TextEditingController(text: p?.localPath ?? '');
    _milestoneController = TextEditingController(text: p?.currentMilestone ?? '');
    _nextActionController = TextEditingController(text: p?.nextAction ?? '');
    _githubOwnerController = TextEditingController(text: p?.github?.owner ?? '');
    _githubRepoController = TextEditingController(text: p?.github?.repo ?? '');

    _type = p?.type ?? ProjectType.flutterApp;
    _humanStatus = p?.humanStatus;
    _priority = p?.priority ?? ProjectPriority.none;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _localPathController.dispose();
    _milestoneController.dispose();
    _nextActionController.dispose();
    _githubOwnerController.dispose();
    _githubRepoController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final owner = _githubOwnerController.text.trim();
    final repo = _githubRepoController.text.trim();

    GitHubTelemetry? githubTelemetry;
    if (owner.isNotEmpty && repo.isNotEmpty) {
      if (widget.initialProject?.github != null &&
          widget.initialProject!.github!.owner == owner &&
          widget.initialProject!.github!.repo == repo) {
        githubTelemetry = widget.initialProject!.github;
      } else {
        githubTelemetry = GitHubTelemetry(
          owner: owner,
          repo: repo,
          repoUrl: 'https://github.com/$owner/$repo',
          lastFetchedAt: DateTime.now(),
        );
      }
    }

    final p = widget.initialProject;
    final now = DateTime.now();

    final project = Project(
      id: p?.id ?? 'proj-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      type: _type,
      localPath: _localPathController.text.trim().isEmpty ? null : _localPathController.text.trim(),
      humanStatus: _humanStatus,
      priority: _priority,
      currentMilestone: _milestoneController.text.trim().isEmpty ? null : _milestoneController.text.trim(),
      nextAction: _nextActionController.text.trim().isEmpty ? null : _nextActionController.text.trim(),
      github: githubTelemetry,
      tasks: p?.tasks ?? const [],
      milestones: p?.milestones ?? const [],
      notes: p?.notes ?? const [],
      links: p?.links ?? const [],
      createdAt: p?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSave(project);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialProject != null;

    return Dialog(
      backgroundColor: CommandColors.surfaceBase,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: CommandColors.borderSubtle),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                  const Icon(Icons.tune_rounded, size: 16, color: CommandColors.signalIce),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'PROJECT CONFIGURATION' : 'REGISTER NEW PROJECT',
                    style: const TextStyle(
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
            ),

            // Scrollable Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      _buildFieldLabel('PROJECT NAME', isRequired: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontFamily: CommandTheme.fontSans,
                          fontSize: 13,
                          color: CommandColors.textPrimary,
                        ),
                        decoration: const InputDecoration(hintText: 'e.g. Prime, Studio, WAYFINDER'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Project name is required' : null,
                      ),

                      const SizedBox(height: 16),

                      // Description
                      _buildFieldLabel('DESCRIPTION'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descController,
                        maxLines: 2,
                        style: const TextStyle(
                          fontFamily: CommandTheme.fontSans,
                          fontSize: 13,
                          color: CommandColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Purpose and scope in the P² ecosystem...',
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Type & Priority Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('PROJECT TYPE'),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<ProjectType>(
                                  initialValue: _type,
                                  dropdownColor: CommandColors.surfaceCard,
                                  style: const TextStyle(
                                    fontFamily: CommandTheme.fontMono,
                                    fontSize: 12,
                                    color: CommandColors.textPrimary,
                                  ),
                                  items: ProjectType.values.map((t) {
                                    return DropdownMenuItem(
                                      value: t,
                                      child: Row(
                                        children: [
                                          Icon(t.icon, size: 14, color: CommandColors.textSecondary),
                                          const SizedBox(width: 8),
                                          Text(t.label),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => _type = v);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('PRIORITY'),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<ProjectPriority>(
                                  initialValue: _priority,
                                  dropdownColor: CommandColors.surfaceCard,
                                  style: const TextStyle(
                                    fontFamily: CommandTheme.fontMono,
                                    fontSize: 12,
                                    color: CommandColors.textPrimary,
                                  ),
                                  items: ProjectPriority.values.map((p) {
                                    return DropdownMenuItem(
                                      value: p,
                                      child: Row(
                                        children: [
                                          Text(
                                            p.short,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: p.color,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(p.label),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => _priority = v);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Human Status (Authoritative)
                      _buildFieldLabel('HUMAN STATUS (AUTHORITATIVE)'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<ProjectHumanStatus?>(
                        initialValue: _humanStatus,
                        dropdownColor: CommandColors.surfaceCard,
                        style: const TextStyle(
                          fontFamily: CommandTheme.fontMono,
                          fontSize: 12,
                          color: CommandColors.textPrimary,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text(
                              'Status not set',
                              style: TextStyle(color: CommandColors.textMuted),
                            ),
                          ),
                          ...ProjectHumanStatus.values.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: s.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(s.label),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (v) => setState(() => _humanStatus = v),
                      ),

                      const SizedBox(height: 16),

                      // Focus & Momentum: Milestone & Next Action
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('CURRENT MILESTONE'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _milestoneController,
                                  style: const TextStyle(
                                    fontFamily: CommandTheme.fontSans,
                                    fontSize: 13,
                                    color: CommandColors.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Dashboard, v1.0 Release',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('NEXT ACTION'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nextActionController,
                                  style: const TextStyle(
                                    fontFamily: CommandTheme.fontSans,
                                    fontSize: 13,
                                    color: CommandColors.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Immediate next task to tackle',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Local Directory Path
                      _buildFieldLabel('LOCAL FILE PATH (OPTIONAL)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _localPathController,
                        style: const TextStyle(
                          fontFamily: CommandTheme.fontMono,
                          fontSize: 12,
                          color: CommandColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: r'C:\Projects\my-project',
                          prefixIcon: Icon(Icons.folder_open_rounded, size: 14),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // GitHub Telemetry Link
                      _buildFieldLabel('GITHUB REPOSITORY LINK (OPTIONAL)'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _githubOwnerController,
                              style: const TextStyle(
                                fontFamily: CommandTheme.fontMono,
                                fontSize: 12,
                                color: CommandColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Owner (e.g. psquare99)',
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '/',
                              style: TextStyle(
                                fontFamily: CommandTheme.fontMono,
                                fontSize: 16,
                                color: CommandColors.textMuted,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _githubRepoController,
                              style: const TextStyle(
                                fontFamily: CommandTheme.fontMono,
                                fontSize: 12,
                                color: CommandColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Repo (e.g. prime)',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Modal Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: CommandColors.surfaceBase,
                border: Border(
                  top: BorderSide(color: CommandColors.borderSubtle),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      side: const BorderSide(color: CommandColors.borderMedium),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 11,
                        color: CommandColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: CommandColors.textPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(
                      isEdit ? 'SAVE CHANGES' : 'CREATE PROJECT',
                      style: const TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 11,
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

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: CommandTheme.fontMono,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: CommandColors.textMuted,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(color: CommandColors.signalCoral, fontSize: 11),
          ),
        ],
      ],
    );
  }
}
