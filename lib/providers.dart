import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/models/word_entry.dart';
import 'data/repository/word_repository.dart';

/// Repository provider (singleton with ChangeNotifier)
final wordRepositoryProvider = ChangeNotifierProvider<WordRepository>((ref) {
  final repository = WordRepository();
  ref.onDispose(() => repository.dispose());
  return repository;
});

/// Provider for watching the words list
final wordsProvider = Provider<List<WordEntry>>((ref) {
  final repository = ref.watch(wordRepositoryProvider);

  // Ensure repository loads data once
  if (!repository.isLoaded) {
    repository.load();
  }

  return repository.cache;
});

/// Provider for the current search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for filtering favorites
final filterFavoritesProvider = StateProvider<bool>((ref) => false);

/// Provider for active tags filter
final activeTagsProvider = StateProvider<Set<String>>((ref) => {});

/// Provider for active part of speech filter
final activePartOfSpeechProvider = StateProvider<Set<String>>((ref) => {});

/// Enum for sort options
enum SortOption {
  alphabetical,
  recentlyAdded,
  dueForReview,
}

/// Provider for the current sort option
final sortOptionProvider =
    StateProvider<SortOption>((ref) => SortOption.alphabetical);

/// Provider for the app theme mode
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Provider for text scale factor
final textScaleFactorProvider = StateProvider<double>((ref) => 1.0);

/// Provider for filtered and sorted words
final filteredSortedWordsProvider = Provider<List<WordEntry>>((ref) {
  final words = ref.watch(wordsProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final filterFavorites = ref.watch(filterFavoritesProvider);
  final activeTags = ref.watch(activeTagsProvider);
  final activePartOfSpeech = ref.watch(activePartOfSpeechProvider);
  final sortOption = ref.watch(sortOptionProvider);

  // Apply filters
  List<WordEntry> filtered = words.where((word) {
    // Search query filter
    if (searchQuery.isNotEmpty) {
      final termMatch = word.term.toLowerCase().contains(searchQuery);
      final meaningMatch = word.meaning.toLowerCase().contains(searchQuery);
      final tagMatch =
          word.tags.any((tag) => tag.toLowerCase().contains(searchQuery));

      if (!(termMatch || meaningMatch || tagMatch)) {
        return false;
      }
    }

    // Favorites filter
    if (filterFavorites && !word.favorite) {
      return false;
    }

    // Tags filter
    if (activeTags.isNotEmpty &&
        !word.tags.any((tag) => activeTags.contains(tag))) {
      return false;
    }

    // Part of speech filter
    if (activePartOfSpeech.isNotEmpty &&
        (word.partOfSpeech == null ||
            !activePartOfSpeech.contains(word.partOfSpeech))) {
      return false;
    }

    return true;
  }).toList();

  // Apply sorting
  switch (sortOption) {
    case SortOption.alphabetical:
      filtered.sort(
          (a, b) => a.term.toLowerCase().compareTo(b.term.toLowerCase()));
      break;
    case SortOption.recentlyAdded:
      filtered.sort((a, b) => b.createdAtEpoch.compareTo(a.createdAtEpoch));
      break;
    case SortOption.dueForReview:
      filtered.sort((a, b) => a.nextReviewEpoch.compareTo(b.nextReviewEpoch));
      break;
  }

  return filtered;
});

/// Provider for words due for review
final dueForReviewWordsProvider = Provider<List<WordEntry>>((ref) {
  final words = ref.watch(wordsProvider);
  final now = DateTime.now().millisecondsSinceEpoch;

  return words
      .where((word) => word.nextReviewEpoch <= now)
      .toList()
    ..sort((a, b) => a.nextReviewEpoch.compareTo(b.nextReviewEpoch));
});

/// Provider for all unique tags in the dictionary
final allTagsProvider = Provider<List<String>>((ref) {
  final words = ref.watch(wordsProvider);
  final Set<String> tags = {};

  for (final word in words) {
    tags.addAll(word.tags);
  }
  return tags.toList()..sort();
});

/// Provider for all unique parts of speech in the dictionary
final allPartsOfSpeechProvider = Provider<List<String>>((ref) {
  final words = ref.watch(wordsProvider);
  final Set<String> partsOfSpeech = {};

  for (final word in words) {
    if (word.partOfSpeech != null && word.partOfSpeech!.isNotEmpty) {
      partsOfSpeech.add(word.partOfSpeech!);
    }
  }
  return partsOfSpeech.toList()..sort();
});
