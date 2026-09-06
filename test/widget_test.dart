import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helm/main.dart';
import 'package:helm/presentation/state/project_manager_controller.dart';
import 'package:helm/domain/models/project.dart';
import 'package:helm/domain/models/github_telemetry.dart';
import 'package:helm/data/repositories/project_repository.dart';
import 'package:helm/data/services/github_service.dart';
import 'package:helm/data/services/local_git_service.dart';
import 'package:helm/core/constants/seed_data.dart';

import 'package:helm/domain/models/github_user.dart';
import 'package:helm/domain/models/github_device_code.dart';

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

  @override
  Future<GitHubDeviceCode?> requestDeviceCode({String? clientId}) async => null;

  @override
  Future<GitHubTokenResponse> pollDeviceToken({
    required String deviceCode,
    String? clientId,
  }) async =>
      const GitHubTokenResponse(status: GitHubTokenStatus.pending);
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
    expect(find.text('HELM'), findsOneWidget);
    expect(find.text('P²'), findsOneWidget);

    // Verify sample projects are rendered
    expect(find.text('Apex Mobile'), findsWidgets);
    expect(find.text('Nexus API Gateway'), findsWidgets);

    // Reset view size after test
    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('Dashboard switches between Simple Mode, Pulse Cards, and Flight Deck Table', (WidgetTester tester) async {
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

    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(ProjectManagerApp(controller: controller));
    await tester.pump();

    // Switch to Simple Mode
    controller.setViewMode(PortfolioViewMode.simpleGrid);
    await tester.pumpAndSettle();

    // Verify Simple Card highlights immediate next action cleanly
    expect(find.text('NEXT: '), findsWidgets);
    expect(find.text('Finalize biometric authentication flow'), findsWidgets);

    // Switch to Flight Deck table
    controller.setViewMode(PortfolioViewMode.flightDeckTable);
    await tester.pumpAndSettle();
    expect(find.text('HUMAN STATE'), findsOneWidget);
    expect(find.text('OBSERVED SIGNAL'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
  });
}
