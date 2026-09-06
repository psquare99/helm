import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_manager/main.dart';
import 'package:project_manager/presentation/state/project_manager_controller.dart';
import 'package:project_manager/domain/models/project.dart';
import 'package:project_manager/domain/models/github_telemetry.dart';
import 'package:project_manager/data/repositories/project_repository.dart';
import 'package:project_manager/data/services/github_service.dart';
import 'package:project_manager/data/services/local_git_service.dart';
import 'package:project_manager/core/constants/seed_data.dart';

import 'package:project_manager/domain/models/github_user.dart';

class MockTestRepository implements ProjectRepository {
  List<Project> _projects;

  MockTestRepository(this._projects);

  @override
  Future<List<Project>> loadProjects() async => _projects;

  @override
  Future<void> saveProjects(List<Project> projects) async {
    _projects = projects;
  }

  @override
  Future<String?> getGitHubToken() async => null;

  @override
  Future<void> saveGitHubToken(String? token) async {}

  @override
  Future<bool> hasCompletedOnboarding() async => true;

  @override
  Future<void> setCompletedOnboarding(bool completed) async {}

  @override
  Future<Map<String, dynamic>> loadSettings() async => {};

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) async {}

  @override
  Future<String> exportPortfolioJson() async => '[]';

  @override
  Future<List<Project>> importPortfolioJson(String jsonStr) async => _projects;

  @override
  Future<String> getStorageDirectoryPath() async => '/mock/path';

  @override
  Future<void> clearPortfolio() async {
    _projects = [];
  }

  @override
  Future<List<Project>> resetToSeedData() async => _projects;
}

class MockTestGitHubService implements GitHubService {
  @override
  Future<GitHubTelemetry?> fetchTelemetry(
    String owner,
    String repo, {
    String? token,
  }) async =>
      null;

  @override
  Future<GitHubUser?> getAuthenticatedUser(String token) async => null;

  @override
  Future<List<GitHubRepositoryInfo>> getUserRepositories(String token) async => [];

  @override
  Future<Map<String, dynamic>?> getRateLimit(String? token) async => null;
}

class MockTestLocalGitService extends LocalGitService {
  @override
  Future<bool> isGitRepository(String path) async => false;

  @override
  Future<List<CommitSummary>> getRecentCommits(String path, {int count = 10}) async => [];

  @override
  Future<String?> getRemoteUrl(String path) async => null;

  @override
  Future<String?> getCurrentBranch(String path) async => null;
}

void main() {
  testWidgets('Project Manager app loads dashboard and displays projects', (WidgetTester tester) async {
    final seedProjects = SeedData.getInitialProjects();
    final mockRepo = MockTestRepository(seedProjects);
    final mockGitHub = MockTestGitHubService();
    final mockLocalGit = MockTestLocalGitService();

    final controller = ProjectManagerController(
      repository: mockRepo,
      gitHubService: mockGitHub,
      localGitService: mockLocalGit,
    );
    await controller.init();

    // Set screen size for desktop layout
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(ProjectManagerApp(controller: controller));
    await tester.pump();

    // Verify command header and identity
    expect(find.text('PROJECT MANAGER'), findsOneWidget);
    expect(find.text('P²'), findsOneWidget);

    // Verify real projects from seed are rendered
    expect(find.text('Prime'), findsWidgets);
    expect(find.text('P² Studio'), findsWidgets);
    expect(find.text('WAYFINDER'), findsWidgets);

    // Reset view size after test
    addTearDown(tester.view.resetPhysicalSize);
  });
}
