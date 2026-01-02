import 'package:flutter/material.dart';

class CompletedTab extends StatelessWidget {
  const CompletedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text(
          'Completed Tab Content',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}