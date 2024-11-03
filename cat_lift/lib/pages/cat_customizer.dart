import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CatCustomizerPage extends StatefulWidget {
  const CatCustomizerPage({super.key});

  @override
  _CatCustomizerPageState createState() => _CatCustomizerPageState();
}

class _CatCustomizerPageState extends State<CatCustomizerPage> with SingleTickerProviderStateMixin {
  Map<String, String?> selectedItems = {
    'Fur Coat': null,
    'Head': null,
    'Face': null,
    'Neck': null,
    'Eyes': null,
    'Eyebrows': null,
    'Mouth': null,
  };

  final Map<String, List<String>> clothingItems = {
    'Fur Coat': ['Fur Coat/black_coat', 'Fur Coat/gray_coat', 'Fur Coat/orange_coat', 'Fur Coat/calico_coat', 'Fur Coat/purple_coat', 'Fur Coat/siamese_coat'],
    'Head': ['Head/bear_hat', 'Head/strawberry_hat', 'Head/hack_hat', 'Head/leaf_hat', 'Head/orange_hat', 'Head/reddit_hat'],
    'Face': ['face/glasses', 'face/saiki', 'face/sunglasses'],
    'Neck': ['Neck/bandana', 'Neck/bow', 'Neck/collar'],
    'Eyes': ['eyes/derpy_eyes', 'eyes/sparkly_eyes', 'eyes/frog_eyes'],
    'Eyebrows': ['eyebrows/straight_brows', 'eyebrows/upturned_brows', 'eyebrows/downturned_brows'],
    'Mouth': ['mouth/open_mouth', 'mouth/tounge'],
  };

  String selectedCategory = 'Fur Coat';
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  bool _isLoading = true;
  bool _isSaving = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _fetchCatSettings();
    _tabController = TabController(length: clothingItems.keys.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        selectedCategory = clothingItems.keys.toList()[_tabController.index];
      });
    });
  }

  Future<void> _fetchCatSettings() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/sign_in');
        return;
      }
      final response = await _supabaseClient
          .from('profiles')
          .select('cat_settings')
          .eq('id', user.id)
          .single()
          .execute();

      if (response.error != null) throw response.error!;
      final data = response.data as Map<String, dynamic>;
      final catSettingsJson = data['cat_settings'] as String?;
      if (catSettingsJson != null) {
        final Map<String, dynamic> catSettingsMap = jsonDecode(catSettingsJson);
        setState(() {
          catSettingsMap.forEach((key, value) {
            if (selectedItems.containsKey(key)) selectedItems[key] = value;
          });
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching cat settings: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCatSettings() async {
    setState(() {
      _isSaving = true;
    });
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) throw Exception('User not authenticated.');

      final String catSettingsJson = jsonEncode(selectedItems);
      final response = await _supabaseClient
          .from('profiles')
          .update({'cat_settings': catSettingsJson})
          .eq('id', user.id)
          .execute();

      if (response.error != null) throw response.error!;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cat settings saved successfully!')),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving cat settings: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _toggleClothing(String category, String item) {
    setState(() {
      selectedItems[category] = selectedItems[category] == item ? null : item;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Closet', style: TextStyle(fontFamily: 'scrapbook')),
        backgroundColor: Colors.purple.shade50,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Upper half with background and cat layers
                Expanded(
                  flex: 2,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background image limited to the upper half and shifted upwards
                      Positioned(
                        top: -50, // Adjust this value as needed to align with the tabs
                        left: 0,
                        right: 0,
                        child: Image.asset(
                          'assets/nav_bar/bedroom_background.png', // Updated path
                          fit: BoxFit.cover,
                          height: MediaQuery.of(context).size.height * 0.5, // Covers upper half
                          alignment: Alignment.topCenter, // Aligns the image to the top
                        ),
                      ),
                      // Cat and clothing layers on top of the background
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/Starter Cat/starter_cat.PNG',
                              width: 300,
                              height: 300,
                            ),
                            if (selectedItems['Fur Coat'] != null)
                              Image.asset(
                                'assets/${selectedItems['Fur Coat']}.PNG',
                                width: 300,
                                height: 300,
                              ),
                            if (selectedItems['Head'] != null)
                              Image.asset(
                                'assets/${selectedItems['Head']}.PNG',
                                width: 300,
                                height: 300,
                              ),
                            if (selectedItems['Face'] != null)
                              Image.asset(
                                'assets/${selectedItems['Face']}.PNG',
                                width: 300,
                                height: 300,
                              ),
                            if (selectedItems['Neck'] != null)
                              Image.asset(
                                'assets/${selectedItems['Neck']}.PNG',
                                width: 300,
                                height: 300,
                              ),
                            if (selectedItems['Eyes'] != null)
                              Image.asset(
                                'assets/${selectedItems['Eyes']}.PNG',
                                width: 300,
                                height: 300,
                              ),
                            if (selectedItems['Eyebrows'] != null)
                              Image.asset(
                                'assets/${selectedItems['Eyebrows']}.PNG',
                                width: 300,
                                height: 300,
                              ),
                            if (selectedItems['Mouth'] != null)
                              Image.asset(
                                'assets/${selectedItems['Mouth']}.PNG',
                                width: 300,
                                height: 300,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab bar and customization items in the lower half
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.brown,
                              width: 2.0,
                            ),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          indicator: BoxDecoration(
                            color: Colors.pinkAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.brown,
                              width: 1.5,
                            ),
                          ),
                          labelColor: Colors.brown,
                          unselectedLabelColor: Colors.grey,
                          tabs: clothingItems.keys.map((category) {
                            return Tab(
                              text: category,
                            );
                          }).toList(),
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: clothingItems.keys.map((category) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: clothingItems[category]!.length,
                                itemBuilder: (context, index) {
                                  final item = clothingItems[category]![index];
                                  return GestureDetector(
                                    onTap: () => _toggleClothing(category, item),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16.0),
                                        color: selectedItems[category] == item
                                            ? Colors.purple.shade100
                                            : Colors.grey.shade200,
                                      ),
                                      child: Center(
                                        child: Image.asset(
                                          'assets/$item.PNG',
                                          fit: BoxFit.contain,
                                          width: 80,
                                          height: 80,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveCatSettings,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: const Text('Save Settings'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
