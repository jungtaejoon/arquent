import 'package:flutter/material.dart';

import '../../app/scaffold_shell.dart';
import '../../domain/permissions.dart';
import '../../domain/recipe_models.dart';
import '../../state/app_store.dart';
import '../../widgets/risk_badge.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return AppScaffoldShell(
      title: 'Marketplace',
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Cloud API: ${store.cloudBaseUrl}'),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton(
                    onPressed: store.isBusy ? null : store.publishDemoRecipe,
                    child: const Text('Publish Demo Recipe'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: store.isBusy ? null : store.refreshMarketplace,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Status: ${store.status}'),
              const SizedBox(height: 16),
              Text('Marketplace Recipes (${store.marketplace.length})'),
              const SizedBox(height: 8),
              if (store.marketplace.isEmpty)
                const Text('No recipes yet. Publish demo recipe first.')
              else
                ...store.marketplace.map(
                  (recipe) => _RecipeTile(
                    recipe: recipe,
                    installed: store.installed.containsKey(recipe.id),
                    onInstall: store.isBusy ? null : () => store.installRecipe(recipe.id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({
    required this.recipe,
    required this.installed,
    required this.onInstall,
  });

  final CloudRecipeSummary recipe;
  final bool installed;
  final VoidCallback? onInstall;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(recipe.id),
        subtitle: Text('Published: ${recipe.createdAt}\nVerified Publisher'),
        trailing: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const RiskBadge(riskLevel: RiskLevel.standard),
            FilledButton(
              onPressed: installed ? null : onInstall,
              child: Text(installed ? 'Installed' : 'Install'),
            ),
          ],
        ),
      ),
    );
  }
}
