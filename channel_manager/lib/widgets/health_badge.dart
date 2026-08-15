import 'package:flutter/material.dart';
import '../services/health_service.dart';

class HealthBadge extends StatelessWidget {
  final HealthStatus status;
  final String? message;
  final int latencyMs;

  const HealthBadge({
    super.key,
    required this.status,
    this.message,
    this.latencyMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, tooltip) = switch (status) {
      HealthStatus.ok => (
          Icons.check_circle,
          Colors.green,
          message ?? '온라인 (${latencyMs}ms)',
        ),
      HealthStatus.failed => (
          Icons.cancel,
          Colors.red,
          message ?? '오프라인',
        ),
      HealthStatus.unknown => (
          Icons.radio_button_unchecked,
          Colors.grey,
          message ?? '미확인',
        ),
    };
    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 18, color: color),
    );
  }
}