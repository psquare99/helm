import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/command_colors.dart';
import '../../core/theme/command_theme.dart';
import '../state/project_manager_controller.dart';
import '../widgets/github_device_login_dialog.dart';

class GitHubImportDialog extends StatefulWidget {
  final ProjectManagerController controller;

  const GitHubImportDialog({super.key, required this.controller});

  @override
  State<GitHubImportDialog> createState() => _GitHubImportDialogState();
}

class _GitHubImportDialogState extends State<GitHubImportDialog> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedRepoFullNames = {};
  bool _isImporting = false;
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    if (widget.controller.gitHubToken != null &&
        widget.controller.gitHubToken!.isNotEmpty) {
      widget.controller.fetchUserRepositories();
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _isRepoAlreadyImported(String fullName) {
    return widget.controller.projects.any((p) =>
        p.github?.fullName.toLowerCase() == fullName.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Dialog(
      backgroundColor: CommandColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: CommandColors.borderSubtle),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: controller.gitHubToken == null || controller.gitHubToken!.isEmpty
            ? _buildConnectAccountView(context)
            : _buildRepositorySelectorView(context),
      ),
    );
  }

  Widget _buildConnectAccountView(BuildContext context) {
    final isAuthenticating = widget.controller.isAuthenticatingGitHub;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CommandColors.signalIceSoft,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: CommandColors.signalIceBorder),
                ),
                child: const Icon(Icons.hub_rounded, size: 20, color: CommandColors.signalIce),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONNECT GITHUB ACCOUNT',
                      style: TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: CommandColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Authenticate to pull and monitor your real repositories',
                      style: TextStyle(
                        fontFamily: CommandTheme.fontSans,
                        fontSize: 12,
                        color: CommandColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isAuthenticating
                  ? null
                  : () async {
                      final success = await GitHubDeviceLoginDialog.show(context, widget.controller);
                      if (success == true && mounted) {
                        setState(() {});
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
          const Text(
            'Personal Access Token (classic or fine-grained)',
            style: TextStyle(
              fontFamily: CommandTheme.fontMono,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: CommandColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _tokenController,
            obscureText: true,
            style: const TextStyle(
              fontFamily: CommandTheme.fontMono,
              fontSize: 12,
              color: CommandColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx or github_pat_xxxx',
              filled: true,
              fillColor: CommandColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              launchUrl(
                Uri.parse('https://github.com/settings/tokens/new?scopes=repo,read:org,read:user&description=P2_Project_Manager'),
                mode: LaunchMode.externalApplication,
              );
            },
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.open_in_new_rounded, size: 13, color: CommandColors.signalIce),
                  SizedBox(width: 6),
                  Text(
                    'Generate new token with "repo" scope on GitHub',
                    style: TextStyle(
                      fontFamily: CommandTheme.fontSans,
                      fontSize: 12,
                      color: CommandColors.signalIce,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: isAuthenticating ? null : _handleLogin,
                style: FilledButton.styleFrom(
                  backgroundColor: CommandColors.textPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: isAuthenticating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'CONNECT & FETCH',
                        style: TextStyle(
                          fontFamily: CommandTheme.fontMono,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;

    final success = await widget.controller.loginWithGitHubToken(token);
    if (success) {
      await widget.controller.fetchUserRepositories();
      if (mounted) setState(() {});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid GitHub token or authentication failed.'),
            backgroundColor: CommandColors.signalCoral,
          ),
        );
      }
    }
  }

  Widget _buildRepositorySelectorView(BuildContext context) {
    final controller = widget.controller;
    final user = controller.currentUser;
    final repos = controller.discoveredRepos;

    final filteredRepos = repos.where((r) {
      if (_searchFilter.trim().isEmpty) return true;
      final q = _searchFilter.toLowerCase().trim();
      return r.name.toLowerCase().contains(q) ||
          (r.description?.toLowerCase().contains(q) ?? false) ||
          (r.language?.toLowerCase().contains(q) ?? false);
    }).toList();

    final unimportedRepos = filteredRepos
        .where((r) => !_isRepoAlreadyImported(r.fullName))
        .toList();

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
          decoration: const BoxDecoration(
            color: CommandColors.surfaceBase,
            border: Border(bottom: BorderSide(color: CommandColors.borderSubtle)),
            borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
          ),
          child: Row(
            children: [
              if (user?.avatarUrl.isNotEmpty ?? false)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    user!.avatarUrl,
                    width: 32,
                    height: 32,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_circle, size: 32),
                  ),
                )
              else
                const Icon(Icons.hub_rounded, size: 28, color: CommandColors.signalIce),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PULL FROM GITHUB: ${user?.login.toUpperCase() ?? 'REPOSITORIES'}',
                      style: const TextStyle(
                        fontFamily: CommandTheme.fontMono,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: CommandColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${repos.length} repositories available • Select projects to track',
                      style: const TextStyle(
                        fontFamily: CommandTheme.fontSans,
                        fontSize: 11.5,
                        color: CommandColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh repositories',
                onPressed: controller.isFetchingRepos
                    ? null
                    : () => controller.fetchUserRepositories(),
                icon: controller.isFetchingRepos
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: CommandColors.signalIce),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ],
          ),
        ),

        // Search & Quick Select Toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchFilter = v),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Search repositories...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 14),
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
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: unimportedRepos.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _selectedRepoFullNames
                              .addAll(unimportedRepos.map((r) => r.fullName));
                        });
                      },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: const BorderSide(color: CommandColors.borderSubtle),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text(
                  'SELECT ALL NEW',
                  style: TextStyle(
                    fontFamily: CommandTheme.fontMono,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (_selectedRepoFullNames.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() => _selectedRepoFullNames.clear());
                  },
                  child: const Text('Clear', style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
        ),

        const Divider(height: 1, color: CommandColors.borderSubtle),

        // Repositories List
        Expanded(
          child: controller.isFetchingRepos
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(strokeWidth: 2, color: CommandColors.signalIce),
                      SizedBox(height: 14),
                      Text(
                        'Fetching repositories from GitHub...',
                        style: TextStyle(
                          fontFamily: CommandTheme.fontMono,
                          fontSize: 12,
                          color: CommandColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : filteredRepos.isEmpty
                  ? Center(
                      child: Text(
                        _searchFilter.isNotEmpty
                            ? 'No repositories match "$_searchFilter"'
                            : 'No repositories found.',
                        style: const TextStyle(
                          fontFamily: CommandTheme.fontMono,
                          fontSize: 12,
                          color: CommandColors.textMuted,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: filteredRepos.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: CommandColors.borderSubtle),
                      itemBuilder: (context, index) {
                        final repo = filteredRepos[index];
                        final isImported = _isRepoAlreadyImported(repo.fullName);
                        final isSelected = _selectedRepoFullNames.contains(repo.fullName);

                        return InkWell(
                          onTap: isImported
                              ? null
                              : () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedRepoFullNames.remove(repo.fullName);
                                    } else {
                                      _selectedRepoFullNames.add(repo.fullName);
                                    }
                                  });
                                },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            child: Row(
                              children: [
                                if (isImported)
                                  const Icon(Icons.check_circle_rounded,
                                      size: 20, color: CommandColors.signalEmerald)
                                else
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selectedRepoFullNames.add(repo.fullName);
                                        } else {
                                          _selectedRepoFullNames.remove(repo.fullName);
                                        }
                                      });
                                    },
                                  ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              repo.name,
                                              style: TextStyle(
                                                fontFamily: CommandTheme.fontSans,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: isImported
                                                    ? CommandColors.textMuted
                                                    : CommandColors.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (repo.isPrivate)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: CommandColors.surfaceRaised,
                                                borderRadius: BorderRadius.circular(2),
                                                border: Border.all(color: CommandColors.borderSubtle),
                                              ),
                                              child: const Text(
                                                'PRIVATE',
                                                style: TextStyle(
                                                  fontFamily: CommandTheme.fontMono,
                                                  fontSize: 9,
                                                  color: CommandColors.textMuted,
                                                ),
                                              ),
                                            ),
                                          if (repo.language != null) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: CommandColors.signalIceSoft,
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                              child: Text(
                                                repo.language!,
                                                style: const TextStyle(
                                                  fontFamily: CommandTheme.fontMono,
                                                  fontSize: 9.5,
                                                  color: CommandColors.signalIce,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                          if (repo.stargazersCount > 0) ...[
                                            const SizedBox(width: 6),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.star_rounded,
                                                    size: 12, color: CommandColors.signalAmber),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${repo.stargazersCount}',
                                                  style: const TextStyle(
                                                    fontFamily: CommandTheme.fontMono,
                                                    fontSize: 10,
                                                    color: CommandColors.textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (repo.description != null &&
                                          repo.description!.trim().isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          repo.description!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: CommandTheme.fontSans,
                                            fontSize: 11.5,
                                            color: CommandColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isImported)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: CommandColors.signalEmeraldSoft,
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(color: CommandColors.signalEmeraldBorder),
                                    ),
                                    child: const Text(
                                      'TRACKED',
                                      style: TextStyle(
                                        fontFamily: CommandTheme.fontMono,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: CommandColors.signalEmerald,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),

        const Divider(height: 1, color: CommandColors.borderSubtle),

        // Footer Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: Row(
            children: [
              Text(
                '${_selectedRepoFullNames.length} selected',
                style: const TextStyle(
                  fontFamily: CommandTheme.fontMono,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: CommandColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: (_selectedRepoFullNames.isEmpty || _isImporting)
                    ? null
                    : _performImport,
                style: FilledButton.styleFrom(
                  backgroundColor: CommandColors.textPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: _isImporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'IMPORT ${_selectedRepoFullNames.length} PROJECTS',
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
    );
  }

  Future<void> _performImport() async {
    setState(() => _isImporting = true);

    final selected = widget.controller.discoveredRepos
        .where((r) => _selectedRepoFullNames.contains(r.fullName))
        .toList();

    final count = await widget.controller.importGitHubRepositories(selected);

    if (mounted) {
      setState(() => _isImporting = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully imported $count project${count == 1 ? '' : 's'} into portfolio.'),
          backgroundColor: CommandColors.signalEmerald,
        ),
      );
    }
  }
}
