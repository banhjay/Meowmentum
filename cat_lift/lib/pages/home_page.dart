// home_page.dart

import 'dart:convert'; // For JSON decoding
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_setup.dart'; 
import 'cat_customizer.dart';
import 'edit_profile.dart';
import 'loading_screen.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Optional: If you choose to create a separate widget for the customized cat display,
/// you can define it here or import it from another file.
class CustomizedCatDisplay extends StatelessWidget {
  final Map<String, String?> selectedItems;

  const CustomizedCatDisplay({Key? key, required this.selectedItems}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Starter cat image that stays the same
        Image.asset(
          'assets/Starter Cat/starter_cat.PNG',
          width: 300,
          height: 300,
        ),
        // Layered items over the starter cat
        if (selectedItems['Fur Coat'] != null)
          Image.asset(
            'assets/${selectedItems['Fur Coat']}.PNG',
            width: 300,
            height: 300,
          ),
        if (selectedItems['Head'] != null)
          Positioned(
            child: Image.asset(
              'assets/${selectedItems['Head']}.PNG',
              width: 300,
              height: 300,
            ),
          ),
        if (selectedItems['Neck'] != null)
          Positioned(
            child: Image.asset(
              'assets/${selectedItems['Neck']}.PNG',
              width: 300,
              height: 300,
            ),
          ),
        if (selectedItems['Face'] != null)
          Positioned(
            child: Image.asset(
              'assets/${selectedItems['Face']}.PNG',
              width: 300,
              height: 300,
            ),
          ),
        if (selectedItems['Eyes'] != null)
          Positioned(
            child: Image.asset(
              'assets/${selectedItems['Eyes']}.PNG',
              width: 300,
              height: 300,
            ),
          ),
        if (selectedItems['Eyebrows'] != null)
          Positioned(
            child: Image.asset(
              'assets/${selectedItems['Eyebrows']}.PNG',
              width: 300,
              height: 300,
            ),
          ),
        if (selectedItems['Mouth'] != null)
          Positioned(
            child: Image.asset(
              'assets/${selectedItems['Mouth']}.PNG',
              width: 300,
              height: 300,
            ),
          ),
      ],
    );
  }
}

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

  /// Checks if the user has a profile. If not, redirects to ProfileSetupPage.
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
    const ActualHomePage(),
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
  int? _currentProgress; // Stores current_progress
  int? _calorieGoal; // Stores calorie_goal
  bool _isLoading = true;

  // Variables to store cat settings
  Map<String, String?> selectedItems = {
    'Fur Coat': null,
    'Head': null,
    'Face': null,
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

  /// Fetches the workout plan, calorie goal, and current progress from Supabase
  Future<void> _fetchWorkoutPlan() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _client
          .from('profiles')
          .select('plan, goal, current_progress') // Added current_progress
          .eq('id', userId)
          .single()
          .execute();

      if (response.error != null) {
        throw response.error!;
      }

      setState(() {
        _workoutPlan = response.data['plan'] as String?;
        _calorieGoal = response.data['goal'] as int?;
        _currentProgress = response.data['current_progress'] as int?;
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
        // User not authenticated, navigate to sign-in page
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
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await _fetchData();
              setState(() {
                _isLoading = false;
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
            // Display Customized Cat using the reusable widget
            Center(
              child: CustomizedCatDisplay(selectedItems: selectedItems),
            ),
            const SizedBox(height: 24.0),

            // Progress Bar Section
            if (_calorieGoal != null && _currentProgress != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Progress',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Progress: $_currentProgress / $_calorieGoal calories',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8.0),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: LinearProgressIndicator(
                      value: _calorieGoal! > 0
                          ? (_currentProgress! / _calorieGoal!).clamp(0.0, 1.0)
                          : 0.0, // Avoid division by zero and clamp to 1.0
                      minHeight: 20,
                      backgroundColor: Colors.grey[300],
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              )
            else
              const SizedBox(), // If goal or progress is null, show nothing
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
                      fontFamily: 'scrapbook'
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
