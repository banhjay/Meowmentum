import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/home_page.dart';
import 'pages/cat_customizer.dart';
import 'pages/edit_profile.dart';
import 'pages/loading_screen.dart';

import 'pages/sign_in.dart';
import 'pages/sign_up.dart';
import 'pages/profile_setup.dart';
import 'pages/services/weight_calc.dart';


void main() async{

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ichhumfztwlflblkzgpg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImljaGh1bWZ6dHdsZmxibGt6Z3BnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA1NzE3NzIsImV4cCI6MjA0NjE0Nzc3Mn0.czrZhXdeNJ2clI77lcktMtkP9xdouImImvyShH03GgY',
  );

  runApp(const MyApp());
  //HackTuah :3
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Build the MaterialApp with routes and authentication handling
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Fitness App',
      theme: ThemeData(
        // Customize your app's theme here
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Define the routes for navigation
      routes: {
        '/loading': (context) => const LoadingScreen(),
        '/home': (context) => const HomePage(),
        '/customizer': (context) => CatCustomizerPage(),
        '/edit_profile': (context) => const EditProfilePage(),
        '/sign_in': (context) => const SignInPage(),
        '/sign_up': (context) => const SignUpPage(),
        '/profile_setup': (context) => const ProfileSetupPage(),
      },
      // Handle authentication state changes
      home: const AuthStateHandler(),
    );
  }
}

class AuthStateHandler extends StatefulWidget {
  const AuthStateHandler({super.key});

  @override
  _AuthStateHandlerState createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends State<AuthStateHandler> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    final session = _supabase.auth.currentSession;
    setState(() {
      _isAuthenticated = session != null;
    });

    // Listen for auth state changes
    _supabase.auth.onAuthStateChange((event, session) {
      setState(() {
        _isAuthenticated = session != null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return const HomePage(); 
    } else {
      return const SignInPage();
    }
  }

  
}