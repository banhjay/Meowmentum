// home_page.dart

import 'dart:convert'; // For JSON decoding
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_setup.dart'; 
import 'cat_customizer.dart';
import 'edit_profile.dart';
import 'loading_screen.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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

class ActualHomePage extends StatefulWidget {
  const ActualHomePage({super.key});

  @override
  _ActualHomePageState createState() => _ActualHomePageState();
}

class _ActualHomePageState extends State<ActualHomePage> {
  final SupabaseClient _client = Supabase.instance.client;
  String? _workoutPlan;
  bool _isLoading = true;

  // Variables to store cat settings
  Map<String, String?> selectedItems = {
    'Fur Coat': null,
    'Head': null,
    'Neck': null,
    'Eyes': null,
    'Eyebrows': null,
    'Mouth': null,
  };

  @override
  void initState() {
    super.initState();
    _fetchData(); // Fetch both workout plan and cat settings
  }

  /// Fetches both workout plan and cat settings
  Future<void> _fetchData() async {
    await Future.wait([
      _fetchWorkoutPlan(),
      _fetchCatSettings(),
    ]);
    setState(() {
      _isLoading = false;
    });
  }

  /// Fetches the workout plan and calorie goal from Supabase
  Future<void> _fetchWorkoutPlan() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _client
          .from('profiles')
          .select('plan, calorie_goal')
          .eq('id', userId)
          .single()
          .execute();

      if (response.error != null) {
        throw response.error!;
      }

      setState(() {
        _workoutPlan = response.data['plan'];
      });
    } catch (e) {
      print('Error fetching workout plan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching workout plan: $e')),
      );
    }
  }

  /// Fetches the cat settings from Supabase
  Future<void> _fetchCatSettings() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        // User not authenticated, handle accordingly
        // For example, navigate to sign-in page
        Navigator.pushReplacementNamed(context, '/sign_in');
        return;
      }

      final response = await _client
          .from('profiles')
          .select('cat_settings')
          .eq('id', user.id)
          .single()
          .execute();

      if (response.error != null) {
        throw response.error!;
      }

      final data = response.data as Map<String, dynamic>;
      final catSettingsJson = data['cat_settings'] as String?;

      if (catSettingsJson != null) {
        final Map<String, dynamic> catSettingsMap = jsonDecode(catSettingsJson);
        setState(() {
          // Update selectedItems with existing settings
          catSettingsMap.forEach((key, value) {
            if (selectedItems.containsKey(key)) {
              selectedItems[key] = value;
            }
          });
        });
      }
    } catch (e) {
      print('Error fetching cat settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching cat settings: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingScreen(); // Show a loading indicator while fetching data
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _fetchData().then((_) {
                setState(() {
                  _isLoading = false;
                });
              });
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Customized Cat
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Starter cat image that stays the same
                  Image.asset('assets/Starter Cat/starter_cat.PNG', width: 200),

                  // Layered items over the starter cat
                  if (selectedItems['Fur Coat'] != null)
                    Positioned(
                      bottom: 0,
                      child: Image.asset('assets/${selectedItems['Fur Coat']}.PNG', width: 200),
                    ),
                  if (selectedItems['Head'] != null)
                    Positioned(
                      top: 20,
                      child: Image.asset('assets/${selectedItems['Head']}.PNG', width: 100),
                    ),
                  if (selectedItems['Neck'] != null)
                    Positioned(
                      bottom: 40,
                      child: Image.asset('assets/${selectedItems['Neck']}.PNG', width: 100),
                    ),
                  if (selectedItems['Eyes'] != null)
                    Positioned(
                      top: 50,
                      child: Image.asset('assets/${selectedItems['Eyes']}.PNG', width: 80),
                    ),
                  if (selectedItems['Eyebrows'] != null)
                    Positioned(
                      top: 45, // Adjust for accurate positioning
                      left: 20, // Adjust this value if needed
                      child: Image.asset('assets/${selectedItems['Eyebrows']}.PNG', width: 80),
                    ),
                  if (selectedItems['Mouth'] != null)
                    Positioned(
                      top: 110,
                      child: Image.asset('assets/${selectedItems['Mouth']}.PNG', width: 80),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            // Display Workout Plan
            if (_workoutPlan != null && _workoutPlan!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Workout Plan',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: MarkdownBody(
                        data: _workoutPlan!,
                        styleSheet: MarkdownStyleSheet(
                          h1: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          h2: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          p: const TextStyle(fontSize: 16),
                          listBullet: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Center(
                child: Column(
                  children: [
                    const Text(
                      'No workout plan available yet.',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to edit profile to generate a plan
                        Navigator.pushNamed(context, '/edit_profile');
                      },
                      child: const Text('Set up your profile to get a plan'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
