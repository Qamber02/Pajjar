import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../data/models/word_entry.dart';
import '../../data/repository/word_repository.dart';
import '../../providers.dart';
import '../details/details_page.dart';
import '../edit/edit_page.dart';
import '../review/review_page.dart';
import '../settings/settings_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the repository directly for immediate updates
    final repository = ref.watch(wordRepositoryProvider);
    final filteredWords = ref.watch(filteredSortedWordsProvider);
    final allTags = ref.watch(allTagsProvider);
    final allPartsOfSpeech = ref.watch(allPartsOfSpeechProvider);
    final activeTags = ref.watch(activeTagsProvider);
    final activePartOfSpeech = ref.watch(activePartOfSpeechProvider);
    final filterFavorites = ref.watch(filterFavoritesProvider);
    final sortOption = ref.watch(sortOptionProvider);
    final dueForReviewCount = ref.watch(dueForReviewWordsProvider).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dictionary'),
        actions: [
          // Due for review indicator
          if (dueForReviewCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Badge(
                label: Text(dueForReviewCount.toString()),
                child: IconButton(
                  icon: const Icon(Icons.timer),
                  tooltip: 'Words due for review',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReviewPage(),
                      ),
                    );
                  },
                ),
              ),
            ),
          // Sort menu
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onSelected: (SortOption option) {
              ref.read(sortOptionProvider.notifier).state = option;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortOption.alphabetical,
                child: Text('A–Z'),
              ),
              const PopupMenuItem(
                value: SortOption.recentlyAdded,
                child: Text('Recently Added'),
              ),
              const PopupMenuItem(
                value: SortOption.dueForReview,
                child: Text('Due for Review'),
              ),
            ],
          ),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search words...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Favorites filter
                FilterChip(
                  label: const Text('Favorites'),
                  selected: filterFavorites,
                  onSelected: (selected) {
                    ref.read(filterFavoritesProvider.notifier).state = selected;
                  },
                  avatar: const Icon(Icons.favorite),
                ),
                const SizedBox(width: 8),
                // Tags filters
                ...allTags.map((tag) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(tag),
                      selected: activeTags.contains(tag),
                      onSelected: (selected) {
                        final newTags = Set<String>.from(activeTags);
                        if (selected) {
                          newTags.add(tag);
                        } else {
                          newTags.remove(tag);
                        }
                        ref.read(activeTagsProvider.notifier).state = newTags;
                      },
                      avatar: const Icon(Icons.tag),
                    ),
                  );
                }),
                // Part of speech filters
                ...allPartsOfSpeech.map((pos) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(pos),
                      selected: activePartOfSpeech.contains(pos),
                      onSelected: (selected) {
                        final newPos = Set<String>.from(activePartOfSpeech);
                        if (selected) {
                          newPos.add(pos);
                        } else {
                          newPos.remove(pos);
                        }
                        ref.read(activePartOfSpeechProvider.notifier).state = newPos;
                      },
                      avatar: const Icon(Icons.category),
                    ),
                  );
                }),
                // Clear filters button
                if (activeTags.isNotEmpty ||
                    activePartOfSpeech.isNotEmpty ||
                    filterFavorites)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ActionChip(
                      label: const Text('Clear Filters'),
                      onPressed: () {
                        ref.read(activeTagsProvider.notifier).state = {};
                        ref.read(activePartOfSpeechProvider.notifier).state = {};
                        ref.read(filterFavoritesProvider.notifier).state = false;
                      },
                      avatar: const Icon(Icons.clear_all),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Word list
          Expanded(
            child: Builder(
              builder: (context) {
                // Show loading if repository is not loaded yet
                if (!repository.isLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (filteredWords.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty ||
                                  activeTags.isNotEmpty ||
                                  activePartOfSpeech.isNotEmpty ||
                                  filterFavorites
                              ? 'No matching words found'
                              : 'No words yet—tap + to add',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredWords.length,
                  itemBuilder: (context, index) {
                    final word = filteredWords[index];
                    return _buildWordListItem(word);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditPage(context),
        tooltip: 'Add Word',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWordListItem(WordEntry word) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _navigateToEditPage(context, word),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (_) => _deleteWord(word),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          word.term,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: word.favorite
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
        ),
        subtitle: Text(
          word.meaning,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: word.isDueForReview
            ? const Icon(Icons.timer, color: Colors.orange)
            : null,
        trailing: word.favorite
            ? Icon(
                Icons.favorite,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsPage(wordId: word.id),
            ),
          );
        },
      ),
    );
  }

  void _navigateToEditPage(BuildContext context, [WordEntry? word]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPage(wordEntry: word),
      ),
    );

    if (result == true) {
      // Word was added or updated - UI should update automatically due to ChangeNotifier
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(word == null ? 'Word added' : 'Word updated'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _deleteWord(WordEntry word) async {
    final repository = ref.read(wordRepositoryProvider);
    
    // Show confirmation dialog for destructive action
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Word'),
        content: Text('Are you sure you want to delete "${word.term}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Store the word for undo functionality
      final deletedWord = word;
      
      // Delete the word
      await repository.remove(word.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${word.term}" deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                repository.add(deletedWord);
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}