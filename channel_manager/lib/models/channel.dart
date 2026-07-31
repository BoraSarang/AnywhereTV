class Channel {
  final String id;
  final String name;
  final String logoUrl;
  final String? streamUrl;
  final String? youtubeChannelId;
  final String? youtubeVideoId;
  final String? youtubeHandle;
  final String category;
  final String sourceType;
  final bool isDefaultFavorite;
  final String? resolver;
  final Map<String, dynamic>? resolverData;

  const Channel({
    required this.id,
    required this.name,
    required this.logoUrl,
    this.streamUrl,
    this.youtubeChannelId,
    this.youtubeVideoId,
    this.youtubeHandle,
    required this.category,
    required this.sourceType,
    this.isDefaultFavorite = false,
    this.resolver,
    this.resolverData,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logoUrl'] as String? ?? '',
      streamUrl: json['streamUrl'] as String?,
      youtubeChannelId: json['youtubeChannelId'] as String?,
      youtubeVideoId: json['youtubeVideoId'] as String?,
      youtubeHandle: json['youtubeHandle'] as String?,
      category: json['category'] as String? ?? '',
      sourceType: json['sourceType'] as String? ?? 'hls',
      isDefaultFavorite: json['isDefaultFavorite'] as bool? ?? false,
      resolver: json['resolver'] as String?,
      resolverData: json['resolverData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'streamUrl': streamUrl,
      'youtubeChannelId': youtubeChannelId,
      'youtubeVideoId': youtubeVideoId,
      'youtubeHandle': youtubeHandle,
      'category': category,
      'sourceType': sourceType,
      'isDefaultFavorite': isDefaultFavorite,
      'resolver': resolver,
      'resolverData': resolverData,
    };
  }

  Channel copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? streamUrl,
    String? youtubeChannelId,
    String? youtubeVideoId,
    String? youtubeHandle,
    String? category,
    String? sourceType,
    bool? isDefaultFavorite,
    String? resolver,
    Map<String, dynamic>? resolverData,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      youtubeChannelId: youtubeChannelId ?? this.youtubeChannelId,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      youtubeHandle: youtubeHandle ?? this.youtubeHandle,
      category: category ?? this.category,
      sourceType: sourceType ?? this.sourceType,
      isDefaultFavorite: isDefaultFavorite ?? this.isDefaultFavorite,
      resolver: resolver ?? this.resolver,
      resolverData: resolverData ?? this.resolverData,
    );
  }
}
