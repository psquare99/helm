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
  Future<List<Project>> resetToSeedData();
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
          if (projects.isNotEmpty) {
            return projects;
          }
        }
      }
    } catch (e) {
      debugPrint('Error reading stored projects: $e');
    }

    // Default to seeded real project portfolio
    final initial = SeedData.getInitialProjects();
    await saveProjects(initial);
    return initial;
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
  Future<String?> getGitHubToken() async {
    try {
      final file = await _getFile(_settingsFileName);
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        final map = jsonDecode(content) as Map<String, dynamic>;
        return map['github_token'] as String?;
      }
    } catch (e) {
      debugPrint('Error reading github token: $e');
    }
    return null;
  }

  @override
  Future<void> saveGitHubToken(String? token) async {
    try {
      final file = await _getFile(_settingsFileName);
      if (file != null) {
        final map = {'github_token': token};
        await file.writeAsString(jsonEncode(map));
      }
    } catch (e) {
      debugPrint('Error persisting github token: $e');
    }
  }

  @override
  Future<List<Project>> resetToSeedData() async {
    final seed = SeedData.getInitialProjects();
    await saveProjects(seed);
    return seed;
  }
}
