import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import 'dart:developer' as developer;

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

class _ChoicePageState extends State<ChoicePage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String _currentStory = '';
  List<String> _currentChoices = [];
  int _turn = 1;

  static const int MAX_TURNS = 5;

  // Design constants
  static const double _padding = 24.0;
  static const double _buttonMargin = 40.0;
  static const double _borderRadius = 12.0;
  static const double _storyFontSize = 18.0;
  static const double _buttonFontSize = 16.0;
  static const double _imageAspectRatio = 1.0; // Add this constant

  @override
  void initState() {
    super.initState();
    developer.log('ChoicePage initState - Initial story: ${widget.story}');
    _currentStory = widget.story;
    _currentChoices = widget.choices;
    if (widget.initialLoading) _simulateInitialLoading();
  }

  Future<void> _simulateInitialLoading() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _onChoiceSelected(int index) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      developer.log('Sending choice: ${_currentChoices[index]}');
      final response = await _apiService.mainStoryLoop(
        sessionId: widget.sessionId,
        choice: _currentChoices[index],
        outcome: 'User selected option ${index + 1}',
      );

      developer.log('Received response: $response');

      setState(() {
        // Use 'description' key from response consistently
        _currentStory = response['description'] ?? '';
        _currentChoices = (response['choices'] as List)
            .map<String>(
                (c) => (c as Map<String, dynamic>)['description'] as String)
            .toList();
        _turn++;
        _isLoading = false;
      });

      developer.log('Updated story: $_currentStory');
      developer.log('Updated choices: $_currentChoices');
    } catch (e) {
      developer.log('Error in main story loop: $e', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _stopStory() {
    // Return to home screen
    Navigator.pushReplacementNamed(context, '/home');
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
                          // Story image
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

                          // Story text
                          Container(
                            margin: const EdgeInsets.all(_padding),
                            padding: const EdgeInsets.all(_padding),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(_borderRadius),
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
                              textAlign: TextAlign.left,
                            ),
                          ),

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
                                      : () => _onChoiceSelected(idx),
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
                              onPressed: _stopStory,
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
                                onPressed: _stopStory,
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
}
