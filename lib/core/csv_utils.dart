import 'dart:convert';
import 'package:csv/csv.dart';
import '../data/models/word_entry.dart';

/// Utility class for handling CSV operations
class CsvUtils {
  /// Private constructor to prevent instantiation
  CsvUtils._();

  /// The delimiter used for separating values within a cell
  static const String inCellDelimiter = '|';

  /// Converts a list of WordEntry objects to CSV format
  static String entriesToCsv(List<WordEntry> entries) {
    // Define CSV header
    final List<List<dynamic>> csvData = [
      [
        'id',
        'term',
        'phonetic',
        'partOfSpeech',
        'meaning',
        'examples',
        'synonyms',
        'antonyms',
        'tags',
        'favorite',
        'createdAtEpoch',
        'updatedAtEpoch',
        'reviewStage',
        'nextReviewEpoch',
      ],
    ];

    // Add data rows
    for (final entry in entries) {
      csvData.add([
        entry.id,
        entry.term,
        entry.phonetic ?? '',
        entry.partOfSpeech ?? '',
        entry.meaning,
        _listToString(entry.examples),
        _listToString(entry.synonyms),
        _listToString(entry.antonyms),
        _listToString(entry.tags),
        entry.favorite ? 'true' : 'false',
        entry.createdAtEpoch.toString(),
        entry.updatedAtEpoch.toString(),
        entry.reviewStage.toString(),
        entry.nextReviewEpoch.toString(),
      ]);
    }

    // Convert to CSV string
    return const ListToCsvConverter().convert(csvData);
  }

  /// Parses a CSV string into a list of WordEntry objects
  static List<WordEntry> csvToEntries(String csvString) {
    try {
      // Parse CSV
      final List<List<dynamic>> csvData =
          const CsvToListConverter().convert(csvString);

      // Ensure there's data and a header row
      if (csvData.isEmpty || csvData.length < 2) {
        return [];
      }

      // Extract header row to map column indices
      final headerRow = csvData[0];
      final Map<String, int> columnIndices = {};

      for (int i = 0; i < headerRow.length; i++) {
        columnIndices[headerRow[i].toString()] = i;
      }

      // Function to safely get a value from a row
      T? getValue<T>(List<dynamic> row, String columnName) {
        final index = columnIndices[columnName];
        if (index == null || index >= row.length) {
          return null;
        }
        final value = row[index];
        if (value == null || value.toString().isEmpty) {
          return null;
        }
        return value as T;
      }

      // Parse data rows
      final List<WordEntry> entries = [];
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];

        // Skip rows that don't have the minimum required fields
        final term = getValue<String>(row, 'term');
        final meaning = getValue<String>(row, 'meaning');
        if (term == null || meaning == null) {
          continue;
        }

        try {
          final entry = WordEntry(
            id: getValue<String>(row, 'id'),
            term: term,
            phonetic: getValue<String>(row, 'phonetic'),
            partOfSpeech: getValue<String>(row, 'partOfSpeech'),
            meaning: meaning,
            examples: _stringToList(getValue<String>(row, 'examples')),
            synonyms: _stringToList(getValue<String>(row, 'synonyms')),
            antonyms: _stringToList(getValue<String>(row, 'antonyms')),
            tags: _stringToList(getValue<String>(row, 'tags')),
            favorite: getValue<String>(row, 'favorite') == 'true',
            createdAtEpoch: int.tryParse(getValue<String>(row, 'createdAtEpoch') ?? '') ?? 
                DateTime.now().millisecondsSinceEpoch,
            updatedAtEpoch: int.tryParse(getValue<String>(row, 'updatedAtEpoch') ?? '') ?? 
                DateTime.now().millisecondsSinceEpoch,
            reviewStage: int.tryParse(getValue<String>(row, 'reviewStage') ?? '') ?? 0,
            nextReviewEpoch: int.tryParse(getValue<String>(row, 'nextReviewEpoch') ?? '') ?? 
                DateTime.now().millisecondsSinceEpoch,
          );
          entries.add(entry);
        } catch (e) {
          // Skip entries that fail to parse
          continue;
        }
      }

      return entries;
    } catch (e) {
      // Return empty list if parsing fails
      return [];
    }
  }

  /// Converts a list of strings to a single string with the in-cell delimiter
  static String _listToString(List<String> list) {
    return list.join(inCellDelimiter);
  }

  /// Converts a delimited string back to a list of strings
  static List<String> _stringToList(String? str) {
    if (str == null || str.isEmpty) {
      return [];
    }
    return str.split(inCellDelimiter).map((s) => s.trim()).toList();
  }

  /// Parses a simple text format where each line is "term — meaning"
  static List<WordEntry> parseSimpleText(String text) {
    final List<WordEntry> entries = [];
    final lines = LineSplitter.split(text).where((line) => line.trim().isNotEmpty);

    for (final line in lines) {
      // Look for term — meaning pattern (with em dash)
      final parts = line.split('—');
      if (parts.length >= 2) {
        final term = parts[0].trim();
        final meaning = parts.sublist(1).join('—').trim();
        if (term.isNotEmpty && meaning.isNotEmpty) {
          entries.add(WordEntry(
            term: term,
            meaning: meaning,
          ));
        }
      }
    }

    return entries;
  }
}