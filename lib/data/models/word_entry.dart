import 'dart:convert';
import 'package:uuid/uuid.dart';

/// A model class representing a dictionary word entry with all its properties.
class WordEntry {
  /// Unique identifier for the word entry (UUID v4)
  final String id;
  
  /// The word or phrase itself
  final String term;
  
  /// Optional phonetic pronunciation guide
  final String? phonetic;
  
  /// Optional part of speech (noun, verb, adjective, etc.)
  final String? partOfSpeech;
  
  /// The definition or meaning of the word
  final String meaning;
  
  /// Optional list of example sentences using the word
  final List<String> examples;
  
  /// Optional list of synonyms
  final List<String> synonyms;
  
  /// Optional list of antonyms
  final List<String> antonyms;
  
  /// Optional list of tags for categorization
  final List<String> tags;
  
  /// Whether the word is marked as favorite
  final bool favorite;
  
  /// Creation timestamp in milliseconds since epoch
  final int createdAtEpoch;
  
  /// Last update timestamp in milliseconds since epoch
  final int updatedAtEpoch;
  
  /// Spaced repetition review stage (0-5)
  final int reviewStage;
  
  /// Next scheduled review timestamp in milliseconds since epoch
  final int nextReviewEpoch;

  WordEntry({
    String? id,
    required this.term,
    this.phonetic,
    this.partOfSpeech,
    required this.meaning,
    List<String>? examples,
    List<String>? synonyms,
    List<String>? antonyms,
    List<String>? tags,
    bool? favorite,
    int? createdAtEpoch,
    int? updatedAtEpoch,
    int? reviewStage,
    int? nextReviewEpoch,
  }) : 
    id = id ?? const Uuid().v4(),
    examples = examples ?? [],
    synonyms = synonyms ?? [],
    antonyms = antonyms ?? [],
    tags = tags ?? [],
    favorite = favorite ?? false,
    createdAtEpoch = createdAtEpoch ?? DateTime.now().millisecondsSinceEpoch,
    updatedAtEpoch = updatedAtEpoch ?? DateTime.now().millisecondsSinceEpoch,
    reviewStage = reviewStage ?? 0,
    nextReviewEpoch = nextReviewEpoch ?? DateTime.now().millisecondsSinceEpoch;

  /// Creates a copy of this WordEntry with the given fields replaced with new values
  WordEntry copyWith({
    String? term,
    String? phonetic,
    String? partOfSpeech,
    String? meaning,
    List<String>? examples,
    List<String>? synonyms,
    List<String>? antonyms,
    List<String>? tags,
    bool? favorite,
    int? updatedAtEpoch,
    int? reviewStage,
    int? nextReviewEpoch,
  }) {
    return WordEntry(
      id: id,
      term: term ?? this.term,
      phonetic: phonetic ?? this.phonetic,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      meaning: meaning ?? this.meaning,
      examples: examples ?? this.examples,
      synonyms: synonyms ?? this.synonyms,
      antonyms: antonyms ?? this.antonyms,
      tags: tags ?? this.tags,
      favorite: favorite ?? this.favorite,
      createdAtEpoch: createdAtEpoch,
      updatedAtEpoch: updatedAtEpoch ?? DateTime.now().millisecondsSinceEpoch,
      reviewStage: reviewStage ?? this.reviewStage,
      nextReviewEpoch: nextReviewEpoch ?? this.nextReviewEpoch,
    );
  }

  /// Converts the WordEntry to a JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'term': term,
      'phonetic': phonetic,
      'partOfSpeech': partOfSpeech,
      'meaning': meaning,
      'examples': examples,
      'synonyms': synonyms,
      'antonyms': antonyms,
      'tags': tags,
      'favorite': favorite,
      'createdAtEpoch': createdAtEpoch,
      'updatedAtEpoch': updatedAtEpoch,
      'reviewStage': reviewStage,
      'nextReviewEpoch': nextReviewEpoch,
    };
  }

  /// Creates a WordEntry from a JSON Map
  factory WordEntry.fromJson(Map<String, dynamic> json) {
    return WordEntry(
      id: json['id'] as String,
      term: json['term'] as String,
      phonetic: json['phonetic'] as String?,
      partOfSpeech: json['partOfSpeech'] as String?,
      meaning: json['meaning'] as String,
      examples: (json['examples'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      synonyms: (json['synonyms'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      antonyms: (json['antonyms'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      favorite: json['favorite'] as bool? ?? false,
      createdAtEpoch: json['createdAtEpoch'] as int,
      updatedAtEpoch: json['updatedAtEpoch'] as int,
      reviewStage: json['reviewStage'] as int? ?? 0,
      nextReviewEpoch: json['nextReviewEpoch'] as int? ?? 0,
    );
  }

  /// Converts a list of WordEntry objects to a JSON string
  static String listToJsonString(List<WordEntry> entries) {
    final List<Map<String, dynamic>> jsonList = 
        entries.map((entry) => entry.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Creates a list of WordEntry objects from a JSON string
  static List<WordEntry> listFromJsonString(String jsonString) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => WordEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return empty list if parsing fails
      return [];
    }
  }

  /// Updates the review stage and next review date based on user feedback
  WordEntry updateReviewStage(String difficulty) {
    int newStage = reviewStage;
    int daysUntilNextReview = 1;

    switch (difficulty) {
      case 'easy':
        newStage = (reviewStage + 2).clamp(0, 5);
        daysUntilNextReview = 7 * newStage;
        break;
      case 'good':
        newStage = (reviewStage + 1).clamp(0, 5);
        daysUntilNextReview = 2 * newStage;
        break;
      case 'hard':
        newStage = (reviewStage - 1).clamp(0, 5);
        daysUntilNextReview = 1;
        break;
    }

    // If stage is 0, set review to tomorrow regardless of difficulty
    if (newStage == 0) {
      daysUntilNextReview = 1;
    }

    // Calculate next review date
    final nextReview = DateTime.now().add(Duration(days: daysUntilNextReview));

    return copyWith(
      reviewStage: newStage,
      nextReviewEpoch: nextReview.millisecondsSinceEpoch,
      updatedAtEpoch: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Checks if the word is due for review
  bool get isDueForReview {
    return DateTime.now().millisecondsSinceEpoch >= nextReviewEpoch;
  }

  @override
  String toString() => 'WordEntry(id: $id, term: $term)';
}