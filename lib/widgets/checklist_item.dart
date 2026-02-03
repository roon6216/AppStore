import 'package:flutter/material.dart';

class ChecklistItem extends StatelessWidget {
  final String text;
  final bool isImportant;

  const ChecklistItem({
    super.key,
    required this.text,
    this.isImportant = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0, right: 8.0),
            child: Icon(
              Icons.check_circle_outline,
              size: 20,
              color: isImportant ? Colors.red : Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
                color: isImportant ? Colors.red : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
