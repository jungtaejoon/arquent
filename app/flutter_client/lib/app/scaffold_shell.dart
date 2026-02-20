import 'package:flutter/material.dart';

import 'app.dart';

class AppScaffoldShell extends StatelessWidget {
  const AppScaffoldShell({
    required this.title,
    required this.body,
    super.key,
  });

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Automation Platform')),
            const ListTile(
              dense: true,
              title: Text('Use Recipes'),
            ),
            _item(context, 'Dashboard', AppRoutes.dashboard),
            _item(context, 'Recipe State', AppRoutes.recipeState),
            _item(context, 'Execution Logs', AppRoutes.executionLogs),
            _item(context, 'Scenario Lab', AppRoutes.scenarioLab),
            const Divider(height: 12),
            const ListTile(
              dense: true,
              title: Text('Create Recipes'),
            ),
            _item(context, 'Builder', AppRoutes.builder),
            _item(context, 'Trigger Setup', AppRoutes.triggerSetup),
            _item(context, 'Action Setup', AppRoutes.actionSetup),
            _item(context, 'Permission Review', AppRoutes.permissionReview),
            _item(context, 'Workspace', AppRoutes.workspace),
            const Divider(height: 12),
            const ListTile(
              dense: true,
              title: Text('Share Recipes'),
            ),
            _item(context, 'Marketplace', AppRoutes.marketplace),
            _item(context, 'Import/Export', AppRoutes.importExport),
          ],
        ),
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _item(BuildContext context, String label, String route) {
    return ListTile(
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed(route);
      },
    );
  }
}
