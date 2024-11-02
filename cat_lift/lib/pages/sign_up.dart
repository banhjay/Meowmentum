import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:email_validator/email_validator.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _client = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  String _email = '';
  String _password = '';
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      // Sign up the user
      final response = await _client.auth.signUp(_email, _password);

      setState(() {
        _isLoading = false;
      });

      if (response.error == null) {
        // Get the user ID
        final userId = response.user?.id;
        if (userId != null) {
          // Collect additional user information
          await _collectAdditionalInfo(userId);
        }

        // Navigate to home page
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Show error message
        _scaffoldKey.currentState!.showSnackBar(
          SnackBar(content: Text(response.error!.message)),
        );
      }
    }
  }

  Future<void> _collectAdditionalInfo(String userId) async {
    // Prompt for username
    final username = await _promptForUsername();
    if (username == null) {
      // User canceled, sign out
      await _client.auth.signOut();
      return;
    }

    // Collect height, weight, and goal
    final userInfo = await _collectUserInfo();
    if (userInfo == null) {
      // User canceled, sign out
      await _client.auth.signOut();
      return;
    }

    // Insert data into 'profiles' table
    final insertResponse = await _client.from('profiles').insert({
      'id': userId,
      'username': username,
      'height': userInfo['height'],
      'weight': userInfo['weight'],
      'goal': userInfo['goal'],
      'streak': 0,  
    }).execute();

    if (insertResponse.error != null) {
      // Handle insert error
      _scaffoldKey.currentState!.showSnackBar(
        SnackBar(content: Text('Error saving profile: ${insertResponse.error!.message}')),
      );
    }
  }

  Future<String?> _promptForUsername() async {
    String? username;
    bool isUsernameValid = false;

    while (!isUsernameValid) {
      username = await _showInputDialog(
        title: 'Enter your desired username',
        labelText: 'Username',
      );

      if (username == null) {
        // User canceled the input
        return null;
      }

      // Check if username already exists
      isUsernameValid = !(await _usernameExists(username));
      if (!isUsernameValid) {
        _scaffoldKey.currentState!.showSnackBar(
          SnackBar(content: Text('Username "$username" is already taken. Please choose another one.')),
        );
      }
    }

    return username;
  }

  Future<String?> _showInputDialog({required String title, required String labelText}) async {
    String? input;
    await showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _controller = TextEditingController();
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: labelText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // User cancels
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                input = _controller.text.trim();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return input;
  }

  Future<bool> _usernameExists(String username) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('username', username)
        .execute();

    if (response.error == null) {
      final data = response.data as List<dynamic>;
      return data.isNotEmpty;
    } else {
      // Handle error (e.g., log it, show a message)
      _scaffoldKey.currentState!.showSnackBar(
        SnackBar(content: Text('Error checking username: ${response.error!.message}')),
      );
      return false;
    }
  }

  Future<Map<String, dynamic>?> _collectUserInfo() async {
    double? height;
    double? weight;
    String? goal;

    await showDialog(
      context: context,
      builder: (context) {
        final _formKey = GlobalKey<FormState>();
        final TextEditingController _heightController = TextEditingController();
        final TextEditingController _weightController = TextEditingController();
        String _goal = 'lose';

        return AlertDialog(
          title: const Text('Enter your information'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Height
                  TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(labelText: 'Height (cm)'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                  ),
                  const SizedBox(height: 8.0),
                  // Weight
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: 'Weight (kg)'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                  ),
                  const SizedBox(height: 8.0),
                  // Goal
                  DropdownButtonFormField<String>(
                    value: _goal,
                    decoration: const InputDecoration(labelText: 'Goal'),
                    items: const [
                      DropdownMenuItem(
                        value: 'lose',
                        child: Text('Lose Weight'),
                      ),
                      DropdownMenuItem(
                        value: 'gain',
                        child: Text('Gain Weight'),
                      ),
                    ],
                    onChanged: (value) {
                      _goal = value!;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // User cancels
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  height = double.parse(_heightController.text.trim());
                  weight = double.parse(_weightController.text.trim());
                  goal = _goal;
                  Navigator.of(context).pop();
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (height != null && weight != null && goal != null) {
      return {
        'height': height,
        'weight': weight,
        'goal': goal,
      };
    } else {
      return null; // User canceled
    }
  }

  void _navigateToSignIn() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sign Up'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Email field
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      } else if (!EmailValidator.validate(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _email = value!.trim();
                    },
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16.0),
                  // Password field
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      } else if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _password = value!;
                    },
                    obscureText: true,
                  ),
                  const SizedBox(height: 24.0),
                  // Sign-up button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Sign Up'),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  // Navigate to sign-in page
                  TextButton(
                    onPressed: _navigateToSignIn,
                    child: const Text('Already have an account? Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
