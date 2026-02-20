import 'package:flutter/material.dart';

import '../../app/scaffold_shell.dart';
import '../../domain/permissions.dart';
import '../../domain/recipe_models.dart';
import '../../state/app_store.dart';
import '../../widgets/risk_badge.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String? _selectedLocalRecipe;
  String? _selectedTagFilter;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return AppScaffoldShell(
      title: 'Marketplace',
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final allInstalledIds = store.installed.keys.toList()..sort();
          final availableTags = store.allInstalledRecipeTags.toList()..sort();
          final installedIds = _selectedTagFilter == null
              ? allInstalledIds
              : (store.installedRecipeIdsByTag(_selectedTagFilter!)..sort());

          if (installedIds.isNotEmpty &&
              (_selectedLocalRecipe == null || !installedIds.contains(_selectedLocalRecipe))) {
            _selectedLocalRecipe = installedIds.first;
          }
          if (installedIds.isEmpty) {
            _selectedLocalRecipe = null;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Share Recipes'),
              const SizedBox(height: 4),
              const Text('Publish local recipes or install community recipes.'),
              const SizedBox(height: 8),
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
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Share local recipe to marketplace'),
                      const SizedBox(height: 8),
                      if (availableTags.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('All'),
                              selected: _selectedTagFilter == null,
                              onSelected: (_) {
                                setState(() {
                                  _selectedTagFilter = null;
                                });
                              },
                            ),
                            ...availableTags.map(
                              (tag) => FilterChip(
                                label: Text('#$tag'),
                                selected: _selectedTagFilter == tag,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedTagFilter = tag;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      DropdownButtonFormField<String>(
                        value: _selectedLocalRecipe,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Installed recipe',
                        ),
                        items: installedIds
                            .map((id) => DropdownMenuItem(value: id, child: Text(id)))
                            .toList(),
                        onChanged: installedIds.isEmpty
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedLocalRecipe = value;
                                });
                              },
                      ),
                      const SizedBox(height: 8),
                      if (_selectedLocalRecipe != null)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: store
                              .installedRecipeTags(_selectedLocalRecipe!)
                              .map((tag) => Chip(label: Text('#$tag')))
                              .toList(),
                        ),
                      if (_selectedTagFilter != null && installedIds.isEmpty)
                        const Text('No installed recipes match selected tag.'),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: store.isBusy || _selectedLocalRecipe == null
                            ? null
                            : () => store.publishInstalledRecipe(_selectedLocalRecipe!),
                        child: const Text('Share to Marketplace'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Status: ${store.status}'),
              const SizedBox(height: 16),
              const Text('Browse & Install'),
              const SizedBox(height: 8),
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
    final usage = recipe.usage;
    final tags = recipe.tags;
    return Card(
      child: ExpansionTile(
        title: Text(recipe.name),
        subtitle: Text('ID: ${recipe.id}\nBy: ${recipe.publisher}\nPublished: ${recipe.createdAt}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          if (recipe.description.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(recipe.description),
            ),
            const SizedBox(height: 8),
          ],
          if (usage.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('How to use'),
            ),
            const SizedBox(height: 4),
            ...usage.asMap().entries.map(
              (entry) => Align(
                alignment: Alignment.centerLeft,
                child: Text('${entry.key + 1}. ${entry.value}'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) => Chip(label: Text('#$tag'))).toList(),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const RiskBadge(riskLevel: RiskLevel.standard),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: installed ? null : onInstall,
                child: Text(installed ? 'Installed' : 'Install'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
