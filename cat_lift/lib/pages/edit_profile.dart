import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/weight_calc.dart';

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
  double _goalWeight = 0.0;
  String _gender = 'Male';
  int _age = 18;
  String _activityLevel = 'sedentary';

  bool _isLoading = true;
  bool _isUpdating = false;

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

  Future<void> _fetchProfile() async {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
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
      _goalWeight = (data['goal_weight'] as num?)?.toDouble() ?? 0.0;
      _gender = data['gender'] ?? 'Male';
      _age = data['age'] ?? 18;
      _activityLevel = (data['activity_level'] as String?)?.toLowerCase() ?? 'sedentary';
      _isLoading = false;
    });
  }

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

      final updateResponse = await _client.from('profiles').update({
        'height': _height,
        'weight': _weight,
        'age': _age,
        'activity_level': _activityLevel,
        'gender': _gender,
        'goal_weight': _goalWeight,
      }).eq('id', userId).execute();

      if (updateResponse.error != null) {
        throw Exception('Error updating profile: ${updateResponse.error!.message}');
      }

      await _userProfileService.calculateAndUpdateCalorieGoal(userId);
      await _userProfileService.getAndStoreWorkoutRecommendation(userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
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
        title: const Text('Edit Profile', style: TextStyle(fontFamily: 'scrapbook')),
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
                      TextFormField(
                        initialValue: _username,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a username';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _username = value!.trim();
                        },
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        initialValue: _height > 0 ? _height.toString() : '',
                        decoration: const InputDecoration(
                          labelText: 'Height (in)',
                          border: OutlineInputBorder(),
                        ),
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
                      TextFormField(
                        initialValue: _weight > 0 ? _weight.toString() : '',
                        decoration: const InputDecoration(
                          labelText: 'Weight (lbs)',
                          border: OutlineInputBorder(),
                        ),
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
                      TextFormField(
                        initialValue: _goalWeight > 0 ? _goalWeight.toString() : '',
                        decoration: const InputDecoration(
                          labelText: 'Goal Weight (lbs)',
                          border: OutlineInputBorder(),
                        ),
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
                            return 'Goal weight must be lower than your current weight (${_weight.toStringAsFixed(1)} lbs)';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _goalWeight = double.parse(value!.trim());
                        },
                      ),
                      const SizedBox(height: 8.0),
                      if (_weight > 0)
                        Text(
                          'Your goal weight must be lower than your current weight (${_weight.toStringAsFixed(1)} lbs).',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        initialValue: _age > 0 ? _age.toString() : '',
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          border: OutlineInputBorder(),
                        ),
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
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(),
                        ),
                        items: _genders.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
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
                      DropdownButtonFormField<String>(
                        value: _activityLevel,
                        decoration: const InputDecoration(
                          labelText: 'Activity Level',
                          border: OutlineInputBorder(),
                        ),
                        items: _activityLevels
                            .map((level) => DropdownMenuItem(
                                  value: level.split(' ')[0].toLowerCase(),
                                  child: Text(level),
                                ))
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
                      const SizedBox(height: 32.0),
                      Center(
                        child: ElevatedButton(
                          onPressed: _isUpdating ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA4B6),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                          ),
                          child: _isUpdating
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Save Changes', style: TextStyle(fontFamily: 'scrapbook')),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
