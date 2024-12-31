class StoryState {
  final String currentStory;
  final List<String> choices;
  final int turn;
  final bool isLoading;

  const StoryState({
    required this.currentStory,
    required this.choices,
    required this.turn,
    this.isLoading = false,
  });

  StoryState copyWith({
    String? currentStory,
    List<String>? choices,
    int? turn,
    bool? isLoading,
  }) {
    return StoryState(
      currentStory: currentStory ?? this.currentStory,
      choices: choices ?? this.choices,
      turn: turn ?? this.turn,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
