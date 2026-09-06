import 'package:flutter/material.dart';
import '../../domain/models/project.dart';
import '../../domain/models/project_status.dart';
import '../../domain/models/project_task.dart';
import '../../domain/models/project_milestone.dart';
import '../../domain/models/project_note.dart';
import '../../domain/models/project_intelligence.dart';
import '../../domain/models/github_telemetry.dart';
import '../../domain/models/github_user.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/services/github_service.dart';
import '../../data/services/local_git_service.dart';
import '../../data/services/intelligence_service.dart';

enum PortfolioFilter {
  all(label: 'All Projects'),
  active(label: 'Active Momentum'),
  inDevelopment(label: 'In Development'),
  planning(label: 'Planning & Ideas'),
  paused(label: 'Paused'),
  complete(label: 'Completed'),
  needsAttention(label: 'Needs Attention');

  final String label;
  const PortfolioFilter({required this.label});
}

enum PortfolioViewMode {
  simpleGrid(label: 'Simple Cards', icon: Icons.view_agenda_outlined),
  pulseGrid(label: 'Pulse Cards', icon: Icons.grid_view_rounded),
  flightDeckTable(label: 'Flight Deck Table', icon: Icons.table_rows_rounded);

  final String label;
  final IconData icon;
  const PortfolioViewMode({required this.label, required this.icon});
}

class ProjectManagerController extends ChangeNotifier {
  final ProjectRepository _repository;
  final GitHubService _gitHubService;
  final LocalGitService _localGitService;
  final IntelligenceService _intelligenceService;

  ProjectManagerController({
    ProjectRepository? repository,
    GitHubService? gitHubService,
    LocalGitService? localGitService,
    IntelligenceService? intelligenceService,
  })  : _repository = repository ?? LocalFileProjectRepository(),
        _gitHubService = gitHubService ?? HttpGitHubService(),
        _localGitService = localGitService ?? LocalGitService(),
        _intelligenceService = intelligenceService ?? IntelligenceService();

  List<Project> _projects = [];
  bool _isLoading = true;
  bool _isSyncingTelemetry = false;
  String? _gitHubToken;
  PortfolioFilter _filter = PortfolioFilter.all;
  PortfolioViewMode _viewMode = PortfolioViewMode.pulseGrid;
  String _searchQuery = '';
  bool _showIntelligenceRadar = true;

  // GitHub User & Onboarding State
  bool _hasCompletedOnboarding = true;
  GitHubUser? _currentUser;
  bool _isAuthenticatingGitHub = false;
  Map<String, dynamic>? _rateLimitInfo;
  List<GitHubRepositoryInfo> _discoveredRepos = [];
  bool _isFetchingRepos = false;
  String _storagePath = '';

  // Getters
  ProjectRepository get repository => _repository;
  GitHubService get gitHubService => _gitHubService;
  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  bool get isSyncingTelemetry => _isSyncingTelemetry;
  String? get gitHubToken => _gitHubToken;
  PortfolioFilter get filter => _filter;
  PortfolioViewMode get viewMode => _viewMode;
  String get searchQuery => _searchQuery;
  bool get showIntelligenceRadar => _showIntelligenceRadar;

  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  GitHubUser? get currentUser => _currentUser;
  bool get isAuthenticatingGitHub => _isAuthenticatingGitHub;
  Map<String, dynamic>? get rateLimitInfo => _rateLimitInfo;
  List<GitHubRepositoryInfo> get discoveredRepos => _discoveredRepos;
  bool get isFetchingRepos => _isFetchingRepos;
  String get storagePath => _storagePath;

  List<ProjectObservation> get observations =>
      _intelligenceService.generateObservations(_projects);

  // Filtered projects
  List<Project> get filteredProjects {
    var list = _projects;

    // Search query filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((p) {
        final nameMatch = p.name.toLowerCase().contains(q);
        final descMatch = p.description?.toLowerCase().contains(q) ?? false;
        final nextActionMatch = p.nextAction?.toLowerCase().contains(q) ?? false;
        final milestoneMatch = p.currentMilestone?.toLowerCase().contains(q) ?? false;
        final repoMatch = p.github?.fullName.toLowerCase().contains(q) ?? false;
        return nameMatch || descMatch || nextActionMatch || milestoneMatch || repoMatch;
      }).toList();
    }

    // Portfolio state filter
    switch (_filter) {
      case PortfolioFilter.all:
        return list;
      case PortfolioFilter.active:
        return list
            .where((p) =>
                p.humanStatus == ProjectHumanStatus.active ||
                p.effectiveObservedActivity == ObservedActivity.veryActive ||
                p.effectiveObservedActivity == ObservedActivity.active)
            .toList();
      case PortfolioFilter.inDevelopment:
        return list
            .where((p) => p.humanStatus == ProjectHumanStatus.inDevelopment)
            .toList();
      case PortfolioFilter.planning:
        return list
            .where((p) =>
                p.humanStatus == ProjectHumanStatus.planning ||
                p.humanStatus == ProjectHumanStatus.idea)
            .toList();
      case PortfolioFilter.paused:
        return list
            .where((p) =>
                p.humanStatus == ProjectHumanStatus.paused ||
                p.humanStatus == ProjectHumanStatus.maintenance)
            .toList();
      case PortfolioFilter.complete:
        return list
            .where((p) =>
                p.humanStatus == ProjectHumanStatus.complete ||
                p.humanStatus == ProjectHumanStatus.archived)
            .toList();
      case PortfolioFilter.needsAttention:
        return list.where((p) => p.needsAttention).toList();
    }
  }

  // Portfolio metrics
  int get totalProjectsCount => _projects.length;
  int get activeProjectsCount =>
      _projects.where((p) => p.humanStatus == ProjectHumanStatus.active).length;
  int get connectedReposCount =>
      _projects.where((p) => p.github != null).length;
  int get missingNextActionsCount =>
      _projects.where((p) => !p.hasNextAction).length;
  int get totalPendingTasksCount =>
      _projects.fold(0, (sum, p) => sum + p.pendingTasksCount);

  // Initialization
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _hasCompletedOnboarding = await _repository.hasCompletedOnboarding();
      _storagePath = await _repository.getStorageDirectoryPath();
      _gitHubToken = await _repository.getGitHubToken();

      if (_gitHubToken != null && _gitHubToken!.trim().isNotEmpty) {
        _currentUser = await _gitHubService.getAuthenticatedUser(_gitHubToken!);
        _rateLimitInfo = await _gitHubService.getRateLimit(_gitHubToken);
      }

      final settings = await _repository.loadSettings();
      final savedMode = settings['default_view_mode'] as String?;
      if (savedMode != null) {
        _viewMode = PortfolioViewMode.values.firstWhere(
          (m) => m.name == savedMode,
          orElse: () => PortfolioViewMode.simpleGrid,
        );
      }

      _projects = await _repository.loadProjects();

      // Proactively sync telemetry on startup for connected repositories
      await _syncLocalAndRemoteTelemetry(quiet: true);
    } catch (e) {
      debugPrint('Initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(PortfolioFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setViewMode(PortfolioViewMode mode) async {
    _viewMode = mode;
    notifyListeners();
    try {
      final settings = await _repository.loadSettings();
      settings['default_view_mode'] = mode.name;
      await _repository.saveSettings(settings);
    } catch (_) {}
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleIntelligenceRadar() {
    _showIntelligenceRadar = !_showIntelligenceRadar;
    notifyListeners();
  }

  // Telemetry Sync
  Future<void> refreshAllTelemetry() async {
    _isSyncingTelemetry = true;
    notifyListeners();

    await _syncLocalAndRemoteTelemetry(quiet: false);

    _isSyncingTelemetry = false;
    notifyListeners();
  }

  Future<void> _syncLocalAndRemoteTelemetry({bool quiet = false}) async {
    final updatedList = <Project>[];

    for (final project in _projects) {
      Project current = project;

      // 1. If local path exists, check local git repository
      if (current.localPath != null && current.localPath!.isNotEmpty) {
        final isGit = await _localGitService.isGitRepository(current.localPath!);
        if (isGit) {
          final localCommits = await _localGitService.getRecentCommits(current.localPath!);
          if (localCommits.isNotEmpty && current.github == null) {
            // Found local git with no remote configured yet
            final remoteUrl = await _localGitService.getRemoteUrl(current.localPath!);
            final branch = await _localGitService.getCurrentBranch(current.localPath!) ?? 'main';
            String owner = '';
            String repo = current.name.toLowerCase().replaceAll(' ', '-');

            if (remoteUrl != null && remoteUrl.contains('github.com')) {
              final parsed = _parseGitHubUrl(remoteUrl);
              if (parsed != null) {
                owner = parsed.$1;
                repo = parsed.$2;
              }
            }

            final top = localCommits.first;
            final now = DateTime.now();
            final commitsThisWeek = localCommits
                .where((c) => now.difference(c.date).inDays <= 7)
                .length;
            final commitsThisMonth = localCommits
                .where((c) => now.difference(c.date).inDays <= 30)
                .length;

            current = current.copyWith(
              github: GitHubTelemetry(
                owner: owner,
                repo: repo,
                repoUrl: remoteUrl,
                defaultBranch: branch,
                latestCommitSha: top.sha,
                latestCommitMessage: top.message,
                latestCommitAuthor: top.author,
                latestCommitDate: top.date,
                recentCommitsThisWeek: commitsThisWeek,
                recentCommitsThisMonth: commitsThisMonth,
                recentCommits: localCommits,
                lastFetchedAt: DateTime.now(),
              ),
            );
          }
        }
      }

      // 2. If GitHub remote is defined, fetch latest external telemetry
      if (current.github != null &&
          current.github!.owner.isNotEmpty &&
          current.github!.repo.isNotEmpty) {
        try {
          final remoteTelemetry = await _gitHubService.fetchTelemetry(
            current.github!.owner,
            current.github!.repo,
            token: _gitHubToken,
          );

          if (remoteTelemetry != null) {
            current = current.copyWith(github: remoteTelemetry);
          }
        } catch (e) {
          debugPrint('GitHub fetch error for ${current.name}: $e');
        }
      }

      updatedList.add(current);
    }

    _projects = updatedList;
    await _repository.saveProjects(_projects);
  }

  Future<void> refreshSingleProjectTelemetry(String projectId) async {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index == -1) return;

    Project current = _projects[index];
    if (current.github != null &&
        current.github!.owner.isNotEmpty &&
        current.github!.repo.isNotEmpty) {
      final telemetry = await _gitHubService.fetchTelemetry(
        current.github!.owner,
        current.github!.repo,
        token: _gitHubToken,
      );
      if (telemetry != null) {
        current = current.copyWith(github: telemetry);
        _projects[index] = current;
        await _repository.saveProjects(_projects);
        notifyListeners();
      }
    }
  }

  // Mutators
  Future<void> addProject(Project project) async {
    _projects.insert(0, project);
    await _repository.saveProjects(_projects);
    notifyListeners();

    // Trigger telemetry fetch for new project if github is specified
    if (project.github != null) {
      refreshSingleProjectTelemetry(project.id);
    }
  }

  Future<void> updateProject(Project project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      _projects[index] = project.copyWith(updatedAt: DateTime.now());
      await _repository.saveProjects(_projects);
      notifyListeners();
    }
  }

  Future<void> deleteProject(String projectId) async {
    _projects.removeWhere((p) => p.id == projectId);
    await _repository.saveProjects(_projects);
    notifyListeners();
  }

  Future<void> updateHumanStatus(String projectId, ProjectHumanStatus? status) async {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      _projects[index] = _projects[index].copyWith(
        humanStatus: status,
        clearHumanStatus: status == null,
        updatedAt: DateTime.now(),
      );
      await _repository.saveProjects(_projects);
      notifyListeners();
    }
  }

  Future<void> updatePriority(String projectId, ProjectPriority priority) async {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      _projects[index] = _projects[index].copyWith(
        priority: priority,
        updatedAt: DateTime.now(),
      );
      await _repository.saveProjects(_projects);
      notifyListeners();
    }
  }

  Future<void> updateNextAction(String projectId, String? nextAction) async {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      final cleaned = nextAction?.trim();
      _projects[index] = _projects[index].copyWith(
        nextAction: cleaned,
        clearNextAction: cleaned == null || cleaned.isEmpty,
        updatedAt: DateTime.now(),
      );
      await _repository.saveProjects(_projects);
      notifyListeners();
    }
  }

  Future<void> updateMilestone(String projectId, String? milestone) async {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      final cleaned = milestone?.trim();
      _projects[index] = _projects[index].copyWith(
        currentMilestone: cleaned,
        clearMilestone: cleaned == null || cleaned.isEmpty,
        updatedAt: DateTime.now(),
      );
      await _repository.saveProjects(_projects);
      notifyListeners();
    }
  }

  Future<void> toggleTask(String projectId, String taskId) async {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      final p = _projects[index];
      final taskList = p.tasks.map((t) {
        if (t.id == taskId) {
          final willComplete = !t.isCompleted;
          return t.copyWith(
            isCompleted: willComplete,
            completedAt: willComplete ? DateTime.now() : null,
          );
        }
        return t;
      }).toList();

      _projects[index] = p.copyWith(tasks: taskList, updatedAt: DateTime.now());
      await _repository.saveProjects(_projects);
      notifyListeners();
    }
  }

  Future<void> addTask(String projectId, String taskTitle) async {
    if (taskTitle.trim().isEmpty) return;
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      final p = _projects[index];
      final newTask = ProjectTask(
        id: 'task-${DateTime.now().millisecondsSinceEpoch}',
        title: taskTitle.trim(),
        createdAt: DateTime.now(),
      );
      final updatedTasks = [...p.tasks, newTask];

      // If project has no next action defined, set this as next action automatically
      final next = p.nextAction ?? taskTitle.trim();

      _projects[index] = p.copyWith(
        tasks: updatedTasks,
        nextAction: next,
        updatedAt: DateTime.now(),
      );
      await _repository.saveProjects(_projects);
      notifyListeners();
    }
  }

  Future<void> deleteTask(String projectId, String taskId) async {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      final p = _projects[index];
      final updatedTasks = p.tasks.where((t) => t.id != taskId).toList();
      _projects[index] = p.copyWith(tasks: updatedTasks, updatedAt: DateTime.now());
      await _repository.saveProjects(_projects);
      notifyListeners();
    }
  }

  Future<void> addMilestone(String projectId, ProjectMilestone milestone) async {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      final p = _projects[index];
      final updatedMilestones = [...p.milestones, milestone];
      _projects[index] = p.copyWith(
        milestones: updatedMilestones,
        currentMilestone: milestone.isCurrent ? milestone.title : p.currentMilestone,
        updatedAt: DateTime.now(),
      );
      await _repository.saveProjects(_projects);
      notifyListeners();
    }
  }

  Future<void> toggleMilestoneCurrent(String projectId, String milestoneId) async {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      final p = _projects[index];
      String? newCurrentTitle;
      final updatedMilestones = p.milestones.map((m) {
        if (m.id == milestoneId) {
          final makeCurrent = !m.isCurrent;
          if (makeCurrent) newCurrentTitle = m.title;
          return m.copyWith(isCurrent: makeCurrent);
        } else {
          return m.copyWith(isCurrent: false);
        }
      }).toList();

      _projects[index] = p.copyWith(
        milestones: updatedMilestones,
        currentMilestone: newCurrentTitle,
        clearMilestone: newCurrentTitle == null,
        updatedAt: DateTime.now(),
      );
      await _repository.saveProjects(_projects);
      notifyListeners();
    }
  }

  Future<void> addNote(String projectId, ProjectNote note) async {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      final p = _projects[index];
      final updatedNotes = [note, ...p.notes];
      _projects[index] = p.copyWith(notes: updatedNotes, updatedAt: DateTime.now());
      await _repository.saveProjects(_projects);
      notifyListeners();
    }
  }

  Future<void> deleteNote(String projectId, String noteId) async {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      final p = _projects[index];
      final updatedNotes = p.notes.where((n) => n.id != noteId).toList();
      _projects[index] = p.copyWith(notes: updatedNotes, updatedAt: DateTime.now());
      await _repository.saveProjects(_projects);
      notifyListeners();
    }
  }

  Future<void> setGitHubToken(String? token) async {
    _gitHubToken = token;
    await _repository.saveGitHubToken(token);
    notifyListeners();
  }

  Future<void> resetToSeedData() async {
    _isLoading = true;
    notifyListeners();

    _projects = await _repository.resetToSeedData();
    await _syncLocalAndRemoteTelemetry(quiet: true);

    _isLoading = false;
    notifyListeners();
  }

  // GitHub Authentication & Account
  Future<bool> loginWithGitHubToken(String token) async {
    final clean = token.trim();
    if (clean.isEmpty) return false;

    _isAuthenticatingGitHub = true;
    notifyListeners();

    try {
      final user = await _gitHubService.getAuthenticatedUser(clean);
      if (user != null) {
        _currentUser = user;
        _gitHubToken = clean;
        await _repository.saveGitHubToken(clean);
        _rateLimitInfo = await _gitHubService.getRateLimit(clean);

        // Proactively refresh telemetry across the portfolio with the authenticated token
        await refreshAllTelemetry();
        _isAuthenticatingGitHub = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('GitHub auth failed: $e');
    } finally {
      _isAuthenticatingGitHub = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> disconnectGitHub() async {
    _gitHubToken = null;
    _currentUser = null;
    _rateLimitInfo = null;
    _discoveredRepos = [];
    await _repository.saveGitHubToken(null);
    notifyListeners();
  }

  Future<void> refreshRateLimit() async {
    _rateLimitInfo = await _gitHubService.getRateLimit(_gitHubToken);
    notifyListeners();
  }

  // GitHub Repository Discovery & Pull
  Future<List<GitHubRepositoryInfo>> fetchUserRepositories() async {
    if (_gitHubToken == null || _gitHubToken!.isEmpty) return [];

    _isFetchingRepos = true;
    notifyListeners();

    try {
      final repos = await _gitHubService.getUserRepositories(_gitHubToken!);
      _discoveredRepos = repos;
      return repos;
    } catch (e) {
      debugPrint('Error fetching repos: $e');
      return [];
    } finally {
      _isFetchingRepos = false;
      notifyListeners();
    }
  }

  Future<int> importGitHubRepositories(List<GitHubRepositoryInfo> reposToImport) async {
    int count = 0;
    for (final repo in reposToImport) {
      final alreadyExists = _projects.any((p) =>
          p.github?.fullName.toLowerCase() == repo.fullName.toLowerCase() ||
          p.name.toLowerCase() == repo.name.toLowerCase());

      if (!alreadyExists) {
        final projectType = _inferProjectType(repo.language, repo.name);
        final formattedName = _formatRepoTitle(repo.name);

        final newProject = Project(
          id: 'gh-${repo.owner}-${repo.name}-${DateTime.now().millisecondsSinceEpoch}-$count',
          name: formattedName,
          description: repo.description ?? 'Imported from GitHub ${repo.fullName}',
          type: projectType,
          humanStatus: ProjectHumanStatus.active,
          priority: ProjectPriority.p2,
          currentMilestone: null,
          nextAction: null,
          github: GitHubTelemetry(
            owner: repo.owner,
            repo: repo.name,
            repoUrl: repo.htmlUrl,
            defaultBranch: repo.defaultBranch,
            openIssuesCount: repo.openIssuesCount,
            lastFetchedAt: DateTime.now(),
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        _projects.add(newProject);
        count++;
      }
    }

    if (count > 0) {
      await _repository.saveProjects(_projects);
      await refreshAllTelemetry();
      notifyListeners();
    }

    return count;
  }

  ProjectType _inferProjectType(String? language, String name) {
    final lang = language?.toLowerCase() ?? '';
    final n = name.toLowerCase();

    if (lang == 'dart' || n.contains('flutter')) {
      return ProjectType.flutterApp;
    } else if (lang == 'python' || (lang == 'go' && n.contains('cli'))) {
      return ProjectType.cliPackage;
    } else if (lang == 'javascript' ||
        lang == 'typescript' ||
        lang == 'html' ||
        lang == 'css' ||
        lang == 'vue') {
      return ProjectType.webApp;
    } else if (n.contains('desktop') || n.contains('hud') || n.contains('monitor')) {
      return ProjectType.desktopApp;
    } else if (lang == 'rust' || lang == 'c' || lang == 'c++') {
      return ProjectType.systemTool;
    } else if (n.contains('bot') || n.contains('robot') || n.contains('hardware')) {
      return ProjectType.hardware;
    } else if (n.contains('service') || n.contains('daemon') || n.contains('server')) {
      return ProjectType.service;
    } else {
      return ProjectType.other;
    }
  }

  String _formatRepoTitle(String name) {
    final words = name.replaceAll(RegExp(r'[-_]'), ' ').split(' ');
    return words.map((w) {
      if (w.isEmpty) return '';
      if (w.length <= 3) return w.toUpperCase();
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ').trim();
  }

  // Onboarding
  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    await _repository.setCompletedOnboarding(true);
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    _hasCompletedOnboarding = false;
    await _repository.setCompletedOnboarding(false);
    notifyListeners();
  }

  // Backup & Import/Export
  Future<String> exportPortfolioJson() async {
    return _repository.exportPortfolioJson();
  }

  Future<bool> importPortfolioJson(String jsonStr) async {
    try {
      final imported = await _repository.importPortfolioJson(jsonStr);
      _projects = imported;
      await _syncLocalAndRemoteTelemetry(quiet: true);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error importing portfolio: $e');
      return false;
    }
  }

  Future<void> clearPortfolio() async {
    _projects = [];
    await _repository.clearPortfolio();
    notifyListeners();
  }

  (String, String)? _parseGitHubUrl(String url) {
    try {
      final trimmed = url.replaceAll('.git', '').trim();
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (segments.length >= 2) {
          return (segments[segments.length - 2], segments[segments.length - 1]);
        }
      }
    } catch (_) {}
    return null;
  }
}
