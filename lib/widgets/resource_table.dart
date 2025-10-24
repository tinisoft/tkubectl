import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../models/kubernetes_resource.dart';
import '../utils/theme.dart';

class PodsTable extends StatelessWidget {
  final List<Pod> pods;
  final Function(Pod)? onPodTap;
  final Function(Pod)? onLogsTap;

  const PodsTable({
    super.key,
    required this.pods,
    this.onPodTap,
    this.onLogsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.widgets, color: AppTheme.consoleBlue),
                const SizedBox(width: 8),
                Text(
                  'Pods (${pods.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: pods.isEmpty
                  ? const Center(
                      child: Text(
                        'No pods found',
                        style: TextStyle(color: AppTheme.consoleMutedWhite),
                      ),
                    )
                  : DataTable2(
                      columnSpacing: 12,
                      horizontalMargin: 12,
                      minWidth: 800,
                      headingRowColor: WidgetStateProperty.all(AppTheme.consoleLightGray),
                      columns: const [
                        DataColumn2(
                          label: Text('NAME', style: TextStyle(fontWeight: FontWeight.bold)),
                          size: ColumnSize.L,
                        ),
                        DataColumn2(
                          label: Text('READY', style: TextStyle(fontWeight: FontWeight.bold)),
                          size: ColumnSize.S,
                        ),
                        DataColumn2(
                          label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold)),
                          size: ColumnSize.M,
                        ),
                        DataColumn2(
                          label: Text('RESTARTS', style: TextStyle(fontWeight: FontWeight.bold)),
                          size: ColumnSize.S,
                        ),
                        DataColumn2(
                          label: Text('AGE', style: TextStyle(fontWeight: FontWeight.bold)),
                          size: ColumnSize.S,
                        ),
                        DataColumn2(
                          label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold)),
                          size: ColumnSize.M,
                        ),
                      ],
                      rows: pods.map((pod) => _buildPodRow(context, pod)).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow2 _buildPodRow(BuildContext context, Pod pod) {
    return DataRow2(
      onTap: () => onPodTap?.call(pod),
      cells: [
        DataCell(
          Text(
            pod.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          Text(
            pod.ready,
            style: TextStyle(
              color: pod.ready.contains('0/') ? AppTheme.consoleRed : AppTheme.consoleGreen,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.getStatusColor(pod.status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppTheme.getStatusColor(pod.status),
                width: 1,
              ),
            ),
            child: Text(
              pod.status.toUpperCase(),
              style: TextStyle(
                color: AppTheme.getStatusColor(pod.status),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            pod.restarts.toString(),
            style: TextStyle(
              color: pod.restarts > 0 ? AppTheme.consoleYellow : AppTheme.consoleWhite,
            ),
          ),
        ),
        DataCell(
          Text(pod.age),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.article, size: 16),
                onPressed: () => onLogsTap?.call(pod),
                tooltip: 'View Logs',
                color: AppTheme.consoleBlue,
              ),
              IconButton(
                icon: const Icon(Icons.info, size: 16),
                onPressed: () => onPodTap?.call(pod),
                tooltip: 'Details',
                color: AppTheme.consoleGreen,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class NamespacesTable extends StatelessWidget {
  final List<Namespace> namespaces;
  final Function(Namespace)? onNamespaceTap;
  final String? selectedNamespace;

  const NamespacesTable({
    super.key,
    required this.namespaces,
    this.onNamespaceTap,
    this.selectedNamespace,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder, color: AppTheme.consoleGreen),
                const SizedBox(width: 8),
                Text(
                  'Namespaces (${namespaces.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: namespaces.isEmpty
                  ? const Center(
                      child: Text(
                        'No namespaces found',
                        style: TextStyle(color: AppTheme.consoleMutedWhite),
                      ),
                    )
                  : DataTable2(
                      columnSpacing: 12,
                      horizontalMargin: 12,
                      minWidth: 600,
                      headingRowColor: WidgetStateProperty.all(AppTheme.consoleLightGray),
                      columns: const [
                        DataColumn2(
                          label: Text('NAME', style: TextStyle(fontWeight: FontWeight.bold)),
                          size: ColumnSize.L,
                        ),
                        DataColumn2(
                          label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold)),
                          size: ColumnSize.M,
                        ),
                        DataColumn2(
                          label: Text('AGE', style: TextStyle(fontWeight: FontWeight.bold)),
                          size: ColumnSize.M,
                        ),
                      ],
                      rows: namespaces.map((namespace) => _buildNamespaceRow(context, namespace)).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow2 _buildNamespaceRow(BuildContext context, Namespace namespace) {
    final isSelected = selectedNamespace == namespace.name;

    return DataRow2(
      onTap: () => onNamespaceTap?.call(namespace),
      color: WidgetStateProperty.all(
        isSelected ? AppTheme.consoleBlue.withValues(alpha: 0.1) : null,
      ),
      cells: [
        DataCell(
          Row(
            children: [
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.consoleBlue,
                  size: 16,
                ),
              if (isSelected) const SizedBox(width: 8),
              Text(
                namespace.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppTheme.consoleBlue : AppTheme.consoleWhite,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.getStatusColor(namespace.status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppTheme.getStatusColor(namespace.status),
                width: 1,
              ),
            ),
            child: Text(
              namespace.status.toUpperCase(),
              style: TextStyle(
                color: AppTheme.getStatusColor(namespace.status),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(
          Text(namespace.age),
        ),
      ],
    );
  }
}