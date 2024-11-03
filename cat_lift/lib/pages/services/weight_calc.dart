
import 'package:supabase_flutter/supabase_flutter.dart';
import 'groq_client.dart';

class UserProfileService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

   Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await _supabaseClient
        .from('profiles')
        .select()
        .eq('id', userId)
        .single()
        .execute();

    if (response.error != null) {
      throw Exception('Error fetching user profile: ${response.error!.message}');
    }

    return response.data;
  }

  Future<void> updateCurrentProgress(String userId, int progressIncrement) async {
    try {
      // Fetch current progress
      final userProfile = await getUserProfile(userId);
      int currentProgress = (userProfile['current_progress'] as num?)?.toInt() ?? 0;

      // Calculate new progress
      int newProgress = currentProgress + progressIncrement;

      // Update progress
      final response = await _supabaseClient
          .from('profiles')
          .update({'current_progress': newProgress})
          .eq('id', userId)
          .execute();

      if (response.error != null) {
        throw Exception('Error updating current progress: ${response.error!.message}');
      }

      print('Current progress updated to $newProgress calories.');
    } catch (e) {
      throw Exception('Error in updateCurrentProgress: $e');
    }
  }

  /// Calculates and updates the daily calorie burn goal based on user profile data
  Future<void> calculateAndUpdateCalorieGoal(String userId) async {
    try {
      // Fetch user profile
      final userProfile = await getUserProfile(userId);
      final weight = (userProfile['weight'] as num?)?.toDouble() ?? 0.0;
      final height = (userProfile['height'] as num?)?.toDouble() ?? 0.0;
      final age = (userProfile['age'] as num?)?.toInt() ?? 0;
      final gender = userProfile['gender'] as String? ?? 'Male';
      final activityLevel = userProfile['activity_level'] as String? ?? 'sedentary';
      final goalWeight = (userProfile['goal_weight'] as num?)?.toDouble() ?? 0.0;

      print('Calculating calorie goal for user: $userId');
      print('Weight: $weight lbs, Height: $height in, Age: $age, Gender: $gender, Activity Level: $activityLevel, Goal Weight: $goalWeight lbs');

      // Calculate calorie goal
      final calorieGoal = calculateCalories(weight, height, age, gender, activityLevel, goalWeight);

      print('Calculated Calorie Goal: $calorieGoal');

      // Update the 'calorie_goal' column in the 'profiles' table with the new calorie burn goal
      final updateResponse = await _supabaseClient
          .from('profiles')
          .update({'calorie_goal': calorieGoal})
          .eq('id', userId)
          .execute();

      if (updateResponse.error != null) {
        throw Exception('Error updating calorie goal: ${updateResponse.error!.message}');
      }

      // Optionally, you can return the calorie burn goal or handle it as needed
      print('Daily Calorie Burn Goal updated to: $calorieGoal calories');
    } catch (e) {
      throw Exception('Error in calculateAndUpdateCalorieGoal: $e');
    }
  }

  /// Calculates the number of calories needed to be burned per day to reach goalWeight
  int calculateCalories(
    double weight,        // Current weight in pounds
    double height,        // Height in inches
    int age,              // Age in years
    String gender,        // 'male' or 'female'
    String activityLevel, // 'sedentary', 'light', 'moderate', 'heavy'
    double goalWeight,    // Goal weight in pounds
  ) {
    // Convert weight from pounds to kilograms
    double weightInKg = weight * 0.453592;
    double goalWeightInKg = goalWeight * 0.453592;

    // Convert height from inches to centimeters
    double heightInCm = height * 2.54;

    // Calculate BMR based on gender using the Mifflin-St Jeor Equation
    double bmr;
    if (gender.toLowerCase() == 'male') {
      bmr = 88.362 + (13.397 * weightInKg) + (4.799 * heightInCm) - (5.677 * age);
    } else if (gender.toLowerCase() == 'female') {
      bmr = 447.593 + (9.247 * weightInKg) + (3.098 * heightInCm) - (4.330 * age);
    } else {
      throw ArgumentError("Gender should be 'male' or 'female'");
    }

    // Determine activity multiplier based on activity level
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

    // Calculate Total Daily Energy Expenditure (TDEE)
    double maintenanceCalories = bmr * activityMultiplier;

    // Calculate weight difference (positive for weight loss)
    double weightDifference = weight - goalWeight;

    if (weightDifference <= 0) {
      throw Exception('Goal weight must be less than current weight.');
    }

    // Calculate total calories deficit needed to reach goal weight in one month
    double weightLossInKg = weightDifference * 0.453592;
    double totalCaloriesToLose = weightLossInKg * 7700; // Approximate 7700 calories per kg of body weight

    // Calculate daily calorie deficit to reach goal within 30 days
    double dailyCalorieDeficit = totalCaloriesToLose / 30;

    // Calculate the daily calorie burn goal
    double goal = dailyCalorieDeficit - 700;

    // Ensure calorie goal is not below the minimum recommended intake
    if (goal < 200) {
      goal = 200; // Minimum safe calorie burn
    }

    return goal.round(); // Returns the calculated calorie burn goal
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
