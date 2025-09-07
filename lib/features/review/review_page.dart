import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/word_entry.dart';
import '../../providers.dart';

class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key});

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  bool _showMeaning = false;
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final dueWords = ref.watch(dueForReviewWordsProvider);

    if (dueWords.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Review'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                'All caught up!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                'No words due for review at this time.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Dictionary'),
              ),
            ],
          ),
        ),
      );
    }

    // If we've reviewed all words, show completion screen
    if (_currentIndex >= dueWords.length) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Review Complete'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.celebration,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 24),
              Text(
                'Review Complete!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'You reviewed ${dueWords.length} word${dueWords.length > 1 ? 's' : ''}.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Dictionary'),
              ),
            ],
          ),
        ),
      );
    }

    final currentWord = dueWords[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '${_currentIndex + 1}/${dueWords.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentIndex + 1) / dueWords.length,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            color: Theme.of(context).colorScheme.primary,
          ),

          // Flashcard content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Term
                  Text(
                    currentWord.term,
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),

                  if (currentWord.phonetic?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      currentWord.phonetic!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ],

                  if (currentWord.partOfSpeech?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    Chip(
                      label: Text(currentWord.partOfSpeech!),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // Meaning (hidden initially)
                  if (_showMeaning) ...[
                    const Divider(),
                    const SizedBox(height: 24),
                    Text(
                      'Meaning:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentWord.meaning,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),

                    // Examples (if any)
                    if (currentWord.examples.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Example:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentWord.examples.first,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ] else
                    Column(
                      children: [
                        // Show meaning button
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showMeaning = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: const Text('Show Meaning'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Review buttons (only shown when meaning is visible)
          if (_showMeaning)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildReviewButton(
                    label: 'Hard',
                    color: Colors.red,
                    onPressed: () => _updateReviewStatus(
                        currentWord, ReviewDifficulty.hard),
                  ),
                  _buildReviewButton(
                    label: 'Good',
                    color: Colors.blue,
                    onPressed: () => _updateReviewStatus(
                        currentWord, ReviewDifficulty.good),
                  ),
                  _buildReviewButton(
                    label: 'Easy',
                    color: Colors.green,
                    onPressed: () => _updateReviewStatus(
                        currentWord, ReviewDifficulty.easy),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(label),
    );
  }

  void _updateReviewStatus(WordEntry word, ReviewDifficulty difficulty) {
    final repository = ref.read(wordRepositoryProvider);

    // Calculate new review stage and next review date based on difficulty
    int newStage;
    int daysUntilNextReview;

    switch (difficulty) {
      case ReviewDifficulty.easy:
        // Easy: stage + 2 (max 5), nextReviewEpoch in 7d * stage
        newStage = word.reviewStage + 2;
        if (newStage > 5) newStage = 5;
        daysUntilNextReview = 7 * newStage;
        break;

      case ReviewDifficulty.good:
        // Good: stage + 1, nextReviewEpoch in 2d * stage
        newStage = word.reviewStage + 1;
        if (newStage > 5) newStage = 5;
        daysUntilNextReview = 2 * newStage;
        break;

      case ReviewDifficulty.hard:
        // Hard: stage stays or -1 (min 0), nextReviewEpoch in 1d
        newStage = word.reviewStage > 0 ? word.reviewStage - 1 : 0;
        daysUntilNextReview = 1;
        break;
    }

    // Calculate next review date
    final now = DateTime.now();
    final nextReview = now.add(Duration(days: daysUntilNextReview));

    // Update word
    final updatedWord = word.copyWith(
      reviewStage: newStage,
      nextReviewEpoch: nextReview.millisecondsSinceEpoch,
    );

    repository.update(updatedWord);

    // Move to next word
    setState(() {
      _currentIndex++;
      _showMeaning = false;
    });
  }
}

enum ReviewDifficulty {
  hard,
  good,
  easy,
}
