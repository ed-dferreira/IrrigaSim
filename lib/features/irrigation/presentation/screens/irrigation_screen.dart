import 'package:flutter/material.dart';

class IrrigationScreen extends StatelessWidget {
  const IrrigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Irrigação'),
      ),
      body: const Center(
        child: Text('Irrigation Screen'),
      ),
    );
  }
}
