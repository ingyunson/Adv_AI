import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;
import '../main.dart' show GradientBackground, HomeScreen;
import '../config/config.dart';

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
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController =
      ScrollController(); // 1. Add controller

  bool _isLoading = false;
  String _currentStory = '';
  List<String> _currentChoices = [];
  List<String> _currentImageFiles = [];
  int _turn = 1;
  final Map<String, String> _choiceOutcomes = {};

  static const int MAX_TURNS = 5;
  static const double _padding = 16;
  static const double _buttonMargin = 20;
  static const double _borderRadius = 16;
  static const double _buttonFontSize = 18;
  static const double _storyFontSize = 20;
  static const double _imageAspectRatio = 1.0;

  @override
  void initState() {
    super.initState();
    developer.log('ChoicePage initState - Initial story: ${widget.story}');
    _currentStory = widget.story;
    _currentChoices = widget.choices;
    _currentImageFiles = widget.imageFiles;
    _isLoading = widget.initialLoading;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _turn / MAX_TURNS,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController, // 2. Attach controller
                      child: Column(
                        children: [
                          _buildStorySection(),
                          // const SizedBox(height: 8),
                          Padding(
                              padding: const EdgeInsets.all(16),
                              child: _buildImageSection()),
                          // const SizedBox(height: 8),
                          if (_turn < MAX_TURNS)
                            ..._buildChoiceButtons(context)
                          else
                            _buildEndButton(context),
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

  // After we update data, jump to the top:
  Future<void> _handleChoice(String choice, int index) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'test';
      final response = await _apiService.mainStoryLoop(
        sessionId: widget.sessionId,
        choice: choice,
        outcome: _choiceOutcomes[choice] ?? '',
        userId: userId,
      );

      final imageList = (response['image_files'] as List<dynamic>?)
              ?.map<String>((e) => e.toString())
              .toList() ??
          [];

      setState(() {
        _currentStory = response['story'] as String? ?? 'No content';
        _currentChoices = (response['choices'] as List?)
                ?.map((item) =>
                    (item as Map<String, dynamic>)['description'] as String? ??
                    '')
                .toList() ??
            [];
        _currentImageFiles = imageList;
        _turn++;
        _isLoading = false;
      });

      // 3. Force scroll to top (jump or animate)
      _scrollController.jumpTo(0.0);
      // _scrollController.animateTo(
      //   0.0,
      //   duration: const Duration(milliseconds: 300),
      //   curve: Curves.easeInOut,
      // );
    } catch (e, stackTrace) {
      developer.log('Error in _handleChoice', error: e, stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStorySection() {
    return Container(
      margin: const EdgeInsets.all(_padding),
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(_borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        _currentStory,
        style: TextStyle(
          fontSize: _storyFontSize,
          height: 1.6,
          color: Colors.grey[850],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    if (_currentImageFiles.isEmpty) {
      return const SizedBox();
    }
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
          child: Image.network(
            _currentImageFiles.first,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.grey[400], size: 48),
                  const SizedBox(height: 8),
                  Text('Failed to load image',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildChoiceButtons(BuildContext context) {
    return [
      for (int i = 0; i < _currentChoices.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _buttonMargin,
            vertical: 8, // 상하 여백 추가
          ),
          child: ElevatedButton(
            onPressed:
                _isLoading ? null : () => _handleChoice(_currentChoices[i], i),
            style: ElevatedButton.styleFrom(
              // 스타일 재사용
              backgroundColor: HomeScreen.kPrimaryColor,
              foregroundColor: HomeScreen.kButtonTextColor,
              minimumSize:
                  const Size(double.infinity, HomeScreen.kButtonHeight),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              _currentChoices[i],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      const SizedBox(height: 20), // 추가 여백
      TextButton.icon(
        onPressed: _handleStop,
        icon: const Icon(Icons.close),
        label: const Text('Stop the Story'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey[600],
        ),
      ),
    ];
  }

  Widget _buildEndButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: _buttonMargin,
        vertical: _padding,
      ),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleStop,
        style: ElevatedButton.styleFrom(
          // Same style from HomeScreen
          backgroundColor: HomeScreen.kPrimaryColor,
          foregroundColor: HomeScreen.kButtonTextColor,
          minimumSize: const Size(double.infinity, HomeScreen.kButtonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'End the Story',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  void _handleStop() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
}
