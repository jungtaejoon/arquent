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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final targetTriggerId = args?['triggerId'] as String?;

    return AppScaffoldShell(
      title: targetTriggerId != null ? 'Configure Trigger' : 'Trigger Setup',
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final sensitive = store.draftRiskLevel == 'Sensitive';
          
          // Case 1: Specific Trigger Configuration
          if (targetTriggerId != null) {
            final trigger = store.draftTriggers.firstWhere(
              (t) => t.id == targetTriggerId,
              orElse: () => RecipeTrigger(id: '', type: 'unknown', params: {}),
            );

            if (trigger.id.isEmpty) {
              return const Center(child: Text('Trigger not found'));
            }

            final def = triggerCatalog.firstWhere(
              (t) => t.type == trigger.type,
              orElse: () => TriggerDefinition(
                type: trigger.type,
                label: trigger.type,
                guide: '',
                userInitiated: false,
                parameters: [],
              ),
            );

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  leading: const Icon(Icons.flash_on, color: Colors.orange, size: 32),
                  title: Text(def.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(def.guide),
                ),
                const Divider(),
                if (def.parameters.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No configurable parameters for this trigger.'),
                  )
                else
                  ...def.parameters.map((paramDef) {
                    final currentValue = trigger.params[paramDef.key] ?? paramDef.defaultValue ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildParameterInput(paramDef, currentValue, (val) {
                        store.updateDraftTriggerParam(trigger.id, paramDef.key, val);
                      }),
                    );
                  }),
              ],
            );
          }

          // Case 2: General Setup (Add/Remove Triggers)
          final selectedTypes = store.draftTriggers.map((t) => t.type).toSet();
          
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
                final isSelected = selectedTypes.contains(value);
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
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: _buildParameterInput(paramDef, currentValue, (val) {
                                store.updateDraftTriggerParam(draftTrigger.id, paramDef.key, val);
                              }, keyPrefix: draftTrigger.id),
                            );
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

  Widget _buildParameterInput(ParameterDefinition paramDef, dynamic currentValue, Function(dynamic) onChanged, {String? keyPrefix}) {
    if (paramDef.type == ParameterType.boolean) {
      return SwitchListTile(
        title: Text(paramDef.label),
        value: currentValue == true || currentValue == 'true',
        onChanged: onChanged,
      );
    } else if (paramDef.type == ParameterType.enumType && paramDef.options != null) {
      return DropdownButtonFormField<String>(
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
            onChanged(val);
          }
        },
      );
    } else {
      return TextFormField(
        key: keyPrefix != null ? ValueKey('$keyPrefix.${paramDef.key}') : null,
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
              onChanged(numValue);
            } else {
              onChanged(val);
            }
          } else {
            onChanged(val);
          }
        },
      );
    }
  }
}
