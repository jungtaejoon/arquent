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
          final selected = store.draftTriggerType;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Active draft: ${store.activeDraftKey}'),
              const SizedBox(height: 8),
              const Text('Choose one trigger for the draft recipe'),
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
                      Text('민감 액션 포함 레시피는 user initiated trigger를 쓰세요.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...triggerCatalog.map((trigger) {
                final value = trigger.type;
                final blocked = sensitive && !trigger.userInitiated;
                return RadioListTile<String>(
                  value: value,
                  groupValue: selected,
                  onChanged: blocked
                      ? null
                      : (next) {
                          if (next != null) {
                            store.updateDraftTrigger(next);
                          }
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
              Text('Current trigger: ${store.draftTriggerType}'),
            ],
          );
        },
      ),
    );
  }
}
