import 'package:flutter/material.dart';

import '../../app/scaffold_shell.dart';
import '../../domain/recipe_catalog.dart';
import '../../state/app_store.dart';

class ActionSetupScreen extends StatefulWidget {
  const ActionSetupScreen({super.key});

  @override
  State<ActionSetupScreen> createState() => _ActionSetupScreenState();
}

class _ActionSetupScreenState extends State<ActionSetupScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final normalizedQuery = _query.trim().toLowerCase();
    final filteredActions = actionCatalog.where((action) {
      if (normalizedQuery.isEmpty) {
        return true;
      }
      return action.type.toLowerCase().contains(normalizedQuery) ||
          action.label.toLowerCase().contains(normalizedQuery) ||
          action.category.toLowerCase().contains(normalizedQuery) ||
          action.guide.toLowerCase().contains(normalizedQuery);
    }).toList(growable: false);

    return AppScaffoldShell(
      title: 'Action Setup',
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Active draft: ${store.activeDraftKey}'),
              const SizedBox(height: 8),
              const Text('Select one or more actions (search by term/action_type)'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Guide'),
                      SizedBox(height: 6),
                      Text('1) action_type를 그대로 검색하세요. 예: network.request, text.summarize'),
                      Text('2) 로컬 실행 가능 항목부터 조합한 뒤 민감 액션을 추가하세요.'),
                      Text('3) 민감 액션은 Sensitive risk + user initiated trigger가 필요합니다.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Search action term',
                  hintText: 'e.g. http.request, ocr, clipboard',
                ),
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              ...filteredActions.map((action) {
                final type = action.type;
                final selected = store.draftActions.any((a) => a.type == type);
                return CheckboxListTile(
                  value: selected,
                  onChanged: (_) => store.toggleDraftAction(type),
                  title: Text('${action.label} · ${action.type}'),
                  subtitle: Text(
                    '${action.category} · ${action.supportedLocally ? 'Local OK' : 'Remote/Planned'}'
                    '${action.sensitive ? ' · Sensitive' : ''}\n${action.guide}',
                  ),
                  isThreeLine: true,
                );
              }),
              const Divider(height: 24),
              const Text('Selected action parameters'),
              const SizedBox(height: 8),
              ...store.draftActions.map((action) {
                final def = actionDefinitionByType(action.type);
                final params = action.params;
                if (def == null || def.parameters.isEmpty) {
                  return Card(
                    child: ListTile(
                      title: Text(action.type),
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
                        Text(action.type, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...def.parameters.map((paramDef) {
                          final currentValue = params[paramDef.key] ?? paramDef.defaultValue ?? '';
                          
                          if (paramDef.type == ParameterType.boolean) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: SwitchListTile(
                                title: Text(paramDef.label),
                                value: currentValue == true || currentValue == 'true',
                                onChanged: (value) {
                                  store.updateDraftActionParam(action.id, paramDef.key, value);
                                },
                              ),
                            );
                          } else if (paramDef.type == ParameterType.enumType && paramDef.options != null) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
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
                                onChanged: (value) {
                                  if (value != null) {
                                    store.updateDraftActionParam(action.id, paramDef.key, value);
                                  }
                                },
                              ),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TextFormField(
                                key: ValueKey('${action.id}.${paramDef.key}'),
                                initialValue: currentValue.toString(),
                                decoration: InputDecoration(
                                  labelText: paramDef.label + (paramDef.required ? ' *' : ''),
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType: paramDef.type == ParameterType.number 
                                    ? TextInputType.number 
                                    : TextInputType.text,
                                onChanged: (value) {
                                  if (paramDef.type == ParameterType.number) {
                                    final numValue = num.tryParse(value);
                                    if (numValue != null) {
                                      store.updateDraftActionParam(action.id, paramDef.key, numValue);
                                    } else {
                                      store.updateDraftActionParam(action.id, paramDef.key, value);
                                    }
                                  } else {
                                    store.updateDraftActionParam(action.id, paramDef.key, value);
                                  }
                                },
                              ),
                            );
                          }
                        }),
                        if (def.outputs.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: const [
                              Icon(Icons.output, size: 16, color: Colors.blueGrey),
                              SizedBox(width: 4),
                              Text('Generates Variables:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: def.outputs.entries.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: SelectableText.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: '{{state.',
                                        style: TextStyle(fontFamily: 'Courier', fontSize: 13, color: Colors.black87),
                                      ),
                                      TextSpan(
                                        text: e.key,
                                        style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                                      ),
                                      const TextSpan(
                                        text: '}}',
                                        style: TextStyle(fontFamily: 'Courier', fontSize: 13, color: Colors.black87),
                                      ),
                                      TextSpan(
                                        text: ' : ${e.value}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              )).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Text('Selected: ${store.draftActions.map((a) => a.type).join(', ')}'),
            ],
          );
        },
      ),
    );
  }
}
