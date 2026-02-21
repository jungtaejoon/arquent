import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

import '../../app/app.dart';
import '../../app/scaffold_shell.dart';
import '../../domain/recipe_catalog.dart';
import '../../state/app_store.dart';

class BuilderScreen extends StatefulWidget {
  const BuilderScreen({super.key});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen> {
  late final TextEditingController _idController;
  late final TextEditingController _draftNameController;
  late final TextEditingController _tagController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _usageController;
  late final TextEditingController _actionSearchController;
  String? _selectedTemplateId;
  String? _selectedTagFilter;
  String _actionSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: AppStore.instance.draftRecipeId);
    _draftNameController = TextEditingController(text: AppStore.instance.activeDraftName);
    _tagController = TextEditingController();
    _descriptionController = TextEditingController(text: AppStore.instance.draftDescription);
    _usageController = TextEditingController(text: AppStore.instance.draftUsageText);
    _actionSearchController = TextEditingController();
  }

  @override
  void dispose() {
    _idController.dispose();
    _draftNameController.dispose();
    _tagController.dispose();
    _descriptionController.dispose();
    _usageController.dispose();
    _actionSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;

    return DefaultTabController(
      length: 3,
      child: AppScaffoldShell(
        title: 'Builder',
        bottom: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.article_outlined), text: 'Info'),
            Tab(icon: Icon(Icons.account_tree_outlined), text: 'Logic'),
            Tab(icon: Icon(Icons.code_outlined), text: 'Preview'),
          ],
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
        ),
        body: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            // Sync controllers with store state
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

            final manifestPreview = const JsonEncoder.withIndent('  ').convert(store.buildDraftManifest());
            final flowPreview = const JsonEncoder.withIndent('  ').convert(store.buildDraftFlow());
            final updated = store.activeDraftUpdatedAt.toLocal().toIso8601String().replaceFirst('T', ' ');
            final availableTags = store.allDraftTags.toList()..sort();
            final templates = store.availableTemplates;
            
            final actionQuery = _actionSearchQuery.trim().toLowerCase();
            final filteredActionCatalog = actionCatalog.where((action) {
              if (actionQuery.isEmpty) return true;
              return action.type.toLowerCase().contains(actionQuery) ||
                  action.label.toLowerCase().contains(actionQuery) ||
                  action.category.toLowerCase().contains(actionQuery) ||
                  action.guide.toLowerCase().contains(actionQuery);
            }).toList(growable: false);

            final filteredDraftKeys = _selectedTagFilter == null
                ? store.draftKeys
                : store.draftKeysByTag(_selectedTagFilter!);
            final activeDraftVisible = filteredDraftKeys.contains(store.activeDraftKey);

            return TabBarView(
              children: [
                // TAB 1: Info (Metadata + Display)
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildDraftSelectionSection(
                      context, store, filteredDraftKeys, activeDraftVisible, availableTags
                    ),
                    const Divider(height: 32),
                    _buildBasicInfoSection(context, store, templates, updated),
                    const Divider(height: 32),
                    _buildDisplaySection(context, store),
                  ],
                ),

                // TAB 2: Logic (Triggers & Actions)
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                     _buildTriggerSection(context, store),
                     const Divider(height: 32),
                     _buildActionSection(context, store, filteredActionCatalog),
                  ],
                ),

                // TAB 3: Preview (JSON)
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Last Updated: $updated', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    const Text('Manifest (Metadata)', style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.grey[200],
                      child: SelectableText(manifestPreview, style: const TextStyle(fontFamily: 'Courier', fontSize: 12)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Flow (Logic)', style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.grey[200],
                      child: SelectableText(flowPreview, style: const TextStyle(fontFamily: 'Courier', fontSize: 12)),
                    ),
                    const SizedBox(height: 16),
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
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDraftSelectionSection(
    BuildContext context, 
    AppStore store, 
    List<String> filteredDraftKeys, 
    bool activeDraftVisible,
    List<String> availableTags,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Draft Workspace', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
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
            prefixIcon: Icon(Icons.folder_open),
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
            child: Text('Current active draft is outside this tag filter.', style: TextStyle(color: Colors.orange)),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => store.createNewDraft(),
                icon: const Icon(Icons.add),
                label: const Text('New'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => store.createNewDraft(duplicateCurrent: true),
                icon: const Icon(Icons.copy),
                label: const Text('Clone'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: store.draftKeys.length > 1 ? store.deleteActiveDraft : null,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection(BuildContext context, AppStore store, List<RecipeTemplateDefinition> templates, String updated) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _draftNameController,
          decoration: const InputDecoration(
            labelText: 'Recipe Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.label),
          ),
          onChanged: (value) => store.renameActiveDraft(value),
        ),
        const SizedBox(height: 8),
        Text('Last edited: $updated', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedTemplateId,
          decoration: const InputDecoration(
            labelText: 'Apply Template (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.content_copy),
          ),
          items: [
             const DropdownMenuItem(value: null, child: Text('(No Template)')),
             ...templates.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
          ],
          onChanged: (value) {
            setState(() {
              _selectedTemplateId = value;
            });
            if (value != null) {
              store.applyTemplateToActiveDraft(value);
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _idController,
          decoration: const InputDecoration(
            labelText: 'Recipe ID (Unique)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.fingerprint),
            helperText: 'e.g., local.custom.my_recipe',
          ),
          onChanged: (value) => store.updateDraftRecipeId(value),
        ),
        const SizedBox(height: 16),
         DropdownButtonFormField<String>(
           value: store.draftRiskLevel,
           decoration: const InputDecoration(
             labelText: 'Risk Level',
             border: OutlineInputBorder(),
             prefixIcon: Icon(Icons.security),
           ),
           items: const [
             DropdownMenuItem(value: 'Standard', child: Text('Standard (Safe)')),
             DropdownMenuItem(value: 'Sensitive', child: Text('Sensitive (Requires Permission)')),
           ],
           onChanged: (value) {
             if (value != null) {
               store.updateDraftRiskLevel(value);
             }
           },
         ),
         const SizedBox(height: 16),
         TextFormField(
           controller: _descriptionController,
           decoration: const InputDecoration(
             labelText: 'Description',
             border: OutlineInputBorder(),
             prefixIcon: Icon(Icons.description),
             alignLabelWithHint: true,
           ),
           maxLines: 3,
           onChanged: (value) => store.updateDraftDescription(value),
         ),
         const SizedBox(height: 16),
         TextFormField(
           controller: _tagController,
           decoration: InputDecoration(
             labelText: 'Tags (Enter to add)',
             border: const OutlineInputBorder(),
             prefixIcon: const Icon(Icons.tag),
             suffixIcon: IconButton(
               icon: const Icon(Icons.add),
               onPressed: () {
                 if (_tagController.text.isNotEmpty) {
                    store.addActiveDraftTag(_tagController.text);
                    _tagController.clear();
                 }
               },
             ),
           ),
           onFieldSubmitted: (value) {
             if (value.isNotEmpty) {
               store.addActiveDraftTag(value);
               _tagController.clear();
             }
           },
         ),
         const SizedBox(height: 8),
         Wrap(
           spacing: 8,
           children: store.activeDraftTags.map((tag) => Chip(
             label: Text(tag),
             onDeleted: () => store.removeActiveDraftTag(tag),
           )).toList(),
         ),
      ],
    );
  }

  Widget _buildDisplaySection(BuildContext context, AppStore store) {
    final display = store.draftDisplay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Display Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Text('Configure how this recipe appears in the dashboard.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        Row(
           children: [
             Expanded(
               child: DropdownButtonFormField<String>(
                 value: display['icon'] as String? ?? 'bolt',
                 decoration: const InputDecoration(
                   labelText: 'Icon',
                   border: OutlineInputBorder(),
                   prefixIcon: Icon(Icons.image),
                 ),
                 items: const [
                   DropdownMenuItem(value: 'bolt', child: Text('Bolt (Default)')),
                   DropdownMenuItem(value: 'play_arrow', child: Text('Play')),
                   DropdownMenuItem(value: 'timer', child: Text('Timer')),
                   DropdownMenuItem(value: 'notifications', child: Text('Notification')),
                   DropdownMenuItem(value: 'star', child: Text('Star')),
                 ],
                 onChanged: (value) => store.updateDraftDisplay('icon', value),
               ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: DropdownButtonFormField<String>(
                 value: display['color'] as String? ?? 'blue',
                 decoration: const InputDecoration(
                   labelText: 'Color',
                   border: OutlineInputBorder(),
                   prefixIcon: Icon(Icons.palette),
                 ),
                 items: const [
                   DropdownMenuItem(value: 'blue', child: Text('Blue')),
                   DropdownMenuItem(value: 'green', child: Text('Green')),
                   DropdownMenuItem(value: 'orange', child: Text('Orange')),
                   DropdownMenuItem(value: 'red', child: Text('Red')),
                   DropdownMenuItem(value: 'purple', child: Text('Purple')),
                 ],
                 onChanged: (value) => store.updateDraftDisplay('color', value),
               ),
             ),
           ],
        ),
        if (store.draftTriggers.any((t) => t.type == 'trigger.manual')) ...[
           const SizedBox(height: 16),
           TextFormField(
             initialValue: display['button_label'] as String? ?? 'Run Recipe',
             decoration: const InputDecoration(
               labelText: 'Manual Button Label',
               border: OutlineInputBorder(),
               helperText: 'Text shown on the manual trigger button',
             ),
             onChanged: (value) => store.updateDraftDisplay('button_label', value),
           ),
        ],
      ],
    );
  }

  Widget _buildTriggerSection(BuildContext context, AppStore store) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             const Text('Triggers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              OutlinedButton.icon(
                onPressed: () {
                   Navigator.of(context).pushNamed(AppRoutes.triggerSetup);
                },
                icon: const Icon(Icons.tune),
                label: const Text('Configure'),
              ),
           ],
         ),
         const SizedBox(height: 8),
         Card(
           child: Padding(
             padding: const EdgeInsets.all(16),
             child: Column(
               children: [
                 DropdownButtonFormField<String>(
                   value: store.draftTriggerMode,
                   decoration: const InputDecoration(
                     labelText: 'Trigger Mode',
                     border: OutlineInputBorder(),
                     helperText: 'How multiple triggers relate to each other'
                   ),
                   items: const [
                     DropdownMenuItem(value: 'any', child: Text('Any (OR) - Fire on any trigger')),
                     DropdownMenuItem(value: 'all', child: Text('All (AND) - Fire when all active')),
                     DropdownMenuItem(value: 'sequence', child: Text('Sequence - Fire in order')),
                   ],
                   onChanged: (value) {
                     if (value != null) {
                       store.setDraftTriggerMode(value);
                     }
                   },
                 ),
                 const SizedBox(height: 16),
                 if (store.draftTriggers.isEmpty)
                    const Text('No triggers selected. Tap Configure to add.', style: TextStyle(color: Colors.grey))
                 else
                    ...store.draftTriggers.map((t) => ListTile(
                      leading: const Icon(Icons.flash_on, color: Colors.orange),
                      title: Text(t.type),
                      subtitle: Text(t.params.toString()),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => Navigator.of(context).pushNamed(
                          AppRoutes.triggerSetup,
                          arguments: {'triggerId': t.id},
                        ),
                      ),
                    )),
               ],
             ),
           ),
         ),
      ],
    );
  }

  Widget _buildActionSection(
    BuildContext context, 
    AppStore store,
    List<ActionDefinition> filteredActionCatalog
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             const Text('Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              OutlinedButton.icon(
                onPressed: () {
                   Navigator.of(context).pushNamed(AppRoutes.actionSetup);
                },
                icon: const Icon(Icons.tune),
                label: const Text('Configure'),
              ),
           ],
         ),
         const SizedBox(height: 8),
         if (store.draftActions.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No actions selected. Tap Configure to add.', style: TextStyle(color: Colors.grey)),
            ))
         else
             Column(
               children: [
                 for (int i=0; i<store.draftActions.length; i++)
                    Card(
                      key: ValueKey(store.draftActions[i].id),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${i+1}'),
                          backgroundColor: Colors.blue[100],
                          foregroundColor: Colors.blue[800],
                        ),
                        title: Text(store.draftActions[i].type),
                        subtitle: Text(
                          store.draftActions[i].params.map((k, v) => MapEntry(k, '$k: $v')).values.join('\n'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                           icon: const Icon(Icons.settings),
                           onPressed: () => Navigator.of(context).pushNamed(
                             AppRoutes.actionSetup,
                             arguments: {'actionId': store.draftActions[i].id},
                           ),
                        ),
                      ),
                    ),
               ],
            ),
         const SizedBox(height: 24),
         SizedBox(
           width: double.infinity,
           child: ElevatedButton.icon(
             onPressed: () {
               store.createDraftRecipe();
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Recipe installed locally!')),
               );
             },
             icon: const Icon(Icons.check),
             label: const Text('Build & Install Recipe'),
             style: ElevatedButton.styleFrom(
               padding: const EdgeInsets.all(16),
               textStyle: const TextStyle(fontSize: 16),
             ),
           ),
         ),
      ],
    );
  }
}
