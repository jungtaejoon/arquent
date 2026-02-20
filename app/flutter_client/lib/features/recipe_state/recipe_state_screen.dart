import 'dart:convert';

import 'package:flutter/material.dart';

import '../../app/scaffold_shell.dart';
import '../../state/app_store.dart';

class RecipeStateScreen extends StatefulWidget {
  const RecipeStateScreen({super.key});

  @override
  State<RecipeStateScreen> createState() => _RecipeStateScreenState();
}

class _RecipeStateScreenState extends State<RecipeStateScreen> {
  String? _selectedRecipeId;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return AppScaffoldShell(
      title: 'Recipe State',
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final installedIds = store.installed.keys.toList()..sort();
          if (installedIds.isNotEmpty &&
              (_selectedRecipeId == null || !installedIds.contains(_selectedRecipeId))) {
            _selectedRecipeId = installedIds.first;
          }
          if (installedIds.isEmpty) {
            _selectedRecipeId = null;
          }

          if (_selectedRecipeId == null) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No installed recipes yet. Install or build a recipe first.'),
            );
          }

          final recipeId = _selectedRecipeId!;
          final package = store.installed[recipeId]!;
          final manifest = package.manifestJson;
          final flow = package.flowJson;
          final trigger = (flow['trigger'] as Map<String, dynamic>? ?? const {})['trigger_type'] ??
              'trigger.manual';
          final actions = (flow['actions'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .map((action) => (action['action_type'] ?? '').toString())
              .where((value) => value.trim().isNotEmpty)
              .toList(growable: false);
          final logs = store.logsForRecipe(recipeId);
          final runCount = store.runCountForRecipe(recipeId);
          final lastInputs = store.lastRunInputsForRecipe(recipeId);
          final lastArtifacts = store.lastRunArtifactsForRecipe(recipeId);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Use Recipes'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: recipeId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Recipe',
                ),
                items: installedIds
                    .map((id) => DropdownMenuItem(value: id, child: Text(id)))
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedRecipeId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: Text(manifest['name']?.toString() ?? recipeId),
                  subtitle: Text(
                    'ID: $recipeId\nTrigger: $trigger\nActions: ${actions.join(', ')}\nRuns: $runCount',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Last Run Inputs'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    lastInputs.isEmpty
                        ? 'No run input captured yet.'
                        : const JsonEncoder.withIndent('  ').convert(lastInputs),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Last Run Artifacts'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    lastArtifacts.isEmpty
                        ? 'No artifacts yet.'
                        : const JsonEncoder.withIndent('  ').convert(lastArtifacts),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Run History'),
              const SizedBox(height: 8),
              if (logs.isEmpty)
                const Text('No runs for this recipe yet.')
              else
                ...logs.map(
                  (entry) => Card(
                    child: ListTile(
                      title: Text(entry.status),
                      subtitle: Text(
                        '${entry.runId}\n${entry.timestamp.toIso8601String()}\n${entry.detail}',
                      ),
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
