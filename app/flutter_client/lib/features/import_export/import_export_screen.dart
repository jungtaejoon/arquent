import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/scaffold_shell.dart';
import '../../state/app_store.dart';

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedRecipeId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return AppScaffoldShell(
      title: 'Import / Export',
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final installedIds = store.installed.keys.toList()..sort();
          if (_selectedRecipeId == null && installedIds.isNotEmpty) {
            _selectedRecipeId = installedIds.first;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Import recipe package (JSON payload)'),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                minLines: 6,
                maxLines: 12,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '{"id":"...","manifest":"...","flow":"..."}',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton(
                    onPressed: () {
                      try {
                        store.importRecipePackage(_controller.text);
                      } catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Import failed: $error')),
                        );
                      }
                    },
                    child: const Text('Import to Local'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      _controller.clear();
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text('Export installed recipe package'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRecipeId,
                items: installedIds
                    .map((id) => DropdownMenuItem(value: id, child: Text(id)))
                    .toList(),
                onChanged: installedIds.isEmpty
                    ? null
                    : (value) {
                        setState(() {
                          _selectedRecipeId = value;
                        });
                      },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Installed recipe',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton(
                    onPressed: installedIds.isEmpty || _selectedRecipeId == null
                        ? null
                        : () async {
                            final exported = store.exportRecipePackage(_selectedRecipeId!);
                            _controller.text = exported;
                            await Clipboard.setData(ClipboardData(text: exported));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Exported and copied to clipboard')),
                              );
                            }
                          },
                    child: const Text('Export + Copy'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Status: ${store.status}'),
            ],
          );
        },
      ),
    );
  }
}
