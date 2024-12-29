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

  Future<Map<String, dynamic>> startStory(Story story) async {
    developer.log('Starting story with: $baseUrl/start-story/');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/start-story/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': story.title,
          'description': story.description,
          'goal': story.goal,
        }),
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        developer.log('Session ID received: ${decodedResponse['session_id']}');
        return decodedResponse;
      } else {
        throw Exception('Failed to start story');
      }
    } catch (e) {
      developer.log('Error in startStory: $e', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> mainStoryLoop({
    required String sessionId,
    required String choice,
    required String outcome,
  }) async {
    developer.log('Calling main-story-loop with sessionId: $sessionId');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/main-story-loop/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'session_id': sessionId,
          'choice': choice,
          'outcome': outcome,
        }),
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to process story loop');
      }
    } catch (e) {
      developer.log('Error in mainStoryLoop: $e', error: e);
      rethrow;
    }
  }
}
