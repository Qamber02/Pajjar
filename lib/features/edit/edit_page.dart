import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/word_entry.dart';
import '../../providers.dart';
import '../widgets/chip_input.dart';

class EditPage extends ConsumerStatefulWidget {
  final WordEntry? wordEntry;

  const EditPage({super.key, this.wordEntry});

  @override
  ConsumerState<EditPage> createState() => _EditPageState();
}

class _EditPageState extends ConsumerState<EditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _termController;
  late final TextEditingController _meaningController;
  late final TextEditingController _phoneticController;
  late final TextEditingController _partOfSpeechController;
  
  List<String> _examples = [];
  List<String> _synonyms = [];
  List<String> _antonyms = [];
  List<String> _tags = [];
  bool _favorite = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing values if editing
    final word = widget.wordEntry;
    _termController = TextEditingController(text: word?.term ?? '');
    _meaningController = TextEditingController(text: word?.meaning ?? '');
    _phoneticController = TextEditingController(text: word?.phonetic ?? '');
    _partOfSpeechController = TextEditingController(text: word?.partOfSpeech ?? '');
    
    if (word != null) {
      _examples = List.from(word.examples);
      _synonyms = List.from(word.synonyms);
      _antonyms = List.from(word.antonyms);
      _tags = List.from(word.tags);
      _favorite = word.favorite;
    }
  }

  @override
  void dispose() {
    _termController.dispose();
    _meaningController.dispose();
    _phoneticController.dispose();
    _partOfSpeechController.dispose();
    super.dispose();
  }

  void _saveWord() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final repository = ref.read(wordRepositoryProvider);
      
      final word = widget.wordEntry?.copyWith(
        term: _termController.text.trim(),
        meaning: _meaningController.text.trim(),
        phonetic: _phoneticController.text.trim(),
        partOfSpeech: _partOfSpeechController.text.trim(),
        examples: _examples,
        synonyms: _synonyms,
        antonyms: _antonyms,
        tags: _tags,
        favorite: _favorite,
        updatedAtEpoch: now,
      ) ?? WordEntry(
        id: const Uuid().v4(),
        term: _termController.text.trim(),
        meaning: _meaningController.text.trim(),
        phonetic: _phoneticController.text.trim(),
        partOfSpeech: _partOfSpeechController.text.trim(),
        examples: _examples,
        synonyms: _synonyms,
        antonyms: _antonyms,
        tags: _tags,
        favorite: _favorite,
        createdAtEpoch: now,
        updatedAtEpoch: now,
      );

      if (widget.wordEntry == null) {
        repository.add(word);
      } else {
        repository.update(word);
      }

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wordEntry == null ? 'Add Word' : 'Edit Word'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveWord,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Term field (required)
              TextFormField(
                controller: _termController,
                decoration: const InputDecoration(
                  labelText: 'Term*',
                  hintText: 'Enter the word or phrase',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a term';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              
              // Meaning field (required)
              TextFormField(
                controller: _meaningController,
                decoration: const InputDecoration(
                  labelText: 'Meaning*',
                  hintText: 'Enter the definition',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a meaning';
                  }
                  return null;
                },
                maxLines: 3,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              
              // Phonetic field (optional)
              TextFormField(
                controller: _phoneticController,
                decoration: const InputDecoration(
                  labelText: 'Phonetic',
                  hintText: 'e.g., /ˈdɪkʃənri/',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              
              // Part of Speech field (optional)
              TextFormField(
                controller: _partOfSpeechController,
                decoration: const InputDecoration(
                  labelText: 'Part of Speech',
                  hintText: 'e.g., noun, verb, adjective',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 24),
              
              // Examples (chip input)
              Text(
                'Examples',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ChipInput(
                values: _examples,
                onChanged: (values) {
                  setState(() {
                    _examples = values;
                  });
                },
                hintText: 'Add an example and press Enter',
              ),
              const SizedBox(height: 24),
              
              // Synonyms (chip input)
              Text(
                'Synonyms',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ChipInput(
                values: _synonyms,
                onChanged: (values) {
                  setState(() {
                    _synonyms = values;
                  });
                },
                hintText: 'Add a synonym and press Enter',
              ),
              const SizedBox(height: 24),
              
              // Antonyms (chip input)
              Text(
                'Antonyms',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ChipInput(
                values: _antonyms,
                onChanged: (values) {
                  setState(() {
                    _antonyms = values;
                  });
                },
                hintText: 'Add an antonym and press Enter',
              ),
              const SizedBox(height: 24),
              
              // Tags (chip input)
              Text(
                'Tags',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ChipInput(
                values: _tags,
                onChanged: (values) {
                  setState(() {
                    _tags = values;
                  });
                },
                hintText: 'Add a tag and press Enter',
              ),
              const SizedBox(height: 24),
              
              // Favorite toggle
              SwitchListTile(
                title: const Text('Favorite'),
                value: _favorite,
                onChanged: (value) {
                  setState(() {
                    _favorite = value;
                  });
                },
                secondary: Icon(
                  Icons.favorite,
                  color: _favorite ? Theme.of(context).colorScheme.primary : Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveWord,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.wordEntry == null ? 'Add Word' : 'Save Changes',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}