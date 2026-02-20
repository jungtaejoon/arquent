import 'package:flutter/material.dart';

import '../../app/scaffold_shell.dart';
import '../../domain/recipe_catalog.dart';
import '../../domain/recipe_models.dart';
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
                final isSelected = selected.contains(value);
                final draftTrigger = store.draftTriggers.firstWhere(
                  (t) => t.type == value,
                  orElse: () => RecipeTrigger(id: '', type: value, params: {}),
                );
                
                return Column(
                  children: [
                    CheckboxListTile(
                      value: isSelected,
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
                    ),
                    if (isSelected && trigger.parameters.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 32.0, right: 16.0, bottom: 16.0),
                        child: Column(
                          children: trigger.parameters.map((paramDef) {
                            final currentValue = draftTrigger.params[paramDef.key] ?? paramDef.defaultValue ?? '';
                            
                            if (paramDef.type == ParameterType.boolean) {
                              return SwitchListTile(
                                title: Text(paramDef.label),
                                value: currentValue == true || currentValue == 'true',
                                onChanged: (val) {
                                  store.updateDraftTriggerParam(draftTrigger.id, paramDef.key, val);
                                },
                              );
                            } else if (paramDef.type == ParameterType.enumType && paramDef.options != null) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: DropdownButtonFormField<String>(
                                  value: currentValue.toString(),
                                  decoration: InputDecoration(
                                    labelText: paramDef.label,
                                    border: const OutlineInputBorder(),
                                  ),
                                  items: paramDef.options!.map((option) {
                                    return DropdownMenuItem(
                                      value: option,
                                      child: Text(option),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      store.updateDraftTriggerParam(draftTrigger.id, paramDef.key, val);
                                    }
                                  },
                                ),
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: TextFormField(
                                  key: ValueKey('${draftTrigger.id}.${paramDef.key}'),
                                  initialValue: currentValue.toString(),
                                  decoration: InputDecoration(
                                    labelText: paramDef.label + (paramDef.required ? ' *' : ''),
                                    border: const OutlineInputBorder(),
                                  ),
                                  keyboardType: paramDef.type == ParameterType.number 
                                      ? TextInputType.number 
                                      : TextInputType.text,
                                  onChanged: (val) {
                                    if (paramDef.type == ParameterType.number) {
                                      final numValue = num.tryParse(val);
                                      if (numValue != null) {
                                        store.updateDraftTriggerParam(draftTrigger.id, paramDef.key, numValue);
                                      } else {
                                        store.updateDraftTriggerParam(draftTrigger.id, paramDef.key, val);
                                      }
                                    } else {
                                      store.updateDraftTriggerParam(draftTrigger.id, paramDef.key, val);
                                    }
                                  },
                                ),
                              );
                            }
                          }).toList(),
                        ),
                      ),
                  ],
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
