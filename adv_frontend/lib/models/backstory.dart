class Story {
  final String title;
  final String description;
  final String goal;

  Story({
    required this.title,
    required this.description,
    required this.goal,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      goal: json['goal'] ?? '',
    );
  }
}

class BackstoryResponse {
  final List<Story> selectedStory; // This is the correct property name

  BackstoryResponse({required this.selectedStory});

  factory BackstoryResponse.fromJson(Map<String, dynamic> json) {
    var stories = (json['selected_story'] as List)
        .map((story) => Story.fromJson(story))
        .take(4)
        .toList();
    return BackstoryResponse(selectedStory: stories);
  }
}
