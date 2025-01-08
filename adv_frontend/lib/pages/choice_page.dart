import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;

// Helper function to determine appropriate base URL.
String _getBaseUrl() {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000';
  } else {
    return 'http://127.0.0.1:8000';
  }
}

class ChoicePage extends StatefulWidget {
  final bool initialLoading;
  final String story;
  final List<String> choices;
  final String sessionId;

  const ChoicePage({
    Key? key,
    this.initialLoading = false,
    required this.story,
    required this.choices,
    required this.sessionId,
  }) : super(key: key);

  @override
  _ChoicePageState createState() => _ChoicePageState();
}

class _ChoicePageState extends State<ChoicePage> {
  final ApiService _apiService = ApiService(_getBaseUrl());
  bool _isLoading = false;
  String _currentStory = '';
  List<String> _currentChoices = [];
  int _turn = 1;

  // Example max turns
  static const int MAX_TURNS = 5;

  // Optional UI values
  static const double _imageAspectRatio = 1;
  static const double _borderRadius = 8;
  static const double _padding = 16;
  static const double _buttonMargin = 20;
  static const double _buttonFontSize = 16;
  static const double _storyFontSize = 16;

  // Track outcomes if needed
  final Map<String, String> _choiceOutcomes = {};

  @override
  void initState() {
    super.initState();
    developer.log('ChoicePage initState - Initial story: ${widget.story}');
    _currentStory = widget.story;
    _currentChoices = widget.choices;
    _isLoading = widget.initialLoading;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Progress indicator
                  LinearProgressIndicator(
                    value: _turn / MAX_TURNS,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Sample story image
                          AspectRatio(
                            aspectRatio: _imageAspectRatio,
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(_borderRadius),
                                      child: Image.asset(
                                        'assets/image_$_turn.png',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.broken_image),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),

                          // Display the story text
                          _buildStorySection(),

                          // Choices section
                          if (_turn < MAX_TURNS) ...[
                            ..._currentChoices.map((choice) {
                              final idx = _currentChoices.indexOf(choice);
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: _buttonMargin,
                                  vertical: 8,
                                ),
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _handleChoice(choice, idx),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                      horizontal: _padding,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(_borderRadius),
                                    ),
                                    elevation: 3,
                                  ),
                                  child: Text(
                                    choice,
                                    style: const TextStyle(
                                      fontSize: _buttonFontSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 20),
                            TextButton.icon(
                              onPressed: _handleStop,
                              icon: const Icon(Icons.close),
                              label: const Text('Stop the Story'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                              ),
                            ),
                          ] else ...[
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: _buttonMargin,
                                vertical: _padding,
                              ),
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _handleStop,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                    horizontal: _padding,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(_borderRadius),
                                  ),
                                  elevation: 3,
                                ),
                                child: const Text(
                                  'End the Story',
                                  style: TextStyle(
                                    fontSize: _buttonFontSize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: _padding),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleChoice(String choice, int index) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    developer.log('Handling choice: $choice at index: $index');

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'test';
      // Call the mainStoryLoop endpoint, which queries Firestore
      final response = await _apiService.mainStoryLoop(
        sessionId: widget.sessionId,
        choice: choice,
        outcome: _choiceOutcomes[choice] ?? '',
        userId: userId,
      );

      developer.log('Raw response: $response');

      // Extract story and choices from the Firestore data returned
      final story =
          response['story'] as String? ?? 'Story content not available';
      final choicesList = (response['choices'] as List?)?.map((item) {
            if (item is Map<String, dynamic>) {
              return {
                'description': item['description'] as String? ?? '',
                'outcome': item['outcome'] as String? ?? ''
              };
            }
            return {'description': '', 'outcome': ''};
          }).toList() ??
          [];

      if (!mounted) return;

      // Update UI with the story data from Firestore
      setState(() {
        _currentStory = story;
        _currentChoices =
            choicesList.map((c) => c['description'] as String).toList();

        // Update outcomes map for next turn
        for (final c in choicesList) {
          _choiceOutcomes[c['description'] as String] = c['outcome'] ?? '';
        }

        _turn++;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      developer.log('Error in _handleChoice',
          error: e, stackTrace: stackTrace, level: 1000);
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _handleStop() async {
    try {
      developer.log('Handling stop action...');
      if (!mounted) return;
      developer.log('Navigating to home screen...');
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      developer.log('Error in handleStop: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error returning to home screen')),
      );
    }
  }

  BoxDecoration _getStoryDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  TextStyle _getStoryTextStyle() {
    return TextStyle(
      fontSize: _storyFontSize,
      height: 1.6,
      color: Colors.grey[850],
      fontFamily: 'NotoSans',
    );
  }

  Widget _buildStorySection() {
    return Container(
      margin: const EdgeInsets.all(_padding),
      padding: const EdgeInsets.all(_padding),
      decoration: _getStoryDecoration(),
      child: Text(
        _currentStory,
        style: _getStoryTextStyle(),
      ),
    );
  }
}
