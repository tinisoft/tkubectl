import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/theme.dart';
import '../models/command_result.dart';
import '../models/kube_config.dart';

class CreateNamespaceDialog extends StatefulWidget {
  const CreateNamespaceDialog({super.key});

  @override
  State<CreateNamespaceDialog> createState() => _CreateNamespaceDialogState();
}

class _CreateNamespaceDialogState extends State<CreateNamespaceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppTheme.consoleGray,
          border: Border(
            bottom: BorderSide(color: AppTheme.consoleGreen, width: 2),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.add, color: AppTheme.consoleGreen, size: 20),
            SizedBox(width: 8),
            Text('Create Namespace', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Namespace Name',
                  hintText: 'my-namespace',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Namespace name is required';
                  }
                  if (!RegExp(r'^[a-z0-9]([-a-z0-9]*[a-z0-9])?$').hasMatch(value.trim())) {
                    return 'Invalid namespace name';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 12),
              const Text(
                'Use lowercase letters, numbers, and hyphens only',
                style: TextStyle(
                  color: AppTheme.consoleMutedWhite,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_nameController.text.trim());
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class CreateDockerRegistrySecretDialog extends StatefulWidget {
  final String? namespace;

  const CreateDockerRegistrySecretDialog({super.key, this.namespace});

  @override
  State<CreateDockerRegistrySecretDialog> createState() => _CreateDockerRegistrySecretDialogState();
}

class _CreateDockerRegistrySecretDialogState extends State<CreateDockerRegistrySecretDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppTheme.consoleGray,
          border: Border(
            bottom: BorderSide(color: AppTheme.consoleYellow, width: 2),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.key, color: AppTheme.consoleYellow, size: 20),
            SizedBox(width: 8),
            Text('Create Docker Registry Secret', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.namespace != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.consoleGray.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.consoleYellow.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppTheme.consoleYellow),
                        const SizedBox(width: 8),
                        Text(
                          'Namespace: ${widget.namespace}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.consoleWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Secret Name',
                    hintText: 'my-registry-secret',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Secret name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _serverController,
                  decoration: const InputDecoration(
                    labelText: 'Registry Server',
                    hintText: 'https://docker.io',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Registry server is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'username',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: '••••••••',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'user@example.com',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Invalid email format';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text.trim(),
                'server': _serverController.text.trim(),
                'username': _usernameController.text.trim(),
                'password': _passwordController.text.trim(),
                'email': _emailController.text.trim(),
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class CustomCommandDialog extends StatefulWidget {
  const CustomCommandDialog({super.key});

  @override
  State<CustomCommandDialog> createState() => _CustomCommandDialogState();
}

class _CustomCommandDialogState extends State<CustomCommandDialog> {
  final _formKey = GlobalKey<FormState>();
  final _commandController = TextEditingController();

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppTheme.consoleGray,
          border: Border(
            bottom: BorderSide(color: AppTheme.consoleBlue, width: 2),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.terminal, color: AppTheme.consoleBlue, size: 20),
            SizedBox(width: 8),
            Text('Execute Custom Command', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _commandController,
                decoration: const InputDecoration(
                  labelText: 'kubectl Command',
                  hintText: 'get pods --all-namespaces',
                  prefixText: 'kubectl ',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Command is required';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 12),
              const Text(
                'Command will execute with current cluster and namespace context',
                style: TextStyle(
                  color: AppTheme.consoleMutedWhite,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_commandController.text.trim());
            }
          },
          child: const Text('Execute'),
        ),
      ],
    );
  }
}

class LogsDialog extends StatelessWidget {
  final String podName;
  final CommandResult logsResult;

  const LogsDialog({
    super.key,
    required this.podName,
    required this.logsResult,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.consoleGray,
                border: Border(
                  bottom: BorderSide(color: AppTheme.consoleBlue, width: 2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.article, color: AppTheme.consoleBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Logs: $podName',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppTheme.consoleBlack,
                child: SingleChildScrollView(
                  child: SelectableText(
                    logsResult.success ? logsResult.output : logsResult.error,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      color: AppTheme.consoleWhite,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClusterConfigDialog extends StatefulWidget {
  final List<KubeConfig> configs;
  final String? currentConfigName;

  const ClusterConfigDialog({
    super.key,
    required this.configs,
    this.currentConfigName,
  });

  @override
  State<ClusterConfigDialog> createState() => _ClusterConfigDialogState();
}

class _ClusterConfigDialogState extends State<ClusterConfigDialog> {
  void _showAddConfigDialog() {
    final nameController = TextEditingController();
    final pathController = TextEditingController();

    Future<void> pickFile() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select Kubeconfig File',
      );

      if (result != null && result.files.single.path != null) {
        pathController.text = result.files.single.path!;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.consoleGray,
              border: Border(
                bottom: BorderSide(color: AppTheme.consoleGreen, width: 2),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.add, color: AppTheme.consoleGreen, size: 20),
                SizedBox(width: 8),
                Text('Add Cluster Config', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Config Name',
                    hintText: 'my-cluster',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pathController,
                  decoration: InputDecoration(
                    labelText: 'Kubeconfig File',
                    hintText: 'Select kubeconfig file',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.folder_open, size: 20),
                      onPressed: () async {
                        await pickFile();
                        setState(() {});
                      },
                      tooltip: 'Browse',
                    ),
                  ),
                  readOnly: true,
                  onTap: () async {
                    await pickFile();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Click the field or folder icon to select a kubeconfig file',
                  style: TextStyle(
                    color: AppTheme.consoleMutedWhite,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty &&
                    pathController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop({
                    'name': nameController.text.trim(),
                    'path': pathController.text.trim(),
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    ).then((result) {
      if (result != null && mounted) {
        Navigator.of(context).pop({
          'action': 'add',
          'name': result['name'],
          'path': result['path'],
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.consoleGray,
                border: Border(
                  bottom: BorderSide(color: AppTheme.consoleBlue, width: 2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud, color: AppTheme.consoleBlue, size: 20),
                  const SizedBox(width: 8),
                  const Text('Select Cluster', style: TextStyle(fontSize: 16)),
                  const Spacer(),
                  IconButton(
                    onPressed: _showAddConfigDialog,
                    icon: const Icon(Icons.add, size: 20),
                    tooltip: 'Add Config',
                    color: AppTheme.consoleGreen,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Flexible(
              child: widget.configs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off,
                            size: 48,
                            color: AppTheme.consoleMutedWhite,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No clusters configured',
                            style: TextStyle(
                              color: AppTheme.consoleMutedWhite,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showAddConfigDialog,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Cluster'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.configs.length,
                      itemBuilder: (context, index) {
                        final config = widget.configs[index];
                        final isSelected = config.name == widget.currentConfigName;
                        return InkWell(
                          onTap: () => Navigator.of(context).pop({
                            'action': 'select',
                            'config': config,
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.consoleGreen.withOpacity(0.1)
                                  : Colors.transparent,
                              border: Border(
                                bottom: BorderSide(
                                  color: AppTheme.consoleMutedWhite.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cloud,
                                  size: 20,
                                  color: isSelected
                                      ? AppTheme.consoleGreen
                                      : AppTheme.consoleBlue,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        config.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? AppTheme.consoleGreen
                                              : AppTheme.consoleWhite,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        config.path,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.consoleMutedWhite,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    size: 20,
                                    color: AppTheme.consoleGreen,
                                  ),
                                IconButton(
                                  onPressed: () {
                                    Navigator.of(context).pop({
                                      'action': 'delete',
                                      'config': config,
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                  ),
                                  tooltip: 'Delete Config',
                                  color: AppTheme.consoleRed,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommandResultDialog extends StatelessWidget {
  final String title;
  final CommandResult result;

  const CommandResultDialog({
    super.key,
    required this.title,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final headerColor = result.success ? AppTheme.consoleGreen : AppTheme.consoleRed;
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.consoleGray,
          border: Border(
            bottom: BorderSide(color: headerColor, width: 2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: headerColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
      content: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 400),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.consoleBlack,
            child: SelectableText(
              result.success ? result.output : result.error,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: AppTheme.consoleWhite,
              ),
            ),
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}