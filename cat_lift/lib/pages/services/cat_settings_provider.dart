// cat_settings_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CatSettingsProvider with ChangeNotifier {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // Map to store selected items for each category
  Map<String, String?> _selectedItems = {
    'Fur Coat': null,
    'Head': null,
    'Neck': null,
    'Eyes': null,
    'Eyebrows': null,
    'Mouth': null,
  };

  Map<String, String?> get selectedItems => _selectedItems;

  /// Fetches cat settings from Supabase and updates the state
  Future<void> fetchCatSettings() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated.');
      }

      final response = await _supabaseClient
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
        _selectedItems = {
          'Fur Coat': catSettingsMap['Fur Coat'] as String?,
          'Head': catSettingsMap['Head'] as String?,
          'Neck': catSettingsMap['Neck'] as String?,
          'Eyes': catSettingsMap['Eyes'] as String?,
          'Eyebrows': catSettingsMap['Eyebrows'] as String?,
          'Mouth': catSettingsMap['Mouth'] as String?,
        };
        notifyListeners();
      }
    } catch (e) {
      // Handle errors appropriately in your app
      debugPrint('Error fetching cat settings: $e');
    }
  }

  /// Updates cat settings in Supabase and local state
  Future<void> updateCatSettings(Map<String, String?> newSettings) async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated.');
      }

      // Serialize to JSON
      final String catSettingsJson = jsonEncode(newSettings);

      final response = await _supabaseClient
          .from('profiles')
          .update({'cat_settings': catSettingsJson})
          .eq('id', user.id)
          .execute();

      if (response.error != null) {
        throw response.error!;
      }

      _selectedItems = newSettings;
      notifyListeners();
    } catch (e) {
      // Handle errors appropriately in your app
      debugPrint('Error updating cat settings: $e');
    }
  }
}
