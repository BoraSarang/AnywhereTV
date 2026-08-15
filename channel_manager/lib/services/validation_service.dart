import '../models/channel.dart';

enum ValidationSeverity { warning, error }

class ValidationIssue {
  final String channelId;
  final String channelName;
  final ValidationSeverity severity;
  final String message;

  const ValidationIssue({
    required this.channelId,
    required this.channelName,
    required this.severity,
    required this.message,
  });
}

class ValidationService {
  static List<ValidationIssue> validate({
    required List<Channel> channels,
    required List<String> categories,
  }) {
    final issues = <ValidationIssue>[];

    final byName = <String, List<Channel>>{};
    final byId = <String, List<Channel>>{};
    final byStreamUrl = <String, List<Channel>>{};
    final byHandle = <String, List<Channel>>{};
    final byVideoId = <String, List<Channel>>{};

    for (final ch in channels) {
      final nameKey = ch.name.trim().toLowerCase();
      if (nameKey.isNotEmpty) byName.putIfAbsent(nameKey, () => []).add(ch);
      byId.putIfAbsent(ch.id, () => []).add(ch);
      final url = ch.streamUrl?.trim();
      if (url != null && url.isNotEmpty) {
        byStreamUrl.putIfAbsent(url, () => []).add(ch);
      }
      final handle = ch.youtubeHandle?.trim().toLowerCase();
      if (handle != null && handle.isNotEmpty) {
        byHandle.putIfAbsent(handle, () => []).add(ch);
      }
      final videoId = ch.youtubeVideoId?.trim();
      if (videoId != null && videoId.isNotEmpty) {
        byVideoId.putIfAbsent(videoId, () => []).add(ch);
      }
    }

    for (final entry in byName.entries) {
      if (entry.value.length > 1) {
        _addIssue(issues, entry.value, '이름 중복: "${entry.key}"');
      }
    }
    for (final entry in byId.entries) {
      if (entry.value.length > 1) {
        _addIssue(issues, entry.value, 'id 중복: "${entry.key}"');
      }
    }
    for (final entry in byStreamUrl.entries) {
      if (entry.value.length > 1) {
        _addIssue(issues, entry.value, '스트림 URL 중복: "${entry.key}"');
      }
    }
    for (final entry in byHandle.entries) {
      if (entry.value.length > 1) {
        _addIssue(issues, entry.value, 'YouTube 핸들 중복: @${entry.key}');
      }
    }
    for (final entry in byVideoId.entries) {
      if (entry.value.length > 1) {
        _addIssue(issues, entry.value, 'YouTube 동영상 중복: ${entry.key}');
      }
    }

    for (final ch in channels) {
      if (ch.name.trim().isEmpty) {
        issues.add(ValidationIssue(
          channelId: ch.id,
          channelName: ch.name,
          severity: ValidationSeverity.error,
          message: '채널 이름이 비어 있습니다',
        ));
      }
      if (ch.category.isEmpty || !categories.contains(ch.category)) {
        issues.add(ValidationIssue(
          channelId: ch.id,
          channelName: ch.name,
          severity: ValidationSeverity.error,
          message: '카테고리가 없거나 유효하지 않습니다: "${ch.category}"',
        ));
      }
      final hasStream = (ch.streamUrl?.isNotEmpty ?? false) ||
          (ch.youtubeHandle?.isNotEmpty ?? false) ||
          (ch.youtubeVideoId?.isNotEmpty ?? false);
      if (!hasStream) {
        issues.add(ValidationIssue(
          channelId: ch.id,
          channelName: ch.name,
          severity: ValidationSeverity.error,
          message: '스트림 소스가 없습니다 (streamUrl/핸들/동영상 모두 비어 있음)',
        ));
      }
      final logo = ch.logoUrl.trim();
      if (logo.isNotEmpty && !_isHttpUrl(logo)) {
        issues.add(ValidationIssue(
          channelId: ch.id,
          channelName: ch.name,
          severity: ValidationSeverity.warning,
          message: '로고 URL 형식이 올바르지 않습니다: "$logo"',
        ));
      }
    }

    return issues;
  }

  static bool _isHttpUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  static void _addIssue(
    List<ValidationIssue> issues,
    List<Channel> dupes,
    String message,
  ) {
    for (final ch in dupes) {
      issues.add(ValidationIssue(
        channelId: ch.id,
        channelName: ch.name,
        severity: ValidationSeverity.warning,
        message: message,
      ));
    }
  }
}