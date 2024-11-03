import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqClient {
  final String apiKey;
  final String baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  GroqClient({required this.apiKey});

  Future<String> getChatCompletion(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'mixtral-8x7b-32768',
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to get completion: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting completion: $e');
    }
  }//yo wassssssaaaappppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp
}//Hack Tuah or imma SMack yuah
