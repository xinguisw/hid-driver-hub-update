import 'package:flutter/material.dart';

/// Macro Settings page — macro list (left) + editor (right).
///
/// Skeleton: static placeholder content. No recording, no L4 wiring yet.
/// All buttons are inert (null) for the skeleton phase.
class HubMacroPanel extends StatelessWidget {
  const HubMacroPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left: macro list.
        SizedBox(
          width: 168,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Text(
                  'Macro List',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: OutlinedButton(
                  onPressed: null, // skeleton — not wired yet
                  child: const Text('New Macro'),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              // Placeholder entries.
              for (final name in const ['M1'])
                ListTile(
                  dense: true,
                  title: Text(name),
                  onTap: null, // skeleton
                ),
            ],
          ),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        // Right: editor.
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'M1',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // Macro type + loop count bar.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('macro type + loop count input',
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 12),
                // Record controls.
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: null, // skeleton
                      child: const Text('Start Recording'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: null, // skeleton
                      child: const Text('Stop Recording'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Record'),
                const SizedBox(height: 8),
                // Placeholder recorded rows.
                for (final row in const [
                  ('A', '135 ms'),
                  ('Backspace', '10 ms'),
                  ('7', '246 ms'),
                ])
                  _MacroRow(keyName: row.$1, delay: row.$2),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: null, // skeleton
                  child: const Text('+ Insert Mouse Button'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: null, // skeleton
                  child: const Text('+ Insert Keyboard Key'),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: null, // skeleton
                      child: const Text('Reset'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: null, // skeleton
                      child: const Text('Save'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: null, // skeleton
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One recorded macro row: key name + delay + edit/delete (inert).
class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.keyName, required this.delay});

  final String keyName;
  final String delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(child: Text(keyName)),
          Text(delay),
          const SizedBox(width: 12),
          const Icon(Icons.edit, size: 16),
          const SizedBox(width: 8),
          const Icon(Icons.delete_outline, size: 16),
        ],
      ),
    );
  }
}
