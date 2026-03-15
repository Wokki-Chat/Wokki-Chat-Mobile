import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSeparator extends StatelessWidget {
  final DateTime date;

  const DateSeparator({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              DateFormat('MMMM d, y').format(date),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF8C8C8C) : const Color(0xFF666666),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
            ),
          ),
        ],
      ),
    );
  }
}