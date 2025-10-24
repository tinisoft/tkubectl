abstract class KubernetesResource {
  final String name;
  final String namespace;
  final Map<String, dynamic> metadata;

  const KubernetesResource({
    required this.name,
    required this.namespace,
    required this.metadata,
  });
}

class Pod extends KubernetesResource {
  final String status;
  final String ready;
  final int restarts;
  final String age;
  final String? node;

  const Pod({
    required super.name,
    required super.namespace,
    required super.metadata,
    required this.status,
    required this.ready,
    required this.restarts,
    required this.age,
    this.node,
  });

  factory Pod.fromMap(Map<String, dynamic> map) {
    return Pod(
      name: map['name'] ?? '',
      namespace: map['namespace'] ?? '',
      metadata: map['metadata'] ?? {},
      status: map['status'] ?? '',
      ready: map['ready'] ?? '',
      restarts: map['restarts'] ?? 0,
      age: map['age'] ?? '',
      node: map['node'],
    );
  }
}

class Namespace extends KubernetesResource {
  final String status;
  final String age;

  const Namespace({
    required super.name,
    required super.namespace,
    required super.metadata,
    required this.status,
    required this.age,
  });

  factory Namespace.fromMap(Map<String, dynamic> map) {
    return Namespace(
      name: map['name'] ?? '',
      namespace: map['namespace'] ?? '',
      metadata: map['metadata'] ?? {},
      status: map['status'] ?? '',
      age: map['age'] ?? '',
    );
  }
}

class Service extends KubernetesResource {
  final String type;
  final String clusterIp;
  final String externalIp;
  final String ports;
  final String age;

  const Service({
    required super.name,
    required super.namespace,
    required super.metadata,
    required this.type,
    required this.clusterIp,
    required this.externalIp,
    required this.ports,
    required this.age,
  });

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      name: map['name'] ?? '',
      namespace: map['namespace'] ?? '',
      metadata: map['metadata'] ?? {},
      type: map['type'] ?? '',
      clusterIp: map['cluster-ip'] ?? '',
      externalIp: map['external-ip'] ?? '',
      ports: map['ports'] ?? '',
      age: map['age'] ?? '',
    );
  }
}