import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

import '../../app/scaffold_shell.dart';
import '../../state/app_store.dart';

class BuilderScreen extends StatefulWidget {
  const BuilderScreen({super.key});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen> {
  late final TextEditingController _idController;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: AppStore.instance.draftRecipeId);
  }

  @override
  void dispose() {
    _idController.dispose();
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
          final manifestPreview = const JsonEncoder.withIndent('  ').convert(
            store.buildDraftManifest(),
          );
          final flowPreview = const JsonEncoder.withIndent('  ').convert(
            store.buildDraftFlow(),
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Recipe ID'),
              const SizedBox(height: 8),
              TextField(
                controller: _idController,
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
