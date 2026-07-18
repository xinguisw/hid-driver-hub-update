import 'package:flutter/material.dart';

/// One settings group card: title + text lines (items).
class SettingsBlockCard extends StatelessWidget {
  const SettingsBlockCard({
    super.key,
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (lines.isEmpty)
              const Text('—', style: TextStyle(color: Colors.grey))
            else
              for (final line in lines) ...[
                Text(line, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
              ],
          ],
        ),
      ),
    );
  }
}
