import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/dialogs.dart';
import '../utils/theme.dart';
import '../models/kubernetes_resource.dart';
import '../models/kube_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Pod? _selectedPod;
  String? _podLogs;
  bool _isLoadingLogs = false;
  Set<String> _selectedLogFilters = {'debug', 'error', 'fail'};
  double _logFontSize = 11.0;
  bool _reverseLogOrder = false;

  // Checkpoint feature
  List<Map<String, String>> _logCheckpoints = [];
  int _selectedCheckpointIndex = -1; // -1 means current logs

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 24),
            _buildClusterSelector(),
          ],
        ),
        actions: [
          _buildActionButtons(),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (appProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.consoleBlue),
            );
          }

          if (appProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error,
                    size: 64,
                    color: AppTheme.consoleRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${appProvider.error}',
                    style: const TextStyle(color: AppTheme.consoleRed),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      appProvider.clearError();
                      if (appProvider.currentKubeConfig != null) {
                        appProvider.loadNamespaces();
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (appProvider.currentKubeConfig == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 64,
                    color: AppTheme.consoleMutedWhite,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No cluster selected',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.consoleMutedWhite,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Select a cluster from the dropdown above',
                    style: TextStyle(color: AppTheme.consoleMutedWhite),
                  ),
                ],
              ),
            );
          }

          return Row(
            children: [
              // Left side - Namespaces list
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.consoleGray,
                      child: Row(
                        children: [
                          const Icon(Icons.folder, color: AppTheme.consoleGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Namespaces (${appProvider.namespaces.length})',
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildNamespacesList(appProvider),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(
                width: 1,
                color: AppTheme.consoleMutedWhite,
              ),
              // Middle - Pods list
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.consoleGray,
                      child: Row(
                        children: [
                          const Icon(Icons.widgets, color: AppTheme.consoleBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pods (${appProvider.pods.length})${appProvider.currentNamespace != null ? ' in ${appProvider.currentNamespace}' : ' (All Namespaces)'}',
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildPodsList(appProvider),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(
                width: 1,
                color: AppTheme.consoleMutedWhite,
              ),
              // Right side - Details/Logs panel
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.consoleGray,
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: AppTheme.consoleYellow),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Details & Logs',
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildDetailsPanel(appProvider),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildClusterSelector() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return InkWell(
          onTap: () => _showClusterConfigDialog(appProvider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.consoleGray,
              border: Border.all(color: AppTheme.consoleBlue.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud, size: 16, color: AppTheme.consoleBlue),
                const SizedBox(width: 8),
                Text(
                  appProvider.currentKubeConfig?.name ?? 'Select Cluster',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.consoleWhite,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showClusterConfigDialog(AppProvider appProvider) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ClusterConfigDialog(
        configs: appProvider.appConfig?.kubeConfigs ?? [],
        currentConfigName: appProvider.currentKubeConfig?.name,
      ),
    );

    if (result != null && mounted) {
      if (result['action'] == 'select') {
        await appProvider.setKubeConfig(result['config']);
      } else if (result['action'] == 'add') {
        final newConfig = KubeConfig(
          name: result['name'],
          path: result['path'],
        );
        await appProvider.addKubeConfig(newConfig);
        await appProvider.setKubeConfig(newConfig);
      } else if (result['action'] == 'delete') {
        final config = result['config'] as KubeConfig;
        final confirmed = await _showDeleteConfigConfirmation(config);
        if (confirmed == true) {
          await appProvider.removeKubeConfig(config.name);
        }
      }
    }
  }

  Future<bool?> _showDeleteConfigConfirmation(KubeConfig config) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.consoleGray,
            border: Border(
              bottom: BorderSide(color: AppTheme.consoleRed, width: 2),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning, color: AppTheme.consoleRed, size: 20),
              SizedBox(width: 8),
              Text('Delete Cluster Config', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this cluster configuration?',
              style: const TextStyle(
                color: AppTheme.consoleWhite,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.consoleBlack,
                border: Border.all(color: AppTheme.consoleYellow),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name: ${config.name}',
                    style: const TextStyle(
                      color: AppTheme.consoleWhite,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Path: ${config.path}',
                    style: const TextStyle(
                      color: AppTheme.consoleMutedWhite,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This will remove the cluster from your config.yaml file.',
              style: TextStyle(
                color: AppTheme.consoleMutedWhite,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.consoleRed,
              foregroundColor: AppTheme.consoleWhite,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }


  Widget _buildActionButtons() {
    return Row(
      children: [
        IconButton(
          onPressed: _showCreateNamespaceDialog,
          icon: const Icon(Icons.add),
          tooltip: 'Create Namespace',
        ),
        IconButton(
          onPressed: _showCreateSecretDialog,
          icon: const Icon(Icons.key),
          tooltip: 'Create Docker Registry Secret',
        ),
        IconButton(
          onPressed: _showCustomCommandDialog,
          icon: const Icon(Icons.terminal),
          tooltip: 'Execute Custom Command',
        ),
        IconButton(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        if (appProvider.currentKubeConfig == null) return const SizedBox();

        return FloatingActionButton(
          onPressed: _refresh,
          backgroundColor: AppTheme.consoleBlue,
          child: const Icon(Icons.refresh),
        );
      },
    );
  }


  void _showCreateNamespaceDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const CreateNamespaceDialog(),
    );

    if (result != null && mounted) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.createNamespace(result);

      if (appProvider.lastCommandResult != null) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => CommandResultDialog(
              title: 'Create Namespace',
              result: appProvider.lastCommandResult!,
            ),
          );
        }
      }
    }
  }

  void _showCreateSecretDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const CreateDockerRegistrySecretDialog(),
    );

    if (result != null && mounted) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.createDockerRegistrySecret(
        name: result['name']!,
        server: result['server']!,
        username: result['username']!,
        password: result['password']!,
        email: result['email']!,
      );

      if (appProvider.lastCommandResult != null) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => CommandResultDialog(
              title: 'Create Docker Registry Secret',
              result: appProvider.lastCommandResult!,
            ),
          );
        }
      }
    }
  }

  void _showCustomCommandDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const CustomCommandDialog(),
    );

    if (result != null && mounted) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.executeCustomCommand(result);

      if (appProvider.lastCommandResult != null) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => CommandResultDialog(
              title: 'Custom Command',
              result: appProvider.lastCommandResult!,
            ),
          );
        }
      }
    }
  }

  void _refresh() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (appProvider.currentKubeConfig != null) {
      appProvider.loadNamespaces();
      appProvider.loadPods();
    }
  }

  Widget _buildNamespacesList(AppProvider appProvider) {
    // Filter out system namespaces
    final systemNamespaces = {
      'kube-system',
      'kube-public',
      'kube-node-lease',
      'kubernetes-dashboard',
      'ingress-nginx',
      'cert-manager',
      'metallb-system',
      'calico-system',
      'tigera-operator',
    };

    final filteredNamespaces = appProvider.namespaces
        .where((ns) => !systemNamespaces.contains(ns.name))
        .map((ns) => ns.name)
        .toList();

    // Ensure default is at the top, but don't duplicate it
    final namespaces = <String>[];
    if (!filteredNamespaces.contains('default')) {
      namespaces.add('default');
    }
    namespaces.addAll(filteredNamespaces);

    // Sort to put default first if it exists in the fetched list
    namespaces.sort((a, b) {
      if (a == 'default') return -1;
      if (b == 'default') return 1;
      return a.compareTo(b);
    });
    final selectedNamespace = appProvider.currentNamespace ?? 'default';

    if (namespaces.isEmpty) {
      return const Center(
        child: Text(
          'No namespaces found',
          style: TextStyle(color: AppTheme.consoleMutedWhite),
        ),
      );
    }

    return ListView.builder(
      itemCount: namespaces.length,
      itemBuilder: (context, index) {
        final namespace = namespaces[index];
        final isSelected = namespace == selectedNamespace;

        return Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.transparent : null,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.consoleLightGray,
                width: 0.5,
              ),
            ),
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: _NamespaceListItem(
              namespace: namespace,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedPod = null;
                  _podLogs = null;
                  _isLoadingLogs = false;
                });
                appProvider.setNamespace(namespace == 'default' ? null : namespace);
              },
              onCopy: () => _copyToClipboard(namespace, 'Namespace'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPodsList(AppProvider appProvider) {
    final pods = appProvider.pods;

    if (pods.isEmpty) {
      return const Center(
        child: Text(
          'No pods found',
          style: TextStyle(color: AppTheme.consoleMutedWhite),
        ),
      );
    }

    return ListView.builder(
      itemCount: pods.length,
      itemBuilder: (context, index) {
        final pod = pods[index];

        final isSelected = _selectedPod?.name == pod.name;

        return Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.transparent : null,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.consoleLightGray,
                width: 0.5,
              ),
            ),
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: _PodListItem(
              pod: pod,
              isSelected: isSelected,
              onTap: () => _selectPod(pod),
              onCopy: () => _copyToClipboard(pod.name, 'Pod name'),
            ),
          ),
        );
      },
    );
  }

  void _selectPod(Pod pod) {
    setState(() {
      _selectedPod = pod;
      _podLogs = null; // Clear previous logs
      _logCheckpoints.clear(); // Clear checkpoints when switching pods
      _selectedCheckpointIndex = -1;
    });
    _loadPodLogs(pod);
  }

  Future<void> _loadPodLogs(Pod pod) async {
    setState(() {
      _isLoadingLogs = true;
      // Switch to current tab when refreshing
      _selectedCheckpointIndex = -1;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final logsResult = await appProvider.getPodLogs(pod.name, lines: 1000);

      if (mounted) {
        setState(() {
          _podLogs = logsResult.success ? logsResult.output : 'Error: ${logsResult.error}';
          _isLoadingLogs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _podLogs = 'Error loading logs: $e';
          _isLoadingLogs = false;
        });
      }
    }
  }

  Widget _buildDetailsPanel(AppProvider appProvider) {
    if (_selectedPod == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app,
              size: 64,
              color: AppTheme.consoleMutedWhite,
            ),
            SizedBox(height: 16),
            Text(
              'Select a pod to view details and logs',
              style: TextStyle(
                color: AppTheme.consoleMutedWhite,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Pod Details Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.consoleLightGray,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.consoleMutedWhite,
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info, color: AppTheme.consoleBlue, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Pod Details',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showDeletePodConfirmation(appProvider),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    tooltip: 'Delete Pod',
                    color: AppTheme.consoleRed,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Name', _selectedPod!.name),
              _buildDetailRow('Namespace', _selectedPod!.namespace),
              _buildDetailRow('Status', _selectedPod!.status),
              _buildDetailRow('Ready', _selectedPod!.ready),
              _buildDetailRow('Restarts', _selectedPod!.restarts.toString()),
              _buildDetailRow('Age', _selectedPod!.age),
              if (_selectedPod!.node != null) _buildDetailRow('Node', _selectedPod!.node!),
            ],
          ),
        ),
        // Logs Section
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: AppTheme.consoleGray,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.article, color: AppTheme.consoleYellow, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Logs',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _buildLogFilterChips()),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (_logFontSize > 8) _logFontSize--;
                            });
                          },
                          icon: const Icon(Icons.remove, size: 16),
                          tooltip: 'Decrease Font Size',
                          color: AppTheme.consoleMutedWhite,
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (_logFontSize < 20) _logFontSize++;
                            });
                          },
                          icon: const Icon(Icons.add, size: 16),
                          tooltip: 'Increase Font Size',
                          color: AppTheme.consoleMutedWhite,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _copyLogsToClipboard(),
                          icon: const Icon(Icons.copy, size: 16),
                          tooltip: 'Copy Logs',
                          color: AppTheme.consoleYellow,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _reverseLogOrder = !_reverseLogOrder;
                            });
                          },
                          icon: Icon(
                            _reverseLogOrder ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 16,
                          ),
                          tooltip: _reverseLogOrder ? 'Oldest First' : 'Newest First',
                          color: _reverseLogOrder ? AppTheme.consoleMutedWhite : AppTheme.consoleWhite,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _createCheckpoint(),
                          icon: const Icon(Icons.bookmark_add, size: 16),
                          tooltip: 'Checkpoint',
                          color: AppTheme.consoleGreen,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _loadPodLogs(_selectedPod!),
                          icon: const Icon(Icons.refresh, size: 16),
                          tooltip: 'Refresh Logs',
                          color: AppTheme.consoleBlue,
                        ),
                      ],
                    ),
                    // Checkpoint tabs
                    if (_logCheckpoints.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Current logs tab
                            _buildCheckpointTab(
                              label: 'Current',
                              index: -1,
                              onTap: () {
                                setState(() {
                                  _selectedCheckpointIndex = -1;
                                });
                              },
                              onClose: null,
                            ),
                            const SizedBox(width: 4),
                            // Checkpoint tabs
                            ..._logCheckpoints.asMap().entries.map((entry) {
                              final index = entry.key;
                              final checkpoint = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: _buildCheckpointTab(
                                  label: checkpoint['name']!,
                                  index: index,
                                  onTap: () {
                                    setState(() {
                                      _selectedCheckpointIndex = index;
                                    });
                                  },
                                  onClose: () {
                                    setState(() {
                                      _logCheckpoints.removeAt(index);
                                      if (_selectedCheckpointIndex == index) {
                                        _selectedCheckpointIndex = -1;
                                      } else if (_selectedCheckpointIndex > index) {
                                        _selectedCheckpointIndex--;
                                      }
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: AppTheme.consoleBlack,
                  child: _isLoadingLogs
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.consoleBlue,
                          ),
                        )
                      : SingleChildScrollView(
                          child: SelectableText.rich(
                            _buildHighlightedLogs(),
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: _logFontSize,
                              color: AppTheme.consoleWhite,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.consoleMutedWhite,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.consoleWhite,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String itemType) {
    Clipboard.setData(ClipboardData(text: text));
  }

  void _copyLogsToClipboard() {
    if (_podLogs != null && _podLogs!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _podLogs!));

      // Show temporary tooltip feedback
      final overlay = Overlay.of(context);
      final overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          right: 60,
          top: MediaQuery.of(context).size.height * 0.3,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.consoleGreen,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Logs copied!',
                style: TextStyle(
                  color: AppTheme.consoleWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );

      overlay.insert(overlayEntry);
      Future.delayed(const Duration(milliseconds: 1500), () {
        overlayEntry.remove();
      });
    }
  }

  Future<void> _showDeletePodConfirmation(AppProvider appProvider) async {
    if (_selectedPod == null) return;

    final random = Random();
    final confirmationCode = (1000 + random.nextInt(9000)).toString();
    final codeController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.consoleGray,
            border: Border(
              bottom: BorderSide(color: AppTheme.consoleRed, width: 2),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning, color: AppTheme.consoleRed, size: 20),
              SizedBox(width: 8),
              Text('Delete Pod', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete pod "${_selectedPod!.name}"?',
              style: const TextStyle(
                color: AppTheme.consoleWhite,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.consoleBlack,
                border: Border.all(color: AppTheme.consoleYellow),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CONFIRMATION CODE',
                    style: TextStyle(
                      color: AppTheme.consoleYellow,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    confirmationCode,
                    style: const TextStyle(
                      color: AppTheme.consoleGreen,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Enter Code',
                hintText: '0000',
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text == confirmationCode) {
                Navigator.of(context).pop();
                await _deletePod(appProvider);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid confirmation code'),
                    backgroundColor: AppTheme.consoleRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.consoleRed,
              foregroundColor: AppTheme.consoleWhite,
            ),
            child: const Text('Delete Pod'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePod(AppProvider appProvider) async {
    if (_selectedPod == null) return;

    final podName = _selectedPod!.name;

    try {
      final result = await appProvider.deletePod(
        _selectedPod!.name,
        _selectedPod!.namespace,
      );

      if (mounted) {
        if (result.success) {
          setState(() {
            _selectedPod = null;
            _podLogs = null;
            _isLoadingLogs = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pod "$podName" deleted successfully'),
              backgroundColor: AppTheme.consoleGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete pod: ${result.error}'),
              backgroundColor: AppTheme.consoleRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting pod: $e'),
            backgroundColor: AppTheme.consoleRed,
          ),
        );
      }
    }
  }

  Widget _buildLogFilterChips() {
    final filters = [
      {'name': 'INFO', 'key': 'info', 'color': AppTheme.consoleBlue},
      {'name': 'DEBUG', 'key': 'debug', 'color': AppTheme.consoleMutedWhite},
      {'name': 'ERROR', 'key': 'error', 'color': AppTheme.consoleRed},
      {'name': 'FAIL', 'key': 'fail', 'color': AppTheme.consoleRed},
      {'name': 'WARNING', 'key': 'warning', 'color': AppTheme.consoleYellow},
    ];

    return Wrap(
      spacing: 8,
      children: filters.map((filter) {
        final isSelected = _selectedLogFilters.contains(filter['key']);
        return FilterChip(
          label: Text(
            filter['name'] as String,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppTheme.consoleBlack : (filter['color'] as Color),
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedLogFilters.add(filter['key'] as String);
              } else {
                _selectedLogFilters.remove(filter['key'] as String);
              }
            });
          },
          backgroundColor: AppTheme.consoleBlack,
          selectedColor: filter['color'] as Color,
          checkmarkColor: AppTheme.consoleBlack,
          side: BorderSide(
            color: filter['color'] as Color,
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        );
      }).toList(),
    );
  }

  String _getFilteredLogs() {
    // Get the current log source (either current logs or checkpoint)
    String? logsToFilter;
    if (_selectedCheckpointIndex >= 0 && _selectedCheckpointIndex < _logCheckpoints.length) {
      logsToFilter = _logCheckpoints[_selectedCheckpointIndex]['logs'];
    } else {
      logsToFilter = _podLogs;
    }

    if (logsToFilter == null || logsToFilter.isEmpty) {
      return 'No logs available';
    }

    if (_selectedLogFilters.isEmpty) {
      return 'No log levels selected';
    }

    // If all filters are selected, return all logs
    if (_selectedLogFilters.length == 5) {
      final lines = logsToFilter.split('\n');
      return _reverseLogOrder ? lines.reversed.join('\n') : logsToFilter;
    }

    final lines = logsToFilter.split('\n');
    final filteredLines = <String>[];

    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      bool shouldInclude = false;

      for (final filter in _selectedLogFilters) {
        switch (filter) {
          case 'info':
            if (lowerLine.contains('info') || lowerLine.contains('information')) {
              shouldInclude = true;
            }
            break;
          case 'debug':
            if (lowerLine.contains('debug') || lowerLine.contains('trace')) {
              shouldInclude = true;
            }
            break;
          case 'error':
            if (lowerLine.contains('error') || lowerLine.contains('exception')) {
              shouldInclude = true;
            }
            break;
          case 'fail':
            if (lowerLine.contains('fail') || lowerLine.contains('fatal')) {
              shouldInclude = true;
            }
            break;
          case 'warning':
            if (lowerLine.contains('warn') || lowerLine.contains('warning')) {
              shouldInclude = true;
            }
            break;
        }
        if (shouldInclude) break;
      }

      // Include lines that don't match any specific log level if all filters are selected
      // or if the line contains timestamp/general log info
      if (!shouldInclude && _selectedLogFilters.length > 3) {
        // Include lines that look like log entries but don't have explicit log levels
        if (RegExp(r'^\d{4}-\d{2}-\d{2}|^\[\d|^time=|^level=').hasMatch(line)) {
          shouldInclude = true;
        }
      }

      if (shouldInclude) {
        filteredLines.add(line);
      }
    }

    // Apply reverse order if enabled
    return filteredLines.isEmpty ? 'No matching log entries found' : (_reverseLogOrder ? filteredLines.reversed.join('\n') : filteredLines.join('\n'));
  }

  TextSpan _buildHighlightedLogs() {
    final logText = _getFilteredLogs();
    final lines = logText.split('\n');
    final List<TextSpan> spans = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      final List<TextSpan> lineSpans = [];
      String remainingLine = line;

      // Regex patterns for datetime formats
      final dateTimePatterns = [
        RegExp(r'^\d{4}-\d{2}-\d{2}[T\s]\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})?'),
        RegExp(r'^\[\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\]'),
        RegExp(r'^\d{2}:\d{2}:\d{2}'),
        RegExp(r'^time="[^"]+"'),
      ];

      // Check for datetime at start of line
      bool foundDateTime = false;
      for (final pattern in dateTimePatterns) {
        final match = pattern.firstMatch(remainingLine);
        if (match != null) {
          lineSpans.add(TextSpan(
            text: match.group(0),
            style: const TextStyle(
              color: AppTheme.consoleBlue,
              fontWeight: FontWeight.bold,
            ),
          ));
          remainingLine = remainingLine.substring(match.end);
          foundDateTime = true;
          break;
        }
      }

      // Highlight log levels
      final logLevelPatterns = {
        RegExp(r'\b(ERROR|ERR|ERRO)\b', caseSensitive: false): AppTheme.consoleRed,
        RegExp(r'\b(FATAL|CRIT|CRITICAL)\b', caseSensitive: false): AppTheme.consoleRed,
        RegExp(r'\b(WARN|WARNING)\b', caseSensitive: false): AppTheme.consoleYellow,
        RegExp(r'\b(INFO)\b', caseSensitive: false): AppTheme.consoleGreen,
        RegExp(r'\b(DEBUG|TRACE)\b', caseSensitive: false): AppTheme.consoleMutedWhite,
        RegExp(r'\b(FAIL|FAILED|FAILURE)\b', caseSensitive: false): AppTheme.consoleRed,
        RegExp(r'\b(SUCCESS|SUCCEEDED)\b', caseSensitive: false): AppTheme.consoleGreen,
      };

      int lastIndex = 0;
      final matches = <MapEntry<int, MapEntry<String, Color>>>[];

      // Find all log level matches
      for (final entry in logLevelPatterns.entries) {
        final pattern = entry.key;
        final color = entry.value;

        for (final match in pattern.allMatches(remainingLine)) {
          matches.add(MapEntry(match.start, MapEntry(match.group(0)!, color)));
        }
      }

      // Sort matches by position
      matches.sort((a, b) => a.key.compareTo(b.key));

      // Build spans with highlighted log levels
      for (final match in matches) {
        if (match.key > lastIndex) {
          lineSpans.add(TextSpan(text: remainingLine.substring(lastIndex, match.key)));
        }
        lineSpans.add(TextSpan(
          text: match.value.key,
          style: TextStyle(
            color: match.value.value,
            fontWeight: FontWeight.bold,
          ),
        ));
        lastIndex = match.key + match.value.key.length;
      }

      // Add remaining text
      if (lastIndex < remainingLine.length) {
        lineSpans.add(TextSpan(text: remainingLine.substring(lastIndex)));
      }

      spans.add(TextSpan(children: lineSpans));
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(children: spans);
  }

  void _createCheckpoint() {
    if (_podLogs == null || _podLogs!.isEmpty) return;

    final timestamp = DateTime.now();
    final formattedTime = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

    setState(() {
      // Create checkpoint with current logs
      _logCheckpoints.add({
        'name': 'CP ${_logCheckpoints.length + 1} ($formattedTime)',
        'logs': _podLogs!,
        'timestamp': timestamp.toIso8601String(),
      });

      // Clear current logs (set to empty so new logs will show when refreshed)
      _podLogs = '';

      // Stay on current tab to show empty logs (ready for refresh)
      _selectedCheckpointIndex = -1;
    });
  }

  Widget _buildCheckpointTab({
    required String label,
    required int index,
    required VoidCallback onTap,
    required VoidCallback? onClose,
  }) {
    final isSelected = _selectedCheckpointIndex == index;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.consoleGreen : AppTheme.consoleGray.withOpacity(0.5),
          border: Border.all(
            color: isSelected ? AppTheme.consoleGreen : AppTheme.consoleMutedWhite,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.consoleBlack : AppTheme.consoleWhite,
              ),
            ),
            if (onClose != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onClose,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: isSelected ? AppTheme.consoleBlack : AppTheme.consoleMutedWhite,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NamespaceListItem extends StatefulWidget {
  final String namespace;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const _NamespaceListItem({
    required this.namespace,
    required this.isSelected,
    required this.onTap,
    required this.onCopy,
  });

  @override
  State<_NamespaceListItem> createState() => _NamespaceListItemState();
}

class _NamespaceListItemState extends State<_NamespaceListItem> {
  bool _isHovered = false;
  bool _showCopiedTooltip = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: ListTile(
        leading: Icon(
          widget.namespace == 'default' ? Icons.home : Icons.folder,
          color: widget.isSelected ? AppTheme.consoleBlue : AppTheme.consoleGreen,
          size: 20,
        ),
        title: Text(
          widget.namespace,
          style: TextStyle(
            color: widget.isSelected ? AppTheme.consoleBlue : AppTheme.consoleWhite,
            fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isHovered)
              Tooltip(
                message: _showCopiedTooltip ? 'Copied!' : 'Copy namespace name',
                child: IconButton(
                  icon: const Icon(Icons.copy, size: 14),
                  onPressed: () {
                    widget.onCopy();
                    setState(() => _showCopiedTooltip = true);
                    Future.delayed(const Duration(milliseconds: 1000), () {
                      if (mounted) {
                        setState(() => _showCopiedTooltip = false);
                      }
                    });
                  },
                  color: AppTheme.consoleMutedWhite,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ),
            if (widget.isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.consoleBlue,
                size: 16,
              ),
          ],
        ),
        onTap: widget.onTap,
      ),
    );
  }
}

class _PodListItem extends StatefulWidget {
  final Pod pod;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const _PodListItem({
    required this.pod,
    required this.isSelected,
    required this.onTap,
    required this.onCopy,
  });

  @override
  State<_PodListItem> createState() => _PodListItemState();
}

class _PodListItemState extends State<_PodListItem> {
  bool _isHovered = false;
  bool _showCopiedTooltip = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: ListTile(
        leading: Icon(
          Icons.widgets,
          color: AppTheme.getStatusColor(widget.pod.status),
          size: 20,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.pod.name,
                style: TextStyle(
                  color: widget.isSelected ? AppTheme.consoleBlue : AppTheme.consoleWhite,
                  fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_isHovered)
              Tooltip(
                message: _showCopiedTooltip ? 'Copied!' : 'Copy pod name',
                child: IconButton(
                  icon: const Icon(Icons.copy, size: 14),
                  onPressed: () {
                    widget.onCopy();
                    setState(() => _showCopiedTooltip = true);
                    Future.delayed(const Duration(milliseconds: 1000), () {
                      if (mounted) {
                        setState(() => _showCopiedTooltip = false);
                      }
                    });
                  },
                  color: AppTheme.consoleMutedWhite,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.getStatusColor(widget.pod.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: AppTheme.getStatusColor(widget.pod.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.pod.status.toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.getStatusColor(widget.pod.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Ready: ${widget.pod.ready}',
                  style: TextStyle(
                    color: widget.pod.ready.contains('0/') ? AppTheme.consoleRed : AppTheme.consoleGreen,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Restarts: ${widget.pod.restarts}',
                  style: TextStyle(
                    color: widget.pod.restarts > 0 ? AppTheme.consoleYellow : AppTheme.consoleMutedWhite,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Age: ${widget.pod.age} | Namespace: ${widget.pod.namespace}',
              style: const TextStyle(
                color: AppTheme.consoleMutedWhite,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: widget.isSelected
            ? const Icon(
                Icons.check_circle,
                color: AppTheme.consoleBlue,
                size: 16,
              )
            : null,
        onTap: widget.onTap,
      ),
    );
  }
}