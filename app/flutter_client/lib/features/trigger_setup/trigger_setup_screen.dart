import 'package:flutter/material.dart';

import '../../app/scaffold_shell.dart';
import '../../domain/recipe_catalog.dart';
import '../../state/app_store.dart';

class TriggerSetupScreen extends StatelessWidget {
  const TriggerSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return AppScaffoldShell(
      title: 'Trigger Setup',
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final sensitive = store.draftRiskLevel == 'Sensitive';
          final selected = store.draftTriggers.map((t) => t.type).toSet();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Active draft: ${store.activeDraftKey}'),
              const SizedBox(height: 8),
              const Text('Choose one or more triggers for the draft recipe'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Guide'),
                      SizedBox(height: 6),
                      Text('trigger.* 용어 그대로 선택하면 됩니다.'),
                      Text('민감 액션 포함 레시피는 user initiated trigger를 최소 1개 포함하세요.'),
                      Text('Mode: any=병렬 OR, all/sequence=모두 충족 필요'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: store.draftTriggerMode,
                decoration: const InputDecoration(
                  labelText: 'Trigger Mode',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'any', child: Text('Any (parallel OR)')),
                  DropdownMenuItem(value: 'all', child: Text('All (parallel AND)')),
                  DropdownMenuItem(value: 'sequence', child: Text('Sequence (ordered chain)')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    store.setDraftTriggerMode(value);
                  }
                },
              ),
              const SizedBox(height: 8),
              ...triggerCatalog.map((trigger) {
                final value = trigger.type;
                final blocked = sensitive && !trigger.userInitiated;
                return CheckboxListTile(
                  value: selected.contains(value),
                  onChanged: blocked
                      ? null
                      : (_) {
                          store.toggleDraftTriggerSelection(value);
                        },
                  title: Text('${trigger.label} · ${trigger.type}'),
                  subtitle: blocked
                      ? const Text('Sensitive recipes require user-initiated trigger')
                      : Text(
                          '${trigger.userInitiated ? 'User Initiated' : 'Background'} · ${trigger.guide}',
                        ),
                );
              }),
              const SizedBox(height: 8),
              Text('Current triggers: ${store.draftTriggers.map((t) => t.type).join(', ')}'),
            ],
          );
        },
      ),
    );
  }
}
