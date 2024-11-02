import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  // Fetch user data from Supabase and display
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Text('Display user progress here'),
      ),
    );
  }
}
