import 'package:flutter/material.dart';

import '../../app/scaffold_shell.dart';
import '../../state/app_store.dart';

class ExecutionLogsScreen extends StatelessWidget {
  const ExecutionLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return AppScaffoldShell(
      title: 'Execution Logs',
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Total logs: ${store.logs.length}'),
              const SizedBox(height: 8),
              if (store.logs.isEmpty)
                const Text('No execution logs yet. Run an installed recipe from Dashboard.')
              else
                ...store.logs.map(
                  (entry) => ListTile(
                    title: Text(entry.runId),
                    subtitle: Text(
                      '${entry.recipeId} · ${entry.status} · Sensitive used: ${entry.sensitiveUsed} · ${entry.timestamp.toIso8601String()}\n${entry.detail}',
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
