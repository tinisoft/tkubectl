class KubeConfig {
  final String name;
  final String path;

  const KubeConfig({
    required this.name,
    required this.path,
  });

  factory KubeConfig.fromMap(Map<String, dynamic> map) {
    final name = map['name'];
    final path = map['path'];

    if (name == null || name.toString().trim().isEmpty) {
      throw Exception('Missing or empty "name" field');
    }

    if (path == null || path.toString().trim().isEmpty) {
      throw Exception('Missing or empty "path" field');
    }

    return KubeConfig(
      name: name.toString().trim(),
      path: path.toString().trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'path': path,
    };
  }

  @override
  String toString() => 'KubeConfig(name: $name, path: $path)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KubeConfig && other.name == name && other.path == path;
  }

  @override
  int get hashCode => name.hashCode ^ path.hashCode;
}

class AppConfig {
  final List<KubeConfig> kubeConfigs;
  final String? defaultCluster;

  const AppConfig({
    required this.kubeConfigs,
    this.defaultCluster,
  });

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    try {
      final kubeConfigsData = map['kube-configs'];

      if (kubeConfigsData == null) {
        throw Exception('Missing "kube-configs" field in configuration');
      }

      if (kubeConfigsData is! List) {
        throw Exception('"kube-configs" must be a list');
      }

      final kubeConfigs = <KubeConfig>[];
      for (int i = 0; i < kubeConfigsData.length; i++) {
        try {
          final configItem = kubeConfigsData[i];
          if (configItem is! Map) {
            throw Exception('kube-configs[$i] must be a map');
          }
          kubeConfigs.add(KubeConfig.fromMap(Map<String, dynamic>.from(configItem)));
        } catch (e) {
          throw Exception('Error parsing kube-configs[$i]: $e');
        }
      }

      return AppConfig(
        kubeConfigs: kubeConfigs,
        defaultCluster: map['default-cluster']?.toString(),
      );
    } catch (e) {
      throw Exception('Failed to parse AppConfig: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'kube-configs': kubeConfigs.map((x) => x.toMap()).toList(),
      'default-cluster': defaultCluster,
    };
  }
}