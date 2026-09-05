import 'package:flutter/material.dart';
import '../../domain/models/project.dart';
import '../../domain/models/project_status.dart';
import '../../domain/models/project_task.dart';
import '../../domain/models/project_milestone.dart';
import '../../domain/models/project_note.dart';
import '../../domain/models/project_intelligence.dart';
import '../../domain/models/github_telemetry.dart';
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

  // Getters
  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  bool get isSyncingTelemetry => _isSyncingTelemetry;
  String? get gitHubToken => _gitHubToken;
  PortfolioFilter get filter => _filter;
  PortfolioViewMode get viewMode => _viewMode;
  String get searchQuery => _searchQuery;
  bool get showIntelligenceRadar => _showIntelligenceRadar;

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
      _gitHubToken = await _repository.getGitHubToken();
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

  void setViewMode(PortfolioViewMode mode) {
    _viewMode = mode;
    notifyListeners();
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
