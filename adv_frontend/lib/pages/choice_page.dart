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
  final String story;
  final List<String> choices;
  final String sessionId;
  final List<String> imageFiles;
  final bool initialLoading;

  const ChoicePage({
    super.key,
    required this.story,
    required this.choices,
    required this.sessionId,
    required this.imageFiles,
    this.initialLoading = false,
  });

  @override
  _ChoicePageState createState() => _ChoicePageState();
}

class _ChoicePageState extends State<ChoicePage> {
  final ApiService _apiService = ApiService(_getBaseUrl());
  bool _isLoading = false;
  String _currentStory = '';
  List<String> _currentChoices = [];
  int _turn = 1;
  List<String> _currentImageFiles = []; // Holds image file URLs from the API

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
    _currentImageFiles = widget.imageFiles; // Initialize with passed imageFiles
    _isLoading = widget.initialLoading;
    developer.log('Initial image files: $_currentImageFiles'); // Debug log
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
                          _buildImageSection(),

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
      final response = await _apiService.mainStoryLoop(
        sessionId: widget.sessionId,
        choice: choice,
        outcome: _choiceOutcomes[choice] ?? '',
        userId: userId,
      );

      developer.log('Raw response: $response');

      // Log image files from response
      final imageList = (response['image_files'] as List<dynamic>?)
              ?.map<String>((e) => e.toString())
              .toList() ??
          [];
      developer.log('Received image files: $imageList');

      setState(() {
        _currentStory =
            response['story'] as String? ?? 'Story content not available';
        _currentChoices = (response['choices'] as List?)
                ?.map((item) =>
                    (item as Map<String, dynamic>)['description'] as String? ??
                    '')
                .toList() ??
            [];
        _currentImageFiles = imageList;
        developer.log('Updated _currentImageFiles: $_currentImageFiles');
        _turn++;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      developer.log('Error in _handleChoice', error: e, stackTrace: stackTrace);
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

  Widget _buildImageSection() {
    developer.log(
        'Building image section. Current image files: $_currentImageFiles');

    return AspectRatio(
      aspectRatio: _imageAspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_borderRadius),
          child: _currentImageFiles.isNotEmpty
              ? Image.network(
                  _currentImageFiles.first,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      developer.log('Image loaded successfully');
                      return child;
                    }
                    developer.log(
                        'Loading image... Progress: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    developer.log(
                        'Error loading image from URL: ${_currentImageFiles.first}',
                        error: error,
                        stackTrace: stackTrace);
                    return Container(
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image,
                              color: Colors.grey[400], size: 48),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_outlined),
                ),
        ),
      ),
    );
  }
}
