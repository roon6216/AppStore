import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatelessWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime> onDateSelected;
  final String label;

  const DatePickerField({
    super.key,
    this.initialDate,
    required this.onDateSelected,
    required this.label,
  });

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy. MM. dd', 'ko');
    final displayDate = initialDate ?? DateTime.now();

    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          dateFormat.format(displayDate),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
