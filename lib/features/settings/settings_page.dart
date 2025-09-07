import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/file_paths.dart';
import '../../data/repository/word_repository.dart';
import '../../providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final textScaleFactor = ref.watch(textScaleFactorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme settings
          _buildSectionHeader(context, 'Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: const Text('Choose light, dark, or system theme'),
            leading: const Icon(Icons.brightness_6),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  ref.read(themeModeProvider.notifier).state = newValue;
                }
              },
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark'),
                ),
              ],
              underline: const SizedBox(),
            ),
          ),
          // Text size slider
          ListTile(
            title: const Text('Text Size'),
            subtitle: Slider(
              value: textScaleFactor,
              min: 0.8,
              max: 1.4,
              divisions: 6,
              label: textScaleFactor.toStringAsFixed(1),
              onChanged: (double value) {
                ref.read(textScaleFactorProvider.notifier).state = value;
              },
            ),
            leading: const Icon(Icons.text_fields),
          ),
          // Preview text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Preview text at this size',
              style: Theme.of(context).textTheme.bodyLarge,
              textScaler: TextScaler.linear(textScaleFactor),
            ),
          ),
          const Divider(),

          // Data management
          _buildSectionHeader(context, 'Data Management'),
          ListTile(
            title: const Text('Backup Now'),
            subtitle: const Text('Create a timestamped backup file'),
            leading: const Icon(Icons.backup),
            onTap: () => _backupData(context, ref),
          ),
          ListTile(
            title: const Text('Import Data'),
            subtitle: const Text('Import from JSON or CSV file'),
            leading: const Icon(Icons.upload_file),
            onTap: () => _showImportDialog(context, ref),
          ),
          ListTile(
            title: const Text('Export Data'),
            subtitle: const Text('Share JSON and CSV files'),
            leading: const Icon(Icons.share),
            onTap: () => _exportData(context, ref),
          ),
          ListTile(
            title: const Text('Show Data Location'),
            subtitle: const Text('View where files are stored'),
            leading: const Icon(Icons.folder),
            onTap: () => _showDataLocation(context),
          ),
          const Divider(),

          // About section
          _buildSectionHeader(context, 'About'),
          const ListTile(
            title: Text('Dictionary App'),
            subtitle: Text('Version 1.0.0'),
            leading: Icon(Icons.info),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Future<void> _backupData(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(wordRepositoryProvider);
      final backupPath = await repository.backupNow();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup created at: ${backupPath.split('/').last}'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () {
                Share.shareXFiles(
                  [XFile(backupPath)],
                  subject: 'Dictionary Backup',
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose import format and method:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildImportOption(
              context,
              title: 'Import from JSON',
              subtitle: 'Import from a words.json file',
              icon: Icons.data_object,
              onTap: () => _importFromClipboard(context, ref, ImportFormat.json),
            ),
            const SizedBox(height: 8),
            _buildImportOption(
              context,
              title: 'Import from CSV',
              subtitle: 'Import from a words.csv file',
              icon: Icons.table_chart,
              onTap: () => _importFromClipboard(context, ref, ImportFormat.csv),
            ),
            const SizedBox(height: 8),
            _buildImportOption(
              context,
              title: 'Quick Import',
              subtitle: 'Import from simple text (term — meaning)',
              icon: Icons.text_snippet,
              onTap: () => _importFromClipboard(context, ref, ImportFormat.text),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildImportOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _importFromClipboard(BuildContext context, WidgetRef ref, ImportFormat format) {
    Navigator.pop(context); // Close the dialog
    
    // Show a dialog to paste content
    showDialog(
      context: context,
      builder: (context) => _ImportDialog(format: format),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final jsonPath = FilePaths.getWordsJsonPath();
      final csvPath = FilePaths.getWordsCsvPath();
      
      final jsonFile = File(jsonPath);
      final csvFile = File(csvPath);
      
      if (!jsonFile.existsSync() || !csvFile.existsSync()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data files not found')),
          );
        }
        return;
      }
      
      if (context.mounted) {
        Share.shareXFiles(
          [XFile(jsonPath), XFile(csvPath)],
          subject: 'Dictionary Data',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _showDataLocation(BuildContext context) async {
    final jsonPath = FilePaths.getWordsJsonPath();
    final csvPath = FilePaths.getWordsCsvPath();
    final backupDir = FilePaths.getBackupDirPath();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your dictionary data is stored at:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPathInfo(context, 'Main Data (JSON):', jsonPath),
            const SizedBox(height: 8),
            _buildPathInfo(context, 'CSV Mirror:', csvPath),
            const SizedBox(height: 8),
            _buildPathInfo(context, 'Backups Directory:', backupDir),
            const SizedBox(height: 16),
            const Text(
              'Note: On iOS, these files are in the app sandbox. On Android, they are in the app\'s private documents directory.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPathInfo(BuildContext context, String label, String path) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            path,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

enum ImportFormat {
  json,
  csv,
  text,
}

class _ImportDialog extends ConsumerStatefulWidget {
  final ImportFormat format;

  const _ImportDialog({required this.format});

  @override
  ConsumerState<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends ConsumerState<_ImportDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _mergeWithExisting = true;
  bool _isImporting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String formatName;
    switch (widget.format) {
      case ImportFormat.json:
        formatName = 'JSON';
        break;
      case ImportFormat.csv:
        formatName = 'CSV';
        break;
      case ImportFormat.text:
        formatName = 'Text';
        break;
      default:
        formatName = 'Unknown';
    }

    return AlertDialog(
      title: Text('Import from $formatName'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Paste your $formatName content below:'),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 8,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: _getHintText(),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.format != ImportFormat.text) // No merge option for text import
            Row(
              children: [
                Checkbox(
                  value: _mergeWithExisting,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _mergeWithExisting = value;
                      });
                    }
                  },
                ),
                const Text('Merge with existing data'),
              ],
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isImporting ? null : _importData,
          child: _isImporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Import'),
        ),
      ],
    );
  }

  String _getHintText() {
    switch (widget.format) {
      case ImportFormat.json:
        return '''
{
  "words": [
    {
      "id": "...",
      "term": "example",
      "meaning": "..."
    }
  ]
}
''';
      case ImportFormat.csv:
        return '''id,term,meaning,phonetic,...''';
      case ImportFormat.text:
        return '''term — meaning
term — meaning
...''';
    }
  }

  Future<void> _importData() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      setState(() {
        _error = 'Please enter some content';
      });
      return;
    }

    setState(() {
      _isImporting = true;
      _error = null;
    });

    try {
      final repository = ref.read(wordRepositoryProvider);
      int importedCount = 0;

      switch (widget.format) {
        case ImportFormat.json:
          importedCount = await repository.importFromJson(
            content,
            merge: _mergeWithExisting,
          );
          break;
        case ImportFormat.csv:
          importedCount = await repository.importFromCsv(
            content,
            merge: _mergeWithExisting,
          );
          break;
        case ImportFormat.text:
          importedCount = await repository.importFromSimpleText(content);
          break;
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported $importedCount word${importedCount != 1 ? 's' : ''}'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
        _error = 'Import failed: $e';
      });
    }
  }
}