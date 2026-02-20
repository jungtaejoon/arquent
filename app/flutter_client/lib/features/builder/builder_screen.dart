import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

import '../../app/app.dart';
import '../../app/scaffold_shell.dart';
import '../../state/app_store.dart';

class BuilderScreen extends StatefulWidget {
  const BuilderScreen({super.key});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen> {
  static const _triggerOptions = [
    ('trigger.manual', 'Manual Run'),
    ('trigger.hotkey', 'Hotkey'),
    ('trigger.widget_tap', 'Widget Tap'),
    ('trigger.share_sheet', 'Share Sheet'),
    ('trigger.schedule', 'Schedule'),
  ];

  static const _actionOptions = [
    ('notification.send', 'Notification'),
    ('file.write', 'File Write'),
    ('clipboard.write', 'Clipboard Write'),
    ('http.request', 'HTTP Request'),
    ('camera.capture', 'Camera Capture'),
    ('microphone.record', 'Microphone Record'),
    ('health.read', 'Health Read'),
  ];

  late final TextEditingController _idController;
  late final TextEditingController _draftNameController;
  late final TextEditingController _tagController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _usageController;
  String? _selectedTagFilter;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: AppStore.instance.draftRecipeId);
    _draftNameController = TextEditingController(text: AppStore.instance.activeDraftName);
    _tagController = TextEditingController();
    _descriptionController = TextEditingController(text: AppStore.instance.draftDescription);
    _usageController = TextEditingController(text: AppStore.instance.draftUsageText);
  }

  @override
  void dispose() {
    _idController.dispose();
    _draftNameController.dispose();
    _tagController.dispose();
    _descriptionController.dispose();
    _usageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return AppScaffoldShell(
      title: 'Builder',
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          if (_idController.text != store.draftRecipeId) {
            _idController.value = TextEditingValue(
              text: store.draftRecipeId,
              selection: TextSelection.collapsed(offset: store.draftRecipeId.length),
            );
          }
          if (_draftNameController.text != store.activeDraftName) {
            _draftNameController.value = TextEditingValue(
              text: store.activeDraftName,
              selection: TextSelection.collapsed(offset: store.activeDraftName.length),
            );
          }
          if (_descriptionController.text != store.draftDescription) {
            _descriptionController.value = TextEditingValue(
              text: store.draftDescription,
              selection: TextSelection.collapsed(offset: store.draftDescription.length),
            );
          }
          if (_usageController.text != store.draftUsageText) {
            _usageController.value = TextEditingValue(
              text: store.draftUsageText,
              selection: TextSelection.collapsed(offset: store.draftUsageText.length),
            );
          }

          final manifestPreview = const JsonEncoder.withIndent('  ').convert(
            store.buildDraftManifest(),
          );
          final flowPreview = const JsonEncoder.withIndent('  ').convert(
            store.buildDraftFlow(),
          );
          final updated = store.activeDraftUpdatedAt.toLocal().toIso8601String().replaceFirst('T', ' ');
          final availableTags = store.allDraftTags.toList()..sort();
          final filteredDraftKeys = _selectedTagFilter == null
              ? store.draftKeys
              : store.draftKeysByTag(_selectedTagFilter!);
          final activeDraftVisible = filteredDraftKeys.contains(store.activeDraftKey);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Draft Workspace'),
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
                value: activeDraftVisible ? store.activeDraftKey : null,
                decoration: const InputDecoration(
                  labelText: 'Active Draft',
                  border: OutlineInputBorder(),
                ),
                items: filteredDraftKeys
                    .map((key) => DropdownMenuItem(value: key, child: Text(store.draftLabel(key))))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    store.switchActiveDraft(value);
                  }
                },
              ),
              if (!activeDraftVisible && filteredDraftKeys.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Current active draft is outside this tag filter.'),
                ),
              if (filteredDraftKeys.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('No drafts found for selected tag filter.'),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _draftNameController,
                onChanged: store.renameActiveDraft,
                decoration: const InputDecoration(
                  labelText: 'Draft Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text('Last edited: $updated'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: 'Add tag',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. finance, morning',
                      ),
                      onSubmitted: (value) {
                        store.addActiveDraftTag(value);
                        _tagController.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      store.addActiveDraftTag(_tagController.text);
                      _tagController.clear();
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (store.activeDraftTags.isEmpty)
                const Text('No tags yet')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: store.activeDraftTags
                      .map(
                        (tag) => InputChip(
                          label: Text(tag),
                          onDeleted: () => store.removeActiveDraftTag(tag),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => store.createNewDraft(),
                    child: const Text('New Draft'),
                  ),
                  OutlinedButton(
                    onPressed: () => store.createNewDraft(duplicateCurrent: true),
                    child: const Text('Duplicate Draft'),
                  ),
                  OutlinedButton(
                    onPressed: store.draftKeys.length > 1 ? store.deleteActiveDraft : null,
                    child: const Text('Delete Draft'),
                  ),
                ],
              ),
              const Divider(height: 24),
              TextField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 4,
                onChanged: store.updateDraftDescription,
                decoration: const InputDecoration(
                  labelText: 'Recipe Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usageController,
                minLines: 3,
                maxLines: 6,
                onChanged: store.updateDraftUsageText,
                decoration: const InputDecoration(
                  labelText: 'Usage Steps (one per line)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Recipe ID'),
              const SizedBox(height: 8),
              TextField(
                controller: _idController,
                onChanged: store.updateDraftRecipeId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'local.custom.recipe',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: store.draftRiskLevel,
                decoration: const InputDecoration(
                  labelText: 'Risk Level',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                  DropdownMenuItem(value: 'Sensitive', child: Text('Sensitive')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    store.updateDraftRiskLevel(value);
                  }
                },
              ),
              const SizedBox(height: 12),
              const Text('Trigger'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: store.draftTriggerType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: _triggerOptions
                    .map((option) => DropdownMenuItem(value: option.$1, child: Text(option.$2)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    store.updateDraftTrigger(value);
                  }
                },
              ),
              const SizedBox(height: 12),
              const Text('Actions'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _actionOptions.map((option) {
                  final actionType = option.$1;
                  final selected = store.draftActions.contains(actionType);
                  return FilterChip(
                    label: Text(option.$2),
                    selected: selected,
                    onSelected: (_) => store.toggleDraftAction(actionType),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Text('Action Parameters'),
              const SizedBox(height: 8),
              if (store.draftActions.isEmpty)
                const Text('Select actions first.')
              else
                ...store.draftActions.map((actionType) {
                  final params =
                      store.draftActionParams[actionType] ?? const <String, dynamic>{};
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
                                  store.updateDraftActionParam(
                                    actionType,
                                    entry.key,
                                    value,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.triggerSetup),
                    child: const Text('Detailed Trigger Setup'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.actionSetup),
                    child: const Text('Detailed Action Setup'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: const Text('Current Draft Summary'),
                  subtitle: Text(
                    'Trigger: ${store.draftTriggerType}\nActions: ${store.draftActions.join(', ')}\nWorkspace: ${store.workspaceScope}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  store.updateDraftRecipeId(_idController.text);
                  store.createDraftRecipe();
                },
                child: const Text('Build & Install Locally'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  store.updateDraftRecipeId(_idController.text);
                  store.createDraftRecipe();
                  await store.publishInstalledRecipe(store.draftRecipeId);
                },
                child: const Text('Build & Share to Marketplace'),
              ),
              const SizedBox(height: 8),
              Text('Status: ${store.status}'),
              const Divider(height: 24),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: manifestPreview));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Manifest copied to clipboard')),
                        );
                      }
                    },
                    child: const Text('Copy Manifest'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: flowPreview));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Flow copied to clipboard')),
                        );
                      }
                    },
                    child: const Text('Copy Flow'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ExpansionTile(
                initiallyExpanded: true,
                title: const Text('Manifest Preview'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(manifestPreview),
                  ),
                ],
              ),
              ExpansionTile(
                title: const Text('Flow Preview'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(flowPreview),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
