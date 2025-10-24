import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/command_result.dart';
import '../models/kubernetes_resource.dart';

class KubectlService {
  String? _currentKubeConfig;
  String? _currentNamespace;

  String? get currentKubeConfig => _currentKubeConfig;
  String? get currentNamespace => _currentNamespace;

  void setKubeConfig(String kubeConfigPath) {
    _currentKubeConfig = kubeConfigPath;
  }

  void setNamespace(String namespace) {
    _currentNamespace = namespace;
  }

  Future<CommandResult> _executeCommand(List<String> args) async {
    try {
      final command = ['kubectl'];

      // Add kubeconfig if set
      if (_currentKubeConfig != null) {
        command.addAll(['--kubeconfig', _currentKubeConfig!]);
      }

      // Add namespace if set and not already in args
      if (_currentNamespace != null && !args.contains('-n') && !args.contains('--namespace')) {
        command.addAll(['-n', _currentNamespace!]);
      }

      command.addAll(args);

      final result = await Process.run(
        command.first,
        command.skip(1).toList(),
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      return CommandResult(
        success: result.exitCode == 0,
        output: result.stdout.toString(),
        error: result.stderr.toString(),
        exitCode: result.exitCode,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return CommandResult.error('Failed to execute kubectl command: $e');
    }
  }

  Future<CommandResult> getNamespaces() async {
    return await _executeCommand(['get', 'namespaces', '-o', 'wide']);
  }

  Future<List<Namespace>> getNamespacesList() async {
    final result = await _executeCommand([
      'get', 'namespaces',
      '-o', 'json'
    ]);

    if (!result.success) {
      throw Exception('Failed to get namespaces: ${result.error}');
    }

    try {
      final jsonData = json.decode(result.output);
      final items = jsonData['items'] as List;

      return items.map((item) {
        final metadata = item['metadata'] as Map<String, dynamic>;
        final status = item['status'] as Map<String, dynamic>;

        return Namespace(
          name: metadata['name'] ?? '',
          namespace: metadata['name'] ?? '',
          metadata: metadata,
          status: status['phase'] ?? '',
          age: _calculateAge(metadata['creationTimestamp']),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to parse namespaces: $e');
    }
  }

  Future<CommandResult> getPods({String? namespace}) async {
    final args = ['get', 'pods', '-o', 'wide'];
    if (namespace != null) {
      args.addAll(['-n', namespace]);
    }
    return await _executeCommand(args);
  }

  Future<List<Pod>> getPodsList({String? namespace}) async {
    final args = ['get', 'pods', '-o', 'json'];
    if (namespace != null) {
      args.addAll(['-n', namespace]);
    }

    final result = await _executeCommand(args);

    if (!result.success) {
      throw Exception('Failed to get pods: ${result.error}');
    }

    try {
      final jsonData = json.decode(result.output);
      final items = jsonData['items'] as List;

      return items.map((item) {
        final metadata = item['metadata'] as Map<String, dynamic>;
        final status = item['status'] as Map<String, dynamic>;

        // Calculate ready containers
        final containerStatuses = status['containerStatuses'] as List? ?? [];
        final readyCount = containerStatuses.where((c) => c['ready'] == true).length;
        final totalCount = containerStatuses.length;

        // Calculate restarts
        final restarts = containerStatuses.fold<int>(
          0,
          (sum, container) => sum + (container['restartCount'] as int? ?? 0)
        );

        return Pod(
          name: metadata['name'] ?? '',
          namespace: metadata['namespace'] ?? '',
          metadata: metadata,
          status: status['phase'] ?? '',
          ready: '$readyCount/$totalCount',
          restarts: restarts,
          age: _calculateAge(metadata['creationTimestamp']),
          node: status['hostIP'],
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to parse pods: $e');
    }
  }

  Future<CommandResult> getLogs(String podName, {String? namespace, int? lines}) async {
    final args = ['logs', podName];
    if (namespace != null) {
      args.addAll(['-n', namespace]);
    }
    if (lines != null) {
      args.addAll(['--tail', lines.toString()]);
    }
    return await _executeCommand(args);
  }

  Future<CommandResult> createNamespace(String name) async {
    return await _executeCommand(['create', 'namespace', name]);
  }

  Future<CommandResult> createDockerRegistrySecret({
    required String name,
    required String server,
    required String username,
    required String password,
    required String email,
    String? namespace,
  }) async {
    final args = [
      'create', 'secret', 'docker-registry', name,
      '--docker-server=$server',
      '--docker-username=$username',
      '--docker-password=$password',
      '--docker-email=$email',
    ];

    if (namespace != null) {
      args.addAll(['-n', namespace]);
    }

    return await _executeCommand(args);
  }

  Future<CommandResult> executeCustomCommand(String command) async {
    // Remove 'kubectl' if user included it
    final cleanCommand = command.startsWith('kubectl ')
        ? command.substring(8).trim()
        : command;

    final args = cleanCommand.split(' ').where((arg) => arg.isNotEmpty).toList();
    return await _executeCommand(args);
  }

  Future<CommandResult> deletePod(String podName, String namespace) async {
    return await _executeCommand([
      'delete', 'pod', podName,
      '-n', namespace,
    ]);
  }

  String _calculateAge(String? creationTimestamp) {
    if (creationTimestamp == null) return 'Unknown';

    try {
      final created = DateTime.parse(creationTimestamp);
      final now = DateTime.now();
      final difference = now.difference(created);

      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return '${difference.inSeconds}s';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}