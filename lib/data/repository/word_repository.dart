import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/csv_utils.dart';
import '../../core/file_paths.dart';
import '../models/word_entry.dart';

/// Repository for managing word entries with local storage capabilities
class WordRepository extends ChangeNotifier {
  /// In-memory cache of word entries
  List<WordEntry> _cache = [];

  /// Timer for debouncing write operations
  Timer? _saveDebounceTimer;

  /// Flag to track if initial load has been performed
  bool _isLoaded = false;

  /// Completer for synchronization
  Completer<void>? _loadCompleter;

  /// Constructor
  WordRepository();

  /// Returns an unmodifiable view of the word cache
  List<WordEntry> get cache => List.unmodifiable(_cache);

  /// Checks if the repository has been loaded
  bool get isLoaded => _isLoaded;

  /// Loads word entries from storage
  Future<void> load() async {
    // Prevent multiple simultaneous loads
    if (_loadCompleter != null) {
      return _loadCompleter!.future;
    }

    _loadCompleter = Completer<void>();

    try {
      final jsonPath = await FilePaths.wordsJsonPath;
      final file = File(jsonPath);

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        _cache = WordEntry.listFromJsonString(jsonString);
      } else {
        _cache = [];
      }

      _isLoaded = true;
      notifyListeners(); // Notify UI about data changes
    } catch (e) {
      // If loading fails, initialize with empty cache
      _cache = [];
      _isLoaded = true;
      notifyListeners();
      debugPrint('Error loading word entries: $e');
    } finally {
      _loadCompleter!.complete();
      _loadCompleter = null;
    }
  }

  /// Adds a new word entry to the repository
  Future<void> add(WordEntry entry) async {
    if (!_isLoaded) await load();
    
    _cache.add(entry);
    notifyListeners(); // Immediately notify UI
    _scheduleSave();
  }

  /// Adds multiple word entries to the repository
  Future<void> addAll(List<WordEntry> entries) async {
    if (!_isLoaded) await load();
    
    _cache.addAll(entries);
    notifyListeners(); // Immediately notify UI
    _scheduleSave();
  }

  /// Updates an existing word entry
  Future<void> update(WordEntry updatedEntry) async {
    if (!_isLoaded) await load();
    
    final index = _cache.indexWhere((entry) => entry.id == updatedEntry.id);
    if (index != -1) {
      _cache[index] = updatedEntry;
      notifyListeners(); // Immediately notify UI
      _scheduleSave();
    }
  }

  /// Removes a word entry by ID
  Future<void> remove(String id) async {
    if (!_isLoaded) await load();
    
    final initialLength = _cache.length;
    _cache.removeWhere((entry) => entry.id == id);
    
    // Only notify and save if something was actually removed
    if (_cache.length != initialLength) {
      notifyListeners(); // Immediately notify UI
      _scheduleSave();
    }
  }

  /// Saves the current state to storage with debouncing
  void _scheduleSave() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 600), _save);
  }

  /// Performs the actual save operation
  Future<void> _save() async {
    try {
      // Create a local copy of the cache to avoid race conditions
      final cacheCopy = List<WordEntry>.from(_cache);

      // Convert to JSON string
      final jsonString = WordEntry.listToJsonString(cacheCopy);

      // Get file paths
      final jsonPath = await FilePaths.wordsJsonPath;
      final jsonTempPath = await FilePaths.wordsJsonTempPath;
      final csvPath = await FilePaths.wordsCsvPath;

      // Ensure directories exist
      final jsonFile = File(jsonPath);
      final csvFile = File(csvPath);
      await jsonFile.parent.create(recursive: true);
      await csvFile.parent.create(recursive: true);

      // Write to temporary file first
      final tempFile = File(jsonTempPath);
      await tempFile.writeAsString(jsonString);

      // Perform atomic rename to prevent data corruption
      await tempFile.rename(jsonPath);

      // Update CSV mirror
      final csvString = CsvUtils.entriesToCsv(cacheCopy);
      await csvFile.writeAsString(csvString);
      
      debugPrint('Data saved successfully. JSON: $jsonPath, CSV: $csvPath');
    } catch (e) {
      debugPrint('Error saving dictionary data: $e');
      rethrow;
    }
  }

  /// Force save without debouncing (useful for critical operations)
  Future<void> saveNow() async {
    _saveDebounceTimer?.cancel();
    await _save();
  }

  /// Creates a backup of the current data
  Future<String> backupNow() async {
    try {
      // Ensure we have the latest data saved
      await saveNow();

      // Get file paths
      final jsonPath = await FilePaths.wordsJsonPath;
      final backupPath = await FilePaths.timestampedBackupPath;

      // Copy the current JSON file to the backup location
      final file = File(jsonPath);
      if (await file.exists()) {
        // Ensure backup directory exists
        final backupFile = File(backupPath);
        await backupFile.parent.create(recursive: true);
        
        await file.copy(backupPath);
        return backupPath;
      } else {
        throw Exception('No data file exists to backup');
      }
    } catch (e) {
      debugPrint('Error creating backup: $e');
      rethrow;
    }
  }

  /// Imports data from a JSON string
  Future<int> importFromJson(String jsonString, {bool merge = false}) async {
    try {
      if (!_isLoaded) await load();
      
      final importedEntries = WordEntry.listFromJsonString(jsonString);

      if (importedEntries.isEmpty) {
        return 0;
      }

      if (merge) {
        // For merging, we need to handle duplicates
        final Map<String, WordEntry> entriesMap = {};

        // First add existing entries to the map
        for (final entry in _cache) {
          entriesMap[entry.term.toLowerCase()] = entry;
        }

        // Then add or update with imported entries
        for (final entry in importedEntries) {
          entriesMap[entry.term.toLowerCase()] = entry;
        }

        _cache = entriesMap.values.toList();
      } else {
        // Replace all entries
        _cache = importedEntries;
      }

      notifyListeners(); // Notify UI immediately
      _scheduleSave();
      return importedEntries.length;
    } catch (e) {
      debugPrint('Error importing from JSON: $e');
      rethrow; // Rethrow to let UI handle the error
    }
  }

  /// Imports data from a CSV string
  Future<int> importFromCsv(String csvString, {bool merge = false}) async {
    try {
      if (!_isLoaded) await load();
      
      final importedEntries = CsvUtils.csvToEntries(csvString);

      if (importedEntries.isEmpty) {
        return 0;
      }

      if (merge) {
        // For merging, we need to handle duplicates
        final Map<String, WordEntry> entriesMap = {};

        // First add existing entries to the map
        for (final entry in _cache) {
          entriesMap[entry.term.toLowerCase()] = entry;
        }

        // Then add or update with imported entries
        for (final entry in importedEntries) {
          entriesMap[entry.term.toLowerCase()] = entry;
        }

        _cache = entriesMap.values.toList();
      } else {
        // Replace all entries
        _cache = importedEntries;
      }

      notifyListeners(); // Notify UI immediately
      _scheduleSave();
      return importedEntries.length;
    } catch (e) {
      debugPrint('Error importing from CSV: $e');
      rethrow; // Rethrow to let UI handle the error
    }
  }

  /// Imports entries from simple text format
  Future<int> importFromSimpleText(String text) async {
    try {
      if (!_isLoaded) await load();
      
      final importedEntries = CsvUtils.parseSimpleText(text);

      if (importedEntries.isEmpty) {
        return 0;
      }

      // Always merge for simple text imports
      final Map<String, WordEntry> entriesMap = {};

      // First add existing entries to the map
      for (final entry in _cache) {
        entriesMap[entry.term.toLowerCase()] = entry;
      }

      // Then add or update with imported entries
      for (final entry in importedEntries) {
        entriesMap[entry.term.toLowerCase()] = entry;
      }

      _cache = entriesMap.values.toList();
      notifyListeners(); // Notify UI immediately
      _scheduleSave();
      return importedEntries.length;
    } catch (e) {
      debugPrint('Error importing from simple text: $e');
      rethrow; // Rethrow to let UI handle the error
    }
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    super.dispose();
  }
}