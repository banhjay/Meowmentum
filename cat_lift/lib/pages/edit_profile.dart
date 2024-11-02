import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _client = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  double _height = 0;
  double _weight = 0;
  String _goal = 'lose'; // or 'gain'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Add TextFormFields for username, height, weight, and goal
            // Save the data to Supabase on form submission
          ],
        ),
      ),
    );
  }
}
