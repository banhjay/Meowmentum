import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CatCustomizerPage extends StatefulWidget {
  @override
  _CatCustomizerPageState createState() => _CatCustomizerPageState();
}

class _CatCustomizerPageState extends State<CatCustomizerPage> with SingleTickerProviderStateMixin {
  // Track selected items by category
  Map<String, String?> selectedItems = {
    'Fur Coat': null,
    'Head': null,
    'Face': null,
    'Neck': null,
    'Eyes': null,
    'Eyebrows': null,
    'Mouth': null,
  };

  // List of items available for each category
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
        title: const Text('Cat Customizer'),
        backgroundColor: Colors.purple.shade50,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Display cat image with layered clothing items
                Expanded(
                  child: Center(
                    child: Stack(
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
                        if (selectedItems['Face'] != null)
                          Positioned(
                            child: Image.asset(
                              'assets/${selectedItems['Face']}.PNG',
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
                    ),
                  ),
                ),
                // Tab Bar for categories
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Colors.pinkAccent,
                  labelColor: Colors.purple,
                  unselectedLabelColor: Colors.grey,
                  tabs: clothingItems.keys.map((category) {
                    return Tab(
                      text: category,
                    );
                  }).toList(),
                ),
                // Tab View for each category
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: clothingItems.keys.map((category) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: clothingItems[category]!.length,
                          itemBuilder: (context, index) {
                            final item = clothingItems[category]![index];
                            return GestureDetector(
                              onTap: () => _toggleClothing(category, item),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  color: selectedItems[category] == item
                                      ? Colors.purple.shade100
                                      : Colors.grey.shade200,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Image.asset(
                                          'assets/$item.PNG',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.split('/').last.replaceAll('_', ' '),
                                        style: TextStyle(fontSize: 10, color: Colors.black87),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
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
                // Save Button at the bottom
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
                      minimumSize: const Size.fromHeight(50), // Full-width button
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
