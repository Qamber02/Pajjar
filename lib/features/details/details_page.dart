import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/word_entry.dart';
import '../../providers.dart';
import '../edit/edit_page.dart';
import '../review/review_page.dart';

class DetailsPage extends ConsumerWidget {
  final String wordId;

  const DetailsPage({super.key, required this.wordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final words = ref.watch(wordsProvider);

    final word = words.firstWhere(
      (w) => w.id == wordId,
      orElse: () => throw Exception('Word not found'),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(word.term),
        actions: [
          // Favorite toggle
          IconButton(
            icon: Icon(
              word.favorite ? Icons.favorite : Icons.favorite_border,
              color: word.favorite
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () {
              final repository = ref.read(wordRepositoryProvider);
              repository.update(word.copyWith(favorite: !word.favorite));
            },
            tooltip: word.favorite
                ? 'Remove from favorites'
                : 'Add to favorites',
          ),
          // Share
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareWord(context, word),
            tooltip: 'Share',
          ),
          // Edit
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditPage(context, ref, word),
            tooltip: 'Edit',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phonetic
            if (word.phonetic?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  word.phonetic!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              ),

            // Part of Speech
            if (word.partOfSpeech?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Chip(
                  label: Text(word.partOfSpeech!),
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),

            // Meaning
            _buildSection(
              context,
              'Meaning',
              child: SelectableText(
                word.meaning,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),

            // Examples
            if (word.examples.isNotEmpty)
              _buildSection(
                context,
                'Examples',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: word.examples.map((example) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: SelectableText(
                        '• $example',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Synonyms
            if (word.synonyms.isNotEmpty)
              _buildSection(
                context,
                'Synonyms',
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: word.synonyms.map((synonym) {
                    return Chip(
                      label: Text(synonym),
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .secondaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Antonyms
            if (word.antonyms.isNotEmpty)
              _buildSection(
                context,
                'Antonyms',
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: word.antonyms.map((antonym) {
                    return Chip(
                      label: Text(antonym),
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
                      labelStyle: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Tags
            if (word.tags.isNotEmpty)
              _buildSection(
                context,
                'Tags',
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: word.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      avatar: const Icon(Icons.tag, size: 16),
                    );
                  }).toList(),
                ),
              ),

            // Review status
            _buildSection(
              context,
              'Review Status',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stage: ${word.reviewStage} / 5'),
                  const SizedBox(height: 8),
                  if (word.isDueForReview)
                    const Text('Status: Due for review')
                  else
                    Text(
                      'Next review: ${_formatNextReview(word.nextReviewEpoch)}',
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _addToReview(context, ref, word),
                    icon: const Icon(Icons.timer),
                    label: const Text('Review Now'),
                  ),
                ],
              ),
            ),

            // Copy button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: () => _copyToClipboard(context, word),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy to Clipboard'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title,
      {required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  String _formatNextReview(int epoch) {
    final date = DateTime.fromMillisecondsSinceEpoch(epoch);
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} from now';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} from now';
    } else {
      return 'Less than an hour from now';
    }
  }

  void _navigateToEditPage(
      BuildContext context, WidgetRef ref, WordEntry word) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPage(wordEntry: word),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Word updated'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareWord(BuildContext context, WordEntry word) {
    final text = '''${word.term}${word.phonetic?.isNotEmpty == true ? ' ${word.phonetic}' : ''}
${word.partOfSpeech?.isNotEmpty == true ? '(${word.partOfSpeech})' : ''}

Meaning: ${word.meaning}

${word.examples.isNotEmpty ? 'Examples:\n${word.examples.map((e) => '• $e').join('\n')}\n' : ''}${word.synonyms.isNotEmpty ? 'Synonyms: ${word.synonyms.join(', ')}\n' : ''}${word.antonyms.isNotEmpty ? 'Antonyms: ${word.antonyms.join(', ')}' : ''}''';

    Share.share(text, subject: 'Word: ${word.term}');
  }

  void _copyToClipboard(BuildContext context, WordEntry word) {
    final text = '''${word.term}${word.phonetic?.isNotEmpty == true ? ' ${word.phonetic}' : ''}
${word.partOfSpeech?.isNotEmpty == true ? '(${word.partOfSpeech})' : ''}

Meaning: ${word.meaning}''';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _addToReview(BuildContext context, WidgetRef ref, WordEntry word) {
    final repository = ref.read(wordRepositoryProvider);
    final updatedWord = word.copyWith(
      reviewStage: 0,
      nextReviewEpoch: DateTime.now().millisecondsSinceEpoch,
    );
    repository.update(updatedWord);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReviewPage(),
      ),
    );
  }
}
