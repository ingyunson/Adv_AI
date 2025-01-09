import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';

import '../services/api_service.dart';
import '../models/backstory.dart';
import '../pages/choice_page.dart';

class BackstoryPage extends StatefulWidget {
  const BackstoryPage({super.key});

  @override
  State<BackstoryPage> createState() => _BackstoryPageState();
}

class _BackstoryPageState extends State<BackstoryPage> {
  // Use dynamic base URL for local dev vs. Android emulator
  static String _getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000'; // Android emulator
    } else {
      return 'http://127.0.0.1:8000';
    }
  }

  final ApiService _apiService = ApiService(_getBaseUrl());
  bool _isLoading = false;
  BackstoryResponse? _backstoryResponse;
  String? _error;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  // UI constants
  static const double _padding = 20.0;
  static const double _borderRadius = 15.0;
  static const double _elevation = 3.0;

  @override
  void initState() {
    super.initState();
    developer.log('Initializing BackstoryPage');
    _fetchBackstories();
  }

  Future<void> _fetchBackstories() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      developer.log('Starting backstory fetch');
      // We still pass userId to maintain Firestore "created_by" logic
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'test';
      final response = await _apiService.fetchBackstories(userId);

      setState(() {
        _backstoryResponse = response;
        developer.log('Received stories: ${response.selectedStory.length}');
      });
    } catch (e) {
      developer.log('Error fetching backstories: $e', error: e);
      setState(() {
        _error = 'Failed to load backstories. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startStory(Story story) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        developer.log('User ID is null', level: 1000);
        throw Exception('User not authenticated');
      }

      final response = await _apiService.startStory(story, userId);
      developer.log('Start story response: $response'); // Debug log

      // Extract all required parameters
      final sessionId = response['session_id'] as String;
      final newStory = response['story'] as String;
      final newChoices = (response['choices'] as List<dynamic>)
          .map<String>((choice) =>
              (choice as Map<String, dynamic>)['description'] as String)
          .toList();
      final imageFiles = List<String>.from(response['image_files'] ?? []);

      developer.log('Navigating to ChoicePage with:');
      developer.log('sessionId: $sessionId');
      developer.log('story: $newStory');
      developer.log('choices: $newChoices');
      developer.log('imageFiles: $imageFiles');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChoicePage(
            story: newStory,
            choices: newChoices,
            sessionId: sessionId,
            imageFiles: imageFiles,
            initialLoading: false,
          ),
        ),
      );
    } catch (e) {
      developer.log('Error starting story: $e', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start story')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Show a pop-up dialog if you want a separate "preview" approach
  void _showStoryDialog(BuildContext context, Story story) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: constraints.maxWidth * 0.9,
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_borderRadius),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(_padding),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(_borderRadius),
                          topRight: Radius.circular(_borderRadius),
                        ),
                      ),
                      child: Text(
                        story.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(_padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.description,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(_borderRadius / 2),
                              border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.flag_outlined,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Goal',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        story.goal ?? 'No goal specified',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color:
                                              Colors.black87.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _startStory(story);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  elevation: _elevation,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(_borderRadius),
                                  ),
                                ),
                                child: const Text('Start Story'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: _padding),
          Text(
            _error!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: _padding),
          ElevatedButton(
            onPressed: _fetchBackstories,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
              elevation: _elevation,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesList() {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _backstoryResponse!.selectedStory.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final story = _backstoryResponse!.selectedStory[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  elevation: _elevation,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_borderRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(_padding),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(_borderRadius),
                            topRight: Radius.circular(_borderRadius),
                          ),
                        ),
                        child: Text(
                          story.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(_padding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                story.description,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(_borderRadius / 2),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.flag_outlined,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        story.goal ?? 'Begin your journey',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _backstoryResponse!.selectedStory.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.all(_padding),
          child: ElevatedButton(
            onPressed: () =>
                _startStory(_backstoryResponse!.selectedStory[_currentPage]),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text(
              'Start This Journey',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Main background gradient
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BackButton(
                  color: Colors.white,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: _padding),
                Text(
                  'Choose Your Story',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: _padding),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                      : _error != null
                          ? _buildErrorWidget()
                          : (_backstoryResponse == null ||
                                  _backstoryResponse!.selectedStory.isEmpty)
                              ? const Center(
                                  child: Text(
                                    'No backstories available.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              : _buildStoriesList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
