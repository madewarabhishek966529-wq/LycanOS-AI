import 'package:flutter/material.dart';

/// AI Assistant landing screen.
///
/// Full feature implementation lands in its dedicated phase (see project
/// README roadmap). This screen intentionally renders a real, styled empty
/// state rather than a blank placeholder so the navigation shell is fully
/// clickable and demoable after Phase 1.
class AiAssistantScreen extends StatelessWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Assistant')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 48, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('AI Assistant', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'This module is built out in its dedicated phase.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
