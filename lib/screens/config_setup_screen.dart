import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/kube_config.dart';
import '../utils/theme.dart';

class ConfigSetupScreen extends StatefulWidget {
  final Function(KubeConfig) onConfigSelected;

  const ConfigSetupScreen({
    super.key,
    required this.onConfigSelected,
  });

  @override
  State<ConfigSetupScreen> createState() => _ConfigSetupScreenState();
}

class _ConfigSetupScreenState extends State<ConfigSetupScreen> {
  final _nameController = TextEditingController();
  String? _selectedPath;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickConfigFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['yaml', 'yml'],
        dialogTitle: 'Select Kubernetes Config File',
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedPath = result.files.single.path!;
          // Auto-populate name if empty
          if (_nameController.text.isEmpty) {
            final fileName = result.files.single.name;
            _nameController.text = fileName.replaceAll('.yaml', '').replaceAll('.yml', '');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: AppTheme.consoleRed,
          ),
        );
      }
    }
  }

  Future<void> _submitConfig() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name for the configuration'),
          backgroundColor: AppTheme.consoleYellow,
        ),
      );
      return;
    }

    if (_selectedPath == null || _selectedPath!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a config file'),
          backgroundColor: AppTheme.consoleYellow,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final config = KubeConfig(
        name: _nameController.text.trim(),
        path: _selectedPath!,
      );

      await widget.onConfigSelected(config);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding configuration: $e'),
            backgroundColor: AppTheme.consoleRed,
          ),
        );
      }
    }
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
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.consoleGray,
                  border: Border.all(color: AppTheme.consoleBlue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add Cluster Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.consoleWhite,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('config_name_field'),
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Configuration Name',
                        hintText: 'e.g., production, staging, local',
                        prefixIcon: Icon(Icons.label, color: AppTheme.consoleBlue),
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.consoleBlack,
                        border: Border.all(
                          color: _selectedPath != null
                              ? AppTheme.consoleGreen
                              : AppTheme.consoleMutedWhite,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _selectedPath != null ? Icons.check_circle : Icons.folder,
                                color: _selectedPath != null
                                    ? AppTheme.consoleGreen
                                    : AppTheme.consoleMutedWhite,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedPath ?? 'No file selected',
                                  style: TextStyle(
                                    color: _selectedPath != null
                                        ? AppTheme.consoleWhite
                                        : AppTheme.consoleMutedWhite,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _pickConfigFile,
                            icon: const Icon(Icons.file_open),
                            label: const Text('Select Kube Config File'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.consoleBlue,
                              foregroundColor: AppTheme.consoleWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitConfig,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.consoleGreen,
                        foregroundColor: AppTheme.consoleWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppTheme.consoleWhite,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Add Configuration',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
