import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/backstory.dart';

class ApiResponse<T> {
  final T? data;
  final String? error;

  ApiResponse({this.data, this.error});
  bool get isSuccess => error == null;
}

// Ensure the baseUrl is correct for your environment

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  Future<ApiResponse<T>> safeApiCall<T>(Future<T> Function() apiCall) async {
    try {
      final result = await apiCall();
      return ApiResponse(data: result);
    } catch (e) {
      return ApiResponse(error: e.toString());
    }
  }

  Future<BackstoryResponse> fetchBackstories(String userId) async {
    developer.log('Fetching backstories from: $baseUrl/get-backstory/');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get-backstory/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"user_id": userId}),
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final docId = data['firestore_key'];
        // Query Firestore with docId
        final snap = await FirebaseFirestore.instance
            .collection('StorySessions')
            .doc(docId)
            .get();
        final storedData = snap.data() ?? {};
        final stories = (storedData['stories'] as List<dynamic>?)
                ?.map((m) => Story.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [];
        return BackstoryResponse(selectedStory: stories);
      } else {
        throw Exception('Failed to load backstories');
      }
    } catch (e) {
      developer.log('Error in fetchBackstories: $e', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> startStory(Story story, String userId) async {
    developer.log('Starting story with: $baseUrl/start-story/');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/start-story/?max_turns=5'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': story.title,
          'description': story.description,
          'goal': story.goal,
          'user_id': userId,
        }),
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final docId = decoded['firestore_key'];
        // Fetch from 'GeneratedStory' using docId
        final snap = await FirebaseFirestore.instance
            .collection('GeneratedStory')
            .doc(docId)
            .get();
        final storedStory = snap.data()?['turn_1'] ?? {};
        return {
          "session_id": decoded['session_id'],
          "story": storedStory['story'] ?? '',
          "choices": storedStory['choices'] ?? [],
        };
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
    required String userId,
  }) async {
    developer.log('Continuing story with: $baseUrl/main-story-loop/');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/main-story-loop/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "session_id": sessionId,
          "choice": choice,
          "outcome": outcome,
          "user_id": userId,
        }),
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final docId = decoded['firestore_key'];
        // Fetch updated story from 'GeneratedStory'
        final snap = await FirebaseFirestore.instance
            .collection('GeneratedStory')
            .doc(docId)
            .get();
        final data = snap.data() ?? {};
        // Identify the last turn updated. This is an example strategy:
        final updatedTurn = data.keys
            .where((k) => k.startsWith('turn_'))
            .reduce((curr, next) => next);
        final storyPart = data[updatedTurn] ?? {};
        return {
          "story": storyPart['story'] ?? '',
          "choices": storyPart['choices'] ?? []
        };
      } else {
        throw Exception('Failed to process story loop');
      }
    } catch (e) {
      developer.log('Error in mainStoryLoop: $e', error: e);
      rethrow;
    }
  }
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addUser(String userId, String name, String email) {
    return _db.collection('Users').doc(userId).set({
      'name': name,
      'email': email,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveStorySession({
    required String sessionId,
    required String title,
    required String description,
    required String goal,
    required String userId,
  }) async {
    await _db.collection('StorySessions').doc(sessionId).set({
      'title': title,
      'description': description,
      'goal': goal,
      'created_at': FieldValue.serverTimestamp(),
      'created_by': userId,
    });
  }

  Future<void> saveGeneratedStory({
    required String sessionId,
    required int turnNumber,
    required String story,
    required List<Map<String, String>> choices,
    required String userChoice,
  }) async {
    final docId = '${sessionId}_$turnNumber';

    // Handle empty choices list for final turn
    final Map<String, dynamic> data = {
      'story': story,
      'created_at': FieldValue.serverTimestamp(),
      'user_choice': userChoice,
    };

    // Add choice data only if available
    if (choices.isNotEmpty) {
      data['choice_1_desc'] = choices[0]['description'] ?? '';
      data['choice_1_outcome'] = choices[0]['outcome'] ?? '';
      if (choices.length > 1) {
        data['choice_2_desc'] = choices[1]['description'] ?? '';
        data['choice_2_outcome'] = choices[1]['outcome'] ?? '';
      }
    }

    await FirebaseFirestore.instance
        .collection('GeneratedStory')
        .doc(docId)
        .set(data);
  }

  // Add more Firestore operations as needed
}
