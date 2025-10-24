import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:path_provider/path_provider.dart';
import '../models/kube_config.dart';

class ConfigService {
  static const String _configFileName = 'config.yaml';

  AppConfig? _appConfig;
  String? _configPath;

  AppConfig? get appConfig => _appConfig;

  Future<void> initialize() async {
    await _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      // First try to load from current working directory (root of app)
      final currentDir = Directory.current;
      final configFile = File('${currentDir.path}/$_configFileName');

      String configContent;

      if (await configFile.exists()) {
        configContent = await configFile.readAsString();
        _configPath = configFile.path;
      } else {
        // If not found, try app documents directory as fallback
        final appDocDir = await getApplicationDocumentsDirectory();
        final fallbackConfigFile = File('${appDocDir.path}/$_configFileName');

        if (await fallbackConfigFile.exists()) {
          configContent = await fallbackConfigFile.readAsString();
          _configPath = fallbackConfigFile.path;
        } else {
          // Create a default config file in current directory
          configContent = '''kube-configs:
  - name: "default-cluster"
    path: "${Platform.isWindows ? 'C:\\\\Users\\\\${Platform.environment['USERNAME']}\\\\.kube\\\\config' : '/home/${Platform.environment['USER']}/.kube/config'}"

# Optional: default cluster to load at startup
default-cluster: "default-cluster"''';

          await configFile.writeAsString(configContent);
          _configPath = configFile.path;
        }
      }

      final yamlData = loadYaml(configContent);

      if (yamlData == null) {
        // Handle empty YAML file - create default empty config
        _appConfig = const AppConfig(kubeConfigs: [], defaultCluster: null);
        return;
      }

      Map<String, dynamic> yamlMap;
      if (yamlData is Map) {
        yamlMap = Map<String, dynamic>.from(yamlData);
      } else {
        throw Exception('Config file must contain a YAML map/object at root level. Got: ${yamlData.runtimeType}');
      }

      _appConfig = AppConfig.fromMap(yamlMap);
    } catch (e) {
      // If there's any error loading config, create a default empty one
      _appConfig = const AppConfig(kubeConfigs: [], defaultCluster: null);
      // Still set the config path so we can save later
      if (_configPath == null) {
        final currentDir = Directory.current;
        _configPath = '${currentDir.path}/$_configFileName';
      }
      throw Exception('Failed to load configuration: $e');
    }
  }

  Future<void> saveConfig(AppConfig config) async {
    if (_configPath == null) {
      // If no config path exists, create one in current directory
      final currentDir = Directory.current;
      _configPath = '${currentDir.path}/$_configFileName';
    }

    try {
      final configFile = File(_configPath!);
      final yamlContent = _convertToYaml(config.toMap());
      await configFile.writeAsString(yamlContent);
      _appConfig = config;
    } catch (e) {
      throw Exception('Failed to save configuration: $e');
    }
  }

  String _convertToYaml(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    final configs = data['kube-configs'] as List;

    if (configs.isEmpty) {
      buffer.writeln('kube-configs: []');
    } else {
      buffer.writeln('kube-configs:');
      for (final config in configs) {
        // Escape backslashes in paths for proper YAML format
        final escapedPath = config['path'].toString().replaceAll('\\', '\\\\');
        buffer.writeln('  - name: "${config['name']}"');
        buffer.writeln('    path: "$escapedPath"');
      }
    }

    if (data['default-cluster'] != null) {
      buffer.writeln();
      buffer.writeln('# Optional: default cluster to load at startup');
      buffer.writeln('default-cluster: "${data['default-cluster']}"');
    }

    return buffer.toString();
  }

  Future<void> addKubeConfig(KubeConfig kubeConfig) async {
    if (_appConfig == null) {
      throw Exception('AppConfig is not initialized. Cannot add kube config.');
    }

    final updatedConfigs = List<KubeConfig>.from(_appConfig!.kubeConfigs)
      ..add(kubeConfig);

    final updatedAppConfig = AppConfig(
      kubeConfigs: updatedConfigs,
      defaultCluster: _appConfig!.defaultCluster,
    );

    await saveConfig(updatedAppConfig);
  }

  Future<void> removeKubeConfig(String name) async {
    if (_appConfig == null) return;

    final updatedConfigs = _appConfig!.kubeConfigs
        .where((config) => config.name != name)
        .toList();

    final updatedAppConfig = AppConfig(
      kubeConfigs: updatedConfigs,
      defaultCluster: _appConfig!.defaultCluster == name
          ? null
          : _appConfig!.defaultCluster,
    );

    await saveConfig(updatedAppConfig);
  }

  Future<void> setDefaultCluster(String? clusterName) async {
    if (_appConfig == null) return;

    final updatedAppConfig = AppConfig(
      kubeConfigs: _appConfig!.kubeConfigs,
      defaultCluster: clusterName,
    );

    await saveConfig(updatedAppConfig);
  }
}