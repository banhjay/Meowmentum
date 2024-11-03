import 'package:flutter/material.dart';

class CatCustomizerPage extends StatefulWidget {
  @override
  _CatCustomizerPageState createState() => _CatCustomizerPageState();
}

class _CatCustomizerPageState extends State<CatCustomizerPage> {
  Map<String, String?> selectedItems = {
    'Fur Coat': null,
    'Head': null,
    'Neck': null,
    'Eyes': null,
    'Eyebrows': null,
    'Mouth': null,
  };

  // Updated clothingItems map with accurate paths
  final Map<String, List<String>> clothingItems = {
    'Fur Coat': ['Fur Coat/black_coat', 'Fur Coat/gray_coat', 'Fur Coat/purple_coat'],
    'Head': ['Head/bear_hat', 'Head/strawberry_hat'],
    'Neck': ['neck/bandana', 'neck/collar'],
    'Eyes': ['eyes/derpy_eyes', 'eyes/sparkly_eyes'],
    'Eyebrows': ['eyebrows/downturned_brows', 'eyebrows/straight_brows'],
    'Mouth': ['mouth/open_mouth', 'mouth/tounge'],
  };

  String selectedCategory = 'Fur Coat'; // Default category

  void _toggleClothing(String category, String item) {
    setState(() {
      if (selectedItems[category] == item) {
        selectedItems[category] = null;
      } else {
        selectedItems[category] = item;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cat Customizer'),
      ),
      body: Column(
        children: [
          // Display cat image with layered clothing items
          Expanded(
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
          // Horizontal bar for categories
          Container(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: clothingItems.keys.map((category) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: selectedCategory == category ? Colors.deepPurple : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: selectedCategory == category ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Buttons to display items as images for each category
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(8.0),
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: clothingItems[selectedCategory]!.map((item) {
                    return ElevatedButton(
                      onPressed: () => _toggleClothing(selectedCategory, item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedItems[selectedCategory] == item
                            ? Colors.red
                            : Colors.blue,
                      ),
                      child: Image.asset(
                        'assets/$item.PNG',
                        width: 50, // Adjust the size of the image preview as needed
                        height: 50,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
