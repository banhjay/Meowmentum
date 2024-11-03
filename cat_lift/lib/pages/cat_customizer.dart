import 'package:flutter/material.dart';

class CatCustomizerPage extends StatefulWidget {
  @override
  _CatCustomizerPageState createState() => _CatCustomizerPageState();
}

class _CatCustomizerPageState extends State<CatCustomizerPage> {
  // Map to keep track of selected items by category
  Map<String, String?> selectedItems = {
    'Fur Coat': null,
    'Head': null,
    'Neck': null,
    'Eyes': null,
    'Eyebrows': null,
    'Mouth': null,
  };

  // List of items available for each category
  final Map<String, List<String>> clothingItems = {
    'Fur Coat': ['Fur Coat/black_coat', 'Fur Coat/gray_coat', 'Fur Coat/orange_coat'],
    'Head': ['Head/bear_hat', 'Head/strawberry_hat'],
    'Neck': ['Neck/bandana', 'Neck/bow'],
    'Eyes': ['eyes/derpy_eyes', 'eyes/sparkly_eyes'],
    'Eyebrows': ['eyebrows/straight_brows', 'eyebrows/upturned_brows'],
    'Mouth': ['mouth/open_mouth', 'mouth/tounge'],
  };

  // Toggle function to add or remove clothing items
  void _toggleClothing(String category, String item) {
    setState(() {
      // If the item is already selected, remove it
      if (selectedItems[category] == item) {
        selectedItems[category] = null;
      } else {
        // Otherwise, select the new item, replacing any existing item in the same category
        selectedItems[category] = item;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String selectedCategory = 'Fur Coat';

    return Scaffold(
      appBar: AppBar(
        title: Text('Cat Customizer'),
      ),
      body: Column(
        children: [
          // Display the base cat image with overlaid clothing items
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Starter cat image (always displayed and larger size)
                  Image.asset(
                    'assets/Starter Cat/starter_cat.PNG',
                    width: 300, // Make starter_cat bigger by increasing width
                    height: 300, // Make starter_cat bigger by increasing height
                  ),
                  // Overlay clothing items on top of starter cat with proper positioning
                  if (selectedItems['Fur Coat'] != null)
                    Positioned(
                      bottom: 0,
                      child: Image.asset(
                        'assets/${selectedItems['Fur Coat']}.PNG',
                        width: 300, // Match width with starter_cat
                        height: 300,
                      ),
                    ),
                  if (selectedItems['Head'] != null)
                    Positioned(
                      top: 50, // Adjust to place it on the cat's head
                      child: Image.asset(
                        'assets/${selectedItems['Head']}.PNG',
                        width: 100, // Adjust size to fit
                        height: 100,
                      ),
                    ),
                  if (selectedItems['Neck'] != null)
                    Positioned(
                      bottom: 50, // Adjust to fit around the neck area
                      child: Image.asset(
                        'assets/${selectedItems['Neck']}.PNG',
                        width: 150,
                        height: 50,
                      ),
                    ),
                  if (selectedItems['Eyes'] != null)
                    Positioned(
                      top: 100, // Adjust to fit the eye position
                      child: Image.asset(
                        'assets/${selectedItems['Eyes']}.PNG',
                        width: 60,
                        height: 30,
                      ),
                    ),
                  if (selectedItems['Eyebrows'] != null)
                    Positioned(
                      top: 85, // Adjust to fit the eyebrow position
                      child: Image.asset(
                        'assets/${selectedItems['Eyebrows']}.PNG',
                        width: 60,
                        height: 20,
                      ),
                    ),
                  if (selectedItems['Mouth'] != null)
                    Positioned(
                      top: 130, // Adjust to fit the mouth position
                      child: Image.asset(
                        'assets/${selectedItems['Mouth']}.PNG',
                        width: 50,
                        height: 30,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Carousel-style category selection
          Container(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: clothingItems.keys.map((category) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedCategory == category ? Colors.purple : Colors.grey,
                    ),
                    child: Text(category),
                  ),
                );
              }).toList(),
            ),
          ),
          // Display items within the selected category as buttons
          Expanded(
            child: ListView(
              children: clothingItems[selectedCategory]!.map((item) {
                final itemName = item.split('/').last.split('_').join(' ');
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ElevatedButton(
                    onPressed: () => _toggleClothing(selectedCategory, item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedItems[selectedCategory] == item ? Colors.blue : Colors.grey,
                    ),
                    child: Text(
                      selectedItems[selectedCategory] == item ? 'Remove $itemName' : 'Add $itemName',
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
