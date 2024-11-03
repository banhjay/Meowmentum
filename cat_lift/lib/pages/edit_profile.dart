// pages/edit_profile.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/weight_calc.dart'; // Ensure the correct path

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final SupabaseClient _client = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Form Fields
  String _username = '';
  double _height = 0.0;
  double _weight = 0.0;
  int _goalWeight = 0; // Changed from String to int
  String _gender = 'Male';
  int _age = 18;
  String _activityLevel = 'sedentary'; // Lowercase for consistency

  bool _isLoading = true; // Indicates if data is being fetched
  bool _isUpdating = false; // Indicates if data is being updated

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

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  /// Fetches the current user's profile from Supabase
  Future<void> _fetchProfile() async {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      // User is not authenticated, redirect to sign-in page
      Navigator.pushReplacementNamed(context, '/sign_in');
      return;
    }

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single()
        .execute();

    if (response.error != null) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching profile: ${response.error!.message}')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final data = response.data as Map<String, dynamic>;

    setState(() {
      _username = data['username'] ?? '';
      _height = (data['height'] as num?)?.toDouble() ?? 0.0;
      _weight = (data['weight'] as num?)?.toDouble() ?? 0.0;
      _goalWeight = (data['goal'] as int?) ?? 0;
      _gender = data['gender'] ?? 'Male';
      _age = data['age'] ?? 18;
      _activityLevel = (data['activity_level'] as String?)?.toLowerCase() ?? 'sedentary';
      _isLoading = false;
    });
  }

  /// Updates the user's profile in Supabase
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      _isUpdating = true;
    });

    try {
      final userId = _client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated.');
      }

      // Update profile data without calorie_goal first
      final updateResponse = await _client.from('profiles').update({
        'height': _height,
        'weight': _weight,
        'age': _age,
        'activity_level': _activityLevel,
        'gender': _gender,
        'goal': _goalWeight, // Updated to send int
        // 'username': _username, // Uncomment if allowing username changes
      }).eq('id', userId).execute();

      if (updateResponse.error != null) {
        throw Exception('Error updating profile: ${updateResponse.error!.message}');
      }


      // Get and update workout plan (if applicable)
      await _userProfileService.getAndStoreWorkoutRecommendation(userId);

      // Success Feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      // Optionally, navigate back or refresh the profile page
    } catch (e) {
      // Error Handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Username (Optional: Allowing username changes)
                      // Uncomment the following block if you want to allow username changes
                      /*
                      TextFormField(
                        initialValue: _username,
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
                      */

                      // Height
                      TextFormField(
                        initialValue: _height > 0 ? _height.toString() : '',
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
                        initialValue: _weight > 0 ? _weight.toString() : '',
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
                        initialValue: _goalWeight > 0 ? _goalWeight.toString() : '',
                        decoration: const InputDecoration(labelText: 'Goal Weight (lbs)'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your goal weight';
                          }
                          final goal = int.tryParse(value);
                          if (goal == null || goal <= 0) {
                            return 'Please enter a valid goal weight';
                          }
                          if (_weight != 0 && goal >= _weight) {
                            return 'Goal weight must be lower than your current weight (${_weight.toStringAsFixed(1)} lbs)';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _goalWeight = int.parse(value!.trim());
                        },
                      ),
                      const SizedBox(height: 8.0),

                      // Goal Weight Validation Note
                      if (_weight > 0)
                        Text(
                          'Your goal weight must be lower than your current weight (${_weight.toStringAsFixed(1)} lbs).',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      const SizedBox(height: 16.0),

                      // Age
                      TextFormField(
                        initialValue: _age > 0 ? _age.toString() : '',
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

                      const SizedBox(height: 32.0),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isUpdating ? null : _updateProfile,
                        child: _isUpdating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.0,
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ],
                  ),
                ),
            ),
    ));
  }
}
