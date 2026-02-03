import 'package:flutter/material.dart';

class DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool allowCustomInput;

  const DropdownField({
    super.key,
    required this.label,
    this.value,
    required this.options,
    required this.onChanged,
    this.allowCustomInput = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      value: value,
      items: [
        if (allowCustomInput)
          const DropdownMenuItem<String>(
            value: null,
            child: Text('직접 입력'),
          ),
        ...options.map((option) => DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            )),
      ],
      onChanged: onChanged,
    );
  }
}
