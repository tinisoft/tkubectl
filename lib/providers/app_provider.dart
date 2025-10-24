import 'package:flutter/foundation.dart';
import '../models/kube_config.dart';
import '../models/kubernetes_resource.dart';
import '../models/command_result.dart';
import '../services/config_service.dart';
import '../services/kubectl_service.dart';

class AppProvider extends ChangeNotifier {
  final ConfigService _configService = ConfigService();
  final KubectlService _kubectlService = KubectlService();

  AppConfig? _appConfig;
  KubeConfig? _currentKubeConfig;
  String? _currentNamespace;
  List<Namespace> _namespaces = [];
  List<Pod> _pods = [];
  bool _isLoading = false;
  String? _error;
  CommandResult? _lastCommandResult;

  // Getters
  AppConfig? get appConfig => _appConfig;
  KubeConfig? get currentKubeConfig => _currentKubeConfig;
  String? get currentNamespace => _currentNamespace;
  List<Namespace> get namespaces => _namespaces;
  List<Pod> get pods => _pods;
  bool get isLoading => _isLoading;
  String? get error => _error;
  CommandResult? get lastCommandResult => _lastCommandResult;
  bool get hasConfigs => _appConfig?.kubeConfigs.isNotEmpty ?? false;

  ConfigService get configService => _configService;
  KubectlService get kubectlService => _kubectlService;

  Future<void> initialize() async {
    setLoading(true);
    try {
      await _configService.initialize();
    } catch (e) {
      _error = e.toString();
    }

    // Always get the appConfig from configService, even if there was an error
    // (the service sets a default empty config on error)
    _appConfig = _configService.appConfig;

    // Set default cluster if available
    if (_appConfig != null && _appConfig!.kubeConfigs.isNotEmpty) {
      try {
        if (_appConfig!.defaultCluster != null) {
          final defaultConfig = _appConfig!.kubeConfigs.firstWhere(
            (config) => config.name == _appConfig!.defaultCluster,
            orElse: () => _appConfig!.kubeConfigs.first,
          );
          await setKubeConfig(defaultConfig);
        } else {
          // If no default cluster specified, use the first one
          await setKubeConfig(_appConfig!.kubeConfigs.first);
        }
        _error = null;
      } catch (e) {
        _error = e.toString();
      }
    }

    setLoading(false);
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> setKubeConfig(KubeConfig kubeConfig) async {
    try {
      _currentKubeConfig = kubeConfig;
      _kubectlService.setKubeConfig(kubeConfig.path);

      // Set default namespace when switching clusters
      _currentNamespace = 'default';
      _kubectlService.setNamespace('default');

      // Clear existing data
      _namespaces.clear();
      _pods.clear();

      // Load namespaces for the new cluster
      await loadNamespaces();
      // Load pods for default namespace
      await loadPods();

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> setNamespace(String? namespace) async {
    try {
      _currentNamespace = namespace;
      _kubectlService.setNamespace(namespace ?? '');

      // Reload pods for the new namespace
      await loadPods();

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadNamespaces() async {
    if (_currentKubeConfig == null) return;

    setLoading(true);
    try {
      _namespaces = await _kubectlService.getNamespacesList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _namespaces.clear();
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadPods() async {
    if (_currentKubeConfig == null) return;

    setLoading(true);
    try {
      _pods = await _kubectlService.getPodsList(namespace: _currentNamespace);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _pods.clear();
    } finally {
      setLoading(false);
    }
  }

  Future<void> createNamespace(String name) async {
    if (_currentKubeConfig == null) return;

    setLoading(true);
    try {
      _lastCommandResult = await _kubectlService.createNamespace(name);
      if (_lastCommandResult!.success) {
        await loadNamespaces();
      }
      _error = _lastCommandResult!.success ? null : _lastCommandResult!.error;
    } catch (e) {
      _error = e.toString();
    } finally {
      setLoading(false);
    }
  }

  Future<void> createDockerRegistrySecret({
    required String name,
    required String server,
    required String username,
    required String password,
    required String email,
  }) async {
    if (_currentKubeConfig == null) return;

    setLoading(true);
    try {
      _lastCommandResult = await _kubectlService.createDockerRegistrySecret(
        name: name,
        server: server,
        username: username,
        password: password,
        email: email,
        namespace: _currentNamespace,
      );
      _error = _lastCommandResult!.success ? null : _lastCommandResult!.error;
    } catch (e) {
      _error = e.toString();
    } finally {
      setLoading(false);
    }
  }

  Future<void> executeCustomCommand(String command) async {
    if (_currentKubeConfig == null) return;

    setLoading(true);
    try {
      _lastCommandResult = await _kubectlService.executeCustomCommand(command);
      _error = _lastCommandResult!.success ? null : _lastCommandResult!.error;

      // If command might have changed resources, reload relevant data
      if (command.contains('create') || command.contains('delete') || command.contains('apply')) {
        if (command.contains('namespace')) {
          await loadNamespaces();
        } else {
          await loadPods();
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setLoading(false);
    }
  }

  Future<CommandResult> getPodLogs(String podName, {int? lines}) async {
    if (_currentKubeConfig == null) {
      return CommandResult.error('No cluster selected');
    }

    try {
      return await _kubectlService.getLogs(
        podName,
        namespace: _currentNamespace,
        lines: lines,
      );
    } catch (e) {
      return CommandResult.error(e.toString());
    }
  }

  Future<CommandResult> deletePod(String podName, String namespace) async {
    if (_currentKubeConfig == null) {
      return CommandResult.error('No cluster selected');
    }

    try {
      final result = await _kubectlService.deletePod(podName, namespace);
      if (result.success) {
        await loadPods();
      }
      return result;
    } catch (e) {
      return CommandResult.error(e.toString());
    }
  }

  Future<void> addKubeConfig(KubeConfig kubeConfig) async {
    try {
      await _configService.addKubeConfig(kubeConfig);
      _appConfig = _configService.appConfig;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeKubeConfig(String name) async {
    try {
      await _configService.removeKubeConfig(name);
      _appConfig = _configService.appConfig;

      // If we removed the current config, reset
      if (_currentKubeConfig?.name == name) {
        _currentKubeConfig = null;
        _currentNamespace = null;
        _namespaces.clear();
        _pods.clear();
      }

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> setDefaultCluster(String? clusterName) async {
    try {
      await _configService.setDefaultCluster(clusterName);
      _appConfig = _configService.appConfig;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}