import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../models/backstory.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  Future<BackstoryResponse> fetchBackstories() async {
    developer.log('Fetching backstories from: $baseUrl/get-backstory/');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get-backstory/'),
        headers: {'Content-Type': 'application/json'},
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BackstoryResponse.fromJson(data);
      } else {
        throw Exception('Failed to load backstories');
      }
    } catch (e) {
      developer.log('Error in fetchBackstories: $e', error: e);
      rethrow;
    }
  }
}
