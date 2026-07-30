class EpgProgram {
  final String channelId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? description;
  final String? category;

  const EpgProgram({
    required this.channelId,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
    this.category,
  });

  factory EpgProgram.fromJson(Map<String, dynamic> json) {
    return EpgProgram(
      channelId: json['channelId'] as String,
      title: json['title'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      description: json['description'] as String?,
      category: json['category'] as String?,
    );
  }

  bool get isCurrentlyAiring {
    final now = DateTime.now();
    return startTime.isBefore(now) && endTime.isAfter(now);
  }
}
