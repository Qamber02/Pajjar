import 'package:flutter/material.dart';

/// A widget for inputting multiple values as chips.
/// Used for examples, synonyms, antonyms, and tags in the dictionary app.
class ChipInput extends StatefulWidget {
  final List<String> values;
  final Function(List<String>) onChanged;
  final String hintText;

  const ChipInput({
    super.key,
    required this.values,
    required this.onChanged,
    required this.hintText,
  });

  @override
  State<ChipInput> createState() => _ChipInputState();
}

class _ChipInputState extends State<ChipInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addValue(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isNotEmpty && !widget.values.contains(trimmedValue)) {
      final newValues = List<String>.from(widget.values);
      newValues.add(trimmedValue);
      widget.onChanged(newValues);
      _controller.clear();
    }
  }

  void _removeValue(String value) {
    final newValues = List<String>.from(widget.values);
    newValues.remove(value);
    widget.onChanged(newValues);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display existing chips
        if (widget.values.isNotEmpty)
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: widget.values.map((value) {
              return InputChip(
                label: Text(value),
                onDeleted: () => _removeValue(value),
                deleteIconColor: Theme.of(context).colorScheme.onSurface,
              );
            }).toList(),
          ),
        if (widget.values.isNotEmpty) const SizedBox(height: 8),
        
        // Input field for new values
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  _addValue(_controller.text);
                }
              },
            ),
          ),
          onSubmitted: (value) {
            _addValue(value);
            _focusNode.requestFocus(); // Keep focus after adding
          },
        ),
      ],
    );
  }
}