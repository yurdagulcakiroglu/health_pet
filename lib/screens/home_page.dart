import 'package:flutter/material.dart';

class PetHealthHomePage extends StatelessWidget {
  const PetHealthHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ana Sayfa')),
      body: const Center(child: Text('Hoş Geldiniz!')),
    );
  }
}
