import 'package:flutter/material.dart';
import '../services/logo_service.dart';

Future<String?> showLogoSearchDialog(BuildContext context, String query) async {
  final results = await LogoService.search(query);
  if (!context.mounted) return null;
  if (results.isEmpty) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로고 검색'),
        content: const Text('일치하는 채널을 찾지 못했습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('로고 검색: $query'),
      content: SizedBox(
        width: 380,
        height: 320,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: results.length,
          itemBuilder: (context, index) {
            final candidate = results[index];
            return ListTile(
              dense: true,
              leading: Image.network(
                candidate.logoUrl,
                width: 32,
                height: 32,
                errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported),
              ),
              title: Text(candidate.name),
              onTap: () => Navigator.pop(ctx, candidate.logoUrl),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('닫기'),
        ),
      ],
    ),
  );
}