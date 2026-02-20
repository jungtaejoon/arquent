import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/scaffold_shell.dart';
import '../../state/app_store.dart';

class ScenarioLabScreen extends StatefulWidget {
  const ScenarioLabScreen({super.key});

  @override
  State<ScenarioLabScreen> createState() => _ScenarioLabScreenState();
}

class _ScenarioLabScreenState extends State<ScenarioLabScreen> {
  final AppStore store = AppStore.instance;
  final Map<String, String> scenarioResults = {};
  String reportMarkdown = '';

  static const scenarioRecipeIds = <String>[
    'share-sheet-url-saver',
    'desktop-screenshot-mobile-push',
    'mobile-widget-photo-memo',
    'meeting-audio-capture',
    'sleep-summary-morning-alert',
  ];

  Future<void> _prepare() async {
    await store.refreshMarketplace();
    for (final recipeId in scenarioRecipeIds) {
      if (!store.installed.containsKey(recipeId)) {
        await store.installRecipe(recipeId);
      }
    }
  }

  Future<void> _runScenario(String recipeId) async {
    final result = await store.runRecipe(recipeId);
    if (result == null) {
      setState(() {
        scenarioResults[recipeId] = 'FAILED: not installed';
      });
      return;
    }

    final artifacts = result.artifacts;
    final verdict = _evaluateScenario(recipeId, result.artifacts, result.success);

    setState(() {
      scenarioResults[recipeId] = verdict;
    });
  }

  String _evaluateScenario(
    String recipeId,
    Map<String, dynamic> artifacts,
    bool success,
  ) {
    switch (recipeId) {
      case 'share-sheet-url-saver':
        final fileCount = artifacts['file_count'] as int? ?? 0;
        return success && fileCount > 0
            ? 'PASS: file.write executed'
            : 'FAIL: file.write not observed';
      case 'desktop-screenshot-mobile-push':
        final state = (artifacts['state'] as Map<String, dynamic>? ?? {});
        final status = state['http_status'] as int? ?? -999;
        return success && status >= 200 && status < 400
            ? 'PASS: webhook relayed (http_status=$status)'
            : 'FAIL: webhook relay failed (http_status=$status)';
      case 'mobile-widget-photo-memo':
        final state = (artifacts['state'] as Map<String, dynamic>? ?? {});
        final source = state['capture_source']?.toString() ?? '';
        return success && source.startsWith('webcam://')
            ? 'PASS: camera permission + capture confirmed'
            : 'FAIL: camera capture not confirmed';
      case 'meeting-audio-capture':
        final state = (artifacts['state'] as Map<String, dynamic>? ?? {});
        final source = state['record_source']?.toString() ?? '';
        return success && source.startsWith('microphone://')
            ? 'PASS: microphone permission + recording confirmed'
            : 'FAIL: microphone recording not confirmed';
      case 'sleep-summary-morning-alert':
        return 'BLOCKED ON WEB: use iOS/Android build for real health connector';
      default:
        return success ? 'PASS' : 'FAIL';
    }
  }

  Future<void> _runAllScenarios() async {
    await _prepare();
    for (final recipeId in scenarioRecipeIds) {
      await _runScenario(recipeId);
    }

    final lines = <String>[
      '# Scenario Lab Report',
      '',
      '- generated_at: ${DateTime.now().toIso8601String()}',
      '- status: ${store.status}',
      '',
      '## Results',
    ];

    for (final recipeId in scenarioRecipeIds) {
      lines.add('- $recipeId: ${scenarioResults[recipeId] ?? 'NOT_RUN'}');
    }

    final report = lines.join('\n');
    await Clipboard.setData(ClipboardData(text: report));

    setState(() {
      reportMarkdown = report;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldShell(
      title: 'Scenario Lab',
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  FilledButton(
                    onPressed: store.isBusy ? null : _prepare,
                    child: const Text('Prepare (Install Scenarios)'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: store.isBusy ? null : store.refreshMarketplace,
                    child: const Text('Refresh Marketplace'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: store.isBusy ? null : _runAllScenarios,
                    child: const Text('Run All + Copy Report'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Status: ${store.status}'),
              const SizedBox(height: 16),
              ...scenarioRecipeIds.map(
                (recipeId) => Card(
                  child: ListTile(
                    title: Text(recipeId),
                    subtitle: Text(scenarioResults[recipeId] ?? 'Not run'),
                    trailing: FilledButton(
                      onPressed: store.isBusy ? null : () => _runScenario(recipeId),
                      child: const Text('Run Scenario'),
                    ),
                  ),
                ),
              ),
              if (reportMarkdown.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Latest Report (copied to clipboard):'),
                const SizedBox(height: 8),
                SelectableText(reportMarkdown),
              ],
              const SizedBox(height: 12),
              const Text(
                'Health scenarios require native iOS/Android connector for real device health read.',
              ),
            ],
          );
        },
      ),
    );
  }
}
