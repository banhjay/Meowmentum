// pages/profile_setup.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/weight_calc.dart'; // Ensure correct path

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  _ProfileSetupPageState createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final SupabaseClient _client = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Form Fields
  String _username = '';
  double _height = 0.0;
  double _weight = 0.0;
  double _goalWeight = 0.0; // Updated to double
  String _gender = 'Male';
  int _age = 18;
  String _activityLevel = 'sedentary'; // Lowercase for consistency

  bool _isLoading = false;

  // Dropdown Options
  final List<String> _genders = ['Male', 'Female'];
  final List<String> _activityLevels = [
    'Sedentary (Exercise 0 days a week)',
    'Light (Exercise 1-3 days a week)',
    'Moderate (Exercise 4-5 days a week)',
    'Heavy (Exercise 6-7 days a week)',
  ];

  // Initialize UserProfileService
  final UserProfileService _userProfileService = UserProfileService();

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      // Insert profile without calorie_goal first
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated.');
      }

      // Insert initial profile data
      final insertResponse = await _client.from('profiles').insert({
        'id': userId,
        'username': _username,
        'height': _height,
        'weight': _weight,
        'goal': _goalWeight,
        'gender': _gender,
        'age': _age,
        'activity_level': _activityLevel,
        'current_progress': 0, // Assuming default value
        'streak': 0, // Assuming default value
      }).execute();

      if (insertResponse.error != null) {
        throw Exception('Error saving profile: ${insertResponse.error!.message}');
      }

      // Get and update workout plan (if applicable)
      await _userProfileService.getAndStoreWorkoutRecommendation(userId);

      // Success Feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile created successfully!')),
      );

      // Navigate to the main screen with navbar
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      // Error Handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Optionally, if you want to include username uniqueness check before insertion,
  // you can integrate similar logic as in EditProfilePage.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Username
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Username'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a username';
                          } else if (value.length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _username = value!.trim();
                        },
                      ),
                      const SizedBox(height: 16.0),
                      // Height
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Height (in)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your height';
                          }
                          final height = double.tryParse(value);
                          if (height == null || height <= 0) {
                            return 'Please enter a valid height';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _height = double.parse(value!.trim());
                        },
                      ),
                      const SizedBox(height: 16.0),
                      // Weight
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Weight (lbs)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your weight';
                          }
                          final weight = double.tryParse(value);
                          if (weight == null || weight <= 0) {
                            return 'Please enter a valid weight';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _weight = double.parse(value!.trim());
                        },
                      ),
                      const SizedBox(height: 16.0),
                      // Goal Weight
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Goal Weight (lbs)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your goal weight';
                          }
                          final goal = double.tryParse(value);
                          if (goal == null || goal <= 0) {
                            return 'Please enter a valid goal weight';
                          }
                          if (_weight != 0 && goal >= _weight) {
                            return 'Goal weight must be lower than your current weight';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _goalWeight = double.parse(value!.trim());
                        },
                      ),
                      const SizedBox(height: 16.0),
                      // Age
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Age'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your age';
                          }
                          final age = int.tryParse(value);
                          if (age == null || age <= 0) {
                            return 'Please enter a valid age';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _age = int.parse(value!.trim());
                        },
                      ),
                      const SizedBox(height: 16.0),
                      // Gender
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        items: _genders
                            .map(
                              (gender) => DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _gender = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select your gender';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      // Activity Level
                      DropdownButtonFormField<String>(
                        value: _activityLevel,
                        decoration: const InputDecoration(labelText: 'Activity Level'),
                        items: _activityLevels
                            .map(
                              (level) => DropdownMenuItem(
                                value: level.split(' ')[0].toLowerCase(), // 'sedentary', 'light', etc.
                                child: Text(level),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _activityLevel = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select your activity level';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      // Goal Weight Validation Note
                      if (_weight > 0)
                        Text(
                          'Your goal weight must be lower than your current weight (${_weight} lbs).',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      const SizedBox(height: 32.0),
                      // Submit Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitProfile,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.0,
                                ),
                              )
                            : const Text('Save Profile'),
                      ),
                    ],
                  ),
                ),
          ),
        ));
      }
    }