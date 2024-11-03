// home_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_setup.dart'; 
import 'cat_customizer.dart';
import 'edit_profile.dart';
import 'loading_screen.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
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
        .execute();

    if (response.error != null) {
      // Handle error
      print('Error fetching profile: ${response.error!.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching profile: ${response.error!.message}')),
      );
      return;
    }

    final data = response.data as List<dynamic>;

    if (data.isEmpty) {
      // Profile does not exist, navigate to ProfileSetupPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileSetupPage()),
      );
    } else {
      // Profile exists, proceed to Home Page with Navigation Bar
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingScreen(); // Show a loading indicator while checking profile
    }

    return const MainScreenWithNavBar(); // Navigate to the main screen with navbar
  }
}

class MainScreenWithNavBar extends StatefulWidget {
  const MainScreenWithNavBar({super.key});

  @override
  _MainScreenWithNavBarState createState() => _MainScreenWithNavBarState();
}

class _MainScreenWithNavBarState extends State<MainScreenWithNavBar> {
  int _selectedIndex = 1; // Start with the Home tab selected

  final List<Widget> _pages = [
    CatCustomizerPage(),
    const ActualHomePage(), // Renamed to avoid confusion
    const EditProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Customize Cat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 30), // Slightly larger for emphasis
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class ActualHomePage extends StatelessWidget {
  const ActualHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Welcome to the Fitness App!'),
    );
  }
}
