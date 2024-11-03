
import 'package:supabase_flutter/supabase_flutter.dart';
import 'groq_client.dart';

class UserProfileService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  /// Fetches the user profile data from Supabase
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await _supabaseClient
        .from('profiles') // Assuming the table name is 'profiles'
        .select()
        .eq('id', userId)
        .single()
        .execute();

    if (response.error != null) {
      throw Exception('Error fetching user profile: ${response.error!.message}');
    }

    return response.data;
  }

  /// Calculates calorie goal based on user profile data
  Future<int> calculateCalorieGoal(String userId) async {
    try {
      // Fetch user profile
      final userProfile = await getUserProfile(userId);
      final weight = (userProfile['weight'] as num?)?.toDouble() ?? 0.0;
      final height = (userProfile['height'] as num?)?.toDouble() ?? 0.0;
      final age = (userProfile['age'] as num?)?.toInt() ?? 0;
      final gender = userProfile['gender'] as String? ?? 'Male';
      final activityLevel = userProfile['activity_level'] as String? ?? 'sedentary';

      // Calculate calorie goal using the Mifflin-St Jeor equation
      return calculateCalories(weight, height, age, gender, activityLevel);
    } catch (e) {
      throw Exception('Error calculating calorie goal: $e');
    }
  }

  /// Updates the calorie_goal in the profiles table
  Future<void> updateCalorieGoal(String userId, int calorieGoal) async {
    final response = await _supabaseClient
        .from('profiles')
        .update({'calorie_goal': calorieGoal})
        .eq('id', userId)
        .execute();

    if (response.error != null) {
      throw Exception('Error updating calorie goal: ${response.error!.message}');
    }
  }

  /// Calculates BMR and adjusts it based on activity level
  int calculateCalories(double weight, double height, int age, String gender, String activityLevel) {
    double bmr;

    // Calculate BMR based on gender
    if (gender.toLowerCase() == 'male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }

    // Adjust BMR based on activity level
    double activityMultiplier;
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        activityMultiplier = 1.2;
        break;
      case 'light':
        activityMultiplier = 1.375;
        break;
      case 'moderate':
        activityMultiplier = 1.55;
        break;
      case 'heavy':
        activityMultiplier = 1.725;
        break;
      default:
        throw Exception('Invalid activity level: $activityLevel');
    }

    return (bmr * activityMultiplier).round(); // Round to nearest whole number
  }

  final GroqClient _groqClient = GroqClient(
    apiKey: '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'
  );

  Future<String> getAndStoreWorkoutRecommendation(String userId) async {
    try {
      final userProfile = await getUserProfile(userId);
      
      final prompt = '''
        Based on this profile, provide ONLY a structured workout plan starting with "**Goals:**". Do not include any introductory text or pleasantries:
        Weight: ${userProfile['weight']} kg
        Height: ${userProfile['height']} cm
        Age: ${userProfile['age']}
        Gender: ${userProfile['gender']}
        Activity Level: ${userProfile['activity_level']}
        
        Format the response with:
        1. Goals section
        2. Weekly Workout Plan section
        3. Each day's workout details
        
        Use markdown formatting with ** for headers.
      ''';

      final recommendation = await _groqClient.getChatCompletion(prompt);

      await _supabaseClient
          .from('profiles')
          .update({
            'plan': recommendation,
          })
          .eq('id', userId)
          .execute();
          
      return recommendation;
    } catch (e) {
      throw Exception('Error getting workout recommendation: $e');
    }
  }
}
