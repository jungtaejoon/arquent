import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../app/scaffold_shell.dart';
import '../../state/app_store.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return AppScaffoldShell(
      title: 'Dashboard',
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Recipes'),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: const Text('Quick Run: Daily Focus Setup'),
                  subtitle: const Text('User initiated only'),
                  trailing: FilledButton(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.permissionReview),
                    child: const Text('Run'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Installed Recipes (${store.installed.length})'),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: store.runtimeSharedUrl,
                decoration: const InputDecoration(
                  labelText: 'Run URL',
                  hintText: 'https://example.com/article',
                ),
                onFieldSubmitted: store.updateRuntimeSharedUrl,
              ),
              const SizedBox(height: 8),
              if (store.installed.isEmpty)
                const Text('Install from Marketplace first.')
              else
                ...store.installed.entries.map(
                  (entry) => Card(
                    child: ListTile(
                      title: Text(entry.key),
                      subtitle: const Text('Local-first execution'),
                      trailing: FilledButton(
                        onPressed: () => store.runRecipe(entry.key),
                        child: const Text('Run Local'),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text('Status: ${store.status}'),
            ],
          );
        },
      ),
    );
  }
}
