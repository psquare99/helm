import 'dart:io';
import '../../domain/models/github_telemetry.dart';

/// Service to inspect local git repositories on disk.
/// Provides offline telemetry directly from the filesystem with strict timeouts.
class LocalGitService {
  static const Duration _timeout = Duration(seconds: 2);

  bool get isGitCliAvailable =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  Future<bool> isGitRepository(String path) async {
    if (!isGitCliAvailable) return false;
    try {
      final dir = Directory(path);
      if (!await dir.exists()) return false;
      final gitDir = Directory('$path${Platform.pathSeparator}.git');
      if (await gitDir.exists()) return true;

      final result = await Process.run(
        'git',
        ['-C', path, 'rev-parse', '--is-inside-work-tree'],
      ).timeout(_timeout, onTimeout: () => ProcessResult(0, 1, '', 'timeout'));

      return result.exitCode == 0 && result.stdout.toString().trim() == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<String?> getRemoteUrl(String path) async {
    if (!isGitCliAvailable) return null;
    try {
      final result = await Process.run(
        'git',
        ['-C', path, 'config', '--get', 'remote.origin.url'],
      ).timeout(_timeout, onTimeout: () => ProcessResult(0, 1, '', 'timeout'));

      if (result.exitCode == 0) {
        final url = result.stdout.toString().trim();
        return url.isNotEmpty ? url : null;
      }
    } catch (_) {}
    return null;
  }

  Future<List<CommitSummary>> getRecentCommits(String path, {int count = 10}) async {
    if (!isGitCliAvailable) return [];
    try {
      // Format: hash%x1fmessage%x1fauthor%x1fdate(iso)
      final result = await Process.run(
        'git',
        ['-C', path, 'log', '-n', '$count', '--pretty=format:%H%x1f%s%x1f%an%x1f%aI'],
      ).timeout(_timeout, onTimeout: () => ProcessResult(0, 1, '', 'timeout'));

      if (result.exitCode != 0) return [];
      final output = result.stdout.toString().trim();
      if (output.isEmpty) return [];

      final lines = output.split('\n');
      final commits = <CommitSummary>[];

      for (final line in lines) {
        final parts = line.split('\x1f');
        if (parts.length >= 4) {
          final sha = parts[0].trim();
          final message = parts[1].trim();
          final author = parts[2].trim();
          final dateStr = parts[3].trim();
          final date = DateTime.tryParse(dateStr) ?? DateTime.now();

          commits.add(CommitSummary(
            sha: sha,
            message: message,
            author: author,
            date: date,
          ));
        }
      }

      return commits;
    } catch (_) {
      return [];
    }
  }

  Future<String?> getCurrentBranch(String path) async {
    if (!isGitCliAvailable) return null;
    try {
      final result = await Process.run(
        'git',
        ['-C', path, 'branch', '--show-current'],
      ).timeout(_timeout, onTimeout: () => ProcessResult(0, 1, '', 'timeout'));

      if (result.exitCode == 0) {
        final branch = result.stdout.toString().trim();
        return branch.isNotEmpty ? branch : null;
      }
    } catch (_) {}
    return null;
  }
}
