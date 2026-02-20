import 'package:flutter/material.dart';

import '../features/action_setup/action_setup_screen.dart';
import '../features/builder/builder_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/execution_logs/execution_logs_screen.dart';
import '../features/import_export/import_export_screen.dart';
import '../features/marketplace/marketplace_screen.dart';
import '../features/permission_review/permission_review_screen.dart';
import '../features/recipe_state/recipe_state_screen.dart';
import '../features/scenario_lab/scenario_lab_screen.dart';
import '../features/trigger_setup/trigger_setup_screen.dart';
import '../features/workspace/workspace_screen.dart';

class AppRoutes {
  static const dashboard = '/';
  static const builder = '/builder';
  static const triggerSetup = '/trigger-setup';
  static const actionSetup = '/action-setup';
  static const permissionReview = '/permission-review';
  static const executionLogs = '/execution-logs';
  static const recipeState = '/recipe-state';
  static const importExport = '/import-export';
  static const workspace = '/workspace';
  static const marketplace = '/marketplace';
  static const scenarioLab = '/scenario-lab';
}

class AutomationApp extends StatelessWidget {
  const AutomationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local-First Automation',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      initialRoute: AppRoutes.dashboard,
      routes: {
        AppRoutes.dashboard: (_) => const DashboardScreen(),
        AppRoutes.builder: (_) => const BuilderScreen(),
        AppRoutes.triggerSetup: (_) => const TriggerSetupScreen(),
        AppRoutes.actionSetup: (_) => const ActionSetupScreen(),
        AppRoutes.permissionReview: (_) => const PermissionReviewScreen(),
        AppRoutes.executionLogs: (_) => const ExecutionLogsScreen(),
        AppRoutes.recipeState: (_) => const RecipeStateScreen(),
        AppRoutes.importExport: (_) => const ImportExportScreen(),
        AppRoutes.workspace: (_) => const WorkspaceScreen(),
        AppRoutes.marketplace: (_) => const MarketplaceScreen(),
        AppRoutes.scenarioLab: (_) => const ScenarioLabScreen(),
      },
    );
  }
}
