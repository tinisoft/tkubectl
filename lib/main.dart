import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/config_setup_screen.dart';
import 'utils/theme.dart';
import 'models/kube_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Set initial window size for setup screen (compact)
  WindowOptions windowOptions = const WindowOptions(
    size: Size(600, 700),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const TKubectlApp());
}

class TKubectlApp extends StatelessWidget {
  const TKubectlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppProvider()..initialize(),
      child: MaterialApp(
        title: 'TKubectl - Kubernetes Management',
        theme: AppTheme.darkTheme,
        home: const AppRouter(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> with WindowListener {
  bool _previousHasConfigs = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _maximizeWindow() async {
    await windowManager.maximize();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        // Detect transition from no configs to has configs
        if (!_previousHasConfigs && appProvider.hasConfigs) {
          _previousHasConfigs = true;
          // Maximize window when transitioning to home screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _maximizeWindow();
          });
        } else if (!appProvider.hasConfigs) {
          _previousHasConfigs = false;
        }

        // Show loading screen while initializing
        if (appProvider.isLoading && appProvider.appConfig == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.consoleBlue),
            ),
          );
        }

        // Show config setup screen if no configs exist
        if (!appProvider.hasConfigs) {
          return ConfigSetupScreen(
            onConfigSelected: (KubeConfig config) async {
              await appProvider.addKubeConfig(config);
              await appProvider.setKubeConfig(config);
            },
          );
        }

        // Show home screen if configs exist
        return const HomeScreen();
      },
    );
  }
}
