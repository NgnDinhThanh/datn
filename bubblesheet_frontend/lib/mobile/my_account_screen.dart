import 'package:flutter/material.dart';

class MyAccountScreen extends StatelessWidget {
  const MyAccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('My Account', style: TextStyle(fontSize: 24))),
    );
  }
} 