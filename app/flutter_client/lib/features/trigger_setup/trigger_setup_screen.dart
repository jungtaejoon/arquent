import 'package:flutter/material.dart';

import '../../app/scaffold_shell.dart';
import '../../state/app_store.dart';

class TriggerSetupScreen extends StatelessWidget {
  const TriggerSetupScreen({super.key});

  static const _triggerOptions = [
    ('trigger.manual', 'Manual Run (recommended for MVP)'),
    ('trigger.hotkey', 'Hotkey'),
    ('trigger.widget_tap', 'Widget Tap'),
    ('trigger.share_sheet', 'Share Sheet'),
    ('trigger.schedule', 'Schedule (standard-only)'),
  ];

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
              const Text('Choose one trigger for the draft recipe'),
              const SizedBox(height: 8),
              ..._triggerOptions.map((option) {
                final value = option.$1;
                final label = option.$2;
                final blocked = sensitive && value == 'trigger.schedule';
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
                  title: Text(label),
                  subtitle: blocked
                      ? const Text('Sensitive recipes require user-initiated trigger')
                      : null,
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
