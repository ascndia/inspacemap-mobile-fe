import 'package:flutter/material.dart';
import '../debug.dart';

class DeveloperModeScreen extends StatefulWidget {
  final Function({String? orgSlug, String? venueSlug}) onFetch;

  const DeveloperModeScreen({super.key, required this.onFetch});

  @override
  State<DeveloperModeScreen> createState() => _DeveloperModeScreenState();
}

class _DeveloperModeScreenState extends State<DeveloperModeScreen> {
  final _orgController = TextEditingController(text: 'demo-org');
  final _venueController = TextEditingController(text: 'demo-venue');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Mode'),
        backgroundColor: Colors.grey[850],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _orgController,
              decoration: const InputDecoration(labelText: 'Org Slug'),
            ),
            TextField(
              controller: _venueController,
              decoration: const InputDecoration(labelText: 'Venue Slug'),
            ),
            SwitchListTile(
              title: const Text('Debug Mode'),
              value: isDebugMode,
              onChanged: (value) {
                setState(() {
                  isDebugMode = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  await widget.onFetch(
                    orgSlug: _orgController.text,
                    venueSlug: _venueController.text,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Venue updated successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error fetching venue: $e')),
                    );
                  }
                }
              },
              child: const Text('Fetch and Update Manifest'),
            ),
          ],
        ),
      ),
    );
  }
}
