import 'package:flutter/material.dart';

class SensitiveConsentCard extends StatelessWidget {
  const SensitiveConsentCard({
    required this.onAccept,
    required this.accepted,
    super.key,
  });

  final ValueChanged<bool> onAccept;
  final bool accepted;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sensitive Action Consent',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'This recipe uses camera/microphone/webcam/health. Capture is only allowed when user-initiated with visible UI.',
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: accepted,
              onChanged: (value) => onAccept(value ?? false),
              title: const Text('I understand and approve sensitive usage'),
            ),
          ],
        ),
      ),
    );
  }
}
