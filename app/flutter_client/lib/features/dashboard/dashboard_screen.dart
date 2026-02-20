import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../app/scaffold_shell.dart';
import '../../state/app_store.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<String?> _promptRunUrl(BuildContext context, String initialValue) async {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Run URL'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'https://example.com/article',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Run'),
            ),
          ],
        );
      },
    );
  }

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
              const Text('Use Recipes'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('This screen is for running installed recipes.'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.builder),
                            child: const Text('Go to Builder'),
                          ),
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.recipeState),
                            child: const Text('Go to Recipe State'),
                          ),
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.marketplace),
                            child: const Text('Go to Marketplace'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
              if (store.installed.isEmpty)
                const Text('Install from Marketplace first.')
              else
                ...store.installed.entries.map(
                  (entry) => Card(
                    child: ListTile(
                      title: Text(entry.key),
                      subtitle: const Text('Local-first execution'),
                      trailing: FilledButton(
                        onPressed: () async {
                          String? sharedUrl;
                          if (store.recipeNeedsSharedUrl(entry.key)) {
                            final url = await _promptRunUrl(
                              context,
                              store.recipeSharedUrl(entry.key),
                            );
                            if (url == null || url.isEmpty) {
                              return;
                            }
                            sharedUrl = url;
                            store.updateRecipeSharedUrl(entry.key, url);
                          }
                          await store.runRecipe(entry.key, sharedUrl: sharedUrl);
                        },
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
