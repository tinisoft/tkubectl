# TKubectl - Kubernetes Management Desktop Application

A Flutter-based desktop application designed to provide a dark-themed, console-like table UI for interacting with Kubernetes clusters. The goal is to simplify and visualize common kubectl operations while retaining flexibility for advanced commands.

## Features

### 🔧 Kube Config Management
- Reads from a central configuration file (`config.yaml`)
- Maintains a list of kube-config file paths (array of name–value pairs)
- Easy switching between different cluster configurations
- Auto-loads default cluster on startup

### 📂 Namespace Management
- Detects and lists available namespaces for the selected cluster
- Quick filters to run commands within a specific namespace
- Create new namespaces via an input form
- Visual namespace selection with current namespace highlighting

### ⚡ Command Execution with UI Support

#### Predefined Commands:
- `kubectl get pods` → Displays results in a table-like view
- `kubectl logs <pod>` → Fetch and display logs in a scrollable console UI
- `kubectl get namespaces` → Lists all namespaces

#### Interactive Commands (with input forms):
- `kubectl create namespace <name>` → Prompts user for namespace name
- `kubectl create secret docker-registry` → Prompts for registry URL, username, password, and email
- Custom Commands: Users can input raw kubectl commands

### 🎨 UI Concept
- **Dark Theme Console Style** → Terminal-like interface with structured tables
- **Table View for Resources** → Pods, Services, Namespaces, etc.
- **Input Dialogs for Interactive Commands** → Modal UI for commands requiring parameters
- **Real-time Status Updates** → Color-coded status indicators for resources

## Installation

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- kubectl installed and configured
- Valid Kubernetes cluster access

### Setup
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd tkubectl
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure your clusters by editing the `config.yaml` file in the root directory:
   ```yaml
   kube-configs:
     - name: "cloud-k8"
       path: "C:\\cloud_k8.yaml"

   default-cluster: "cloud"
   ```

4. Run the application:
   ```bash
   flutter run -d windows  # For Windows
   flutter run -d macos    # For macOS
   flutter run -d linux    # For Linux
   ```

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── models/                   # Data models
│   ├── kube_config.dart     # Configuration models
│   ├── kubernetes_resource.dart # K8s resource models
│   └── command_result.dart   # Command execution results
├── services/                 # Business logic services
│   ├── config_service.dart   # Configuration management
│   └── kubectl_service.dart  # kubectl command execution
├── providers/                # State management
│   └── app_provider.dart     # Main application state
├── screens/                  # Application screens
│   └── home_screen.dart      # Main dashboard
├── widgets/                  # Reusable UI components
│   ├── resource_table.dart   # Data tables for resources
│   └── dialogs.dart          # Modal dialogs and forms
└── utils/                    # Utilities
    └── theme.dart            # Dark theme configuration
```

## Configuration

The application uses a YAML configuration file located in the root directory as `config.yaml`:

```yaml
 kube-configs:
     - name: "cloud-k8"
       path: "C:\\cloud_k8.yaml"

# Optional: default cluster to load at startup
default-cluster: "cloud-turtle-2"
```

## Usage

1. **Select Cluster**: Use the cluster dropdown in the top toolbar to switch between configured clusters
2. **Choose Namespace**: Select a specific namespace or view all namespaces using the namespace dropdown
3. **View Resources**: Use the tabs to switch between Pods and Namespaces views
4. **Execute Commands**: Use the action buttons to create resources or run custom commands
5. **View Logs**: Click the logs button next to any pod to view its logs in a dedicated dialog

## Supported Operations

- ✅ View and manage namespaces
- ✅ View pod status and details
- ✅ View pod logs
- ✅ Create namespaces
- ✅ Create Docker registry secrets
- ✅ Execute custom kubectl commands
- ✅ Switch between multiple clusters
- ✅ Filter by namespace

## Development

### Dependencies
- `flutter`: Flutter framework
- `provider`: State management
- `yaml`: YAML parsing for configuration
- `process_run`: Process execution for kubectl commands
- `data_table_2`: Enhanced data tables
- `path_provider`: File system access

### Building for Release

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Troubleshooting

### Common Issues

1. **"kubectl not found"**: Ensure kubectl is installed and in your PATH
2. **"Permission denied"**: Check that your kubeconfig files have proper permissions
3. **"Context not found"**: Verify your kubeconfig files are valid and accessible

### Getting Help

If you encounter issues:
1. Check that kubectl works from your command line
2. Verify your kubeconfig paths in the configuration file
3. Ensure you have proper cluster access permissions
