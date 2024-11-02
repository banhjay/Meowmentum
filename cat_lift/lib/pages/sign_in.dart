import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:email_validator/email_validator.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _client = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  String _email = '';
  String _password = '';
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      final response = await _client.auth.signIn(
        email: _email,
        password: _password,
      );

      setState(() {
        _isLoading = false;
      });

      if (response.error == null) {
        // User is signed in, navigation will be handled by StreamBuilder in main.dart
      } else {
        // Show error message
        _scaffoldKey.currentState!.showSnackBar(
          SnackBar(content: Text(response.error!.message)),
        );
      }
    }
  }

  void _navigateToSignUp() {
    Navigator.pushNamed(context, '/sign_up');
  }

  Future<void> _resetPassword() async {
    final emailController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Enter your email'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final email = emailController.text.trim();
      if (email.isNotEmpty && EmailValidator.validate(email)) {
        final response = await _client.auth.api.resetPasswordForEmail(email);

        if (response.error == null) {
          _scaffoldKey.currentState!.showSnackBar(
            const SnackBar(content: Text('Password reset email sent')),
          );
        } else {
          _scaffoldKey.currentState!.showSnackBar(
            SnackBar(content: Text(response.error!.message)),
          );
        }
      } else {
        _scaffoldKey.currentState!.showSnackBar(
          const SnackBar(content: Text('Please enter a valid email')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sign In'),
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
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _password = value!;
                    },
                    obscureText: true,
                  ),
                  const SizedBox(height: 24.0),
                  // Sign-in button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  // Forgot password
                  TextButton(
                    onPressed: _resetPassword,
                    child: const Text('Forgot Password?'),
                  ),
                  const SizedBox(height: 16.0),
                  // Navigate to sign-up page
                  TextButton(
                    onPressed: _navigateToSignUp,
                    child: const Text('Don\'t have an account? Sign Up'),
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
