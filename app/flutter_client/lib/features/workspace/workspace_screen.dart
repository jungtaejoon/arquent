import 'package:flutter/material.dart';

import '../../app/scaffold_shell.dart';
import '../../state/app_store.dart';

class WorkspaceScreen extends StatelessWidget {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return AppScaffoldShell(
      title: 'Workspace',
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Execution scope for newly built recipes'),
              const SizedBox(height: 8),
              RadioListTile<String>(
                value: 'personal',
                groupValue: store.workspaceScope,
                onChanged: (value) {
                  if (value != null) {
                    store.updateWorkspaceScope(value);
                  }
                },
                title: const Text('Personal Scope'),
                subtitle: const Text('Default local-first scope for single user'),
              ),
              RadioListTile<String>(
                value: 'team',
                groupValue: store.workspaceScope,
                onChanged: (value) {
                  if (value != null) {
                    store.updateWorkspaceScope(value);
                  }
                },
                title: const Text('Team Scope'),
                subtitle: const Text('Shared scope metadata (enterprise sync later)'),
              ),
              const SizedBox(height: 8),
              Text('Current scope: ${store.workspaceScope}'),
            ],
          );
        },
      ),
    );
  }
}
