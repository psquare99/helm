import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/models/project.dart';
import '../../core/constants/seed_data.dart';

abstract class ProjectRepository {
  Future<List<Project>> loadProjects();
  Future<void> saveProjects(List<Project> projects);
  Future<String?> getGitHubToken();
  Future<void> saveGitHubToken(String? token);
  Future<bool> hasCompletedOnboarding();
  Future<void> setCompletedOnboarding(bool completed);
  Future<Map<String, dynamic>> loadSettings();
  Future<void> saveSettings(Map<String, dynamic> settings);
  Future<String> exportPortfolioJson();
  Future<List<Project>> importPortfolioJson(String jsonStr);
  Future<String> getStorageDirectoryPath();
  Future<List<Project>> resetToSeedData();
  Future<void> clearPortfolio();
}

class LocalFileProjectRepository implements ProjectRepository {
  static const String _fileName = 'p2_project_manager_data.json';
  static const String _settingsFileName = 'p2_project_manager_settings.json';

  Future<File?> _getFile(String filename) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}${Platform.pathSeparator}$filename');
    } catch (e) {
      debugPrint('Error locating documents directory: $e');
      return null;
    }
  }

  @override
  Future<String> getStorageDirectoryPath() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Future<List<Project>> loadProjects() async {
    try {
      final file = await _getFile(_fileName);
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final decoded = jsonDecode(content) as List<dynamic>;
          final projects = decoded
              .map((item) => Project.fromJson(item as Map<String, dynamic>))
              .toList();
          return projects;
        }
      }
    } catch (e) {
      debugPrint('Error reading stored projects: $e');
    }

    // Default to clean empty state for new users
    return [];
  }

  @override
  Future<void> saveProjects(List<Project> projects) async {
    try {
      final file = await _getFile(_fileName);
      if (file != null) {
        final jsonList = projects.map((p) => p.toJson()).toList();
        await file.writeAsString(jsonEncode(jsonList));
      }
    } catch (e) {
      debugPrint('Error persisting projects: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> loadSettings() async {
    try {
      final file = await _getFile(_settingsFileName);
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
    return {};
  }

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      final file = await _getFile(_settingsFileName);
      if (file != null) {
        await file.writeAsString(jsonEncode(settings));
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  @override
  Future<String?> getGitHubToken() async {
    final settings = await loadSettings();
    return settings['github_token'] as String?;
  }

  @override
  Future<void> saveGitHubToken(String? token) async {
    final settings = await loadSettings();
    settings['github_token'] = token;
    await saveSettings(settings);
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    final settings = await loadSettings();
    return settings['has_completed_onboarding'] as bool? ?? false;
  }

  @override
  Future<void> setCompletedOnboarding(bool completed) async {
    final settings = await loadSettings();
    settings['has_completed_onboarding'] = completed;
    await saveSettings(settings);
  }

  @override
  Future<String> exportPortfolioJson() async {
    final projects = await loadProjects();
    return const JsonEncoder.withIndent('  ')
        .convert(projects.map((p) => p.toJson()).toList());
  }

  @override
  Future<List<Project>> importPortfolioJson(String jsonStr) async {
    final decoded = jsonDecode(jsonStr) as List<dynamic>;
    final imported = decoded
        .map((item) => Project.fromJson(item as Map<String, dynamic>))
        .toList();
    await saveProjects(imported);
    return imported;
  }

  @override
  Future<void> clearPortfolio() async {
    await saveProjects([]);
  }

  @override
  Future<List<Project>> resetToSeedData() async {
    final seed = SeedData.getInitialProjects();
    await saveProjects(seed);
    return seed;
  }
}
