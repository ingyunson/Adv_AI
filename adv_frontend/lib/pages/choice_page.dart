import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import 'dart:developer' as developer;

class ChoicePage extends StatefulWidget {
  final bool initialLoading;
  final String story;
  final List<String> choices;
  final String sessionId; // Add sessionId

  const ChoicePage({
    Key? key,
    this.initialLoading = false,
    required this.story,
    required this.choices,
    required this.sessionId, // Add parameter
  }) : super(key: key);

  @override
  _ChoicePageState createState() => _ChoicePageState();
}

class _ChoicePageState extends State<ChoicePage> {
  static const Duration _timeout = Duration(seconds: 60);
  int _turn = 1;
  bool _isLoading = false;
  String _currentStory = '';
  List<String> _currentChoices = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _currentStory = widget.story;
    _currentChoices = widget.choices;
    if (widget.initialLoading) {
      _simulateInitialLoading();
    }
  }

  Future<void> _simulateInitialLoading() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _incrementTurn() async {
    if (_turn < 5) {
      setState(() {
        _isLoading = true;
      });

      // Simulate page loading
      await Future.delayed(
          Duration(milliseconds: 1500 + (500 * (1 + _turn ~/ 3))));

      if (!mounted) return;
      setState(() {
        _turn++;
        _isLoading = false;
      });
    }
  }

  Future<void> _endStory() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate final loading
    await Future.delayed(const Duration(milliseconds: 2000));

    Navigator.of(context).pop();
  }

  Future<void> _onChoiceSelected(int choiceIndex) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _callWithTimeout(() => _apiService.mainStoryLoop(
            sessionId: widget.sessionId,
            choice: _currentChoices[choiceIndex],
            outcome: "User selected option ${choiceIndex + 1}",
          ));

      setState(() {
        _currentStory = response['story'];
        _currentChoices = (response['choices'] as List)
            .map<String>((choice) => choice['description'] as String)
            .toList();
        _turn++;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error in main story loop: $e', error: e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<T> _callWithTimeout<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall().timeout(_timeout, onTimeout: () {
        throw TimeoutException('Request timed out');
      });
    } on TimeoutException catch (_) {
      developer.log('Request timed out, retrying...');
      return await apiCall();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Image.asset(
                          'assets/image_$_turn.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'Turn $_turn',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _currentStory, // Use current story
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        if (_turn < 5) ...[
                          const Text(
                            "Choose one option",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _onChoiceSelected(0),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                              ),
                              child: Text(
                                  _currentChoices[0]), // Use current choices
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _onChoiceSelected(1),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                              ),
                              child: Text(
                                  _currentChoices[1]), // Use current choices
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.of(context).pop();
                                    },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Stop the story'),
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _endStory,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('End the story'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
