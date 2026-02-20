import 'package:flutter/material.dart';

import '../../app/scaffold_shell.dart';
import '../../state/app_store.dart';

class ActionSetupScreen extends StatelessWidget {
  const ActionSetupScreen({super.key});

  static const _actionOptions = [
    ('notification.send', 'Notification'),
    ('file.write', 'File Write'),
    ('clipboard.write', 'Clipboard Write'),
    ('http.request', 'HTTP Request'),
    ('camera.capture', 'Camera Capture (Sensitive)'),
    ('microphone.record', 'Microphone Record (Sensitive)'),
    ('health.read', 'Health Daily Summary (Sensitive)'),
  ];

  static const _sensitive = {'camera.capture', 'microphone.record', 'health.read'};

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return AppScaffoldShell(
      title: 'Action Setup',
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Select one or more actions'),
              const SizedBox(height: 8),
              ..._actionOptions.map((option) {
                final type = option.$1;
                final label = option.$2;
                final selected = store.draftActions.contains(type);
                return CheckboxListTile(
                  value: selected,
                  onChanged: (_) => store.toggleDraftAction(type),
                  title: Text(label),
                  subtitle: _sensitive.contains(type)
                      ? const Text('Requires Sensitive risk + user-initiated trigger')
                      : null,
                );
              }),
              const Divider(height: 24),
              const Text('Selected action parameters'),
              const SizedBox(height: 8),
              ...store.draftActions.map((actionType) {
                final params = store.draftActionParams[actionType] ?? const <String, dynamic>{};
                if (params.isEmpty) {
                  return Card(
                    child: ListTile(
                      title: Text(actionType),
                      subtitle: const Text('No editable params'),
                    ),
                  );
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(actionType, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...params.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TextFormField(
                              key: ValueKey('$actionType.${entry.key}'),
                              initialValue: entry.value.toString(),
                              decoration: InputDecoration(
                                labelText: entry.key,
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                store.updateDraftActionParam(actionType, entry.key, value);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Text('Selected: ${store.draftActions.join(', ')}'),
            ],
          );
        },
      ),
    );
  }
}
