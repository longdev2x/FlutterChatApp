import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Chat'),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}